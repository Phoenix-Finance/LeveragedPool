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
    struct leverageInfo {
        uint8 id;
        IStakePool leveragePool;
        uint256 leverageRate;
        uint64 buyFee;
        uint64 sellFee;
        uint64 rebalanceFee;
        uint128 rebalanceWorth;
        uint128 defaultRebalanceWorth;
        IRebaseToken leverageToken;
        address token;
    }
    leverageInfo internal leverageCoin;
    leverageInfo internal hedgeCoin;
    IUniswapV2Router02 internal IUniswap;
    uint256 internal rebasePrice;
    uint256 internal currentPrice;

    address payable internal feeAddress;
    uint256 internal defaultLeverageRatio;
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
    function setLeverageFee(uint64 buyFee,uint64 sellFee,uint64 rebalanceFee) onlyOwner public{
        leverageCoin.buyFee = buyFee;
        leverageCoin.sellFee = sellFee;
        leverageCoin.rebalanceFee = rebalanceFee;
    }
    function setHedgeFee(uint64 buyFee,uint64 sellFee,uint64 rebalanceFee) onlyOwner public{
        hedgeCoin.buyFee = buyFee;
        hedgeCoin.sellFee = sellFee;
        hedgeCoin.rebalanceFee = rebalanceFee;
    }
    function getLeverageFee()public view returns(uint64,uint64,uint64){
        return (leverageCoin.buyFee,leverageCoin.sellFee,leverageCoin.rebalanceFee);
    }
    function getHedgeFee()public view returns(uint64,uint64,uint64){
        return (hedgeCoin.buyFee,hedgeCoin.sellFee,hedgeCoin.rebalanceFee);
    }
    function setLeveragePoolInfo(address rebaseImplement,uint256 rebaseVersion,address leveragePool,address hedgePool,address oracle,address swapRouter,
        uint256 leverageRatio,uint128 leverageRebaseWorth,uint128 hedgeRebaseWorth,string memory baseCoinName) public onlyOwner {
        defaultLeverageRatio = leverageRatio;
        _oracle = IFNXOracle(oracle);
        leverageCoin.id = 0;
        leverageCoin.leveragePool = IStakePool(leveragePool);
        leverageCoin.leverageRate = leverageRatio;
        leverageCoin.buyFee = 1e15;
        leverageCoin.sellFee = 1e15;
        leverageCoin.rebalanceFee = 1e15;
        leverageCoin.rebalanceWorth = leverageRebaseWorth;
        leverageCoin.defaultRebalanceWorth = leverageRebaseWorth;
        fnxProxy newToken = new fnxProxy(rebaseImplement,rebaseVersion);
        leverageCoin.leverageToken = IRebaseToken(address(newToken));
        leverageCoin.token = leverageCoin.leveragePool.poolToken();
        if(leverageCoin.token != address(0)){
            IERC20 oToken = IERC20(leverageCoin.token);
            oToken.safeApprove(swapRouter,uint256(-1));
            oToken.safeApprove(leveragePool,uint256(-1));
        }


        hedgeCoin.id = 1;
        hedgeCoin.leveragePool = IStakePool(hedgePool);
        hedgeCoin.leverageRate = leverageRatio;
        hedgeCoin.buyFee = 1e15;
        hedgeCoin.sellFee = 1e15;
        hedgeCoin.rebalanceFee = 1e15;
        hedgeCoin.rebalanceWorth = hedgeRebaseWorth;
        hedgeCoin.defaultRebalanceWorth = hedgeRebaseWorth;
        newToken = new fnxProxy(rebaseImplement,rebaseVersion);
        hedgeCoin.leverageToken = IRebaseToken(address(newToken));
        hedgeCoin.token = hedgeCoin.leveragePool.poolToken();
        if(hedgeCoin.token != address(0)){
            IERC20 oToken = IERC20(hedgeCoin.token);
            oToken.safeApprove(swapRouter,uint256(-1));
            oToken.safeApprove(hedgePool,uint256(-1));
        }
        string memory token0 = (leverageCoin.token == address(0)) ? baseCoinName : IERC20(leverageCoin.token).symbol();
        string memory token1 = (hedgeCoin.token == address(0)) ? baseCoinName : IERC20(hedgeCoin.token).symbol();

        string memory leverage = leverageRatio2str(leverageRatio);
        string memory leverageName = strConcat("LFT_",token0,"_",token1,leverage);
        string memory hedgeName = strConcat("HFT_",token1,"_",token0,leverage);

        leverageCoin.leverageToken.changeTokenName(leverageName,leverageName);
        hedgeCoin.leverageToken.changeTokenName(hedgeName,hedgeName);

        IUniswap = IUniswapV2Router02(swapRouter);
        uint256[] memory assets = new uint256[](2);
        assets[0] = uint256(leverageCoin.token);
        assets[1] = uint256(hedgeCoin.token);
        uint256[]memory prices = oraclegetPrices(assets);
        rebasePrice = prices[1]*calDecimal/prices[0];
    }
    function getDefaultLeverageRatio()public view returns (uint256){
        return defaultLeverageRatio;
    }
    function leverageRate()public view returns (uint256){
        return leverageCoin.leverageRate;
    }
    function hedgeRate()public view returns (uint256){
        return hedgeCoin.leverageRate;
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

    function getLeverageTotalworth() public view returns(uint256){
        return _totalWorthView(leverageCoin,_getUnderlyingPriceView(leverageCoin.id));
    }
    function getHedgeTotalworth() public view returns(uint256){
        return _totalWorthView(hedgeCoin,_getUnderlyingPriceView(hedgeCoin.id));
    }
    function getLeverageTokenNetworth() public view returns(uint256){
        return _tokenNetworthView(leverageCoin);
    }
    function getHedgeTokenNetworth() public view returns(uint256){
        return _tokenNetworthView(hedgeCoin);
    }
    function _totalWorthView(leverageInfo memory coinInfo,uint256 underlyingPrice) internal view returns (uint256){
        uint256 totalSup = coinInfo.leverageToken.totalSupply();
        uint256 allLoan = totalSup.mul(coinInfo.rebalanceWorth)/calDecimal;
        allLoan = allLoan.mul(coinInfo.leverageRate-calDecimal);
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
        amount = getPayableAmount(inputToken,amount);

        require(amount > 0, 'buy amount is zero');
        uint256 fee;
        (amount,fee) = getFees(coinInfo.buyFee,amount);
        uint256 leverageAmount = amount.mul(UnderlyingPrice(coinInfo.id))/_tokenNetworthBuy(coinInfo);
        require(leverageAmount>=minAmount,"token amount is less than minAmount");
        emit DebugEvent(address(0),_tokenNetworthBuy(coinInfo), _tokenNetworth(coinInfo));
        uint256 userLoan = leverageAmount.mul(coinInfo.rebalanceWorth)/calDecimal;
        userLoan = userLoan.mul(coinInfo.leverageRate-calDecimal)/calDecimal;
        emit DebugEvent(address(0),amount, userLoan);
        userLoan = coinInfo.leveragePool.borrow(userLoan);
        amount = swapBuy(coinInfo.id,userLoan,0,true);
        emit DebugEvent(address(0),amount, userLoan);
        coinInfo.leverageToken.mint(msg.sender,leverageAmount);
        if(fee>0){
            _redeem(feeAddress, inputToken, fee);
        }
    }
    function _buy(leverageInfo memory coinInfo,uint256 amount,uint256 minAmount,bytes memory /*data*/) getUnderlyingPrice internal{
        amount = getPayableAmount(coinInfo.token,amount);
        require(amount > 0, 'buy amount is zero');
        uint256 fee;
        (amount,fee) = getFees(coinInfo.buyFee,amount);
        uint256 leverageAmount = amount.mul(calDecimal)/_tokenNetworthBuy(coinInfo);
        require(leverageAmount>=minAmount,"token amount is less than minAmount");
        emit DebugEvent(address(0),_tokenNetworthBuy(coinInfo), _tokenNetworth(coinInfo));
        uint256 userLoan = leverageAmount.mul(coinInfo.rebalanceWorth)/calDecimal;
        userLoan = userLoan.mul(coinInfo.leverageRate-calDecimal)/calDecimal;
        emit DebugEvent(address(0),amount, userLoan);
        userLoan = coinInfo.leveragePool.borrow(userLoan);
        amount = swapBuy(coinInfo.id,userLoan.add(amount),0,true);
        emit DebugEvent(address(0),amount, userLoan);
        coinInfo.leverageToken.mint(msg.sender,leverageAmount);
        if(fee>0){
            _redeem(feeAddress, coinInfo.token, fee);
        }
    }
    function _sell(leverageInfo memory coinInfo,uint256 amount,uint256 minAmount,bytes memory /*data*/) getUnderlyingPrice internal{
        require(amount > 0, 'sell amount is zero');
        uint256 userLoan = amount.mul(coinInfo.rebalanceWorth)/calDecimal;
        userLoan = userLoan.mul(coinInfo.leverageRate-calDecimal);
        uint256 userPayback =  amount.mul(_tokenNetworth(coinInfo));
        uint256 allSell = swapSell(coinInfo.id,userLoan.add(userPayback)/UnderlyingPrice(coinInfo.id),0,true);
        userLoan = userLoan/calDecimal;
        emit DebugEvent(address(111), allSell, userLoan);
        (uint256 repay,uint256 fee) = getFees(coinInfo.sellFee,allSell.sub(userLoan));
        emit DebugEvent(address(111), underlyingBalance(0), underlyingBalance(1));
        require(repay >= minAmount, "Repay amount is less than minAmount");
        _repay(coinInfo,userLoan);
        _redeem(msg.sender,coinInfo.token,repay);
        coinInfo.leverageToken.burn(msg.sender,amount);
        _redeem(feeAddress, coinInfo.token, fee);
    }
    
    function _settle(leverageInfo memory coinInfo,bool bRebalanceWorth) internal returns(uint256,uint256){
        uint256 tokenNum = _coinTotalSupply(coinInfo.leverageToken);
        if (tokenNum == 0){
            return (0,0);
        }
        uint256 insterest = coinInfo.leveragePool.interestRate();
        uint256 curPrice = UnderlyingPrice(coinInfo.id);
        uint256 oldUnderlying = curPrice.mul(underlyingBalance(coinInfo.id))/calDecimal;
        //uint256 newLoan = UnderlyingPrice().mul(coinInfo.underlyingBalance).mul(calDecimal-insterest);
        //uint256 totalWorth =  newLoan.div(calDecimal+(calDecimal-insterest).mul(coinInfo.leverageRate-calDecimal))
        uint256 totalWorth = _totalWorth(coinInfo);
        if (bRebalanceWorth){
            uint256 newSupply = totalWorth/coinInfo.rebalanceWorth;
            coinInfo.leverageToken.calRebaseRatio(newSupply);
        }else{
            coinInfo.rebalanceWorth = uint128(totalWorth/tokenNum);
        }
        totalWorth = totalWorth/calDecimal;
        uint256 allLoan = totalWorth.mul(coinInfo.leverageRate-calDecimal)/calDecimal;
        uint256 poolBalance = coinInfo.leveragePool.poolBalance();
        emit DebugEvent(address(3), allLoan, poolBalance);
        if(allLoan <= poolBalance){
            coinInfo.leverageRate = defaultLeverageRatio;
        }else{
            allLoan = poolBalance;
            coinInfo.leverageRate = poolBalance.mul(calDecimal)/totalWorth + calDecimal;
        } 

        uint256 loadInterest = allLoan.mul(insterest)/1e8;
        emit DebugEvent(address(3), loadInterest, coinInfo.leverageRate);
        uint256 newUnderlying = totalWorth+allLoan-loadInterest;
        emit DebugEvent(address(4), oldUnderlying, newUnderlying);
        if(oldUnderlying>newUnderlying){
            return (0,oldUnderlying-newUnderlying);
        }else{
            return (newUnderlying-oldUnderlying,0);
        }
    }
    function rebalance(bool bRebalanceWorth) getUnderlyingPrice public {
        (uint256 buyLev,uint256 sellLev) = _settle(leverageCoin,bRebalanceWorth);
        (uint256 buyHe,uint256 sellHe) = _settle(hedgeCoin,bRebalanceWorth);
        rebasePrice = UnderlyingPrice(0);
        uint256 _curPrice = rebasePrice;
        emit DebugEvent(address(1), buyHe, sellHe);
        emit DebugEvent(address(12), _curPrice, sellHe.mul(_curPrice)/calDecimal);
        if (buyLev>0 && buyHe>0){
            leverageCoin.leveragePool.borrowAndInterest(buyLev);
            hedgeCoin.leveragePool.borrowAndInterest(buyHe);
            buyHe = _curPrice.mul(buyHe);
            buyLev = buyLev.mul(calDecimal);
            if(buyLev>buyHe){
                swapBuy(0,(buyLev - buyHe)/calDecimal,(buyLev - buyHe)/_curPrice/2,true);
            }else{
                swapSell(0,(buyHe - buyLev)/_curPrice,(buyHe - buyLev)/calDecimal/2,true);
            }
        }else if(sellLev>0 && sellHe>0){
            uint256 sellHe1 = _curPrice.mul(sellHe);
            uint256 sellLev1 = sellLev.mul(calDecimal);
            if(sellLev1>sellHe1){
                sellLev1 = (sellLev1-sellHe1);
                sellHe1 = sellLev1/calDecimal;
                sellLev1 = sellLev1.add(sellLev1/10)/_curPrice;
                swapSell(0,sellLev1,sellHe1,false);
            }else{
                sellLev1 = (sellHe1-sellLev1);
                sellHe1 = sellLev1.add(sellLev1)/calDecimal;
                sellLev1 =  sellLev1/_curPrice;
                swapBuy(0,sellHe1,sellLev1,false);
            }
        }else{
            if (buyLev>0){
                leverageCoin.leveragePool.borrowAndInterest(buyLev);
                swapBuy(0,buyLev,buyLev.mul(_curPrice)/_curPrice/2,true);
            }else if (sellLev>0){
                swapSell(0,sellLev.add(sellLev/10).mul(calDecimal)/_curPrice,sellLev,false);
            }
            if(buyHe>0){
                hedgeCoin.leveragePool.borrowAndInterest(buyHe);
                swapSell(0,buyHe,buyHe.mul(_curPrice)/calDecimal/2,true);
            }else if(sellHe>0){
                emit DebugEvent(address(13), sellHe.add(sellHe/10).mul(_curPrice)/calDecimal, sellHe);
                swapBuy(0,sellHe.add(sellHe/10).mul(_curPrice)/calDecimal,sellHe,false);
            }
        }
        emit DebugEvent(address(14), underlyingBalance(1), underlyingBalance(0));
        if(sellLev>0){
            _repayAndInterest(leverageCoin,sellLev);
        }
        if(sellHe>0){
            _repayAndInterest(hedgeCoin,sellHe);
        }
    }
    function _repay(leverageInfo memory coinInfo,uint256 amount)internal{
        if (coinInfo.token == address(0)){
            coinInfo.leveragePool.repay.value(amount)(amount);
        }else{
            coinInfo.leveragePool.repay(amount);
        }
    }
    function _repayAndInterest(leverageInfo memory coinInfo,uint256 amount)internal{
        if (coinInfo.token == address(0)){
            coinInfo.leveragePool.repayAndInterest.value(amount)(amount);
        }else{
            coinInfo.leveragePool.repayAndInterest(amount);
        }
    }
    function getFees(uint256 feeRatio,uint256 amount) internal pure returns (uint256,uint256){
        uint256 fee = amount.mul(feeRatio)/calDecimal;
        return(amount.sub(fee),fee);
    }

    function swapBuy(uint8 id,uint256 amount0,uint256 amount1,bool firstExact)internal returns (uint256) {
        return id == 0 ? _swap(leverageCoin.token,hedgeCoin.token,amount0,amount1,firstExact) : 
            _swap(hedgeCoin.token,leverageCoin.token,amount0,amount1,firstExact);
    }
    function swapSell(uint8 id,uint256 amount0,uint256 amount1,bool firstExact) internal returns (uint256) {
        return id == 1 ? _swap(leverageCoin.token,hedgeCoin.token,amount0,amount1,firstExact) :
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
            uint256 preBalance = oToken.balanceOf(address(this));
            oToken.safeTransferFrom(msg.sender, address(this), amount);
            uint256 afterBalance = oToken.balanceOf(address(this));
            require(afterBalance-preBalance==amount,"input token transfer error!");
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
            uint256 preBalance = token.balanceOf(address(this));
            token.safeTransfer(recieptor,amount);
//            token.transfer(recieptor,amount);
            uint256 afterBalance = token.balanceOf(address(this));
            require(preBalance - afterBalance == amount,"settlement token transfer error!");
        }
    }
    function _getUnderlyingPriceView(uint8 id) internal view returns(uint256){
        uint256[] memory assets = new uint256[](2);
        assets[0] = uint256(leverageCoin.token);
        assets[1] = uint256(hedgeCoin.token);
        uint256[]memory prices = oraclegetPrices(assets);
        return id == 0 ? prices[1]*calDecimal/prices[0] : prices[0]*calDecimal/prices[1];
    }
    modifier getUnderlyingPrice(){
        uint256[] memory assets = new uint256[](2);
        assets[0] = uint256(leverageCoin.token);
        assets[1] = uint256(hedgeCoin.token);
        uint256[]memory prices = oraclegetPrices(assets);
        currentPrice = prices[1]*calDecimal/prices[0];
        _;
    }
    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;uint i = 0;
        for (i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }
    function leverageRatio2str(uint leverageRatio) internal pure returns (string memory){
        if (leverageRatio == 0) return "0";
        bytes memory bstr = new bytes(6);
        uint j = leverageRatio*100/calDecimal;
        uint k = 5;
        if (j%10 > 0){
            bstr[k--]= bytes1(uint8(48 + j%10));
        }
        j /= 10;
        if (j%10 > 0){
            bstr[k--]= bytes1(uint8(48 + j%10));
        }
        if (k<4){
            bstr[k--]= bytes1(uint8(46));
        }
        j /= 10;
        bstr[k--]= bytes1(uint8(48 + j%10));
        if (j>0){
            j /= 10;
            bstr[k--]= bytes1(uint8(48 + j%10));
        }
        if (k==0){
            bstr[0] = bytes1(uint8(88));
            return string(bstr);
        }else{
            bytes memory newstr = new bytes(5-k);
            k++;
            for (uint i = 0; i < newstr.length; i++) newstr[i] = bstr[k++];
            newstr[0] = bytes1(uint8(88));
            return string(newstr);
        }
    }
    
}