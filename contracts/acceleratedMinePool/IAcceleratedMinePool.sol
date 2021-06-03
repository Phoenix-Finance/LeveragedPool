pragma solidity =0.5.16;
interface IAcceleratedMinePool {
    function changeAcceleratedInfo(address account,uint256 oldAcceleratedStake,uint64 oldAcceleratedPeriod) external;
}