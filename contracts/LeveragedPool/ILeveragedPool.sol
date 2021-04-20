pragma solidity =0.5.16;
interface ILeveragedPool {
    function leverageTokens() external view returns (address,address);
    function setOracleAddress(address oracle)external;
    function setFeeAddress(address payable addrFee) external;
    function setLeverageFee(uint64 buyFee,uint64 sellFee,uint64 rebalanceFee) external;
    function setHedgeFee(uint64 buyFee,uint64 sellFee,uint64 rebalanceFee) external;
    function setLeveragePoolAddress(address payable _feeAddress,address leveragePool,address hedgePool,address oracle,address swapRouter)external;
    function setLeveragePoolInfo(address rebaseImplement,uint256 rebaseVersion,
        uint256 fees,uint256 _liquidateThreshold,uint256 rebaseWorth,string calldata leverageTokenName,string calldata hedgeTokenName)  external;
    function rebalance() external;
}
