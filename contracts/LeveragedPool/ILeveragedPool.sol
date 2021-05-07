pragma solidity =0.5.16;
interface ILeveragedPool {
    function modifyPermission(address addAddress,uint256 permission)external;
    function leverageTokens() external view returns (address,address);
    function setUniswapAddress(address _uniswap)external;
    function setOracleAddress(address oracle)external;
    function setFeeAddress(address payable addrFee) external;
    function setLeverageFee(uint64 buyFee,uint64 sellFee,uint64 rebalanceFee) external;
    function setLeveragePoolInfo(address payable _feeAddress,address leveragePool,address hedgePool,
            address oracle,address swapRouter,address rebaseTokenA,address rebaseTokenB,
            uint256 fees,uint256 _threshold,uint256 rebaseWorth)external;
    function rebalance() external;
}
