pragma solidity =0.5.16;
import './Ownable.sol';
contract versionUpdater is Ownable {
    mapping(uint256 => bool) private versionUpdated;
    function initialize(uint256 _version) public versionUpdate(_version){
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    modifier versionUpdate(uint256 _version){
        require(!versionUpdated[_version],"New version implementation is already updated!");
        versionUpdated[_version] = true;
        _;
    }
}