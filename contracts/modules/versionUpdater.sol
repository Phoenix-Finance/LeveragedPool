pragma solidity =0.5.16;
import './Ownable.sol';
import './initializable.sol';
contract versionUpdater is Ownable,initializable {
    function implementationVersion() public pure returns (uint256);
    mapping(uint256 => bool) private versionUpdated;
    function initialize() public initializer versionUpdate {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    modifier versionUpdate(){
        uint256 version = implementationVersion();
        require(!versionUpdated[version],"New version implementation is already updated!");
        versionUpdated[version] = true;
        _;
    }
}