// SPDX-License-Identifier: GNU

/* Copyright (C) 2021

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

import "./external/govern/Governed.sol";
import "./Master.sol";

abstract contract IERC20 {

  function transfer(address _to, uint256 _value) public virtual returns (bool);
}

contract DemoDApp is Governed {

  IERC20 dappToken;

    function sendFunds(address _receiverAddress, uint256 _amount) public onlyAuthorizedToGovern {
      dappToken.transfer(_receiverAddress,_amount);
    }

    /// @dev To Initiate default settings whenever the contract is regenerated!
    function updateDependencyAddresses() public { //solhint-disable-line
      Master ms = Master(masterAddress);
      dappToken = IERC20(ms.dAppToken());

    }

    /// @dev just to adhere to GovBlockss' Upgradeable interface
    function changeMasterAddress(address _masterAddress) public { //solhint-disable-line
        if (masterAddress == address(0)) {
            masterAddress = _masterAddress;
        } else {
            require(msg.sender == masterAddress);
            masterAddress = _masterAddress;
        }
    }
}