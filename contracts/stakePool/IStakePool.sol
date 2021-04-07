pragma solidity =0.5.16;
interface IStakePool {
    function poolToken()external view returns (address);
    function loan(address account) external view returns(uint256);
    function FPTCoin()external view returns (address);
    function interestRate()external view returns (uint64);
    function poolBalance() external view returns (uint256);
    function borrow(uint256 amount) external returns(uint256);
    function borrowAndInterest(uint256 amount) external returns(uint256);
    function repay(uint256 amount) external payable;
    function repayAndInterest(uint256 amount) external payable returns(uint256);
    function setPoolInfo(address fptToken,address stakeToken,uint64 interestrate) external;
}
