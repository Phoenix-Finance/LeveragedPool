pragma solidity =0.5.16;
import "../ERC20/safeErc20.sol";
import "../modules/SafeMath.sol";
import "./leveragedData.sol";
import "../modules/safeTransfer.sol";

contract leveragedPool is leveragedData,safeTransfer{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    constructor (address multiSignature) proxyOwner(multiSignature) public{
    }
    function() external payable {
    }
    function initialize() public{
        versionUpdater.initialize();
        rebalanceTol = 5e7;
    }
    function update() external versionUpdate {
    }
    function setSwapRouterAddress(address _swapRouter)public onlyOwner{
        require(swapRouter != _swapRouter,"swapRouter : same address");
        swapRouter = _swapRouter;
        if(leverageCoin.token != address(0)){
            IERC20 oToken = IERC20(leverageCoin.token);
            oToken.safeApprove(swapRouter,uint256(-1));
        }
        if(hedgeCoin.token != address(0)){
            IERC20 oToken = IERC20(hedgeCoin.token);
            oToken.safeApprove(swapRouter,uint256(-1));
        }
    }
    function setSwapLibAddress(address _swapLib)public onlyOwner{
        phxSwapLib = _swapLib;
    }
    function setFeeAddress(address payable addrFee) onlyOwner external {
        feeAddress = addrFee;
    }
    function getLeverageRebase() external view returns (bool,bool) {
        return (leverageCoin.bRebase,hedgeCoin.bRebase);
    }
    function getCurrentLeverageRate()external view returns (uint256,uint256) {
        uint256[2] memory underlyingPrice = getUnderlyingPriceView();
        return (_getCurrentLeverageRate(leverageCoin,underlyingPrice),_getCurrentLeverageRate(hedgeCoin,underlyingPrice));
    }
    function _getCurrentLeverageRate(leverageInfo memory coinInfo,uint256[2] memory underlyingPrice)internal view returns (uint256){
        uint256 leverageCp = coinInfo.leverageRate.mulPrice(underlyingPrice, coinInfo.id);
        uint256 leverageRp = (coinInfo.leverageRate-feeDecimal).mulPrice(rebalancePrices, coinInfo.id);
        return leverageCp.mul(feeDecimal).div(leverageCp.sub(leverageRp));
    }
    function getLeverageInfo() external view returns (address,address,address,uint256,uint256) {
        return (leverageCoin.token,address(leverageCoin.stakePool),address(leverageCoin.leverageToken),leverageCoin.leverageRate,leverageCoin.rebalanceWorth);
    }
    function getHedgeInfo() external view returns (address,address,address,uint256,uint256) {
        return (hedgeCoin.token,address(hedgeCoin.stakePool),address(hedgeCoin.leverageToken),hedgeCoin.leverageRate,hedgeCoin.rebalanceWorth);
    }
    function setLeverageFee(uint256 _buyFee,uint256 _sellFee,uint256 _rebalanceFee) OwnerOrOrigin external{
        buyFee = _buyFee;
        sellFee = _sellFee;
        rebalanceFee = _rebalanceFee;
    }
    function setLeveragePoolInfo(address payable _feeAddress,address leveragePool,address hedgePool,
        address oracle,address _swapRouter,address swaplib,address rebaseTokenA,address rebaseTokenB,
        uint256 fees,uint256 _threshold,uint256 rebaseWorth) onlyOwner external{
            setLeveragePoolAddress(_feeAddress,leveragePool,hedgePool,oracle,_swapRouter,swaplib);
            setLeveragePoolInfo_sub(rebaseTokenA,rebaseTokenB,fees,_threshold,rebaseWorth);
        }
    function setLeveragePoolAddress(address payable _feeAddress,address leveragePool,address hedgePool,
        address oracle,address _swapRouter,address swaplib)internal{
        feeAddress = _feeAddress;
        _oracle = IPHXOracle(oracle);
        swapRouter = _swapRouter;
        phxSwapLib = swaplib;
        setStakePool(leverageCoin,0,leveragePool);
        setStakePool(hedgeCoin,1,hedgePool);
    }
    function setLeveragePoolInfo_sub(address rebaseTokenA,address rebaseTokenB,
        uint256 fees,uint256 _threshold,uint256 rebaseWorth) internal {
        rebalancePrices = getUnderlyingPriceView();
        defaultLeverageRatio = uint64(fees>>192);
        defaultRebalanceWorth = rebaseWorth;
        leverageCoin.leverageRate = defaultLeverageRatio;
        leverageCoin.rebalanceWorth = rebaseWorth*calDecimal/rebalancePrices[0];
        leverageCoin.leverageToken = IRebaseToken(rebaseTokenA);
        hedgeCoin.leverageRate = defaultLeverageRatio;
        hedgeCoin.rebalanceWorth = rebaseWorth*calDecimal/rebalancePrices[1];
        hedgeCoin.leverageToken = IRebaseToken(rebaseTokenB);
        buyFee = uint64(fees);
        sellFee = uint64(fees>>64);
        rebalanceFee = uint64(fees>>128);
        rebaseThreshold = uint128(_threshold);
        liquidateThreshold = uint128(_threshold>>128);
    }
    function setStakePool(leverageInfo storage coinInfo,uint8 id,address stakePool) internal{
        coinInfo.id = id;
        coinInfo.stakePool = IStakePool(stakePool);
        coinInfo.token = coinInfo.stakePool.poolToken();
        if(coinInfo.token != address(0)){
            IERC20 oToken = IERC20(coinInfo.token);
            oToken.safeApprove(swapRouter,uint256(-1));
            oToken.safeApprove(stakePool,uint256(-1));
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
        uint256[2] memory underlyingPrice = getUnderlyingPriceView();
        return (_totalWorth(leverageCoin,underlyingPrice),_totalWorth(hedgeCoin,underlyingPrice));
    }
    function getTokenNetworths() public view returns(uint256,uint256){
        uint256[2] memory underlyingPrice = getUnderlyingPriceView();
        return (_tokenNetworth(leverageCoin,underlyingPrice),_tokenNetworth(hedgeCoin,underlyingPrice));
    }
    function _totalWorth(leverageInfo memory coinInfo,uint256[2] memory underlyingPrice) internal view returns (uint256){
        uint256 totalSup = coinInfo.leverageToken.totalSupply();
        uint256 allLoan = (totalSup.mul(coinInfo.rebalanceWorth)/feeDecimal).mul(coinInfo.leverageRate-feeDecimal);
        return underlyingBalance(coinInfo.id).mulPrice(underlyingPrice,coinInfo.id).sub(allLoan);
    }

    function buyPrices() public view returns(uint256,uint256){
        uint256[2] memory underlyingPrice = getUnderlyingPriceView();
        return (_tokenNetworthBuy(leverageCoin,underlyingPrice),_tokenNetworthBuy(hedgeCoin,underlyingPrice));
    }
    function _tokenNetworthBuy(leverageInfo memory coinInfo,uint256[2] memory underlyingPrice) internal view returns (uint256){
        uint256 curValue = coinInfo.rebalanceWorth.mul(coinInfo.leverageRate).mulPrice(underlyingPrice,coinInfo.id).divPrice(rebalancePrices,coinInfo.id);
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
    function buyLeverage(uint256 amount,uint256 minAmount,uint256 deadLine,bytes calldata /*data*/) external payable{
        _buy(leverageCoin,amount,minAmount,deadLine,true);
    }
    function buyHedge(uint256 amount,uint256 minAmount,uint256 deadLine,bytes calldata /*data*/)  external payable{
        _buy(hedgeCoin, amount,minAmount,deadLine,true);
    }
    function buyLeverage2(uint256 amount,uint256 minAmount,uint256 deadLine,bytes calldata /*data*/) external payable{
        _buy(leverageCoin,amount,minAmount,deadLine,false);
    }
    function buyHedge2(uint256 amount,uint256 minAmount,uint256 deadLine,bytes calldata /*data*/) external payable{
        _buy(hedgeCoin, amount,minAmount,deadLine,false);
    }
    function sellLeverage(uint256 amount,uint256 minAmount,uint256 deadLine,bytes calldata /*data*/) external payable{
        _sell(leverageCoin,amount,minAmount,deadLine,true);
    }
    function sellHedge(uint256 amount,uint256 minAmount,uint256 deadLine,bytes calldata /*data*/)  external payable{
        _sell(hedgeCoin, amount,minAmount,deadLine,true);
    }
    function sellLeverage2(uint256 amount,uint256 minAmount,uint256 deadLine,bytes calldata /*data*/) external payable{
        _sell(leverageCoin,amount,minAmount,deadLine,false);
    }
    function sellHedge2(uint256 amount,uint256 minAmount,uint256 deadLine,bytes calldata /*data*/) external payable{
        _sell(hedgeCoin, amount,minAmount,deadLine,false);
    }
    function delegateCallSwap(bytes memory data) public returns (bytes memory) {
        (bool success, bytes memory returnData) = phxSwapLib.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return returnData;
    }
    function _swap(address token0,address token1,uint256 amountSell) internal returns (uint256){
        return abi.decode(delegateCallSwap(abi.encodeWithSignature("swap(address,address,address,uint256)",swapRouter,token0,token1,amountSell)), (uint256));
    }
    function _buy(leverageInfo memory coinInfo,uint256 amount,uint256 minAmount,uint256 deadLine,bool bFirstToken) ensure(deadLine) nonReentrant getUnderlyingPrice internal{
        address inputToken;
        if(bFirstToken){
            inputToken = coinInfo.token;
        }else{
            inputToken = (coinInfo.id == 0) ? hedgeCoin.token : leverageCoin.token;
        }
        amount = getPayableAmount(inputToken,amount);
        require(amount > 0, 'buy amount is zero');
        uint256 userPay = amount;
        amount = redeemFees(buyFee,inputToken,amount);
        uint256 price = _tokenNetworthBuy(coinInfo,currentPrice);
        uint256 leverageAmount = bFirstToken ? amount.mul(calDecimal)/price :
            amount.mulPrice(currentPrice,coinInfo.id)/price;
        require(leverageAmount>=minAmount,"token amount is less than minAmount");
        {
            uint256 userLoan = (leverageAmount.mul(coinInfo.rebalanceWorth)/calDecimal).mul(coinInfo.leverageRate-feeDecimal)/feeDecimal;
            userLoan = coinInfo.stakePool.borrow(userLoan);
            amount = bFirstToken ? userLoan.add(amount) : userLoan;
            //98%
            uint256 amountOut = amount.mul(98e16).divPrice(currentPrice,coinInfo.id);
            address token1 = (coinInfo.id == 0) ? hedgeCoin.token : leverageCoin.token;
            amount = _swap(coinInfo.token,token1,amount);
            require(amount>=amountOut, "swap slip page is more than 2%");
        }
        coinInfo.leverageToken.mint(msg.sender,leverageAmount);
        price = price.mul(currentPrice[coinInfo.id])/calDecimal;
        if(coinInfo.id == 0){
            emit BuyLeverage(msg.sender,inputToken,userPay,leverageAmount,price);
        }else{
            emit BuyHedge(msg.sender,inputToken,userPay,leverageAmount,price);
        }  
    }
    function _sellSwap(uint8 id,uint256 sellAmount,uint256 userLoan)internal returns(uint256){
        (address token0,address token1) = (id == 0) ? (hedgeCoin.token,leverageCoin.token) : (leverageCoin.token,hedgeCoin.token);
        sellAmount = _swap(token0,token1,sellAmount);
        return sellAmount.sub(userLoan);
    }
    function _sellSwap2(uint8 id,uint256 sellAmount,uint256 userLoan)internal returns(uint256){
        (address token0,address token1) = (id == 0) ? (hedgeCoin.token,leverageCoin.token) : (leverageCoin.token,hedgeCoin.token);
        (uint256 amountIn,) = abi.decode(
            delegateCallSwap(abi.encodeWithSignature("sellExactAmount(address,address,address,uint256)",swapRouter,token0,token1,userLoan)), (uint256,uint256));
        return sellAmount.sub(amountIn);
    }
    function _sell(leverageInfo memory coinInfo,uint256 amount,uint256 minAmount,uint256 deadLine,bool bFirstToken) ensure(deadLine) nonReentrant getUnderlyingPrice internal{
        require(amount > 0, 'sell amount is zero');
        uint256 total = coinInfo.leverageToken.totalSupply();
        uint256 getLoan = coinInfo.stakePool.loan(address(this)).mul(calDecimal);
        uint256 userLoan;
        uint256 sellAmount;
        uint256 userPayback;
        if(total == amount){
            userLoan = getLoan;
            sellAmount = underlyingBalance(coinInfo.id);
        }else{
            userLoan = (amount.mul(coinInfo.rebalanceWorth)/feeDecimal).mul(coinInfo.leverageRate-feeDecimal);
            if(userLoan > getLoan){
                userLoan = getLoan;
            }
            userPayback =  amount.mul(_tokenNetworth(coinInfo,currentPrice));
            sellAmount = userLoan.add(userPayback).divPrice(currentPrice,coinInfo.id);
        }
        userLoan = userLoan/calDecimal;
        address outputToken;
        uint256 sellPrice;
        if (bFirstToken){
            userPayback = _sellSwap(coinInfo.id,sellAmount,userLoan);
            outputToken = coinInfo.token;
            sellPrice = userPayback.mul(currentPrice[coinInfo.id])/amount;
        }else{
            userPayback = _sellSwap2(coinInfo.id,sellAmount,userLoan);
            outputToken = coinInfo.id == 0 ? hedgeCoin.token : leverageCoin.token;
            uint256 id = coinInfo.id == 0 ? 1 : 0;
            sellPrice = userPayback.mul(currentPrice[id])/amount;
        }
        userPayback = redeemFees(sellFee,outputToken,userPayback);
        require(userPayback >= minAmount, "Repay amount is less than minAmount");
        _repay(coinInfo,userLoan,false);
        _redeem(msg.sender,outputToken,userPayback);
        //burn must run after getnetworth
        coinInfo.leverageToken.burn(msg.sender,amount);
        if(coinInfo.id == 0){
            emit SellLeverage(msg.sender,outputToken,amount,userPayback,sellPrice);
        }else{
            emit SellHedge(msg.sender,outputToken,amount,userPayback,sellPrice);
        } 
    }
    function _settle(leverageInfo storage coinInfo) internal returns(uint256,uint256){
        if (coinInfo.leverageToken.totalSupply() == 0){
            return (0,0);
        }
        uint256 insterest = coinInfo.stakePool.interestRate();
        uint256 totalWorth = _totalWorth(coinInfo,currentPrice).divPrice(currentPrice,coinInfo.id);
        totalWorth = redeemFees(rebalanceFee,(coinInfo.id == 0) ? hedgeCoin.token : leverageCoin.token,totalWorth);
        uint256 oldUnderlying = underlyingBalance(coinInfo.id).mulPrice(currentPrice,coinInfo.id)/calDecimal;
        uint256 oldLoan = coinInfo.stakePool.loan(address(this));
        uint256 oldLoanAdd = oldLoan.mul(feeDecimal)/(feeDecimal.sub(insterest)); 
        if(oldUnderlying>oldLoanAdd){ 
            uint256 leverageRate = oldUnderlying.mul(feeDecimal)/(oldUnderlying-oldLoanAdd);
            if(leverageRate <defaultLeverageRatio+rebalanceTol &&
                leverageRate >defaultLeverageRatio-rebalanceTol){
                    return (0,0);
            }
        }
        uint256 leverageRate = defaultLeverageRatio;
        //allLoan = allworth*(l-1)/(1+lr-2r)
        uint256 allLoan = oldUnderlying.sub(oldLoan).mul(leverageRate-feeDecimal).mul(feeDecimal);
        allLoan = allLoan/(feeDecimal*feeDecimal+leverageRate*insterest-2*feeDecimal*insterest);
        uint256 poolBorrow = coinInfo.stakePool.borrowLimit(address(this));
        if(allLoan > poolBorrow){
            allLoan = poolBorrow;
            // l = loan(1-r)/(allworth-loan*r) + 1
            totalWorth = oldUnderlying.sub(oldLoan).mul(feeDecimal).sub(allLoan.mul(insterest));
//            leverageRate = allLoan.mul((feeDecimal-insterest)*feeDecimal)/div+feeDecimal;
        }else{
            totalWorth = allLoan.mul((feeDecimal-insterest)*feeDecimal)/(leverageRate-feeDecimal)/feeDecimal;
        }
        uint256 newUnderlying = totalWorth+allLoan;
        if(oldUnderlying>newUnderlying){
            return (0,oldUnderlying-newUnderlying);
        }else{
            return (newUnderlying-oldUnderlying,0);
        }
    }
    function rebalance() getUnderlyingPrice OwnerOrOrigin external {
        _rebalance();
    }
    function _rebalance() internal {
        uint256 levSlip = calAverageSlip(leverageCoin);
        uint256 heSlip = calAverageSlip(hedgeCoin);
        (uint256 buyLev,uint256 sellLev) = _settle(leverageCoin);
        emit Rebalance(msg.sender,leverageCoin.token,buyLev,sellLev);
        (uint256 buyHe,uint256 sellHe) = _settle(hedgeCoin);
        emit Rebalance(msg.sender,hedgeCoin.token,buyHe,sellHe);
        rebalancePrices = currentPrice;
        if (buyLev>0){
            leverageCoin.stakePool.borrowAndInterest(buyLev);
        }
        if(buyHe>0){
            hedgeCoin.stakePool.borrowAndInterest(buyHe);
        }
        if (buyLev > 0 && buyHe>0){
            delegateCallSwap(abi.encodeWithSignature("swapBuyAndBuy(address,address,address,uint256,uint256,uint256[2])",
                swapRouter,leverageCoin.token,hedgeCoin.token,buyLev,buyHe,currentPrice));
        }else if(buyLev>0){
            delegateCallSwap(abi.encodeWithSignature("swapBuyAndSell(address,address,address,uint256,uint256,uint256[2],uint8)",
                swapRouter,leverageCoin.token,hedgeCoin.token,buyLev,sellHe.mulPrice(currentPrice,0)/calDecimal,currentPrice,0));
        }else if(buyHe>0){
            delegateCallSwap(abi.encodeWithSignature("swapBuyAndSell(address,address,address,uint256,uint256,uint256[2],uint8)",
                swapRouter,hedgeCoin.token,leverageCoin.token,buyHe,sellLev.mulPrice(currentPrice,1)/calDecimal,currentPrice,1));
        }else{
            if(sellLev>0 || sellHe> 0){
                (sellLev,sellHe)= abi.decode(delegateCallSwap(abi.encodeWithSignature("swapSellAndSell(address,address,address,uint256,uint256,uint256[2])",
                    swapRouter,leverageCoin.token,hedgeCoin.token,sellLev,sellHe,currentPrice)), (uint256,uint256));
            }
        }
        if(buyLev == 0){
            _repayAndInterest(leverageCoin,sellLev);
        }
        if(buyHe == 0){
            _repayAndInterest(hedgeCoin,sellHe);
        }
        calLeverageInfo(leverageCoin,levSlip);
        calLeverageInfo(hedgeCoin,heSlip);
    }
    function calAverageSlip(leverageInfo memory coinInfo) internal view returns(uint256) {
        uint256 loan = coinInfo.stakePool.loan(address(this));
        if(loan>0){
            return underlyingBalance(coinInfo.id).mulPrice(rebalancePrices, coinInfo.id).mul(coinInfo.leverageRate - feeDecimal)/coinInfo.leverageRate/loan/(calDecimal/feeDecimal);
        }else{
            return feeDecimal;
        }
    }
    function calLeverageInfo(leverageInfo storage coinInfo,uint256 swapSlip) internal{
        uint256 tokenNum = coinInfo.leverageToken.totalSupply();
        if(tokenNum > 0){
            uint256 balance = underlyingBalance(coinInfo.id).mulPrice(rebalancePrices, coinInfo.id).mul(feeDecimal)/swapSlip;
            uint256 loan = coinInfo.stakePool.loan(address(this));
            uint256 totalWorth = balance.sub(loan.mul(calDecimal));
            coinInfo.leverageRate = balance.mul(feeDecimal)/totalWorth;
            if (coinInfo.bRebase){
                coinInfo.rebalanceWorth = defaultRebalanceWorth*calDecimal/currentPrice[coinInfo.id];
                coinInfo.bRebase = false;
                coinInfo.leverageToken.calRebaseRatio(totalWorth/coinInfo.rebalanceWorth);
            }else{
                coinInfo.rebalanceWorth = totalWorth/tokenNum;
                coinInfo.bRebase = coinInfo.rebalanceWorth<defaultRebalanceWorth.mul(feeDecimal*calDecimal)/currentPrice[coinInfo.id]/rebaseThreshold;
            }
        }
    }
    function rebalanceAndLiquidate() external getUnderlyingPrice {
        if(checkLiquidate(leverageCoin,currentPrice,liquidateThreshold)){
            _liquidate(leverageCoin);
        }else if(checkLiquidate(hedgeCoin,currentPrice,liquidateThreshold)){
            _liquidate(hedgeCoin);
        }else if(checkLiquidate(leverageCoin,currentPrice,liquidateThreshold*4) || 
            checkLiquidate(hedgeCoin,currentPrice,liquidateThreshold*4)){
            _rebalance();
        }else{
            require(false, "Liquidate: current price is not under the threshold!");
        }
    }
    function _liquidate(leverageInfo storage coinInfo) internal{
        //all selled
        (address token0,address token1) = (coinInfo.id == 0) ? (hedgeCoin.token,leverageCoin.token) : (leverageCoin.token,hedgeCoin.token);
        uint256 amount = _swap(token0,token1,underlyingBalance(coinInfo.id));
        uint256 fee = amount.mul(rebalanceFee)/feeDecimal;
        uint256 leftAmount = amount.sub(fee);
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
        leftAmount = leftAmount -allLoan;
        if(leftAmount>0){
            _redeem(address(uint160(address(coinInfo.leverageToken))),coinInfo.token,leftAmount);
        }
        coinInfo.leverageToken.newErc20(leftAmount);
        emit Liquidate(msg.sender,coinInfo.token,allLoan,fee,leftAmount);
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
    function redeemFees(uint256 feeRatio,address token,uint256 amount) internal returns (uint256){
        uint256 fee = amount.mul(feeRatio)/feeDecimal;
        if (fee>0){
            _redeem(feeAddress,token, fee);
        }
        return amount.sub(fee);
    }
    function getUnderlyingPriceView() public view returns(uint256[2]memory){
        uint256[] memory assets = new uint256[](2);
        assets[0] = uint256(leverageCoin.token);
        assets[1] = uint256(hedgeCoin.token);
        uint256[]memory prices = oraclegetPrices(assets);
        return [prices[0],prices[1]];
    }
    function getEnableRebalanceAndLiquidate()external view returns (bool,bool){
        uint256[2]memory prices = getUnderlyingPriceView();
        uint256 threshold = liquidateThreshold*39e7/feeDecimal;
        return (checkLiquidate(leverageCoin,prices,threshold),
                checkLiquidate(hedgeCoin,prices,threshold));
    }
    function checkLiquidate(leverageInfo memory coinInfo,uint256[2]memory prices,uint256 threshold) internal view returns(bool){
        if(coinInfo.leverageToken.totalSupply() == 0){
            return false;
        }
        //3CP < RP*(2+liquidateThreshold)
        return coinInfo.leverageRate.mulPrice(prices,coinInfo.id) < 
            (coinInfo.leverageRate-feeDecimal+threshold).mulPrice(rebalancePrices,coinInfo.id);
    }
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'leveragedPool: EXPIRED');
        _;
    }
    modifier getUnderlyingPrice(){
        currentPrice = getUnderlyingPriceView();
        _;
    }
}