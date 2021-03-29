pragma solidity =0.5.16;
interface IRebaseToken {
    function lockedBalanceOf(address account) external view returns (uint256);
    function lockedWorthOf(address account) external view returns (uint256);
    function getLockedBalance(address account) external view returns (uint256,uint256);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function addlockBalance(address account, uint256 amount,uint256 lockedWorth)external; 
    function getTotalLockedWorth() external view returns (uint256);
    function addMinerBalance(address account,uint256 amount) external;
    function redeemLockedCollateral(address account,uint256 tokenAmount,uint256 leftCollateral)external returns (uint256,uint256);
}
