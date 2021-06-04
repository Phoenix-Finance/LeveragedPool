pragma solidity =0.5.16;
import "./SharedCoin.sol";
import "../modules/SafeMath.sol";
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */

/**
 * @title FPTCoin is Phoenix collateral Pool token, implement ERC20 interface.
 * @dev ERC20 token. Its inside value is collatral pool net worth.
 *
 */
contract FPTCoin is SharedCoin {
    using SafeMath for uint256;
    mapping (address => bool) internal timeLimitWhiteList;
    constructor ()public{
    }
    function initialize() public{
        versionUpdater.initialize();
        _totalSupply = 0;
        decimals = 18;
    }

    function update() public versionUpdate{
    }
    /**
     * @dev Retrieve total locked worth. 
     */ 
    function getTotalLockedWorth() public view returns (uint256) {
        return _totalLockedWorth;
    }
    /**
     * @dev Retrieve user's locked balance. 
     * @param account user's account.
     */ 
    function lockedBalanceOf(address account) public view returns (uint256) {
        return lockedBalances[account];
    }
    /**
     * @dev Retrieve user's locked net worth. 
     * @param account user's account.
     */ 
    function lockedWorthOf(address account) public view returns (uint256) {
        return lockedTotalWorth[account];
    }
    /**
     * @dev Retrieve user's locked balance and locked net worth. 
     * @param account user's account.
     */ 
    function getLockedBalance(address account) public view returns (uint256,uint256) {
        return (lockedBalances[account],lockedTotalWorth[account]);
    }

    /**
     * @dev Move user's FPT to locked balance, when user redeem collateral. 
     * @param account user's account.
     * @param amount amount of locked FPT.
     * @param lockedWorth net worth of locked FPT.
     */ 
    function addlockBalance(address account, uint256 amount,uint256 lockedWorth)public onlyManager {
        burn(account,amount);
        _addLockBalance(account,amount,lockedWorth);
    }
    /**
     * @dev Move user's FPT to 'recipient' balance, a interface in ERC20. 
     * @param recipient recipient's account.
     * @param amount amount of FPT.
     */ 
    function transfer(address recipient, uint256 amount)public returns (bool){
        require(address(minePool) != address(0),"FnxMinePool is not set");
        if(SharedCoin.transfer(recipient,amount)){
            minePool.transferFPTCoin(msg.sender,recipient);
            return true;
        }
        return false;
    }
        /**
     * @dev Move sender's FPT to 'recipient' balance, a interface in ERC20. 
     * @param sender sender's account.
     * @param recipient recipient's account.
     * @param amount amount of FPT.
     */ 
    function transferFrom(address sender, address recipient, uint256 amount)public returns (bool){
        require(address(minePool) != address(0),"FnxMinePool is not set");
        if(SharedCoin.transferFrom(sender,recipient,amount)){
            minePool.transferFPTCoin(sender,recipient);
            return true;            
        }
        return false;
    }
    /**
     * @dev burn user's FPT when user redeem FPTCoin. 
     * @param account user's account.
     * @param amount amount of FPT.
     */ 
    function burn(address account, uint256 amount) public onlyManager OutLimitation(account) {
        //require(address(_FnxMinePool) != address(0),"FnxMinePool is not set");
        //_FnxMinePool.burnMinerCoin(account,amount);
        SharedCoin._burn(account,amount);
        minePool.changeFPTStake(account);
    }
    /**
     * @dev mint user's FPT when user add collateral. 
     * @param account user's account.
     * @param amount amount of FPT.
     */ 
    function mint(address account, uint256 amount) public onlyManager {
        SharedCoin._mint(account,amount);
        minePool.changeFPTStake(account);
    }
    /**
     * @dev An auxiliary function, add user's locked balance. 
     * @param account user's account.
     * @param amount amount of FPT.
     * @param lockedWorth net worth of FPT.
     */ 
    function _addLockBalance(address account, uint256 amount,uint256 lockedWorth)internal {
        lockedBalances[account]= lockedBalances[account].add(amount);
        lockedTotalWorth[account]= lockedTotalWorth[account].add(lockedWorth);
        _totalLockedWorth = _totalLockedWorth.add(lockedWorth);
        emit AddLocked(account, amount,lockedWorth);
    }
    /**
     * @dev An auxiliary function, deduct user's locked balance. 
     * @param account user's account.
     * @param amount amount of FPT.
     * @param lockedWorth net worth of FPT.
     */ 
    function _subLockBalance(address account,uint256 amount,uint256 lockedWorth)internal {
        lockedBalances[account]= lockedBalances[account].sub(amount);
        lockedTotalWorth[account]= lockedTotalWorth[account].sub(lockedWorth);
        _totalLockedWorth = _totalLockedWorth.sub(lockedWorth);
        emit BurnLocked(account, amount,lockedWorth);
    }
    /**
     * @dev An interface of redeem locked FPT, when user redeem collateral, only manager contract can invoke. 
     * @param account user's account.
     * @param tokenAmount amount of FPT.
     * @param leftCollateral left available collateral in collateral pool, priced in USD.
     */ 
    function redeemLockedCollateral(address account,uint256 tokenAmount,uint256 leftCollateral)public onlyManager OutLimitation(account) returns (uint256,uint256){
        if (leftCollateral == 0){
            return(0,0);
        }
        uint256 lockedAmount = lockedBalances[account];
        uint256 lockedWorth = lockedTotalWorth[account];
        if (lockedAmount == 0 || lockedWorth == 0){
            return (0,0);
        }
        uint256 redeemWorth = 0;
        uint256 lockedBurn = 0;
        uint256 lockedPrice = lockedWorth/lockedAmount;
        if (lockedAmount >= tokenAmount){
            lockedBurn = tokenAmount;
            redeemWorth = tokenAmount*lockedPrice;
        }else{
            lockedBurn = lockedAmount;
            redeemWorth = lockedWorth;
        }
        if (redeemWorth > leftCollateral) {
            lockedBurn = leftCollateral/lockedPrice;
            redeemWorth = lockedBurn*lockedPrice;
        }
        if (lockedBurn > 0){
            _subLockBalance(account,lockedBurn,redeemWorth);
            return (lockedBurn,redeemWorth);
        }
        return (0,0);
    }
}
