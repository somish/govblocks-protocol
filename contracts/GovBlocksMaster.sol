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
    
    Master MS;
    address public owner;
    address GBTControllerAddress;
    address GBTAddress;
    address GDAddress;
    address SVAddress;
    address GOVAddress;
    address public authGBOwner;

    mapping(bytes32=>address) govBlocksDapps;
    mapping (address=>string) govBlocksUser;
    
    bytes32[] allGovBlocksUsers;
    string byteCodeHash;
    string contractsAbiHash;

    modifier onlyOwner() 
    {
      require(msg.sender == owner);
      _;
    }

    function GovBlocksMasterInit(address _GBTControllerAddress,address _GBTAddress) 
    {
      require(owner == 0x00);
      owner = msg.sender; 
      GBTControllerAddress=_GBTControllerAddress;
      GBTAddress = _GBTAddress;
    } 

    function changeAuthorizedGB(address _memberAddress)
    {
      if(authGBOwner == 0x00)
        authGBOwner = _memberAddress;
      else
        require(msg.sender == authGBOwner);
        authGBOwner = _memberAddress;
    }

    function isAuthorizedGBOwner(address _memberAddress)constant returns(uint auth)
    {
       if(authGBOwner == _memberAddress)
          auth = 1;
    } 

    function transferOwnership(address _newOwner) onlyOwner  
    {
      owner = _newOwner;
    }

    function updateGBTAddress(address _GBTContractAddress) onlyOwner
    {
        GBTAddress=_GBTContractAddress;
        for(uint i=0;i<allGovBlocksUsers.length; i++)
        {
          address masterAddress = govBlocksDapps[allGovBlocksUsers[i]];
          MS=Master(masterAddress);
          MS.changeGBTAddress(_GBTContractAddress);
        }  
    }

    function updateGBTControllerAddress(address _GBTConrollerAddress) onlyOwner
    {
        GBTControllerAddress=_GBTConrollerAddress;
        for(uint i=0;i<allGovBlocksUsers.length; i++){
        address masterAddress = govBlocksDapps[allGovBlocksUsers[i]];
        MS=Master(masterAddress);
        MS.changeGBTControllerAddress(_GBTConrollerAddress);
        } 
    }

    function setGovBlocksOwnerInMaster(uint _masterId) onlyOwner
    {
        address masterAddress = govBlocksDapps[allGovBlocksUsers[_masterId]];
        MS=Master(masterAddress);
        MS.GovBlocksOwner();
    }

    function addGovBlocksUser(bytes32 _gbUserName) onlyOwner
    {
        require(govBlocksDapps[_gbUserName]==0x00);
        address _newMasterAddress = new Master(address(this),_gbUserName);
        allGovBlocksUsers.push(_gbUserName);  
        govBlocksDapps[_gbUserName] = _newMasterAddress;
        MS=Master(_newMasterAddress);
        MS.setOwner(msg.sender);
    }

    function changeDappMasterAddress(bytes32 _gbUserName,address _newMasterAddress)
    {
       if( govBlocksDapps[_gbUserName] == 0x000)
                   govBlocksDapps[_gbUserName] = _newMasterAddress;
       else
        {            
            if(msg.sender ==  govBlocksDapps[_gbUserName])
                 govBlocksDapps[_gbUserName] = _newMasterAddress;
            else
                throw;
        }   
    }
    
    function setByteCodeAndAbi(string _byteCodeHash,string _abiHash) onlyOwner
    {
        byteCodeHash = _byteCodeHash;
        contractsAbiHash = _abiHash;
    }

    function changeAllAddress(address _GDAddress,address _SVAddress,address _GOVAddress) onlyOwner
    {
       GDAddress = _GDAddress;
       SVAddress = _SVAddress;
       GOVAddress = _GOVAddress;
    }

    function changeAllAddress1(address _GBTControllerAddress,address _GBTokenAddress) onlyOwner
    {
        GBTControllerAddress = _GBTControllerAddress;
       _GBToken = _GBTokenAddress;
    }
    
    function setDappUser(address _memberAddress,string _hash) onlyOwner
    {
       govBlocksUser[_memberAddress] = _hash;
    }

    function getGBTandGBTC() constant returns(address _GBTController,address _GBToken)
    {
       return (GBTControllerAddress,GBTAddress);
    }

    function getGBTAddress()constant returns(address)
    {
       return GBTAddress;
    }

    function getGBTCAddress()constant returns(address)
    {
       return GBTControllerAddress;
    }

    function getGDAddress()constant returns(address)
    {
      return GDAddress;
    }

    function getSVAddress()constant returns(address)
    {
       return SVAddress;
    }

    function getGOVAddress()constant returns(address)
    {
      return GOVAddress;
    }

    function getByteCodeAndAbi()constant returns(string byteCode, string abiHash)
    {
       return (byteCodeHash,contractsAbiHash);
    }

    function getGovBlocksUserDetails(bytes32 _gbUserName) constant returns(bytes32 GbUserName,address masterContractAddress,string byteCode,string contractsAbi)
    {
        return (_gbUserName,govBlocksDapps[_gbUserName],byteCodeHash,contractsAbiHash);
    }

    function getGovBlocksUserDetailsByIndex(uint _index) constant returns(uint index,bytes32 GbUserName,address MasterContractAddress)
    {
       return (_index,allGovBlocksUsers[_index],govBlocksDapps[allGovBlocksUsers[_index]]);
    }

    function getAllDappLength()constant returns(uint)
    {
       return (allGovBlocksUsers.length);
    }

    function getAllDappById(uint _gbIndex)constant returns (bytes32 _gbUserName)
    {
       return (allGovBlocksUsers[_gbIndex]);
    }

    function getAllDappArray()constant returns(bytes32[])
    {
       return (allGovBlocksUsers);
    }

    function getDappUser(address _memberAddress)constant returns (string)
    {
       return (govBlocksUser[_memberAddress]);
    }

    // function changeDappGDAddress(bytes32 _gbUserName,address _GDAddress) 
    // {
    //     require(govBlocksDapps[_gbUserName][0]!=0x00 || (msg.sender ==  govBlocksDapps[_gbUserName][0] && govBlocksDapps[_gbUserName][0]==0x00));
    //     MS=Master(govBlocksDapps[_gbUserName][0]);
    //     require(MS.isOwner(msg.sender) == 1);        
    //     govBlocksDapps[_gbUserName][1] = _GDAddress;
    // }

    // function changeDappSVAddress(bytes32 _gbUserName,address _SVAddress) 
    // {
    //     require(govBlocksDapps[_gbUserName][0]!=0x00);
    //     MS=Master(govBlocksDapps[_gbUserName][0]);
    //     require(MS.isOwner(msg.sender) == 1);        
    //     govBlocksDapps[_gbUserName][2] = _SVAddress;
    // }

    // function changeDappGOVAddress(bytes32 _gbUserName,address _GOVAddress) 
    // {
    //     require(govBlocksDapps[_gbUserName][0]!=0x00);
    //     MS=Master(govBlocksDapps[_gbUserName][0]);
    //     require(MS.isOwner(msg.sender) == 1);        
    //     govBlocksDapps[_gbUserName][3] = _GOVAddress;
    // }
    
    // function getDappVersionData(bytes32 _gbUserName,uint _addressIndex)constant returns(address contractAddress)
    // {
    //     return (govBlocksDapps[_gbUserName][_addressIndex]);
    // }

}