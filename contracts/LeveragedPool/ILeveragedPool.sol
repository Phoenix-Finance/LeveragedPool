pragma solidity =0.5.16;
interface ILeveragedPool {
    function leverageTokens() external view returns (address,address);
    function setOracleAddress(address oracle)external;
    function setFeeAddress(address payable addrFee) external;
    function setLeverageFee(uint64 buyFee,uint64 sellFee,uint64 rebalanceFee) external;
    function setHedgeFee(uint64 buyFee,uint64 sellFee,uint64 rebalanceFee) external;
    function setLeveragePoolInfo(address rebaseImplement,uint256 rebaseVersion,address leveragePool,address hedgePool,address oracle,address swapRouter,
        uint256 leverageRatio,uint128 leverageRebaseWorth,uint128 hedgeRebaseWorth,string calldata baseCoinName) external;
    function rebalance(bool bRebalanceWorth) external;
}
