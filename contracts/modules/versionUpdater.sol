pragma solidity =0.5.16;
import './Ownable.sol';
import './initializable.sol';
contract versionUpdater is Ownable,initializable {
    uint256 constant public implementationVersion = 0;
    mapping(uint256 => bool) private versionUpdated;
    function initialize() public initializer versionUpdate(){
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    modifier versionUpdate(){
        require(!versionUpdated[implementationVersion],"New version implementation is already updated!");
        versionUpdated[implementationVersion] = true;
        _;
    }
}