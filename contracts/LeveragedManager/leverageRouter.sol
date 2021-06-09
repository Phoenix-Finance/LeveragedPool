pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
import "../modules/SafeMath.sol";
import "./leverageRouterData.sol";
/**
 * @title leverage contract Router.
 * @dev A smart-contract which manage leverage smart-contract's and peripheries.
 *
 */
contract leverageRouter is leverageRouterData{
    using SafeMath for uint256;
}