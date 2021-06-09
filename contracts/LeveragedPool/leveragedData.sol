pragma solidity =0.5.16;
import "../proxyModules/versionUpdater.sol";
import "../interface/IPHXOracle.sol";
import "../rebaseToken/IRebaseToken.sol";
import "../stakePool/IStakePool.sol";
import "../modules/ReentrancyGuard.sol";
import "../proxyModules/proxyOperator.sol";
import "../proxyModules/halt.sol";
contract leveragedData is ImportOracle,versionUpdater,proxyOperator,ReentrancyGuard,Halt{
    uint256 constant internal currentVersion = 2;
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
    event Swap(address indexed fromCoin,address indexed toCoin,uint256 fromValue,uint256 toValue);
    event Redeem(address indexed recieptor,address indexed Coin,uint256 amount);
    event BuyLeverage(address indexed from,address indexed Coin,uint256 amount,uint256 leverageAmount);
    event BuyHedge(address indexed from,address indexed Coin,uint256 amount,uint256 hedgeAmount);
    event SellLeverage(address indexed from,address indexed Coin,uint256 leverageAmount,uint256 amount);
    event SellHedge(address indexed from,address indexed Coin,uint256 hedgeAmount,uint256 amount);
    event Rebalance(address indexed from,address indexed token,uint256 buyAount,uint256 sellAmount,bool bRebase);
    event Liquidate(address indexed from,address indexed token,uint256 loan,uint256 fee,uint256 leftAmount);
}