pragma solidity =0.5.16;
import "../modules/Ownable.sol";
import "../ERC20/safeErc20.sol";
import "../modules/versionUpdater.sol";
import "../modules/AddressPermission.sol";
contract rebaseTokenData is Ownable,versionUpdater,AddressPermission{
    uint256 constant allowRebalance = 1;
    uint256 constant allowNewErc20 = 1<<1;
    uint256 constant allowMint = 1<<2;
    uint256 constant allowBurn = 1<<3;
    string public name;
    string public symbol;
    IERC20 public leftToken;
    uint8 public decimals = 18;
    uint256 constant rebaseDecimal = 1e18;
    mapping (address => mapping (address => uint256)) internal _allowances;    
    struct Erc20Info {
        mapping (address => uint256) balances;
        uint256 _totalSupply;
        uint256 rebaseRatio;
        uint256 leftAmount;
    }
    Erc20Info[] internal Erc20InfoList;
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}