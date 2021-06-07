pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
import "../modules/Operator.sol";
interface IPPTCoin {
    function setTimeLimitation(uint256 _limitation) external;
    function changeTokenName(string calldata _name, string calldata _symbol,uint8 _decimals)external;
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}
contract ImportIPPTCoin is Operator{
    IPPTCoin internal _PPTCoin;
    function getPPTCoinAddress() public view returns(address){
        return address(_PPTCoin);
    }
    function setPPTCoinAddress(address PPTCoinAddr)public onlyOwner{
        _PPTCoin = IPPTCoin(PPTCoinAddr);
    }
}