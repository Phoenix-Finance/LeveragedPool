pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
import "../PhoenixModules/proxyModules/versionUpdater.sol";
import "./ILeverageFactory.sol";

/**
 * @title leverage contract Router.
 * @dev A smart-contract which manage leverage smart-contract's and peripheries.
 *
 */
contract leverageDashboardData is versionUpdater {
    uint256 constant internal currentVersion = 1;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }
    ILeverageFactory public factory;
    uint256 constant internal feeDecimal = 1e8; 
    uint256 constant internal calDecimal = 1e18; 
}