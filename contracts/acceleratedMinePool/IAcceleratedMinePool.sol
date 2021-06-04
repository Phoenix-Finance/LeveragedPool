pragma solidity =0.5.16;
interface IAcceleratedMinePool {
    function changeAcceleratedInfo(address account,uint256 oldAcceleratedStake,uint64 oldAcceleratedPeriod) external;
    function transferFPTCoin(address account,address recieptor) external;
    function changeFPTStake(address account) external;
}