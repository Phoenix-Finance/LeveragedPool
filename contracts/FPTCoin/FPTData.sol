pragma solidity =0.5.16;
import "../modules/versionUpdater.sol";
import "../ERC20/Erc20Data.sol";
import "../modules/timeLimitation.sol";
contract FPTData is Erc20Data,timeLimitation,versionUpdater{
    /**
    * @dev lock mechanism is used when user redeem collateral and left collateral is insufficient.
    * _totalLockedWorth stores total locked worth, priced in USD.
    * lockedBalances stores user's locked FPTCoin.
    * lockedTotalWorth stores user's locked worth, priced in USD. For locked FPTCoin's net worth is constant when It was locked.
    */
    uint256 constant internal currentVersion = 0;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }
    uint256 internal _totalLockedWorth;
    mapping (address => uint256) internal lockedBalances;
    mapping (address => uint256) internal lockedTotalWorth;
    /**
     * @dev Emitted when `owner` locked  `amount` FPT, which net worth is  `worth` in USD. 
     */
    event AddLocked(address indexed owner, uint256 amount,uint256 worth);
    /**
     * @dev Emitted when `owner` burned locked  `amount` FPT, which net worth is  `worth` in USD. 
     */
    event BurnLocked(address indexed owner, uint256 amount,uint256 worth);

}