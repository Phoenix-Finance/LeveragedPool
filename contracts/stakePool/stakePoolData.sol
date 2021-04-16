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
}