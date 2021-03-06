pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
import "../PhoenixModules/proxyModules/versionUpdater.sol";
import "../PhoenixModules/proxyModules/proxyOperator.sol";
/**
 * @title leverage contract factory.
 * @dev A smart-contract which manage leverage smart-contract's and peripheries.
 *
 */
contract leverageFactoryData is versionUpdater,proxyOperator{
    uint256 constant internal currentVersion = 4;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }
    uint256 constant public LeveragePoolID = 0;
    uint256 constant public stakePoolID = 1;
    uint256 constant public rebasePoolID = 2;
    uint256 constant public PPTTokenID = 3;
    uint256 constant public MinePoolID = 4;
    struct proxyInfo {
        address implementation;
        address payable[] proxyList;
    }
    mapping(uint256=>proxyInfo) public proxyinfoMap;
    mapping(address=>address payable) public stakePoolMap;
    mapping(bytes32=>address payable) public leveragePoolMap;
    address public vestingPool;

    string public baseCoinName;

    //feeDecimals = 8; 
    uint64 public buyFee;
    uint64 public sellFee;
    uint64 public rebalanceFee;
    uint64 public interestInflation;
    address public phxOracle;
    uint64 public rebaseThreshold;
    uint32 public PPTTimeLimit;
    address public swapRouter;
    uint64 public liquidateThreshold;
    uint32 public rebaseTimeLimit;
    address payable public feeAddress;
    uint64 public rebalanceInterval;
    address public phxSwapLib;
    uint64 public lastRebalance;
    event CreateLeveragePool(address indexed leveragePool,address indexed  tokenA,address indexed  tokenB,
        uint256 leverageRatio,uint256 leverageRebaseWorth);
    event CreateStakePool(address indexed stakePool,address indexed token,uint256 interestrate);
}