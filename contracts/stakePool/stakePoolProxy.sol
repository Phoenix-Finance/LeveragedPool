pragma solidity =0.5.16;
import "../Proxy/newBaseProxy.sol";
import "../FPTCoin/FPTProxy.sol";
contract stakePoolProxy is newBaseProxy {
    constructor (address implementation_,address _poolToken,address FPTimple_,string memory tokenName,uint64 interestrate)
        newBaseProxy(implementation_,1) public{
        FPTProxy fpt = new FPTProxy(FPTimple_,tokenName);
        fpt.setManager(address(this));
        (bool success,) = implementation_.delegatecall(abi.encodeWithSignature(
                "setPoolInfo(address,address,uint64)",
                address(fpt),
                _poolToken,
                interestrate));
        require(success);
    }
    function getFPTCoinAddress() public view returns(address){
        delegateToViewAndReturn();
    }
    function setFPTCoinAddress(address /*FPTCoinAddr*/)public{
        delegateAndReturn();
    }
    function setPoolInfo(address /*fptToken*/,address /*poolToken*/,uint64 /*interestrate*/) public{
        delegateAndReturn();
    }
    function poolToken()public view returns (address){
        delegateToViewAndReturn();
    }
    function interestRate()public view returns (uint64){
        delegateToViewAndReturn();
    }
    function setInterestRate(uint64 /*interestrate*/) public{
        delegateAndReturn();
    }
    function totalSupply()public view returns (uint256){
        delegateToViewAndReturn();
    }
    function poolBalance()public view returns (uint256){
        delegateToViewAndReturn();
    }
    function borrow(uint256 /*amount*/) public returns(uint256){
        delegateAndReturn();
    }
    function borrowAndInterest(uint256 /*amount*/) public returns(uint256){
        delegateAndReturn();
    }
    function repay(uint256 /*amount*/) public payable{
        delegateAndReturn();
    }
    function repayAndInterest(uint256 /*amount*/) public payable returns(uint256){
        delegateAndReturn();
    }
    function FPTTotalSuply()public view returns (uint256){
        delegateToViewAndReturn();
    }
    function tokenNetworth() public view returns (uint256){
        delegateToViewAndReturn();
    }
    function stake(uint256 /*amount*/) public payable{
        delegateAndReturn();
    }
    function unstake(uint256 /*amount*/) public{
        delegateAndReturn();
    }
}