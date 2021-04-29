pragma solidity =0.5.16;
import "../ERC20/safeErc20.sol";
import "../modules/SafeMath.sol";
import "./leveragedData.sol";

contract leveragedPool is leveragedData{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    function() external payable {
    }
    function update() public onlyOwner versionUpdate(){
    }
    function setUniswapAddress(address _uniswap) onlyOwner public {
        IUniswap = IUniswapV2Router02(_uniswap);
    }
    function setFeeAddress(address payable addrFee) onlyOwner public {
        feeAddress = addrFee;
    }
    function getLeverageRebase() public view returns (bool,bool) {
        return (leverageCoin.bRebase,hedgeCoin.bRebase);
    }
    function getCurrentLeverageRate()public view returns (uint256,uint256) {
        uint256[2] memory underlyingPrice = _getUnderlyingPriceView();
        return (_getCurrentLeverageRate(leverageCoin,underlyingPrice),_getCurrentLeverageRate(hedgeCoin,underlyingPrice));
    }
    function _getCurrentLeverageRate(leverageInfo memory coinInfo,uint256[2] memory underlyingPrice)internal view returns (uint256){
        uint256 leverageCp = coinInfo.leverageRate.mulPrice(underlyingPrice, coinInfo.id);
        uint256 leverageRp = (coinInfo.leverageRate-feeDecimal).mulPrice(rebasePrices, coinInfo.id);
        return leverageCp.mul(feeDecimal).div(leverageCp.sub(leverageRp));
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
    function setLeveragePoolInfo(address rebaseTokenA,address rebaseTokenB,
        uint256 fees,uint256 _threshold,uint256 rebaseWorth) public onlyOwner {
        rebasePrices = _getUnderlyingPriceView();
        defaultLeverageRatio = uint64(fees>>192);
        defaultRebalanceWorth = rebaseWorth;
        leverageCoin.leverageRate = defaultLeverageRatio;
        leverageCoin.rebalanceWorth = rebaseWorth*calDecimal/rebasePrices[0];
        leverageCoin.leverageToken = IRebaseToken(rebaseTokenA);
        hedgeCoin.leverageRate = defaultLeverageRatio;
        hedgeCoin.rebalanceWorth = rebaseWorth*calDecimal/rebasePrices[1];
        hedgeCoin.leverageToken = IRebaseToken(rebaseTokenB);
        buyFee = uint64(fees);
        sellFee = uint64(fees>>64);
        rebalanceFee = uint64(fees>>128);
        rebaseThreshold = uint128(_threshold);
        liquidateThreshold = uint128(_threshold>>128);


    }
    function getDefaultLeverageRate()public view returns (uint256){
        return defaultLeverageRatio;
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
        uint256[2] memory underlyingPrice = _getUnderlyingPriceView();
        return (_totalWorth(leverageCoin,underlyingPrice),_totalWorth(hedgeCoin,underlyingPrice));
    }
    function getTokenNetworths() public view returns(uint256,uint256){
        uint256[2] memory underlyingPrice = _getUnderlyingPriceView();
        return (_tokenNetworth(leverageCoin,underlyingPrice),_tokenNetworth(hedgeCoin,underlyingPrice));
    }
    function _totalWorth(leverageInfo memory coinInfo,uint256[2] memory underlyingPrice) internal view returns (uint256){
        uint256 totalSup = coinInfo.leverageToken.totalSupply();
        uint256 allLoan = (totalSup.mul(coinInfo.rebalanceWorth)/feeDecimal).mul(coinInfo.leverageRate-feeDecimal);
        return underlyingBalance(coinInfo.id).mulPrice(underlyingPrice,coinInfo.id).sub(allLoan);
    }

    function buyPrices() public view returns(uint256,uint256){
        uint256[2] memory underlyingPrice = _getUnderlyingPriceView();
        return (_tokenNetworthBuy(leverageCoin,underlyingPrice),_tokenNetworthBuy(hedgeCoin,underlyingPrice));
    }
    function _tokenNetworthBuy(leverageInfo memory coinInfo,uint256[2] memory underlyingPrice) internal view returns (uint256){
        uint256 curValue = coinInfo.rebalanceWorth.mul(coinInfo.leverageRate).mulPrice(underlyingPrice,coinInfo.id).divPrice(rebasePrices,coinInfo.id);
        return curValue.sub(coinInfo.rebalanceWorth.mul(coinInfo.leverageRate-feeDecimal))/feeDecimal;
    }
    function _tokenNetworth(leverageInfo memory coinInfo,uint256[2] memory underlyingPrice) internal view returns (uint256){
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
        uint256 leverageAmount = amount.mulPrice(currentPrice,coinInfo.id)/_tokenNetworthBuy(coinInfo,currentPrice);
        _buySub(coinInfo,leverageAmount,0,minAmount);
    }
    function _buy(leverageInfo memory coinInfo,uint256 amount,uint256 minAmount,bytes memory /*data*/) getUnderlyingPrice internal{
        amount = _redeemBuyFeeSub(coinInfo.token,amount);
        uint256 leverageAmount = amount.mul(calDecimal)/_tokenNetworthBuy(coinInfo,currentPrice);
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
        uint256 userLoan = (leverageAmount.mul(coinInfo.rebalanceWorth)/calDecimal).mul(coinInfo.leverageRate-feeDecimal)/feeDecimal;
        userLoan = coinInfo.stakePool.borrow(userLoan);
        amount = userLoan.add(amount);
        //98%
        uint256 amountOut = amount.mul(98e16).divPrice(currentPrice,coinInfo.id);
        amount = swap(true,coinInfo.id,amount,amountOut);
        coinInfo.leverageToken.mint(msg.sender,leverageAmount);
    }
    function _sell(leverageInfo memory coinInfo,uint256 amount,uint256 minAmount,bytes memory /*data*/) getUnderlyingPrice internal{
        require(amount > 0, 'sell amount is zero');
        uint256 userLoan;
        uint256 allSell;
        uint256 getLoan = coinInfo.stakePool.loan(address(this)).mul(calDecimal);
        if(coinInfo.leverageToken.totalSupply() == amount){
            userLoan = getLoan;
            allSell = swap(false,coinInfo.id,underlyingBalance(coinInfo.id),0);
        }else{
            userLoan = (amount.mul(coinInfo.rebalanceWorth)/feeDecimal).mul(coinInfo.leverageRate-feeDecimal);
            if(userLoan > getLoan){
                userLoan = getLoan;
            }
            uint256 userPayback =  amount.mul(_tokenNetworth(coinInfo,currentPrice));
            allSell = swap(false,coinInfo.id,userLoan.add(userPayback).divPrice(currentPrice,coinInfo.id),0);
        }
        userLoan = userLoan/calDecimal;
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
        uint256 totalWorth = _totalWorth(coinInfo,currentPrice).divPrice(currentPrice,coinInfo.id);
        uint256 fee;
        (totalWorth,fee) = getFees(rebalanceFee,totalWorth);
        if(fee>0){
            _redeem(feeAddress,(coinInfo.id == 0) ? hedgeCoin.token : leverageCoin.token, fee);
        } 
        uint256 oldUnderlying = underlyingBalance(coinInfo.id).mulPrice(currentPrice,coinInfo.id)/calDecimal;
        uint256 oldLoan = coinInfo.stakePool.loan(address(this));
        coinInfo.leverageRate = defaultLeverageRatio;
        //allLoan = allworth*(l-1)/(1+lr-2r)
        uint256 allLoan = oldUnderlying.sub(oldLoan).mul(coinInfo.leverageRate-feeDecimal).mul(feeDecimal);
        allLoan = allLoan/(feeDecimal*feeDecimal+coinInfo.leverageRate*insterest-2*feeDecimal*insterest);
        uint256 poolBorrow = coinInfo.stakePool.borrowLimit(address(this));
        if(allLoan > poolBorrow){
            allLoan = poolBorrow;
            // l = loan(1-r)/(allworth-loan*r) + 1
            uint div = oldUnderlying.sub(oldLoan).mul(feeDecimal).sub(allLoan.mul(insterest));
            coinInfo.leverageRate = allLoan.mul((feeDecimal-insterest)*feeDecimal)/div+feeDecimal;
        }
        totalWorth = allLoan.mul((feeDecimal-insterest)*feeDecimal)/(coinInfo.leverageRate-feeDecimal)/feeDecimal;
        //rebasetoken : amount * rebalanceWorth * (leverageRate-1) = allLoan
        if (coinInfo.bRebase){
            coinInfo.rebalanceWorth = defaultRebalanceWorth*calDecimal/currentPrice[coinInfo.id];
            coinInfo.bRebase = false;
            coinInfo.leverageToken.calRebaseRatio(allLoan.mul(feeDecimal*calDecimal)/(coinInfo.leverageRate-feeDecimal)/coinInfo.rebalanceWorth);
        }else{
            coinInfo.rebalanceWorth = allLoan.mul(feeDecimal*calDecimal)/(coinInfo.leverageRate-feeDecimal)/tokenNum;
            uint256 defaultWorth = defaultRebalanceWorth*calDecimal/currentPrice[coinInfo.id];
            coinInfo.bRebase = coinInfo.rebalanceWorth<defaultWorth.mul(feeDecimal).div(rebaseThreshold);
        }
 
        uint256 newUnderlying = totalWorth+allLoan;
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
        rebasePrices = currentPrice;
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
        if(buyAmounts[0]>0){
            _swap(leverageCoin.token,hedgeCoin.token,uint256(buyAmounts[0]),0);
        }else if(buyAmounts[1]<0){
            _swap(hedgeCoin.token,leverageCoin.token,uint256(-buyAmounts[1]),0);
        }
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
        if(leftAmount>allLoan){
            _redeem(address(uint160(address(coinInfo.leverageToken))),coinInfo.token,leftAmount-allLoan);
        }
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
    function _getUnderlyingPriceView() internal view returns(uint256[2]memory){
        uint256[] memory assets = new uint256[](2);
        assets[0] = uint256(leverageCoin.token);
        assets[1] = uint256(hedgeCoin.token);
        uint256[]memory prices = oraclegetPrices(assets);
        return [prices[0],prices[1]];
    }
    function getEnableLiquidate()public view returns (bool,bool){
        uint256[2]memory prices = _getUnderlyingPriceView();
        uint256 price0 = prices[0]*(calDecimal+calDecimal/100)/calDecimal;
        uint256 price1 = prices[1]*(calDecimal+calDecimal/100)/calDecimal;
        return (checkLiquidate(leverageCoin,[prices[0],price1]),
                checkLiquidate(hedgeCoin,[price0,prices[1]]));
    }
    function checkLiquidate(leverageInfo memory coinInfo,uint256[2]memory prices) internal view returns(bool){
        if(coinInfo.leverageToken.totalSupply() == 0){
            return false;
        }
        //3CP < RP*(2+liquidateThreshold)
        return coinInfo.leverageRate.mulPrice(prices,coinInfo.id) < 
            (coinInfo.leverageRate-feeDecimal+liquidateThreshold).mulPrice(rebasePrices,coinInfo.id);
    }
    modifier canLiquidate(leverageInfo memory coinInfo){
        currentPrice = _getUnderlyingPriceView();
        require(checkLiquidate(coinInfo,currentPrice),"Liquidate: current price is not under the threshold!");
        _;
    }
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'leveragedPool: EXPIRED');
        _;
    }

    modifier getUnderlyingPrice(){
        currentPrice = _getUnderlyingPriceView();
        _;
    }
}