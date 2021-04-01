pragma solidity =0.5.16;
import "../Proxy/newBaseProxy.sol";
contract rebaseTokenProxy is newBaseProxy {
    constructor (address implementation_,string memory tokenName) newBaseProxy(implementation_,1) public{
        (bool success,) = implementation_.delegatecall(abi.encodeWithSignature(
            "setTokenName(string)",tokenName));
        require(success);
    }
    function name() external view returns (string memory){
        delegateToViewAndReturn();
    }
    function symbol() external view returns (string memory){
        delegateToViewAndReturn();
    }
    function decimals() external view returns (uint8){
        delegateToViewAndReturn();
    }
    function totalSupply() external view returns (uint256){
        delegateToViewAndReturn();
    }
    function calRebaseRatio(uint256 /*newTotalSupply*/) public {
        delegateAndReturn();
    }
    function balanceOf(address /*account*/) external view returns (uint256){
        delegateToViewAndReturn();
    }
    function transfer(address /*recipient*/, uint256 /*amount*/) public returns (bool){
        delegateAndReturn();
    }
    function allowance(address /*owner*/, address /*spender*/) public view returns (uint256) {
        delegateToViewAndReturn();
    }
    function approve(address /*spender*/, uint256 /*amount*/) public returns (bool){
        delegateAndReturn();
    }
    function transferFrom(address /*sender*/, address /*recipient*/, uint256 /*amount*/)
        public
        returns (bool){
        delegateAndReturn();
    }
    function increaseAllowance(address /*spender*/, uint256 /*addedValue*/)
    public
    returns (bool){
        delegateAndReturn();
    }
    function decreaseAllowance(address /*spender*/, uint256 /*subtractedValue*/)
    public
    returns (bool) {
        delegateAndReturn();
    }
    function burn(address /*account*/,uint256 /*amount*/) public returns (bool){
        delegateAndReturn();
    }
    function mint(address /*account*/,uint256 /*amount*/) public returns (bool){
        delegateAndReturn();
    }
}