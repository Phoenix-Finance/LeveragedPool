pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * FinNexus
 * Copyright (C) 2020 FinNexus Options Protocol
 */
import "../modules/AddressPermission.sol";
import "../modules/versionUpdater.sol";
/**
 * @title FNX period mine pool.
 * @dev A smart-contract which distribute some mine coins when user stake FPT-A and FPT-B coins.
 *
 */
contract leverageFactoryData is AddressPermission,versionUpdater{
    uint256 constant internal currentVersion = 2;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }
    mapping(address=>address payable) public stakePoolMap;
    mapping(bytes32=>address payable) public leveragePoolMap;
    uint256 constant public allowRebalance = 1;

    string public baseCoinName;

    address public stakePoolImpl;
    //feeDecimals = 8; 
    uint64 public buyFee;
    address public leveragePoolImpl;
    uint64 public sellFee;
    address public FPTCoinImpl;
    uint64 public rebalanceFee;
    uint32 public FPTTimeLimit;
    address public rebaseTokenImpl;
    uint64 public interestAddRate;
    uint32 public rebaseTimeLimit;
    address public fnxOracle;
    uint64 public rebaseThreshold;
    address public uniswap;
    uint64 public liquidateThreshold;
    address payable public feeAddress;
    uint64 public rebalanceInterval;
    uint64 public lastRebalance;

    address payable[] public fptCoinList;
    address payable[] public stakePoolList;
    address payable[] public leveragePoolList;

}