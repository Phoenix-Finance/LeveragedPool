pragma solidity =0.5.16;
import "../modules/SafeMath.sol";
import "../ERC20/safeErc20.sol";
contract FNXSwapRouter{
    uint256 constant internal calDecimal = 1e18; 
    event Swap(address indexed fromCoin,address indexed toCoin,uint256 fromValue,uint256 toValue);
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    function calSlit(address swapRouter,address token0,address token1,uint256 sellAmount,uint256[2] memory prices,uint8 id)internal view returns (uint256);
    function getAmountIn(address swapRouter,address token0,address token1,uint256 amountOut) internal view returns (uint256);
    function _swap(address swapRouter,address token0,address token1,uint256 amount0) internal returns (uint256);
    function calRate(address swapRouter,address token0,address token1,uint256 sellBig,uint256 sellSmall,uint256[2] memory prices,uint8 id) internal view returns (uint256){
        if(sellBig == 0){
            return calDecimal;
        }
        uint256 slit = calSlit(swapRouter,token0,token1,sellBig - sellSmall,prices,id);
        //(Xl + Xg*s)/(Xg+Xl*s)
        uint256 rate = sellSmall.mul(calDecimal).add(sellBig.mul(slit)).mul(calDecimal)/(sellBig.mul(calDecimal).add(sellSmall.mul(slit)));
        return rate;
    }
    function swapBuyAndBuySub(address swapRouter,address token0,address token1,uint256 buyLev,uint256 buyHe,uint256[2] memory prices,uint8 id) internal returns (uint256){
        uint256 rate = calRate(swapRouter,token0,token1,buyLev,buyHe,prices,id);
        buyHe = buyHe.mul(rate)/calDecimal;
        if (buyLev*100 > buyHe*101){
            buyLev = buyLev - buyHe;
            return _swap(swapRouter,token0,token1,buyLev);
        }else{
            return 0;
        }
    }
    function swapBuyAndBuy(address swapRouter,address token0,address token1,uint256 buyLev,uint256 buyHe,uint256[2] calldata prices) external returns (uint256){
        uint256 buyLev1 = buyLev.mul(calDecimal);
        uint256 buyHe1 = buyHe.mulPrice(prices, 0);
        if(buyLev1 >= buyHe1){
            return swapBuyAndBuySub(swapRouter,token0,token1,buyLev,buyHe1/calDecimal,prices,0);
        }else{
            return swapBuyAndBuySub(swapRouter,token1,token0,buyHe,buyLev1.divPrice(prices,0),prices,1);
        }
    }
    function swapSellAndSellSub(address swapRouter,address token0,address token1,uint256 sellLev,uint256 sellHe,uint256[2] memory prices,uint8 id) 
        internal returns (uint256,uint256){
        uint256 rate = calRate(swapRouter,token0,token1,sellLev,sellHe,prices,id);
        uint256 selltemp = sellLev.mul(calDecimal)/rate;
        if (selltemp*100 > sellHe*101){
            selltemp = selltemp - sellHe;
            selltemp = _swap(swapRouter,token0,token1,selltemp);
            return (selltemp.add(sellHe.mul(calDecimal*calDecimal).divPrice(prices,id)/rate),sellHe);
        }else{
            return (sellHe.mul(calDecimal*calDecimal).divPrice(prices,id)/rate,sellHe);
        }
    }
    function swapSellAndSell(address swapRouter,address token0,address token1,uint256 sellLev,uint256 sellHe,uint256[2] calldata prices)external returns (uint256,uint256){
        uint256 sellLev1 = sellLev.mul(calDecimal);
        uint256 sellHe1 = sellHe.mulPrice(prices, 0);
        if(sellLev1 >= sellHe1){
            (sellLev,sellHe) = swapSellAndSellSub(swapRouter,token1,token0,sellLev1.divPrice(prices,0),sellHe,prices,1);
        }else{
            (sellHe,sellLev) = swapSellAndSellSub(swapRouter,token0,token1,sellHe1/calDecimal,sellLev,prices,0);
        }
        return (sellLev,sellHe);
    }
    function swapBuyAndSell(address swapRouter,address token0,address token1,uint256 buyAmount,uint256 sellAmount,uint256[2] calldata prices,uint8 id)external returns (uint256){
        uint256 amountSell = buyAmount.add(sellAmount).add(sellAmount/10);
        uint256 rate = calSlit(swapRouter,token0,token1,amountSell,prices,id);
        sellAmount = sellAmount.mul(calDecimal)/rate;
        return _swap(swapRouter,token0,token1,buyAmount.add(sellAmount));
    }
    function sellExactAmount(address swapRouter,address token0,address token1,uint256 amountout)external returns (uint256,uint256){
        uint256 amountSell = getAmountIn(swapRouter,token0,token1,amountout);
        return (amountSell,_swap(swapRouter,token0,token1,amountSell));
    }
    function swap(address swapRouter,address token0,address token1,uint256 amountSell)external returns (uint256){
        return _swap(swapRouter,token0,token1,amountSell);
    }
}