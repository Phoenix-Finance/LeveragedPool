pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * FinNexus
 * Copyright (C) 2020 FinNexus Options Protocol
 */
import "../proxyModules/versionUpdater.sol";
import "../proxyModules/proxyOperator.sol";
/**
 * @title FNX period mine pool.
 * @dev A smart-contract which distribute some mine coins when user stake FPT-A and FPT-B coins.
 *
 */
contract leverageFactoryData is versionUpdater,proxyOperator{
    uint256 constant internal currentVersion = 0;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }
    uint256 constant public LeveragePoolID = 0;
    uint256 constant public stakePoolID = 1;
    uint256 constant public rebasePoolID = 2;
    uint256 constant public FPTTokenID = 3;
    struct proxyInfo {
        address implementation;
        address payable[] proxyList;
    }
    mapping(uint256=>proxyInfo) public proxyinfoMap;
    mapping(address=>address payable) public stakePoolMap;
    mapping(bytes32=>address payable) public leveragePoolMap;

    string public baseCoinName;

    //feeDecimals = 8; 
    uint64 public buyFee;
    uint64 public sellFee;
    uint64 public rebalanceFee;
    uint64 public interestInflation;
    address public fnxOracle;
    uint64 public rebaseThreshold;
    uint32 public FPTTimeLimit;
    address public swapRouter;
    uint64 public liquidateThreshold;
    uint32 public rebaseTimeLimit;
    address payable public feeAddress;
    uint64 public rebalanceInterval;
    address public fnxSwapLib;
    uint64 public lastRebalance;

}