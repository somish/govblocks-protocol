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

contract GovBlocksMaster 
{
    address MasterAddress;
    Master MS;
    address public owner;
  
    struct govBlocksUsers
    {
      string GbUserName;
      address masterAddress;
    }

    govBlocksUsers[] allGovBlocksUsers;


    function setGovBlocksMaster() 
    {
      require(owner == 0x00);
      owner = 0xed2f74e1fb73b775e6e35720869ae7a7f4d755ad; 
    } 
    
    modifier onlyOwner() 
    {
      require(msg.sender == owner);
      _;
    }

    function transferOwnership(address _newOwner) onlyOwner  
    {
      owner = _newOwner;
    }

    function updateGBTAddress(uint _masterId,address _GBTContractAddress) onlyOwner
    {
        MasterAddress = allGovBlocksUsers[_masterId].masterAddress;
        MS=Master(MasterAddress);
        MS.changeGBTAddress(_GBTContractAddress);
    }

    function setGovBlocksOwnerInMaster(uint _masterId) onlyOwner
    {
        MasterAddress = allGovBlocksUsers[_masterId].masterAddress;
        MS=Master(MasterAddress);
        MS.GovBlocksOwner();
    }

    function addGovBlocksUser(string _GbUserName,address _masterAddress) onlyOwner
    {
        allGovBlocksUsers.push(govBlocksUsers(_GbUserName,_masterAddress));   
    }

    function getGovBlocksUserDetails(uint _Id) constant returns(string GbUserName,address MasterContractAddress)
    {
        return (allGovBlocksUsers[_Id].GbUserName,allGovBlocksUsers[_Id].masterAddress);
    }

}