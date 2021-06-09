pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
import "../PPTCoin/IPPTCoin.sol";
import "../proxyModules/versionUpdater.sol";
import "../modules/ReentrancyGuard.sol";
import "../proxyModules/AddressPermission.sol";
import "../proxyModules/halt.sol";
contract stakePoolData is ImportIPPTCoin,versionUpdater,ReentrancyGuard,AddressPermission,Halt{
    uint256 constant internal currentVersion = 1;
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
    uint64 internal _defaultRate;
    mapping (address => uint256) internal loanAccountMap;
    event Borrow(address indexed from,address indexed token,uint256 reply,uint256 loan);
    event Redeem(address indexed recieptor,address indexed Coin,uint256 amount);
    event Stake(address indexed from,address indexed token,uint256 amount,uint256 mintAmount);
    event Unstake(address indexed from,address indexed token,uint256 amount,uint256 burnAmount);
    event Repay(address indexed from,address indexed token,uint256 amount,uint256 leftLoan);
    event RepayAndInterest(address indexed from,address indexed token,uint256 amount,uint256 leftLoan);
}