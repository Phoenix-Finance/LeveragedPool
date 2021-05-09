pragma solidity =0.5.16;
import "../modules/Operator.sol";
import './initializable.sol';
contract versionUpdater is Operator,initializable {
    function implementationVersion() public pure returns (uint256);
    uint256 lastVersion;
    function initialize() public initializer versionUpdate {
        _operators[0] = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
        _operators[1] = tx.origin;
        emit OriginTransferred(address(0), tx.origin);
    }
    modifier versionUpdate(){
        uint256 version = implementationVersion();
        require(version >= lastVersion,"New version implementation is already updated!");
        lastVersion = version;
        _;
    }
}