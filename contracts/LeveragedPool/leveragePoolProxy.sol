pragma solidity =0.5.16;
import "../Proxy/newBaseProxy.sol";
contract leveragePoolProxy is newBaseProxy {
    constructor (address implementation_) newBaseProxy(implementation_,1) public{
    }
    function() external payable {
        
    }
    function setFeeAddress(address payable /*addrFee*/) public {
        delegateAndReturn();
    }
    function leverageTokens() public view returns (address,address){
        delegateToViewAndReturn();
    }
    function setLeverageFee(uint64 /*buyFee*/,uint64 /*sellFee*/,uint64 /*rebalanceFee*/) public{
        delegateAndReturn();
    }
    function setHedgeFee(uint64 /*buyFee*/,uint64 /*sellFee*/,uint64 /*rebalanceFee*/) public{
        delegateAndReturn();
    }
    function getLeverageFee()public view returns(uint64,uint64,uint64){
        delegateToViewAndReturn();
    }
    function getHedgeFee()public view returns(uint64,uint64,uint64){
        delegateToViewAndReturn();
    }
    function setLeveragePoolInfo(address /*rebaseImplement*/,address /*leveragePool*/,address /*hedgePool*/,
        address /*oracle*/,address /*swapRouter*/,
        uint256 /*leverageRatio*/,uint256 /*leverageRebaseWorth*/,uint256 /*hedgeRebaseWorth*/) public {
        delegateAndReturn();
    }
    function getDefaultLeverageRatio()public view returns (uint256){
        delegateToViewAndReturn();
    }
    function leverageRatio()public view returns (uint256){
        delegateToViewAndReturn();
    }
    function hedgeRatio()internal view returns (uint256){
        delegateToViewAndReturn();
    }
    function getLeverageTotalworth() public view returns(uint256){
        delegateToViewAndReturn();
    }
    function getHedgeTotalworth() public view returns(uint256){
        delegateToViewAndReturn();
    }
    function getLeverageTokenNetworth() public view returns(uint256){
        delegateToViewAndReturn();
    }
    function getHedgeTokenNetworth() public view returns(uint256){
        delegateToViewAndReturn();
    }
    function buyLeverage(uint256 /*amount*/,uint256 /*minAmount*/,bytes memory /*data*/) public payable{
        delegateAndReturn();
    }
    function buyHedge(uint256 /*amount*/,uint256 /*minAmount*/,bytes memory /*data*/) public payable{
        delegateAndReturn();
    }
    function buyLeverage2(uint256 /*amount*/,uint256 /*minAmount*/,bytes memory /*data*/) public payable{
        delegateAndReturn();
    }
    function buyHedge2(uint256 /*amount*/,uint256 /*minAmount*/,bytes memory /*data*/) public payable{
        delegateAndReturn();
    }
    function sellLeverage(uint256 /*amount*/,uint256 /*minAmount*/,bytes memory /*data*/) public payable{
        delegateAndReturn();
    }
    function sellHedge(uint256 /*amount*/,uint256 /*minAmount*/,bytes memory /*data*/) public payable{
        delegateAndReturn();
    }
    function rebalance() public {
        delegateAndReturn();
    }
}