pragma solidity =0.5.16;
interface IStakePool {
    function modifyPermission(address addAddress,uint256 permission)external;
    function poolToken()external view returns (address);
    function loan(address account) external view returns(uint256);
    function PPTCoin()external view returns (address);
    function interestRate()external view returns (uint64);
    function setInterestRate(uint64 interestrate)external;
    function interestInflation(uint64 inflation)external;
    function poolBalance() external view returns (uint256);
    function borrowLimit(address account)external view returns (uint256);
    function borrow(uint256 amount) external returns(uint256);
    function borrowAndInterest(uint256 amount) external;
    function repay(uint256 amount,bool bAll) external payable;
    function repayAndInterest(uint256 amount) external payable;
    function setPoolInfo(address PPTToken,address stakeToken,uint64 interestrate) external;
}
