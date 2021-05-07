pragma solidity =0.5.16;
interface IRebaseToken {
    function setTimeLimitation(uint256 _limitation) external;
    function modifyPermission(address addAddress,uint256 permission)external;
    function changeTokenName(string calldata _name, string calldata _symbol,address token)external;
    function calRebaseRatio(uint256 newTotalSupply) external;
    function newErc20(uint256 leftAmount) external;
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}
