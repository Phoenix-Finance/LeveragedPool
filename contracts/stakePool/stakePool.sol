pragma solidity =0.5.16;
import "../ERC20/safeErc20.sol";
import "../FPTCoin/IFPTCoin.sol";
import "../modules/SafeMath.sol";
contract stakePool is ImportIFPTCoin{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    uint256 constant internal calDecimal = 1e8; 
    uint256 internal _totalSupply;
    address internal _poolToken;
    uint64 internal _interestRate;
    mapping (address => uint256) internal loanAccountMap;
    event DebugEvent(address indexed from,uint256 value1,uint256 value2);
    function initialize() public{
    }
    function setPoolInfo(address fptToken,address stakeToken,uint64 interestrate) public{
        _FPTCoin = IFPTCoin(fptToken);
        _poolToken = stakeToken;
        _interestRate = interestrate;
    }

    function poolToken()public view returns (address){
        return _poolToken;
    }
    function interestRate()public view returns (uint64){
        return _interestRate;
    }
    function setInterestRate(uint64 interestrate) public{
        _interestRate = interestrate;
    }
    function totalSupply()public view returns (uint256){
        return _totalSupply;
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
    function borrow(uint256 amount) public returns(uint256) {
        loanAccountMap[msg.sender] = loanAccountMap[msg.sender].add(amount);
        uint256 _loan = amount.mul((calDecimal-_interestRate))/calDecimal;
        _totalSupply = _totalSupply.add(amount-_loan);
        _redeem(msg.sender,_poolToken,_loan);
        return _loan;
    }
    function borrowAndInterest(uint256 amount) public returns(uint256){
        loanAccountMap[msg.sender] = loanAccountMap[msg.sender].add(amount);
        uint256 _loan = amount.sub(loanAccountMap[msg.sender].mul(_interestRate)/calDecimal);
        _totalSupply = _totalSupply.add(amount-_loan);

        _redeem(msg.sender,_poolToken,_loan);
        return _loan;
    }
    function repay(uint256 amount) public payable {
        amount = getPayableAmount(_poolToken,amount);
        loanAccountMap[msg.sender] = loanAccountMap[msg.sender].sub(amount);
    }
    function repayAndInterest(uint256 amount) public payable returns(uint256){
        amount = getPayableAmount(_poolToken,amount);
        uint256 repayAmount = amount.mul(calDecimal).sub(loanAccountMap[msg.sender].mul(_interestRate))/(calDecimal-_interestRate);
        if (repayAmount > amount){
            repayAmount = amount;
        }
        loanAccountMap[msg.sender] = loanAccountMap[msg.sender].sub(repayAmount);
        emit DebugEvent(msg.sender,repayAmount,amount);
        _totalSupply = _totalSupply.add(amount-repayAmount);
        return repayAmount;
    }
    function FPTTotalSuply()public view returns (uint256){
        return _FPTCoin.totalSupply();
    }
    function tokenNetworth() public view returns (uint256){
        uint256 tokenNum = FPTTotalSuply();
        return (tokenNum > 0 ) ? _totalSupply.mul(calDecimal)/tokenNum : calDecimal;
    }
    function stake(uint256 amount) public payable {
        amount = getPayableAmount(_poolToken,amount);
        require(amount > 0, 'stake amount is zero');
        uint256 netWorth = tokenNetworth();
        uint256 mintAmount = amount.mul(calDecimal)/netWorth;
        _totalSupply = _totalSupply.add(amount);
        _FPTCoin.mint(msg.sender,mintAmount);
    }
    function unstake(uint256 amount) public {
        require(amount > 0, 'unstake amount is zero');
        uint256 netWorth = tokenNetworth();
        uint256 redeemAmount = netWorth.mul(amount)/calDecimal;
        require(redeemAmount<=poolBalance(),"Available pool liquidity is unsufficient");
        _FPTCoin.burn(msg.sender,amount);
        _totalSupply = _totalSupply.sub(redeemAmount);
        _redeem(msg.sender,_poolToken,redeemAmount);
    }
    function getPayableAmount(address stakeCoin,uint256 amount) internal returns (uint256) {
        if (stakeCoin == address(0)){
            amount = msg.value;
        }else if (amount > 0){
            IERC20 oToken = IERC20(stakeCoin);
            uint256 preBalance = oToken.balanceOf(address(this));
            oToken.safeTransferFrom(msg.sender, address(this), amount);
            uint256 afterBalance = oToken.balanceOf(address(this));
            require(afterBalance-preBalance==amount,"input token transfer error!");
        }
        return amount;
    }
        /**
     * @dev An auxiliary foundation which transter amount stake coins to recieptor.
     * @param recieptor recieptor recieptor's account.
     * @param stakeCoin stake address
     * @param amount redeem amount.
     */
    function _redeem(address payable recieptor,address stakeCoin,uint256 amount) internal{
        if (stakeCoin == address(0)){
            recieptor.transfer(amount);
        }else{
            IERC20 token = IERC20(stakeCoin);
            uint256 preBalance = token.balanceOf(address(this));
            token.safeTransfer(recieptor,amount);
//            token.transfer(recieptor,amount);
            uint256 afterBalance = token.balanceOf(address(this));
            require(preBalance - afterBalance == amount,"settlement token transfer error!");
        }
    }
}