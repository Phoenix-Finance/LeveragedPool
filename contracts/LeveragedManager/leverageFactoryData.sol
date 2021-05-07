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
    uint256 constant internal currentVersion = 0;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }
    mapping(address=>address payable) public stakePoolMap;
    mapping(bytes32=>address payable) public leveragePoolMap;
    uint256 constant public allowRebalance = 1;

    string public baseCoinName;

    address public stakePoolImpl;

    address public leveragePoolImpl;

    address public FPTCoinImpl;

    address public rebaseTokenImpl;

    address public fnxOracle;
    address public uniswap;

    address payable public feeAddress;

    //feeDecimals = 8; 
    uint64 public buyFee;
    uint64 public sellFee;
    uint64 public rebalanceFee;
    uint64 public interestRate;
    uint64 public rebaseThreshold;
    uint64 public liquidateThreshold;


    address payable[] public fptCoinList;
    address payable[] public stakePoolList;
    address payable[] public leveragePoolList;
}