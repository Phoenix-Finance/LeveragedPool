pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
import "../ERC20/safeErc20.sol";
import "../modules/SafeMath.sol";
import "./stakePoolData.sol";
import "../modules/safeTransfer.sol";
contract stakePool is stakePoolData,safeTransfer{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    constructor (address multiSignature) proxyOwner(multiSignature) public{
    }
    function setPoolInfo(address PPTToken,address stakeToken,uint64 interestrate) public onlyOwner{
        _PPTCoin = IPPTCoin(PPTToken);
        _poolToken = stakeToken;
        _interestRate = interestrate;
        _defaultRate = interestrate;
    }
    function update() public versionUpdate{
    }
    function poolInterest()public view returns (uint256){
        if(_totalSupply == 0){
            return 0;
        }
        uint256 balance = poolBalance();
        return (_totalSupply.sub(balance)).mul(_interestRate)/_totalSupply;
    }
    function poolToken()public view returns (address){
        return _poolToken;
    }
    function interestRate()public view returns (uint64){
        return _interestRate;
    }
    function setInterestRate(uint64 interestrate) public onlyOwner{
        _interestRate = interestrate;
        _defaultRate = interestrate;
    }
    function interestInflation(uint64 inflation)public onlyOwner{
        if(_totalSupply > 0){
            uint256 balance = poolBalance();
            if(balance*100<_totalSupply){
                _interestRate = _interestRate*inflation/1e8;
            }else{
                _interestRate = _defaultRate;
            }
        }
    }
    function totalSupply()public view returns (uint256){
        return _totalSupply;
    }
    function borrowLimit(address account)public view returns (uint256){
        return loanAccountMap[account].add(poolBalance());
    }
    function poolBalance()public view returns (uint256){
        if (_poolToken == address(0)){
            return address(this).balance;
        }else{
            return IERC20(_poolToken).balanceOf(address(this));
        }
    }
    function loan(address account) public view returns(uint256){
        return loanAccountMap[account];
    }
    function borrow(uint256 amount) public addressPermissionAllowed(msg.sender,allowBorrow) returns(uint256) {
        loanAccountMap[msg.sender] = loanAccountMap[msg.sender].add(amount);
        uint256 reply = amount.mul((calDecimal-_interestRate))/calDecimal;
        _totalSupply = _totalSupply.add(amount-reply);
        _redeem(msg.sender,_poolToken,reply);
        emit Borrow(msg.sender,_poolToken,reply,amount);
        return reply;
    }
    function borrowAndInterest(uint256 amount) public addressPermissionAllowed(msg.sender,allowBorrow){
        //l1*r + (l0-l1) = -amount
        uint256 _loan = loanAccountMap[msg.sender].add(amount).mul(calDecimal)/(calDecimal-_interestRate);
        loanAccountMap[msg.sender] = _loan;
        _totalSupply = _totalSupply.add(_loan.mul(_interestRate).div(calDecimal));
        _redeem(msg.sender,_poolToken,amount);
        emit Borrow(msg.sender,_poolToken,amount,_loan);
    }
    function repay(uint256 amount,bool bAll) public payable addressPermissionAllowed(msg.sender,allowRepay) {
        amount = getPayableAmount(_poolToken,amount);
        if(!bAll){
            loanAccountMap[msg.sender] = loanAccountMap[msg.sender].sub(amount);
        }else{
            _totalSupply = _totalSupply.sub(loanAccountMap[msg.sender]).add(amount);
            loanAccountMap[msg.sender] = 0;
        }
        emit Repay(msg.sender,_poolToken,amount,loanAccountMap[msg.sender]);
    }
    function repayAndInterest(uint256 amount) public payable addressPermissionAllowed(msg.sender,allowRepay){
        amount = getPayableAmount(_poolToken,amount);
        //l1*r + (l0-l1) = amount
        uint256 _loan = loanAccountMap[msg.sender].sub(amount).mul(calDecimal)/(calDecimal-_interestRate);
        loanAccountMap[msg.sender] = _loan;
        _totalSupply = _totalSupply.add(_loan.mul(_interestRate).div(calDecimal));
        emit RepayAndInterest(msg.sender,_poolToken,amount,_loan);
    }
    function PPTTotalSuply()public view returns (uint256){
        return _PPTCoin.totalSupply();
    }
    function tokenNetworth() public view returns (uint256){
        uint256 tokenNum = PPTTotalSuply();
        return (tokenNum > 0 ) ? _totalSupply.mul(calDecimal)/tokenNum : calDecimal;
    }
    function stake(uint256 amount) public payable nonReentrant {
        amount = getPayableAmount(_poolToken,amount);
        require(amount > 0, 'stake amount is zero');
        uint256 netWorth = tokenNetworth();
        uint256 mintAmount = amount.mul(calDecimal)/netWorth;
        _totalSupply = _totalSupply.add(amount);
        _PPTCoin.mint(msg.sender,mintAmount);
        emit Stake(msg.sender,_poolToken,amount,mintAmount);
    }
    function unstake(uint256 amount) public nonReentrant {
        require(amount > 0, 'unstake amount is zero');
        uint256 netWorth = tokenNetworth();
        uint256 redeemAmount = netWorth.mul(amount)/calDecimal;
        require(redeemAmount<=poolBalance(),"Available pool liquidity is unsufficient");
        _PPTCoin.burn(msg.sender,amount);
        _totalSupply = _totalSupply.sub(redeemAmount);
        _redeem(msg.sender,_poolToken,redeemAmount);
        emit Unstake(msg.sender,_poolToken,redeemAmount,amount);
    }
}