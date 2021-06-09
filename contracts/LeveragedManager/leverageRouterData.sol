pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
import "../proxyModules/versionUpdater.sol";
import "./ILeverageFactory.sol";
/**
 * @title leverage contract Router.
 * @dev A smart-contract which manage leverage smart-contract's and peripheries.
 *
 */
contract leverageRouterData is versionUpdater {
    uint256 constant internal currentVersion = 1;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }
    ILeverageFactory public factory;
}