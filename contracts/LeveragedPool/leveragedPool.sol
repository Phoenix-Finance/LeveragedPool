pragma solidity =0.5.16;
import "../proxy/fnxProxy.sol";


import "../ERC20/safeErc20.sol";
import "../modules/SafeMath.sol";
import "./leveragedData.sol";

contract leveragedPool is leveragedData{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    constructor() public {

    }
    function() external payable {
        
    }
    function setFeeAddress(address payable addrFee) onlyOwner public {
        feeAddress = addrFee;
    }
    function getLeverageRebase() public view returns (bool,bool) {
        return (leverageCoin.bRebase,hedgeCoin.bRebase);
    }
    function getLeverageInfo() public view returns (address,address,address,uint256,uint256) {
        return (leverageCoin.token,address(leverageCoin.stakePool),address(leverageCoin.leverageToken),leverageCoin.leverageRate,leverageCoin.rebalanceWorth);
    }
    function getHedgeInfo() public view returns (address,address,address,uint256,uint256) {
        return (hedgeCoin.token,address(hedgeCoin.stakePool),address(hedgeCoin.leverageToken),hedgeCoin.leverageRate,hedgeCoin.rebalanceWorth);
    }
    function setLeverageFee(uint256 _buyFee,uint256 _sellFee,uint256 _rebalanceFee) onlyOwner public{
        buyFee = _buyFee;
        sellFee = _sellFee;
        rebalanceFee = _rebalanceFee;
    }
    function getLeverageFee()public view returns(uint256,uint256,uint256){
        return (buyFee,sellFee,rebalanceFee);
    }
    function setLeveragePoolAddress(address payable _feeAddress,address leveragePool,address hedgePool,address oracle,address swapRouter)public onlyOwner{
        feeAddress = _feeAddress;
        _oracle = IFNXOracle(oracle);
        IUniswap = IUniswapV2Router02(swapRouter);
        setStakePool(leverageCoin,0,leveragePool);
        setStakePool(hedgeCoin,1,hedgePool);
    }
    function setStakePool(leverageInfo storage coinInfo,uint8 id,address stakePool) internal{
        coinInfo.id = id;
        coinInfo.stakePool = IStakePool(stakePool);
        coinInfo.token = coinInfo.stakePool.poolToken();
        if(coinInfo.token != address(0)){
            IERC20 oToken = IERC20(coinInfo.token);
            oToken.safeApprove(address(IUniswap),uint256(-1));
            oToken.safeApprove(stakePool,uint256(-1));
        }
    }
    function setLeveragePoolInfo(address rebaseImplement,uint256 rebaseVersion,
        uint256 fees,uint256 _threshold,uint256 rebaseWorth,string memory leverageTokenName,string memory hedgeTokenName) public onlyOwner {
        defaultLeverageRatio = uint64(fees>>192);
        defaultRebalanceWorth = rebaseWorth;
        setPoolInfo(leverageCoin,uint128(rebaseWorth),rebaseImplement,rebaseVersion,leverageTokenName);
        setPoolInfo(hedgeCoin,uint128(rebaseWorth>>128),rebaseImplement,rebaseVersion,hedgeTokenName);
        buyFee = uint64(fees);
        sellFee = uint64(fees>>64);
        rebalanceFee = uint64(fees>>128);
        rebaseThreshold = uint128(_threshold);
        liquidateThreshold = uint128(_threshold<<128);

        rebasePrice = _getUnderlyingPriceView(0);
    }
    function setPoolInfo(leverageInfo storage coinInfo,uint256 rebaseWorth,
        address rebaseImplement,uint256 rebaseVersion,string memory tokenName) internal{
        coinInfo.leverageRate = defaultLeverageRatio;
        coinInfo.rebalanceWorth = rebaseWorth;
        fnxProxy newToken = new fnxProxy(rebaseImplement,rebaseVersion);
        coinInfo.leverageToken = IRebaseToken(address(newToken));
        coinInfo.leverageToken.modifyPermission(address(this),0xFFFFFFFFFFFFFFFF);
        coinInfo.leverageToken.changeTokenName(tokenName,tokenName,coinInfo.token);
    }
    function getDefaultLeverageRate()public view returns (uint256){
        return defaultLeverageRatio;
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
    function getTotalworths() public view returns(uint256,uint256){
        return (_totalWorth(leverageCoin,_getUnderlyingPriceView(0)),_totalWorth(hedgeCoin,_getUnderlyingPriceView(1)));
    }
    function getTokenNetworths() public view returns(uint256,uint256){
        return (_tokenNetworth(leverageCoin,_getUnderlyingPriceView(0)),_tokenNetworth(hedgeCoin,_getUnderlyingPriceView(1)));
    }
    function _totalWorth(leverageInfo memory coinInfo,uint256 underlyingPrice) internal view returns (uint256){
        uint256 totalSup = coinInfo.leverageToken.totalSupply();
        uint256 allLoan = totalSup.mul(coinInfo.rebalanceWorth)/feeDecimal;
        allLoan = allLoan.mul(coinInfo.leverageRate-feeDecimal);
        return underlyingPrice.mul(underlyingBalance(coinInfo.id)).sub(allLoan);
    }

    function buyPrices() public view returns(uint256,uint256){
        return (_tokenNetworthBuy(leverageCoin),_tokenNetworthBuy(hedgeCoin));
    }
    function _tokenNetworthBuy(leverageInfo memory coinInfo) internal view returns (uint256){
        uint256 curPrice = UnderlyingPrice(coinInfo.id);
        uint256 rePrice = getRebasePrice(coinInfo.id);
        return coinInfo.rebalanceWorth.mul((curPrice.mul(coinInfo.leverageRate)/rePrice+feeDecimal).sub(coinInfo.leverageRate))/feeDecimal;
    }
    function _tokenNetworth(leverageInfo memory coinInfo,uint256 underlyingPrice) internal view returns (uint256){
        uint256 tokenNum = coinInfo.leverageToken.totalSupply();
        if (tokenNum == 0){
            return coinInfo.rebalanceWorth;
        }else{
            return _totalWorth(coinInfo,underlyingPrice)/tokenNum;
        }
    }
    function buyLeverage(uint256 amount,uint256 minAmount,uint256 deadLine,bytes memory data) ensure(deadLine) nonReentrant public payable{
        _buy(leverageCoin,amount,minAmount,data);
    }
    function buyHedge(uint256 amount,uint256 minAmount,uint256 deadLine,bytes memory data) ensure(deadLine) nonReentrant public payable{
        _buy(hedgeCoin, amount,minAmount,data);
    }
    function buyLeverage2(uint256 amount,uint256 minAmount,uint256 deadLine,bytes memory data) ensure(deadLine) nonReentrant public payable{
        _buy2(leverageCoin,amount,minAmount,data);
    }
    function buyHedge2(uint256 amount,uint256 minAmount,uint256 deadLine,bytes memory data) ensure(deadLine) nonReentrant public payable{
        _buy2(hedgeCoin, amount,minAmount,data);
    }
    function sellLeverage(uint256 amount,uint256 minAmount,uint256 deadLine,bytes memory data) ensure(deadLine) nonReentrant public payable{
        _sell(leverageCoin,amount,minAmount,data);
    }
    function sellHedge(uint256 amount,uint256 minAmount,uint256 deadLine,bytes memory data) ensure(deadLine) nonReentrant public payable{
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
        emit DebugEvent(address(0x111),leverageAmount, _tokenNetworth(coinInfo,UnderlyingPrice(coinInfo.id)));
        uint256 userLoan = leverageAmount.mul(coinInfo.rebalanceWorth)/calDecimal;
        userLoan = userLoan.mul(coinInfo.leverageRate-feeDecimal)/feeDecimal;
        userLoan = coinInfo.stakePool.borrow(userLoan);
        amount = swap(true,coinInfo.id,userLoan.add(amount),0);
        coinInfo.leverageToken.mint(msg.sender,leverageAmount);
    }
    function _sell(leverageInfo memory coinInfo,uint256 amount,uint256 minAmount,bytes memory /*data*/) getUnderlyingPrice internal{
        require(amount > 0, 'sell amount is zero');
        uint256 userLoan = amount.mul(coinInfo.rebalanceWorth)/feeDecimal;
        userLoan = userLoan.mul(coinInfo.leverageRate-feeDecimal);
        uint256 getLoan = coinInfo.stakePool.loan(address(this)).mul(calDecimal);
        if(coinInfo.leverageToken.totalSupply() == amount || userLoan > getLoan) {
            userLoan = getLoan;
        }
        emit DebugEvent(address(0x2222),userLoan, getLoan);
        uint256 userPayback =  amount.mul(_tokenNetworth(coinInfo,UnderlyingPrice(coinInfo.id)));
        uint256 allSell = swap(false,coinInfo.id,userLoan.add(userPayback)/UnderlyingPrice(coinInfo.id),0);
        emit DebugEvent(address(0x3333),userPayback,userLoan.add(userPayback)/UnderlyingPrice(coinInfo.id));
        userLoan = userLoan/calDecimal;
        emit DebugEvent(address(111), allSell, userLoan);
        (uint256 repay,uint256 fee) = getFees(sellFee,allSell.sub(userLoan));
        require(repay >= minAmount, "Repay amount is less than minAmount");
        _repay(coinInfo,userLoan,false);
        _redeem(msg.sender,coinInfo.token,repay);
        coinInfo.leverageToken.burn(msg.sender,amount);
        _redeem(feeAddress, coinInfo.token, fee);
    }
    
    function _settle(leverageInfo storage coinInfo) internal returns(uint256,uint256){
        uint256 tokenNum = coinInfo.leverageToken.totalSupply();
        if (tokenNum == 0){
            return (0,0);
        }
        uint256 insterest = coinInfo.stakePool.interestRate();
        uint256 curPrice = UnderlyingPrice(coinInfo.id);
        uint256 totalWorth = _totalWorth(coinInfo,curPrice)/curPrice;
        uint256 fee;
        (totalWorth,fee) = getFees(rebalanceFee,totalWorth);
        emit DebugEvent(address(0x1321), totalWorth,fee);
        if(fee>0){
            _redeem(feeAddress,(coinInfo.id == 0) ? hedgeCoin.token : leverageCoin.token, fee);
        } 
        uint256 oldUnderlying = curPrice.mul(underlyingBalance(coinInfo.id))/calDecimal;
        totalWorth = _totalWorth(coinInfo,curPrice);
        if (coinInfo.bRebase){
            uint256 newSupply = totalWorth/coinInfo.rebalanceWorth;
            coinInfo.leverageToken.calRebaseRatio(newSupply);
        }else{
            coinInfo.rebalanceWorth = totalWorth/tokenNum;
        }
        totalWorth = totalWorth/calDecimal;
        uint256 allLoan = totalWorth.mul(coinInfo.leverageRate-feeDecimal)/feeDecimal;
        uint256 poolBalance = coinInfo.stakePool.poolBalance();
        if(allLoan <= poolBalance){
            coinInfo.leverageRate = defaultLeverageRatio;
        }else{
            allLoan = poolBalance;
            coinInfo.leverageRate = poolBalance.mul(feeDecimal)/totalWorth + feeDecimal;
        } 
        {
            uint256 buyPrice = _tokenNetworthBuy(coinInfo).mul(feeDecimal);
            uint256 defaultWorth = coinInfo.id == 0 ? uint128(defaultRebalanceWorth) : uint128(defaultRebalanceWorth>>128);
            coinInfo.bRebase = buyPrice<defaultWorth.mul(feeDecimal-rebaseThreshold) || buyPrice>defaultWorth.mul(feeDecimal+rebaseThreshold);
        }
        uint256 loadInterest = allLoan.mul(insterest)/1e8;
        emit DebugEvent(address(0x321), loadInterest, coinInfo.rebalanceWorth);
        uint256 newUnderlying = totalWorth+allLoan-loadInterest;
        emit DebugEvent(address(0x1321), oldUnderlying,newUnderlying);
        if(oldUnderlying>newUnderlying){
            return (0,oldUnderlying-newUnderlying);
        }else{
            return (newUnderlying-oldUnderlying,0);
        }
    }
    function getSwapAmounts(bool token0to1,bool AmountsIn,uint256 amount,int256[] memory buyAmounts) internal view returns(int256[] memory){
        address[] memory path = new address[](2);
        address token0 = leverageCoin.token == address(0) ? IUniswap.WETH() : leverageCoin.token;
        address token1 = hedgeCoin.token == address(0) ? IUniswap.WETH() : hedgeCoin.token;
        (path[0],path[1]) = token0to1? (token0,token1) : (token1,token0);
        uint[] memory amounts = AmountsIn ? IUniswap.getAmountsIn(amount, path) : IUniswap.getAmountsOut(amount, path);
        if (token0to1){
            buyAmounts[0] += int256(amounts[0]);
            buyAmounts[1] += int256(amounts[1]);
        }else{
            buyAmounts[0] -= int256(amounts[1]);
            buyAmounts[1] -= int256(amounts[0]);
        }
        return buyAmounts;
    }
    function rebalance() getUnderlyingPrice public {
        (uint256 buyLev,uint256 sellLev) = _settle(leverageCoin);
        (uint256 buyHe,uint256 sellHe) = _settle(hedgeCoin);
        rebasePrice = UnderlyingPrice(0);
        emit DebugEvent(address(0x1221), buyLev, sellLev);
        emit DebugEvent(address(0x1222), buyHe, sellHe);
        int256[] memory buyAmounts = new int256[](2);
        if (buyLev>0){
            leverageCoin.stakePool.borrowAndInterest(buyLev);
            buyAmounts = getSwapAmounts(true,false,buyLev,buyAmounts);
        }else if(sellLev>0){
            buyAmounts = getSwapAmounts(false,true,sellLev,buyAmounts);
        }
        if(buyHe>0){
            hedgeCoin.stakePool.borrowAndInterest(buyHe);
            buyAmounts = getSwapAmounts(false,false,buyHe,buyAmounts);
        }else if(sellHe>0){
            buyAmounts = getSwapAmounts(true,true,sellHe,buyAmounts);
        }
        emit DebugEvent1(address(0x1222), buyAmounts[0], buyAmounts[1]);
        emit DebugEvent(address(14), underlyingBalance(1), underlyingBalance(0));
        if(buyAmounts[0]>0){
            uint256 amount = underlyingBalance(1);
            if(uint256(buyAmounts[0]) < amount){
                amount = uint256(buyAmounts[0]);
            }
            _swap(leverageCoin.token,hedgeCoin.token,amount,0);
        }else if(buyAmounts[1]<0){
            uint256 amount = underlyingBalance(0);
            if(uint256(-buyAmounts[1]) < amount){
                amount = uint256(-buyAmounts[1]);
            }
            _swap(hedgeCoin.token,leverageCoin.token,amount,0);
        }
        if(buyLev == 0){
            _repayAndInterest(leverageCoin,sellLev);
        }
        if(buyHe == 0){
            _repayAndInterest(hedgeCoin,sellHe);
        }
        emit DebugEvent(address(14), underlyingBalance(1), underlyingBalance(0));
    }
    function liquidateLeverage() public {
        _liquidate(leverageCoin);
    }
    function liquidateHedge() public {
        _liquidate(hedgeCoin);
    }
    function _liquidate(leverageInfo storage coinInfo) canLiquidate(coinInfo)  internal{
        //all selled
        uint256 amount = swap(false,coinInfo.id,underlyingBalance(coinInfo.id),0);
        (uint256 leftAmount,uint256 fee) = getFees(rebalanceFee,amount);
        uint256 allLoan = coinInfo.stakePool.loan(address(this));
        if (amount<allLoan){
            allLoan = amount;
            leftAmount = amount;
            fee = 0;
        }else if(leftAmount<allLoan){
            leftAmount = allLoan;
            fee = amount-leftAmount;
        }
        if(fee>0){
            _redeem(feeAddress,coinInfo.token, fee);
        } 
        _repay(coinInfo,allLoan,true);
        _redeem(address(uint160(address(coinInfo.leverageToken))),coinInfo.token,leftAmount-allLoan);
        coinInfo.leverageToken.newErc20(leftAmount-allLoan);
    }
    function _repay(leverageInfo memory coinInfo,uint256 amount,bool bAll)internal{
        if (coinInfo.token == address(0)){
            coinInfo.stakePool.repay.value(amount)(amount,bAll);
        }else{
            coinInfo.stakePool.repay(amount,bAll);
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

    function swap(bool buy,uint8 id,uint256 amount0,uint256 amount1)internal returns (uint256) {
        return (id == 0) == buy ? _swap(leverageCoin.token,hedgeCoin.token,amount0,amount1) : 
            _swap(hedgeCoin.token,leverageCoin.token,amount0,amount1);
    }
    function _swap(address token0,address token1,uint256 amount0,uint256 amount1) internal returns (uint256) {
        address[] memory path = new address[](2);
        uint[] memory amounts;
        if(token0 == address(0)){
            path[0] = IUniswap.WETH();
            path[1] = token1;
            amounts = IUniswap.swapExactETHForTokens.value(amount0)(amount1, path, address(this), now+30);
        }else if(token1 == address(0)){
            path[0] = token0;
            path[1] = IUniswap.WETH();
            amounts = IUniswap.swapExactTokensForETH(amount0,amount1, path, address(this), now+30);
        }else{
            path[0] = token0;
            path[1] = token1;
            amounts = IUniswap.swapExactTokensForTokens(amount0,amount1, path, address(this), now+30);
        }
        emit Swap(token0,token1,amounts[0],amounts[1]);
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
        emit Redeem(recieptor,stakeCoin,amount);
    }
    function _getUnderlyingPriceView(uint8 id) internal view returns(uint256){
        uint256[] memory assets = new uint256[](2);
        assets[0] = uint256(leverageCoin.token);
        assets[1] = uint256(hedgeCoin.token);
        uint256[]memory prices = oraclegetPrices(assets);
        return id == 0 ? prices[1]*calDecimal/prices[0] : prices[0]*calDecimal/prices[1];
    }

    function getEnableLiquidate()public view returns (bool,bool){
        uint256[] memory assets = new uint256[](2);
        assets[0] = uint256(leverageCoin.token);
        assets[1] = uint256(hedgeCoin.token);
        uint256[]memory prices = oraclegetPrices(assets);
        uint256 price0 = prices[1]*(calDecimal+calDecimal/100)/prices[0];
        uint256 price1 = prices[0]*(calDecimal+calDecimal/100)/prices[1];
        return (checkLiquidate(leverageCoin,price0),
                checkLiquidate(hedgeCoin,price1));
    }
    function checkLiquidate(leverageInfo memory coinInfo,uint256 curPrice) internal view returns(bool){
        if(coinInfo.leverageToken.totalSupply() == 0){
            return false;
        }
        uint256 rePrice = getRebasePrice(coinInfo.id);
        //3CP-2RP < RP*liquidateThreshold
        return curPrice.mul(coinInfo.leverageRate).sub(rePrice.mul(coinInfo.leverageRate-feeDecimal)) < rePrice.mul(liquidateThreshold);
    }
    modifier canLiquidate(leverageInfo memory coinInfo){
        currentPrice = _getUnderlyingPriceView(0);
        require(checkLiquidate(coinInfo,UnderlyingPrice(coinInfo.id)),"Liquidate: current price is not under the threshold!");
        _;
    }
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'leveragedPool: EXPIRED');
        _;
    }

    modifier getUnderlyingPrice(){
        currentPrice = _getUnderlyingPriceView(0);
        _;
    }
}