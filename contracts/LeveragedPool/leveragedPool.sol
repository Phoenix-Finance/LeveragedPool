pragma solidity =0.5.16;
import "../proxy/fnxProxy.sol";
import "../rebaseToken/IRebaseToken.sol";
import "../uniswap/IUniswapV2Router02.sol";
import "../stakePool/IStakePool.sol";
import "../interface/IFNXOracle.sol";
import "../ERC20/safeErc20.sol";
import "../modules/SafeMath.sol";

contract leveragedPool is ImportOracle{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    uint256 constant internal calDecimal = 1e18; 
    uint256 constant internal feeDecimal = 1e8; 
    struct leverageInfo {
        uint8 id;
        bool bRebase;
        address token;
        IStakePool stakePool;
        uint256 leverageRate;
        uint256 rebalanceWorth;
        uint256 defaultRebalanceWorth;
        IRebaseToken leverageToken;

    }
    leverageInfo internal leverageCoin;
    leverageInfo internal hedgeCoin;
    IUniswapV2Router02 internal IUniswap;
    uint256 internal rebasePrice;
    uint256 internal currentPrice;
    uint256 internal buyFee;
    uint256 internal sellFee;
    uint256 internal rebalanceFee;
    uint256 internal defaultLeverageRatio;
    uint256 internal liquidateThreshold;
    address payable internal feeAddress;

    event DebugEvent(address indexed from,uint256 value1,uint256 value2);
    constructor() public {

    }
    function() external payable {
        
    }
    function initialize() public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    function setFeeAddress(address payable addrFee) onlyOwner public {
        feeAddress = addrFee;
    }
    function leverageTokens() public view returns (address,address){
        return (address(leverageCoin.leverageToken),address(hedgeCoin.leverageToken));
    }
    function setLeverageFee(uint256 _buyFee,uint256 _sellFee,uint256 _rebalanceFee) onlyOwner public{
        buyFee = _buyFee;
        sellFee = _sellFee;
        rebalanceFee = _rebalanceFee;
    }
    function getLeverageFee()public view returns(uint256,uint256,uint256){
        return (buyFee,sellFee,rebalanceFee);
    }
    function setLeveragePoolInfo(address payable _feeAddress,address rebaseImplement,uint256 rebaseVersion,address leveragePool,address hedgePool,address oracle,address swapRouter,
        uint256 fees,uint256 _liquidateThreshold,uint256 rebaseWorth,string memory baseCoinName) public onlyOwner {
        feeAddress = _feeAddress;
        uint256 lRate = uint64(fees>>192);
        defaultLeverageRatio = lRate;
        _oracle = IFNXOracle(oracle);
        leverageCoin.id = 0;
        leverageCoin.stakePool = IStakePool(leveragePool);
        leverageCoin.leverageRate = lRate;
        leverageCoin.rebalanceWorth = uint128(rebaseWorth);
        leverageCoin.defaultRebalanceWorth = uint128(rebaseWorth);
        fnxProxy newToken = new fnxProxy(rebaseImplement,rebaseVersion);
        leverageCoin.leverageToken = IRebaseToken(address(newToken));
        leverageCoin.token = leverageCoin.stakePool.poolToken();
        if(leverageCoin.token != address(0)){
            IERC20 oToken = IERC20(leverageCoin.token);
            oToken.safeApprove(swapRouter,uint256(-1));
            oToken.safeApprove(leveragePool,uint256(-1));
        }
        hedgeCoin.id = 1;
        hedgeCoin.stakePool = IStakePool(hedgePool);
        hedgeCoin.leverageRate = lRate;
        hedgeCoin.rebalanceWorth = uint128(rebaseWorth>>128);
        hedgeCoin.defaultRebalanceWorth = hedgeCoin.rebalanceWorth;
        newToken = new fnxProxy(rebaseImplement,rebaseVersion);
        hedgeCoin.leverageToken = IRebaseToken(address(newToken));
        hedgeCoin.token = hedgeCoin.stakePool.poolToken();
        if(hedgeCoin.token != address(0)){
            IERC20 oToken = IERC20(hedgeCoin.token);
            oToken.safeApprove(swapRouter,uint256(-1));
            oToken.safeApprove(hedgePool,uint256(-1));
        }
        buyFee = uint64(fees);
        sellFee = uint64(fees>>64);
        rebalanceFee = uint64(fees>>128);
        liquidateThreshold = _liquidateThreshold;
        string memory token0 = (leverageCoin.token == address(0)) ? baseCoinName : IERC20(leverageCoin.token).symbol();
        string memory token1 = (hedgeCoin.token == address(0)) ? baseCoinName : IERC20(hedgeCoin.token).symbol();
        string memory suffix = leverageSuffix(lRate);

        string memory leverageName = string(abi.encodePacked("LPT_",token0,uint8(95),token1,suffix));
        string memory hedgeName = string(abi.encodePacked("HPT_",token1,uint8(95),token0,suffix));

        leverageCoin.leverageToken.changeTokenName(leverageName,leverageName,leverageCoin.token);
        hedgeCoin.leverageToken.changeTokenName(hedgeName,hedgeName,hedgeCoin.token);
        IUniswap = IUniswapV2Router02(swapRouter);
        rebasePrice = _getUnderlyingPriceView(0);
    }
    function getDefaultLeverageRate()public view returns (uint256){
        return defaultLeverageRatio;
    }
    function leverageRates()public view returns (uint256,uint256){
        return (leverageCoin.leverageRate,hedgeCoin.leverageRate);
    }
    function UnderlyingPrice(uint8 id) internal view returns (uint256){
        if (id == 0){
            return currentPrice;
        }else{
            return calDecimal*calDecimal/currentPrice;
        }
    }
    function getRebasePrice(uint8 id) internal view returns (uint256){
        if (id == 0){
            return rebasePrice;
        }else{
            return calDecimal*calDecimal/rebasePrice;
        }
    }
    function underlyingBalance(uint8 id)internal view returns (uint256){
        address token = (id == 0) ? hedgeCoin.token : leverageCoin.token;
        if (token == address(0)){
            return address(this).balance;
        }else{
            return IERC20(token).balanceOf(address(this));
        }
    }
    function _coinTotalSupply(IRebaseToken leverageToken) internal view returns (uint256){
        return leverageToken.totalSupply();
    }

    function getTotalworths() public view returns(uint256,uint256){
        return (_totalWorthView(leverageCoin,_getUnderlyingPriceView(leverageCoin.id)),_totalWorthView(hedgeCoin,_getUnderlyingPriceView(hedgeCoin.id)));
    }
    function getTokenNetworths() public view returns(uint256,uint256){
        return (_tokenNetworthView(leverageCoin),_tokenNetworthView(hedgeCoin));
    }
    function _totalWorthView(leverageInfo memory coinInfo,uint256 underlyingPrice) internal view returns (uint256){
        uint256 totalSup = coinInfo.leverageToken.totalSupply();
        uint256 allLoan = totalSup.mul(coinInfo.rebalanceWorth)/feeDecimal;
        allLoan = allLoan.mul(coinInfo.leverageRate-feeDecimal);
        return underlyingPrice.mul(underlyingBalance(coinInfo.id)).sub(allLoan);
    }
    function _totalWorth(leverageInfo memory coinInfo) internal view returns (uint256){
        return _totalWorthView(coinInfo,UnderlyingPrice(coinInfo.id));
    }
    function _tokenNetworthBuy(leverageInfo memory coinInfo) internal view returns (uint256){
        uint256 curPrice = UnderlyingPrice(coinInfo.id);
        uint256 rePrice = getRebasePrice(coinInfo.id);
        return ((curPrice*3).mul(coinInfo.rebalanceWorth)/rePrice).sub(coinInfo.rebalanceWorth*2);
    }
    function _tokenNetworthView(leverageInfo memory coinInfo) internal view returns (uint256){
        uint256 tokenNum = _coinTotalSupply(coinInfo.leverageToken);
        if (tokenNum == 0){
            return coinInfo.rebalanceWorth;
        }else{
            return _totalWorthView(coinInfo,_getUnderlyingPriceView(coinInfo.id))/tokenNum;
        }
    }
    function _tokenNetworth(leverageInfo memory coinInfo) internal view returns (uint256){
        uint256 tokenNum = _coinTotalSupply(coinInfo.leverageToken);
        if (tokenNum == 0){
            return coinInfo.rebalanceWorth;
        }else{
            return _totalWorth(coinInfo)/tokenNum;
        }
    }
    function buyLeverage(uint256 amount,uint256 minAmount,bytes memory data) public payable{
        _buy(leverageCoin,amount,minAmount,data);
    }
    function buyHedge(uint256 amount,uint256 minAmount,bytes memory data) public payable{
        _buy(hedgeCoin, amount,minAmount,data);
    }
    function buyLeverage2(uint256 amount,uint256 minAmount,bytes memory data) public payable{
        _buy2(leverageCoin,amount,minAmount,data);
    }
    function buyHedge2(uint256 amount,uint256 minAmount,bytes memory data) public payable{
        _buy2(hedgeCoin, amount,minAmount,data);
    }
    function sellLeverage(uint256 amount,uint256 minAmount,bytes memory data) public payable{
        _sell(leverageCoin,amount,minAmount,data);
    }
    function sellHedge(uint256 amount,uint256 minAmount,bytes memory data) public payable{
        _sell(hedgeCoin, amount,minAmount,data);
    }
    function _buy2(leverageInfo memory coinInfo,uint256 amount,uint256 minAmount,bytes memory /*data*/) getUnderlyingPrice internal{
        address inputToken = (coinInfo.id == 0) ? hedgeCoin.token : leverageCoin.token;
        amount = _redeemBuyFeeSub(inputToken,amount);
        uint256 leverageAmount = amount.mul(UnderlyingPrice(coinInfo.id))/_tokenNetworthBuy(coinInfo);
        _buySub(coinInfo,leverageAmount,0,minAmount);
    }
    function _buy(leverageInfo memory coinInfo,uint256 amount,uint256 minAmount,bytes memory /*data*/) getUnderlyingPrice internal{
        amount = _redeemBuyFeeSub(coinInfo.token,amount);
        uint256 leverageAmount = amount.mul(calDecimal)/_tokenNetworthBuy(coinInfo);
        _buySub(coinInfo,leverageAmount,amount,minAmount);
    }
    function _redeemBuyFeeSub(address token,uint256 amount) internal returns(uint256){
        amount = getPayableAmount(token,amount);
        require(amount > 0, 'buy amount is zero');
        uint256 fee;
        (amount,fee) = getFees(buyFee,amount);
        if(fee>0){
            _redeem(feeAddress,token, fee);
        } 
        return amount;
    }
    function _buySub(leverageInfo memory coinInfo,uint256 leverageAmount,uint256 amount,uint256 minAmount) internal{
        require(leverageAmount>=minAmount,"token amount is less than minAmount");
        emit DebugEvent(address(0x111),leverageAmount, _tokenNetworth(coinInfo));
        uint256 userLoan = leverageAmount.mul(coinInfo.rebalanceWorth)/calDecimal;
        userLoan = userLoan.mul(coinInfo.leverageRate-feeDecimal)/feeDecimal;
        emit DebugEvent(address(0x222),amount, userLoan);
        userLoan = coinInfo.stakePool.borrow(userLoan);
        amount = swap(true,coinInfo.id,userLoan.add(amount),0,true);
        emit DebugEvent(address(0x333),amount, userLoan);
        coinInfo.leverageToken.mint(msg.sender,leverageAmount);
    }
    function _sell(leverageInfo memory coinInfo,uint256 amount,uint256 minAmount,bytes memory /*data*/) getUnderlyingPrice internal{
        require(amount > 0, 'sell amount is zero');
        uint256 userLoan = amount.mul(coinInfo.rebalanceWorth)/feeDecimal;
        userLoan = userLoan.mul(coinInfo.leverageRate-feeDecimal);
        uint256 getLoan = coinInfo.stakePool.loan(address(this)).mul(calDecimal);
        emit DebugEvent(address(0x123), getLoan, userLoan);
        if (userLoan > getLoan) {
            userLoan = getLoan;
        }
        uint256 userPayback =  amount.mul(_tokenNetworth(coinInfo));
        emit DebugEvent(address(0x333), underlyingBalance(0), underlyingBalance(1));
        uint256 allSell = swap(false,coinInfo.id,userLoan.add(userPayback)/UnderlyingPrice(coinInfo.id),0,true);
        userLoan = userLoan/calDecimal;
        emit DebugEvent(address(111), allSell, userLoan);
        (uint256 repay,uint256 fee) = getFees(sellFee,allSell.sub(userLoan));
        emit DebugEvent(address(0x222), repay, fee);
        emit DebugEvent(address(111), underlyingBalance(0), underlyingBalance(1));
        require(repay >= minAmount, "Repay amount is less than minAmount");
        _repay(coinInfo,userLoan);
        _redeem(msg.sender,coinInfo.token,repay);
        coinInfo.leverageToken.burn(msg.sender,amount);
        emit DebugEvent(address(0x555), fee, underlyingBalance(0));
        _redeem(feeAddress, coinInfo.token, fee);
    }
    
    function _settle(leverageInfo storage coinInfo) internal returns(uint256,uint256){
        uint256 tokenNum = _coinTotalSupply(coinInfo.leverageToken);
        if (tokenNum == 0){
            return (0,0);
        }
        uint256 insterest = coinInfo.stakePool.interestRate();
        uint256 curPrice = UnderlyingPrice(coinInfo.id);
        uint256 oldUnderlying = curPrice.mul(underlyingBalance(coinInfo.id))/calDecimal;
        uint256 totalWorth = _totalWorth(coinInfo);
        uint256 fee;
        (totalWorth,fee) = getFees(rebalanceFee,totalWorth);
        fee = fee/calDecimal;
        if(fee>0){
            _redeem(feeAddress,coinInfo.token, fee);
        } 
        if (coinInfo.bRebase){
            uint256 newSupply = totalWorth/coinInfo.rebalanceWorth;
            coinInfo.leverageToken.calRebaseRatio(newSupply);
        }else{
            coinInfo.rebalanceWorth = totalWorth/tokenNum;
        }
        totalWorth = totalWorth/calDecimal;
        uint256 allLoan = totalWorth.mul(coinInfo.leverageRate-feeDecimal)/feeDecimal;
        uint256 poolBalance = coinInfo.stakePool.poolBalance();
        emit DebugEvent(address(3), allLoan, poolBalance);
        if(allLoan <= poolBalance){
            coinInfo.leverageRate = defaultLeverageRatio;
        }else{
            allLoan = poolBalance;
            coinInfo.leverageRate = poolBalance.mul(feeDecimal)/totalWorth + feeDecimal;
        } 
        uint256 loadInterest = allLoan.mul(insterest)/1e8;
        emit DebugEvent(address(0x321), loadInterest, coinInfo.rebalanceWorth);
        uint256 newUnderlying = totalWorth+allLoan-loadInterest;
        if(oldUnderlying>newUnderlying){
            return (0,oldUnderlying-newUnderlying);
        }else{
            return (newUnderlying-oldUnderlying,0);
        }
    }
    function rebalance() getUnderlyingPrice public {
        (uint256 buyLev,uint256 sellLev) = _settle(leverageCoin);
        (uint256 buyHe,uint256 sellHe) = _settle(hedgeCoin);
        rebasePrice = UnderlyingPrice(0);
        uint256 _curPrice = rebasePrice;
        emit DebugEvent(address(0x1221), buyHe, sellHe);
        emit DebugEvent(address(0x1222), _curPrice, sellHe.mul(_curPrice)/calDecimal);
        if (buyLev>0){
            leverageCoin.stakePool.borrowAndInterest(buyLev);
        }
        if(buyHe>0){
            hedgeCoin.stakePool.borrowAndInterest(buyHe);
        }
        if (buyLev>0 && buyHe>0){
            buyHe = _curPrice.mul(buyHe);
            buyLev = buyLev.mul(calDecimal);
            if(buyLev>buyHe){
                swap(true,0,(buyLev - buyHe)/calDecimal,(buyLev - buyHe)/_curPrice/2,true);
            }else{
                swap(false,0,(buyHe - buyLev)/_curPrice,(buyHe - buyLev)/calDecimal/2,true);
            }
        }else if(sellLev>0 && sellHe>0){
            uint256 sellHe1 = _curPrice.mul(sellHe);
            uint256 sellLev1 = sellLev.mul(calDecimal);
            if(sellLev1>sellHe1){
                sellLev1 = (sellLev1-sellHe1);
                sellHe1 = sellLev1/calDecimal;
                sellLev1 = sellLev1.add(sellLev1/10)/_curPrice;
                swap(false,0,sellLev1,sellHe1,false);
            }else{
                sellLev1 = (sellHe1-sellLev1);
                sellHe1 = sellLev1.add(sellLev1)/calDecimal;
                sellLev1 =  sellLev1/_curPrice;
                swap(true,0,sellHe1,sellLev1,false);
            }
        }else{
            if (buyLev>0){
                swap(true,0,buyLev,buyLev.mul(_curPrice)/_curPrice/2,true);
            }else if (sellLev>0){
                swap(false,0,sellLev.add(sellLev/10).mul(calDecimal)/_curPrice,sellLev,false);
            }
            if(buyHe>0){
                swap(false,0,buyHe,buyHe.mul(_curPrice)/calDecimal/2,true);
            }else if(sellHe>0){
                emit DebugEvent(address(13), sellHe.add(sellHe/10).mul(_curPrice)/calDecimal, sellHe);
                swap(true,0,sellHe.add(sellHe/10).mul(_curPrice)/calDecimal,sellHe,false);
            }
        }
        emit DebugEvent(address(14), underlyingBalance(1), underlyingBalance(0));
        if(buyLev == 0){
            _repayAndInterest(leverageCoin,sellLev);
        }
        if(buyHe == 0){
            _repayAndInterest(hedgeCoin,sellHe);
        }
    }
    function liquidateLeverage() public {
        _liquidate(leverageCoin);
    }
    function liquidateHedge() public {
        _liquidate(hedgeCoin);
    }
    function _liquidate(leverageInfo storage coinInfo) canLiquidate(coinInfo)  internal{
        //all selled
        uint256 amount = swap(false,coinInfo.id,underlyingBalance(coinInfo.id),0,true);
        uint256 fee;
        (amount,fee) = getFees(rebalanceFee,amount);
        if(fee>0){
            _redeem(feeAddress,coinInfo.token, fee);
        } 
        uint256 allLoan = coinInfo.stakePool.loan(address(this));
        if (amount > allLoan){
            _repay(coinInfo,allLoan);
            _redeem(address(uint160(address(coinInfo.leverageToken))),coinInfo.token,amount-allLoan);
            coinInfo.leverageToken.newErc20(amount-allLoan);
        }else{
            _repay(coinInfo,amount);
        }
    }
    function _repay(leverageInfo memory coinInfo,uint256 amount)internal{
        if (coinInfo.token == address(0)){
            emit DebugEvent(coinInfo.token, amount, address(this).balance);
            coinInfo.stakePool.repay.value(amount)(amount);
        }else{
            coinInfo.stakePool.repay(amount);
        }
    }
    function _repayAndInterest(leverageInfo memory coinInfo,uint256 amount)internal{
        if (coinInfo.token == address(0)){
            coinInfo.stakePool.repayAndInterest.value(amount)(amount);
        }else{
            coinInfo.stakePool.repayAndInterest(amount);
        }
    }
    function getFees(uint256 feeRatio,uint256 amount) internal pure returns (uint256,uint256){
        uint256 fee = amount.mul(feeRatio)/feeDecimal;
        return(amount.sub(fee),fee);
    }

    function swap(bool buy,uint8 id,uint256 amount0,uint256 amount1,bool firstExact)internal returns (uint256) {
        return (id == 0) == buy ? _swap(leverageCoin.token,hedgeCoin.token,amount0,amount1,firstExact) : 
            _swap(hedgeCoin.token,leverageCoin.token,amount0,amount1,firstExact);
    }
    function _swap(address token0,address token1,uint256 amount0,uint256 amount1,bool firstExact) internal returns (uint256) {
        address[] memory path = new address[](2);
        uint[] memory amounts;
        if(token0 == address(0)){
            path[0] = IUniswap.WETH();
            path[1] = token1;
            if (!firstExact){
                amounts = IUniswap.swapETHForExactTokens.value(amount0)(amount1, path, address(this), now+30);
            }else{
                amounts = IUniswap.swapExactETHForTokens.value(amount0)(amount1, path, address(this), now+30);
            } 
        }else if(token1 == address(0)){
            path[0] = token0;
            path[1] = IUniswap.WETH();
            if (!firstExact){
                amounts = IUniswap.swapTokensForExactETH(amount1,amount0, path, address(this), now+30);
            }else{
                amounts = IUniswap.swapExactTokensForETH(amount0,amount1, path, address(this), now+30);
            }
        }else{
            path[0] = token0;
            path[1] = token1;
            if (!firstExact){
                amounts = IUniswap.swapTokensForExactTokens(amount1,amount0, path, address(this), now+30);
            }else{
                amounts = IUniswap.swapExactTokensForTokens(amount0,amount1, path, address(this), now+30);
            }
        }
        return amounts[amounts.length-1];
    }
    function getPayableAmount(address stakeCoin,uint256 amount) internal returns (uint256) {
        if (stakeCoin == address(0)){
            amount = msg.value;
        }else if (amount > 0){
            IERC20 oToken = IERC20(stakeCoin);
            oToken.safeTransferFrom(msg.sender, address(this), amount);
        }
        return amount;
    }
        /**
     * @dev An auxiliary foundation which transter amount stake coins to recieptor.
     * @param recieptor recieptor recieptor's account.
     * @param stakeCoin stake address
     * @param amount redeem amount.
     */
    function _redeem(address payable recieptor,address stakeCoin,uint256 amount) internal{
        if (stakeCoin == address(0)){
            recieptor.transfer(amount);
        }else{
            IERC20 token = IERC20(stakeCoin);
            token.safeTransfer(recieptor,amount);
        }
    }
    function _getUnderlyingPriceView(uint8 id) internal view returns(uint256){
        uint256[] memory assets = new uint256[](2);
        assets[0] = uint256(leverageCoin.token);
        assets[1] = uint256(hedgeCoin.token);
        uint256[]memory prices = oraclegetPrices(assets);
        return id == 0 ? prices[1]*calDecimal/prices[0] : prices[0]*calDecimal/prices[1];
    }
    modifier canLiquidate(leverageInfo memory coinInfo){
        require(_coinTotalSupply(coinInfo.leverageToken)>0,"Liquidate : current pool is empty!");
        currentPrice = _getUnderlyingPriceView(0);
        uint256 allLoan = coinInfo.rebalanceWorth.mul(coinInfo.leverageRate-feeDecimal);
        require(UnderlyingPrice(coinInfo.id).mul(feeDecimal+liquidateThreshold)<allLoan,"Liquidate: current price is not under the threshold!");
        _;
    }
    modifier getUnderlyingPrice(){
        currentPrice = _getUnderlyingPriceView(0);
        _;
    }
    function leverageSuffix(uint256 leverageRatio) internal pure returns (string memory){
        if (leverageRatio == 0) return "0";
        uint256 integer = leverageRatio*10/feeDecimal;
        uint8 fraction = uint8(integer%10+48);
        integer = integer/10;
        uint8 ten = uint8(integer/10+48);
        uint8 unit = uint8(integer%10+48);
        bytes memory suffix = new bytes(7);
        suffix[0] = bytes1(uint8(95));
        suffix[1] = bytes1(uint8(88));
        uint len = 2;
        if(ten>48){
                suffix[len++] = bytes1(ten);
            }
        suffix[len++] = bytes1(unit);
        if (fraction>48){
            suffix[len++] = bytes1(uint8(46));
            suffix[len++] = bytes1(fraction);
        }
        bytes memory newSuffix = new bytes(len);
        for(uint i=0;i<len;i++){
            newSuffix[i] = suffix[i];
        }
        return string(newSuffix);
    }

}