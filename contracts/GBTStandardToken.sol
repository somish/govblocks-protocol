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

import "./external/lockable-token/LockableToken.sol";
import "./external/openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol";


contract GBTStandardToken is MintableToken, LockableToken {
    uint public tokenPrice;

    /// @dev constructor
    constructor() LockableToken(10 ** 20, "GovBlocks Standard Token", "GBT", 18) {
        tokenPrice = 10 ** 15;
    }

    /// @dev payable function to buy tokens. send ETH to get GBT
    function buyToken() public payable returns(uint actualAmount) {
        actualAmount = (msg.value*uint256(10) ** decimals)/tokenPrice;
        _mint(msg.sender, actualAmount);
        emit Mint(msg.sender, actualAmount);
    } 
}