pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
interface IAcceleratedMinePool {
    function changeAcceleratedInfo(address account,uint256 oldAcceleratedStake,uint64 oldAcceleratedPeriod) external;
    function transferFPTCoin(address account,address recieptor) external;
    function changeFPTStake(address account) external;
}