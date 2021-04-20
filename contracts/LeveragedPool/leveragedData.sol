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
    uint256 internal rebasePrice;
    uint256 internal currentPrice;
    uint256 internal buyFee;
    uint256 internal sellFee;
    uint256 internal rebalanceFee;
    uint256 internal defaultLeverageRatio;
    uint256 internal defaultRebalanceWorth;
    uint256 internal liquidateThreshold;
    address payable internal feeAddress;

    event DebugEvent(address indexed from,uint256 value1,uint256 value2);
    event DebugEvent1(address indexed from,int256 value1,int256 value2);
    event Swap(address indexed fromCoin,address indexed toCoin,uint256 fromValue,uint256 toValue);
    event Redeem(address indexed recieptor,address indexed Coin,uint256 amount);
}