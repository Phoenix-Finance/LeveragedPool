pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * FinNexus
 * Copyright (C) 2020 FinNexus Options Protocol
 */

interface ILeverageFactory{
    function getLeveragePool(address tokenA,address tokenB,uint256 leverageRatio)external 
        view returns (address _stakePoolA,address _stakePoolB,address _leveragePool);
    function getStakePool(address token)external view returns (address _stakePool);
    function getAllStakePool()external view returns (address payable[] memory);
    function getAllLeveragePool()external view returns (address payable[] memory);
}