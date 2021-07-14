pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
import "../PhoenixModules/PPTCoin/IPPTCoin.sol";
import "../PhoenixModules/proxyModules/versionUpdater.sol";
import "../PhoenixModules/modules/ReentrancyGuard.sol";
import "../PhoenixModules/proxyModules/AddressPermission.sol";
import "../PhoenixModules/proxyModules/Halt.sol";
contract stakePoolData is versionUpdater,ReentrancyGuard,AddressPermission,Halt{
    uint256 constant internal currentVersion = 3;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }
    uint256 constant public allowBorrow = 1;
    uint256 constant public allowRepay = 1<<1;
    uint256 constant internal calDecimal = 1e8; 
    uint256 internal _totalSupply;
    address internal _poolToken;
    uint64 internal _interestRate;
    IPPTCoin public pptCoin;
    uint64 internal _defaultRate;
    mapping (address => uint256) internal loanAccountMap;
    event Borrow(address indexed from,address indexed token,uint256 reply,uint256 loan);
    event Interest(address indexed from,address indexed token,uint256 interest);
    event Redeem(address indexed recieptor,address indexed Coin,uint256 amount);
    event Stake(address indexed from,address indexed token,uint256 amount,uint256 mintAmount);
    event Unstake(address indexed from,address indexed token,uint256 amount,uint256 burnAmount);
    event Repay(address indexed from,address indexed token,uint256 amount,uint256 leftLoan);
}