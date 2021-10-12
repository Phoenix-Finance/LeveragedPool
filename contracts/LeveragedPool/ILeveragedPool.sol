pragma solidity =0.5.16;
interface ILeveragedPool {
    function leverageTokens() external view returns (address,address);
    function setUniswapAddress(address _uniswap)external;
    function setOracleAddress(address oracle)external;
    function setFeeAddress(address payable addrFee) external;
    function setLeverageFee(uint256 _buyFee,uint256 _sellFee,uint256 _rebalanceFee) external;
    function setLeveragePoolInfo(address payable _feeAddress,address leveragePool,address hedgePool,
            address oracle,address swapRouter,address swaplib,address rebaseTokenA,address rebaseTokenB,
            uint256 fees,uint256 _threshold,uint256 rebaseWorth)external;
    function rebalance() external;
    function getLeverageInfo() external view returns (address,address,address,uint256,uint256);
    function getHedgeInfo() external view returns (address,address,address,uint256,uint256);
    function buyPrices() external view returns(uint256,uint256);
    function getUnderlyingPriceView() external view returns(uint256[2]memory);
    function getTokenNetworths() external view returns(uint256,uint256);
    function swapRouter() external view returns(address);
    function buyFee() external view returns(uint256);
    function sellFee() external view returns(uint256);
    function getSwapRoutingPath(address token0,address token1) external view returns (address[] memory);
}

