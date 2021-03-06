pragma solidity =0.5.16;
import "./PHXSwapRouter.sol";
import "../uniswap/IUniswapV2Router02.sol";
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
contract UniSwapRouter is PHXSwapRouter{
    constructor()public{

    }
    function getSwapPath(address swapRouter,address token0,address token1) internal view returns (address[] memory path){
        (bool success, bytes memory returnData) = address(this).staticcall(abi.encodeWithSignature("getSwapRoutingPath(address,address)",token0,token1));
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        path = abi.decode(returnData, (address[]));
        if(path.length>0){
            return path;
        }
        IUniswapV2Router02 IUniswap = IUniswapV2Router02(swapRouter);
        path = new address[](2);
        path[0] = token0 == address(0) ? IUniswap.WETH() : token0;
        path[1] = token1 == address(0) ? IUniswap.WETH() : token1;
    }
    function calSlit(address swapRouter,address token0,address token1,uint256 sellAmount,uint256[2] memory prices,uint8 id)internal view returns (uint256){
        IUniswapV2Router02 IUniswap = IUniswapV2Router02(swapRouter);
        if(sellAmount>0){
            address[] memory path = getSwapPath(swapRouter,token0,token1);
            uint[] memory amounts = IUniswap.getAmountsOut(sellAmount, path);
            //emit Swap(swapRouter,address(0x22),amounts[0],amounts[1]);
            if(amounts[amounts.length-1]>0){
                return amounts[amounts.length-1].mulPrice(prices,id)/amounts[0];
            }
        }
        return calDecimal;
    }
    function getAmountIn(address swapRouter,address token0,address token1,uint256 amountOut) internal view returns (uint256){
        IUniswapV2Router02 IUniswap = IUniswapV2Router02(swapRouter);
        address[] memory path = getSwapPath(swapRouter,token0,token1);
        uint[] memory amounts = IUniswap.getAmountsIn(amountOut, path);
        return amounts[0];
    }
    function _swap(address swapRouter,address token0,address token1,uint256 amount0) internal returns (uint256) {
        IUniswapV2Router02 IUniswap = IUniswapV2Router02(swapRouter);
        address[] memory path = getSwapPath(swapRouter,token0,token1);
        uint256[] memory amounts;
        if(token0 == address(0)){
            amounts = IUniswap.swapExactETHForTokens.value(amount0)(0, path,address(this), now+30);
        }else if(token1 == address(0)){
            amounts = IUniswap.swapExactTokensForETH(amount0,0, path, address(this), now+30);
        }else{
            amounts = IUniswap.swapExactTokensForTokens(amount0,0, path, address(this), now+30);
        }
        emit Swap(token0,token1,amounts[0],amounts[amounts.length-1]);
        return amounts[amounts.length-1];
    }

}