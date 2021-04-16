pragma solidity =0.5.16;
import "../modules/versionUpdater.sol";
import "../interface/IFNXOracle.sol";
import "../rebaseToken/IRebaseToken.sol";
import "../uniswap/IUniswapV2Router02.sol";
import "../stakePool/IStakePool.sol";
import "../modules/AddressPermission.sol";
contract leveragedData is ImportOracle,versionUpdater,AddressPermission{
    uint256 constant internal calDecimal = 1e18; 
    uint256 constant internal feeDecimal = 1e8; 
    struct leverageInfo {
        uint8 id;
        bool bRebase;
        address token;
        IStakePool stakePool;
        uint256 leverageRate;
        uint256 rebalanceWorth;
        uint256 defaultRebalanceWorth;
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
    uint256 internal liquidateThreshold;
    address payable internal feeAddress;

    event DebugEvent(address indexed from,uint256 value1,uint256 value2);
}