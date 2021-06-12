pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
interface IPHXSwap {
    function swapBuyAndBuy(address token0,address token1,uint256 buyLev,uint256 buyHe,uint256[2] calldata prices)payable  external returns (uint256);
    function swapSellAndSell(address token0,address token1,uint256 sellLev,uint256 sellHe,uint256[2] calldata prices)payable external returns (uint256,uint256);
    function swapBuyAndSell(address token0,address token1,uint256 buyAmount,uint256 sellAmount,uint256[2] calldata prices,uint8 id)payable external returns (uint256);
    function sellExactAmount(address token0,address token1,uint256 amountout)payable external returns (uint256,uint256);
    function swap(address token0,address token1,uint256 amountSell)payable external returns (uint256);
}
