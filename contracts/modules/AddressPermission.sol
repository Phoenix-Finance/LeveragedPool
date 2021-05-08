pragma solidity >=0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * FinNexus
 * Copyright (C) 2020 FinNexus Options Protocol
 */
import './Operator.sol';

contract AddressPermission is Operator {
    mapping(address => uint256) public addressPermission;
    function modifyPermission(address addAddress,uint256 permission)public onlyOperator2(0,1){
        addressPermission[addAddress] = permission;
    }
    function checkAddressPermission(address tmpAddress,uint256 state) public view returns (bool){
        return  (addressPermission[tmpAddress]&state) == state;
    }
    modifier addressPermissionAllowed(address tmpAddress,uint256 state){
        require(checkAddressPermission(tmpAddress,state) , "Input address is not allowed");
        _;
    }
}