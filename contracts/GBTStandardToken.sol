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

contract GBTStandardToken is StandardToken
{
    event TransferGBT(address indexed from, address indexed to, uint256 value,string description);

    using SafeMath for uint;
    uint public tokenPrice;
    string public name;
    string public symbol;
    uint public decimals;
    address owner;
    address GBTCAddress;
    address GBMAddress;
    uint  initialTokens;
    uint public tokenHoldingTime;


    struct lock
    {
        uint amount;
        uint validUpto;
    }

    lock[] lockToken;
    mapping(bytes32=>mapping(uint=>uint)) proposal_lockToken;
    mapping(address=>uint) user_lockToken;

    function lockMemberToken(bytes32 _gbUserName,uint _proposalId,uint _memberStake)
    {
        // lockToken.push((stake*_tokenlockPerc)/100,totalTime);
        // proposal_lockToken[_gbUserName][_proposalId] = id;
        // user_lockToken[msg.sender] = id;
    }

    function getLockedTokenId(bytes32 _gbUserName,uint _proposalId)constant returns(uint id)
    {
        id = proposal_lockToken[_gbUserName][_proposalId];
    }

    function getLockedAmountMyId(uint _id)constant returns (uint stake)
    {
        stake = lockToken[_id];
    }

    modifier onlyGBTController
    {  
        require(msg.sender == GBTCAddress);
        _; 
    }

    modifier onlyGBM
    {
        require(msg.sender == GBMAddress);
        _;
    }

    function GBTStandardToken() 
    {
        owner = msg.sender;
        balances[address(this)] = 0;              
        totalSupply = 0;                      
        name = "GBT";                        
        symbol = "";                  
        decimals = 18;
    }

    function changeGBMAddress(address _GBMAddress) onlyGBM
    {
        GBMAddress = _GBMAddress;
    }

    function changeGBTControllerAddress(address _GBTCAddress) onlyGBM
    {
        GBTCAddress = _GBTCAddress;
    }

    function addInBalance(address _Address,uint _value) onlyGBTController
    {
        balances[_Address] = SafeMath.add(balances[_Address],_value);
    }

    function subFromBalance(address _Address,uint _value)  onlyGBTController
    {
        balances[_Address] = SafeMath.sub(balances[_Address],_value);
    }

    function callTransferGBTEvent(address _from, address _to, uint256 _value,string _description) onlyGBTController
    {
        TransferGBT(_from,_to,_value,_description);
        Transfer(_from, _to, _value);
    }
    
    function addInTotalSupply(uint _tokens) onlyGBTController
    {
        totalSupply = totalSupply + _tokens;
    }
    
    function subFromTotalSupply(uint _tokens) onlyGBTController
    {
        totalSupply = totalSupply - _tokens;
    }
}