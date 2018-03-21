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
    
pragma solidity ^0.4.8;
import "./StandardToken.sol";
import "./SafeMath.sol";
// import "./zeppelin-solidity/contracts/token/StandardToken.sol";


contract GBTStandardToken is StandardToken
{
    event TransferGBT(address indexed from, address indexed to, uint256 value,string description);

    using SafeMath for uint;
    uint public tokenPrice;
    string public name;
    string public symbol;
    uint8 public decimals;
    address owner;
    uint  initialTokens;

    function GBTStandardToken(uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol) 
    {
        owner = msg.sender;
        balances[address(this)] = initialSupply;              
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;               
    }

    function addInBalance(address _Address,uint _value) 
    {
        balances[_Address] = SafeMath.add(balances[_Address],_value);
    }

    function subFromBalance(address _Address,uint _value) 
    {
        balances[_Address] = SafeMath.sub(balances[_Address],_value);
    }

    function callTransferEvent(address _from,address _to,uint _value) 
    {
        Transfer(_from, _to, _value);
    }

    function callTransferGBTEvent(address _from, address _to, uint256 _value,string _description)
    {
        TransferGBT(_from,_to,_value,_description);
        Transfer(_from, _to, _value);
    }
    
    function addInTotalSupply(uint _tokens)
    {
        totalSupply = totalSupply + _tokens;
    }
    
    function subFromTotalSupply(uint _tokens)
    {
        totalSupply = totalSupply - _tokens;
    }
}