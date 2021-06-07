pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
import "./PHXAcceleratorData.sol";
import "../modules/SafeMath.sol";
import "../acceleratedMinePool/IAcceleratedMinePool.sol";
contract PHXAccelerator is PHXAcceleratorData{
    using SafeMath for uint256;
        /**
     * @dev constructor.
     */
    constructor (address multiSignature) proxyOwner(multiSignature) public{
    }
    function initMineLockedInfo(uint256 _startTime,uint256 _periodTime,
        uint256 _maxPeriodLimit,uint256 _flexibleExpired) external originOnce {
        startTime = _startTime;
        period = _periodTime;
        maxPeriodLimit = _maxPeriodLimit;
        flexibleExpired = _flexibleExpired;
    }
    function update() external versionUpdate {
    }
    function getAcceleratedBalance(address account,address minePool)external returns(uint256,uint64){
        return (userInfoMap[account].acceleratedBalance[minePool],userInfoMap[account].maxPeriodID);
    }
    function getAcceleratorPeriodInfo()external returns (uint256,uint256){
        return (startTime,period);
    }
    function stake(address token,uint256 amount,uint128 maxLockedPeriod,address toMinePool) nonReentrant notHalted public {
        amount = getPayableAmount(token,amount);
        require(amount>0, "Stake amount is zero!");
        uint256 rate = tokenAcceleratorRate[token];
        require(rate>0 , "Stake token accelerate rate is zero!");
        uint256 balance = amount.mul(rate);
        userInfoMap[msg.sender].AcceleratorBalance  =  userInfoMap[msg.sender].AcceleratorBalance.add(balance);
        serUserLockedPeriod(msg.sender,maxLockedPeriod);
        _accelerateMinePool(toMinePool,balance);
        emit Stake(msg.sender,token,amount,maxLockedPeriod);
    }
    /**
     * @dev Add PHX locked period.
     * @param maxLockedPeriod accelerated locked preiod number.
     */
    function changeStakePeriod(uint64 maxLockedPeriod)public validPeriod(maxLockedPeriod) notHalted{
        require(userInfoMap[msg.sender].AcceleratorBalance > 0, "stake balance is zero");
        uint64 oldPeriod = userInfoMap[msg.sender].maxPeriodID;
        serUserLockedPeriod(msg.sender,maxLockedPeriod);
        uint256 poolLen = minePoolList.length;
        for(uint256 i=0;i<poolLen;i++){
            _changeMinePoolPeriod(minePoolList[i],oldPeriod);
        }
        emit ChangePeriod(msg.sender,maxLockedPeriod);
    }
    /**
     * @dev withdraw PHX coin.
     * @param amount PHX amount that withdraw from mine pool.
     */
    function unstake(address token,uint256 amount)public nonReentrant notHalted periodExpired(msg.sender){
        require(amount > 0, 'unstake amount is zero');
        require(userInfoMap[msg.sender].tokenBalance[token] >= amount,
            'unstake amount is greater than total user stakes');
        uint256 rate = tokenAcceleratorRate[token];
        require(rate>0 , "Stake token accelerate rate is zero!");
        uint256 balance = amount.mul(rate);
        userInfoMap[msg.sender].AcceleratorBalance = userInfoMap[msg.sender].AcceleratorBalance.sub(balance);
        userInfoMap[msg.sender].tokenBalance[token] = userInfoMap[msg.sender].tokenBalance[token]-amount;
        emit Unstake(msg.sender,token,amount);
    }
    function transferAcceleratedBalance(address fromMinePool,address toMinePool,uint256 amount) public{
        _removeFromMinoPool(fromMinePool,amount);
        _accelerateMinePool(toMinePool,amount);
    }
    function _changeMinePoolPeriod(address minePool,uint64 oldPeriod)internal {
        if(userInfoMap[msg.sender].acceleratedBalance[minePool] > 0){
            IAcceleratedMinePool(minePool).changeAcceleratedInfo(msg.sender,userInfoMap[msg.sender].acceleratedBalance[minePool],oldPeriod);
        }
    }
    function _removeFromMinoPool(address minePool,uint256 amount) internal{
        require(userInfoMap[msg.sender].acceleratedBalance[minePool]>=amount,"mine pool accelerated balance is unsufficient");
        uint256 oldBalance = userInfoMap[msg.sender].acceleratedBalance[minePool];
        userInfoMap[msg.sender].acceleratedBalance[minePool] = oldBalance-amount;
        if (minePool != address(0)){
            IAcceleratedMinePool(minePool).changeAcceleratedInfo(msg.sender,oldBalance,userInfoMap[msg.sender].maxPeriodID);
        } 
    }
    function _accelerateMinePool(address minePool,uint256 amount) internal{
        uint256 oldBalance = userInfoMap[msg.sender].acceleratedBalance[minePool];
        userInfoMap[msg.sender].acceleratedBalance[minePool] = oldBalance.add(amount);
        if (minePool != address(0)){
            IAcceleratedMinePool(minePool).changeAcceleratedInfo(msg.sender,oldBalance,userInfoMap[msg.sender].maxPeriodID);
        } 
    }
    /**
     * @dev getting user's maximium locked period ID.
     * @param account user's account
     */
    function getUserMaxPeriodId(address account)public view returns (uint256) {
        return userInfoMap[account].maxPeriodID;
    }
    /**
     * @dev getting user's locked expired time. After this time user can unstake PHX coins.
     * @param account user's account
     */
    function getUserExpired(address account)public view returns (uint256) {
        return userInfoMap[account].lockedExpired;
    }
    /**
     * @dev getting current mine period ID.
     */
    function getCurrentPeriodID()public view returns (uint256) {
        return getPeriodIndex(currentTime());
    }
    function setFlexibleExpired(uint64 expired)public onlyOwner{
        flexibleExpired = expired;
    }
    /**
     * @dev convert timestamp to period ID.
     * @param _time timestamp. 
     */ 
    function getPeriodIndex(uint256 _time) public view returns (uint256) {
        if (_time<startTime){
            return 0;
        }
        return _time.sub(startTime).div(period)+1;
    }
    function serUserLockedPeriod(address account,uint256 lockedPeriod) internal{
        uint256 curPeriod = getPeriodIndex(currentTime());
        uint256 userMaxPeriod = curPeriod+lockedPeriod-1;
        require(userMaxPeriod>=userInfoMap[account].maxPeriodID, "lockedPeriod cannot be smaller than current locked period");
        if(userInfoMap[account].maxPeriodID<curPeriod && lockedPeriod == 1){
            require(getPeriodFinishTime(userMaxPeriod)>currentTime() + flexibleExpired, 'locked time must greater than flexible days');
        }
        if (lockedPeriod == 0){
            userInfoMap[account].maxPeriodID = 0;
            userInfoMap[account].lockedExpired = uint128(currentTime().add(flexibleExpired));
        }else{
            userInfoMap[account].maxPeriodID = uint64(userMaxPeriod);
            userInfoMap[account].lockedExpired = uint128(getPeriodFinishTime(curPeriod+lockedPeriod-1));
        }
    }
    /**
     * @dev convert period ID to period's finish timestamp.
     * @param periodID period ID. 
     */
    function getPeriodFinishTime(uint256 periodID)public view returns (uint256) {
        return periodID.mul(period).add(startTime);
    }
        /**
     * @dev Throws if input period number is greater than _maxPeriod.
     */
    modifier validPeriod(uint64 period){
        require(period >= 0 && period <= maxPeriodLimit, 'locked period must be in valid range');
        _;
    }
    /**
     * @dev get now timestamp.
     */
    function currentTime() internal view returns (uint256){
        return now;
    }    
    /**
     * @dev Throws if user's locked expired timestamp is less than now.
     */
    modifier periodExpired(address account){
        require(userInfoMap[account].lockedExpired < currentTime(),'locked period is not expired');

        _;
    }
}