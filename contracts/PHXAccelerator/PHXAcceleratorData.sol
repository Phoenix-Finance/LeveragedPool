pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
import "../proxyModules/versionUpdater.sol";
import "../proxyModules/timeLimitation.sol";
import "../proxyModules/Halt.sol";
import "../modules/safeTransfer.sol";
import "../modules/ReentrancyGuard.sol";
contract PHXAcceleratorData is Halt,timeLimitation,ReentrancyGuard,versionUpdater,safeTransfer{
    mapping(address=>uint256) public tokenAcceleratorRate;
    struct userAcceleratorInfo {
        uint256 AcceleratorBalance;
        //Period ID start at 1. if a PeriodID equals zero, it means your FPT-B is flexible staked.
        //User's max locked period id;
        uint64 maxPeriodID;
        //User's max locked period timestamp. Flexible FPT-B is locked _flexibleExpired seconds;
        uint128 lockedExpired;
        mapping(address=>uint256) tokenBalance;
        mapping(address=>uint256) acceleratedBalance;
    }
    mapping(address=>userAcceleratorInfo) public userInfoMap;
    address[] minePoolList;
    uint256 public flexibleExpired;
    uint256 public maxPeriodLimit;
    uint256 public period;
    uint256 public startTime;
    event Stake(address indexed sender,address indexed token,uint256 amount,uint256 maxPeriod);
    event Unstake(address indexed sender,address indexed token,uint256 amount);
    event ChangePeriod(address indexed sender,uint256 maxPeriod);
}