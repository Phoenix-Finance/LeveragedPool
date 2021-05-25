pragma solidity =0.5.16;
import "./proxyOwner.sol";
import './initializable.sol';
contract versionUpdater is proxyOwner,initializable {
    function implementationVersion() public pure returns (uint256);
    function initialize() public initializer versionUpdate {

    }
    modifier versionUpdate(){
        uint256 version = implementationVersion();
        require(version > version(),"New version implementation is already updated!");
        _;
    }
}