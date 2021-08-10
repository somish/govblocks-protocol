// SPDX-License-Identifier: GNU

/* Copyright (C) 2017 GovBlocks.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.8.0;

import "./Master.sol";


abstract contract Upgradeable {

    Master public ms;

    function updateDependencyAddresses() public virtual; //To be implemented by every contract depending on its needs

    function changeMasterAddress(address _masterAddress) public {
        if (address(ms) == address(0))
            ms = Master(_masterAddress);
        else {
            require(msg.sender == address(ms));
            ms = Master(_masterAddress);
        }
    }
}