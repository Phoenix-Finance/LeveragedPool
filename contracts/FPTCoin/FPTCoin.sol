pragma solidity =0.5.16;
import "./SharedCoin.sol";
import "../modules/SafeMath.sol";


/**
 * @title FPTCoin is finnexus collateral Pool token, implement ERC20 interface.
 * @dev ERC20 token. Its inside value is collatral pool net worth.
 *
 */
contract FPTCoin is SharedCoin {
    using SafeMath for uint256;
    mapping (address => bool) internal timeLimitWhiteList;
    constructor ()public{
        initialize();
    }
    /**
     * @dev constructor function. set FNX minePool contract address. 
     */ 
    function initialize() onlyOwner public{
        SharedCoin.initialize();
    }
    function update() onlyOwner public{
    }
  /**
     * EXTERNAL FUNCTION
     *
     * @dev change token name
     * @param _name token name
     * @param _symbol token symbol
     *
     */
    function changeTokenName(string memory _name, string memory _symbol)
        public
        onlyOwner
    {
        //check parameter in ico minter contract
        name = _name;
        symbol = _symbol;
    }
    /**
     * @dev Retrieve user's start time for burning. 
     * @param user user's account.
     */ 
    function getUserBurnTimeLimite(address user) public view returns (uint256){
        return getItemTimeLimitation(uint256(user));
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
     * @dev Interface to manager FNX mine pool contract, add miner balance when user has bought some options. 
     * @param account user's account.
     * @param amount user's pay for buying options, priced in USD.
     */ 
    function addMinerBalance(address account,uint256 amount) public onlyOwner{
        if (amount == 0){
            timeLimitWhiteList[account] = false;
        }else{
            timeLimitWhiteList[account] = true;
        }
        //_FnxMinePool.addMinerBalance(account,amount);
    }
    function setTransferTimeLimitation(address from,address recipient) internal {
        if (!timeLimitWhiteList[from]){
            setItemTimeLimitation(uint256(recipient));
        }
    }
    /**
     * dev Burn user's locked balance, when user redeem collateral. 
     * param account user's account.
     * param amount amount of burned FPT.
 
    function burnLocked(address account, uint256 amount) public onlyManager{
        require(latestTransferIn[account]+timeLimited<now,"FPT coin locked time is not expired!");
        uint256 lockedAmount = lockedBalances[account];
        require(amount<=lockedAmount,"burnLocked: balance is insufficient");
        if(lockedAmount>0){
            uint256 lockedWorth = lockedTotalWorth[account];
            if (amount == lockedAmount){
                _subLockBalance(account,lockedAmount,lockedWorth);
            }else{
                uint256 burnWorth = amount*lockedWorth/lockedAmount;
                _subLockBalance(account,amount,burnWorth);
            }
        }
    }
     */
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
        //require(address(_FnxMinePool) != address(0),"FnxMinePool is not set");
        //_FnxMinePool.transferMinerCoin(msg.sender,recipient,amount);
        setTransferTimeLimitation(msg.sender,recipient);
        return SharedCoin.transfer(recipient,amount);
    }
    /**
     * @dev Move sender's FPT to 'recipient' balance, a interface in ERC20. 
     * @param sender sender's account.
     * @param recipient recipient's account.
     * @param amount amount of FPT.
     */ 
    function transferFrom(address sender, address recipient, uint256 amount)public returns (bool){
        //require(address(_FnxMinePool) != address(0),"FnxMinePool is not set");
        //_FnxMinePool.transferMinerCoin(sender,recipient,amount);
        setTransferTimeLimitation(sender,recipient);
        return SharedCoin.transferFrom(sender,recipient,amount);
    }
    /**
     * @dev burn user's FPT when user redeem FPTCoin. 
     * @param account user's account.
     * @param amount amount of FPT.
     */ 
    function burn(address account, uint256 amount) public onlyManager OutLimitation(uint256(account)) {
        //require(address(_FnxMinePool) != address(0),"FnxMinePool is not set");
        //_FnxMinePool.burnMinerCoin(account,amount);
        SharedCoin._burn(account,amount);
    }
    /**
     * @dev mint user's FPT when user add collateral. 
     * @param account user's account.
     * @param amount amount of FPT.
     */ 
    function mint(address account, uint256 amount) public onlyManager {
        //require(address(_FnxMinePool) != address(0),"FnxMinePool is not set");
        //_FnxMinePool.mintMinerCoin(account,amount);
        setTransferTimeLimitation(address(0),account);
        SharedCoin._mint(account,amount);
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
    function redeemLockedCollateral(address account,uint256 tokenAmount,uint256 leftCollateral)public onlyManager OutLimitation(uint256(account)) returns (uint256,uint256){
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
