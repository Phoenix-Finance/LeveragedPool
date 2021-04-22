pragma solidity =0.5.16;
import "../modules/versionUpdater.sol";
import "../interface/IFNXOracle.sol";
import "../rebaseToken/IRebaseToken.sol";
import "../uniswap/IUniswapV2Router02.sol";
import "../stakePool/IStakePool.sol";
import "../modules/AddressPermission.sol";
import "../modules/ReentrancyGuard.sol";
contract leveragedData is ImportOracle,versionUpdater,ReentrancyGuard,AddressPermission{
    uint256 constant internal calDecimal = 1e18; 
    uint256 constant internal feeDecimal = 1e8; 
    struct leverageInfo {
        uint8 id;
        bool bRebase;
        address token;
        IStakePool stakePool;
        uint256 leverageRate;
        uint256 rebalanceWorth;
        IRebaseToken leverageToken;
    }
    leverageInfo internal leverageCoin;
    leverageInfo internal hedgeCoin;
    IUniswapV2Router02 internal IUniswap;
    uint256[2] public rebasePrices;
    uint256[2] internal currentPrice;
    uint256 public buyFee;
    uint256 public sellFee;
    uint256 public rebalanceFee;
    uint256 public defaultLeverageRatio;
    uint256 public defaultRebalanceWorth;
    uint256 public rebaseThreshold;
    uint256 public liquidateThreshold;
    address payable public feeAddress;

    event Swap(address indexed fromCoin,address indexed toCoin,uint256 fromValue,uint256 toValue);
    event Redeem(address indexed recieptor,address indexed Coin,uint256 amount);
}