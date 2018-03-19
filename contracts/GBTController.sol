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

import "./Master.sol";
import "./GBTStandardToken.sol";

contract GBTController {

    // event Transfer(address indexed from, address indexed to, uint256 value);
    // event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    // event Burn(address indexed _of,bytes16 eventName , uint coverId ,uint tokens);
    address public GBTStandardTokenAddress;
    address masterAddress;
    address public owner;
    Master MS;
    GBTStandardToken GBTS;
    uint tokenPrice;

    function changeMasterAddress(address _masterContractAddress) 
    {
        if(masterAddress == 0x000)
            masterAddress = _masterContractAddress;
        else
        {
            MS=Master(masterAddress);
            require(MS.isInternal(msg.sender) == 1);
                masterAddress = _masterContractAddress;
        }
    }

    modifier onlyInternal {
        MS=Master(masterAddress);
            require(MS.isInternal(msg.sender) == 1);
        _; 
    }
    modifier onlyOwner{
        MS=Master(masterAddress);
            require(MS.isOwner(msg.sender) == 1);
        _; 
    }

    function GBTController() 
    {
        owner = msg.sender;
        tokenPrice = 1*10**15;
    }

    function changeGBTtokenAddress(address _Address) onlyInternal
    {
        GBTStandardTokenAddress = _Address;
    }

    function transferGBT(address _to, uint256 _value,string _description) onlyInternal
    {
        GBTS=GBTStandardToken(GBTStandardTokenAddress);

        require(_value <= GBTS.balanceOf(address(this)));
        GBTS.addInBalance(_to,_value);
        GBTS.subFromBalance(address(this),_value);
        GBTS.callTransferEvent(address(this), _to, _value, _description);
    }
    
    function receiveGBT(address _from,uint _value, string _description) onlyInternal
    {
        GBTS=GBTStandardToken(GBTStandardTokenAddress);

        require(_value <= GBTS.balanceOf(_from));
        GBTS.addInBalance(address(this),_value);
        GBTS.subFromBalance(_from,_value);
        GBTS.callTransferEvent(_from, address(this), _value, _description);
    }  
    
    uint public actual_amount;
    
    function buyTokenGBT(address _to,string _description) payable 
    {
        actual_amount = (msg.value/tokenPrice);  // amount that was sent          
        rewardToken(_to,actual_amount,_description);
    }

    function rewardToken(address _to,uint _amount,string _description)  onlyInternal  
    {
        GBTS=GBTStandardToken(GBTStandardTokenAddress);
        GBTS.addInBalance(_to,_amount);
        GBTS.addInTotalSupply(_amount);
        GBTS.callTransferEvent(GBTStandardTokenAddress, _to, _amount, _description);
    }

    function changeTokenPrice(uint _price)
    {
        tokenPrice = _price;
    }
 
}
