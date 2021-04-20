pragma solidity =0.5.16;
import "../FPTCoin/IFPTCoin.sol";
import "../modules/versionUpdater.sol";
import "../modules/ReentrancyGuard.sol";
import "../modules/AddressPermission.sol";
contract stakePoolData is ImportIFPTCoin,versionUpdater,ReentrancyGuard,AddressPermission{
    uint256 constant allowBorrow = 1;
    uint256 constant allowRepay = 1<<1;
    uint256 constant internal calDecimal = 1e8; 
    uint256 internal _totalSupply;
    address internal _poolToken;
    uint64 internal _interestRate;
    mapping (address => uint256) internal loanAccountMap;
    event DebugEvent(address indexed from,uint256 value1,uint256 value2);
    event Borrow(address indexed from,address indexed token,uint256 loan,uint256 borrow);
    event Redeem(address indexed recieptor,address indexed Coin,uint256 amount);
    event Stake(address indexed from,address indexed token,uint256 amount,uint256 mintAmount);
    event Unstake(address indexed from,address indexed token,uint256 amount,uint256 burnAmount);
    event Repay(address indexed from,address indexed token,uint256 amount,uint256 leftLoan);
    event RepayAndInterest(address indexed from,address indexed token,uint256 amount,uint256 interest,uint256 leftLoan);
}