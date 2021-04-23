pragma solidity =0.5.16;
import './Ownable.sol';
import './initializable.sol';
contract versionUpdater is Ownable,initializable {
    uint256 constant public implementationVersion = 0;
    function initialize() public initializer versionUpdate(implementationVersion){
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
}