pragma solidity =0.5.16;
import "../PhoenixModules/modules/SafeMath.sol";
import "../PhoenixModules/ERC20/safeErc20.sol";
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
contract PHXSwapRouter{
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
    function swapRebalance(address swapRouter,address token0,address token1,uint256 amountLev,uint256 amountHe,uint256[2] calldata prices,uint256 id)payable external returns (uint256,uint256){
        uint256 key = (id>>128);
        if (key == 0){
            uint256 vulue = swapBuyAndBuy(swapRouter,token0,token1,amountLev,amountHe,prices);
            return (vulue,0);
        }else if(key == 1){
            return swapSellAndSell(swapRouter,token0,token1,amountLev,amountHe,prices);
        }else{
            uint256 vulue = swapBuyAndSell(swapRouter,token0,token1,amountLev,amountHe,prices,uint8(id));
            return (vulue,0);
        }
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
    function swapBuyAndBuy(address swapRouter,address token0,address token1,uint256 buyLev,uint256 buyHe,uint256[2] memory prices) payable public returns (uint256){
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
    function swapSellAndSell(address swapRouter,address token0,address token1,uint256 sellLev,uint256 sellHe,uint256[2] memory prices) payable public returns (uint256,uint256){
        uint256 sellLev1 = sellLev.mul(calDecimal);
        uint256 sellHe1 = sellHe.mulPrice(prices, 0);
        if(sellLev1 >= sellHe1){
            (sellLev,sellHe) = swapSellAndSellSub(swapRouter,token1,token0,sellLev1.divPrice(prices,0),sellHe,prices,1);
        }else{
            (sellHe,sellLev) = swapSellAndSellSub(swapRouter,token0,token1,sellHe1/calDecimal,sellLev,prices,0);
        }
        return (sellLev,sellHe);
    }
    function swapBuyAndSell(address swapRouter,address token0,address token1,uint256 buyAmount,uint256 sellAmount,uint256[2] memory prices,uint8 id)payable public returns (uint256){
        uint256 amountSell = sellAmount > 0 ? getAmountIn(swapRouter,token0,token1,sellAmount) : 0;
        return _swap(swapRouter,token0,token1,buyAmount.add(amountSell));
    }
    function sellExactAmount(address swapRouter,address token0,address token1,uint256 amountout) payable external returns (uint256,uint256){
        uint256 amountSell = amountout > 0 ? getAmountIn(swapRouter,token0,token1,amountout) : 0;
        return (amountSell,_swap(swapRouter,token0,token1,amountSell));
    }
    function swap(address swapRouter,address token0,address token1,uint256 amountSell) payable external returns (uint256){
        return _swap(swapRouter,token0,token1,amountSell);
    }
}