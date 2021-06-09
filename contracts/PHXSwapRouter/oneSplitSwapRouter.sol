pragma solidity =0.5.16;
import "./PHXSwapRouter.sol";
import "../OneSplit/IOneSplit.sol";
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
contract oneSplitSwapRouter is PHXSwapRouter{
    address constant private eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    constructor()public{

    }
    function calSlit(address swapRouter,address token0,address token1,uint256 sellAmount,uint256[2] memory prices,uint8 id)internal view returns (uint256){
        IOneSplit oneSplit = IOneSplit(swapRouter);
        if(sellAmount>0){
            if (token0 == address(0)){
                token0 = eth;
            }
            if (token1 == address(0)){
                token1 = eth;
            }
            (uint256 returnAmount,) = oneSplit.getExpectedReturn(IERC20(token0),IERC20(token1),sellAmount,1,0);
            if(returnAmount>0){
                return returnAmount.mulPrice(prices,id)/sellAmount;
            }
        }
        return calDecimal;
    }
    function getAmountIn(address swapRouter,address token0,address token1,uint256 amountOut,uint256[2] memory prices,uint8 id) internal view returns (uint256){
        uint256 amountIn = amountOut.mulPrice(prices,id)/99e16;
        if (token0 == address(0)){
            token0 = eth;
        }
        if (token1 == address(0)){
            token1 = eth;
        }
        IOneSplit oneSplit = IOneSplit(swapRouter);
        (uint256 returnAmount,) = oneSplit.getExpectedReturn(IERC20(token0),IERC20(token1),amountIn,1,0);
        if(returnAmount>0){
            return amountIn.mul(amountOut)/returnAmount;
        }
        return 0;
    }
    function _swap(address swapRouter,address token0,address token1,uint256 amount0) internal returns (uint256) {
        uint256 inputValue = 0;
        if (token0 == address(0)){
            token0 = eth;
            inputValue = amount0;
        }
        if (token1 == address(0)){
            token1 = eth;
        }
        IOneSplit oneSplit = IOneSplit(swapRouter);
        uint256[] memory quoteDistribution = new uint256[](0);
        uint256 amountOut = oneSplit.swap.value(inputValue)(IERC20(token0), IERC20(token1), amount0, 0, quoteDistribution, 0);
        emit Swap(token0,token1,amount0,amountOut);
        return amountOut;
    }

}