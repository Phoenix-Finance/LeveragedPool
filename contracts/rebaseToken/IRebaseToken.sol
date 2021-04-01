pragma solidity =0.5.16;
interface IRebaseToken {
    function changeTokenName(string calldata _name, string calldata _symbol)external;
    function calRebaseRatio(uint256 newTotalSupply) external;
    function newErc20() external;
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}
