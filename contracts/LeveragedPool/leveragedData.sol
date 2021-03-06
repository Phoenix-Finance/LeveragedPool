pragma solidity =0.5.16;
import "../PhoenixModules/proxyModules/versionUpdater.sol";
import "../PhoenixModules/interface/IPHXOracle.sol";
import "../rebaseToken/IRebaseToken.sol";
import "../stakePool/IStakePool.sol";
import "../PhoenixModules/modules/ReentrancyGuard.sol";
import "../PhoenixModules/proxyModules/proxyOperator.sol";
contract leveragedData is ImportOracle,versionUpdater,proxyOperator,ReentrancyGuard{
    uint256 constant internal currentVersion = 7;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }
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
    address public swapRouter;
    address public phxSwapLib;
    uint256[2] public rebalancePrices;
    uint256[2] internal currentPrice;
    uint256 public buyFee;
    uint256 public sellFee;
    uint256 public rebalanceFee;
    uint256 public defaultLeverageRatio;
    uint256 public defaultRebalanceWorth;
    uint256 public rebaseThreshold;
    uint256 public liquidateThreshold;

    address payable public feeAddress;
    uint256 public rebalanceTol;

    mapping(address=>mapping(address=>address[])) internal swapRoutingPath;

    bool internal halted; 

    
    event Swap(address indexed fromCoin,address indexed toCoin,uint256 fromValue,uint256 toValue);
    event Redeem(address indexed recieptor,address indexed Coin,uint256 amount);
    event BuyLeverage(address indexed from,address indexed Coin,uint256 payAmount,uint256 leverageAmount,uint256 tokenPrice);
    event BuyHedge(address indexed from,address indexed Coin,uint256 payAmount,uint256 hedgeAmount,uint256 tokenPrice);
    event SellLeverage(address indexed from,address indexed Coin,uint256 leverageAmount,uint256 amount,uint256 tokenPrice);
    event SellHedge(address indexed from,address indexed Coin,uint256 hedgeAmount,uint256 amount,uint256 tokenPrice);
    event Rebalance(address indexed from,address indexed token,uint256 buyAount,uint256 sellAmount);
    event Liquidate(address indexed from,address indexed token,uint256 loan,uint256 fee,uint256 leftAmount);
}