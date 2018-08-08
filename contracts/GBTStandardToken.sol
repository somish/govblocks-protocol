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

pragma solidity 0.4.24;

import "./LockableToken.sol";
import "./imports/openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "./imports/openzeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol";

contract GBTStandardToken is LockableToken, MintableToken, DetailedERC20 {
    uint public tokenPrice;

    /// @dev constructor
    constructor() public {
        owner = msg.sender;
        totalSupply_ = 10 ** 20;
        balances[address(msg.sender)] = totalSupply_;
        name = "GovBlocks Standard Token";
        symbol = "GBT";
        decimals = 18;
        tokenPrice = 10 ** 15;
    }

    /// @dev payable function to buy tokens. send ETH to get GBT
    function buyToken() public payable returns(uint actualAmount) {
        actualAmount = SafeMath.mul(SafeMath.div(msg.value, tokenPrice), uint256(10) ** decimals);
        mint(msg.sender, actualAmount);
    } 

    /*/// @dev function to change Token price
    function changeTokenPrice(uint _price) public onlyOwner {
        tokenPrice = _price;
    }*/
}