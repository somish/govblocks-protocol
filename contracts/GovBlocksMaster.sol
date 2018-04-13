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
import "./GenerateGD.sol";
import "./GenerateSV.sol";
import "./GenerateGOV.sol";
import "./memberRoles.sol";
import "./ProposalCategory.sol";
import "./governanceData.sol";
import "./GBTController.sol";
import "./GBTStandardToken.sol";

contract GovBlocksMaster 
{
    
    Master MS;
    memberRoles MR;
    ProposalCategory PC;
    governanceData GD;
    GBTController GBTC;
    GBTStandardToken GBTS;
    address public owner;
    address GBTControllerAddress;
    address GBTAddress;
    // address GDAddress;
    // address SVAddress;
    // address GOVAddress;
    address public authGBOwner;

    struct GBDapps
    {
      address masterAddress;
      address tokenAddress;
      address authGBAddress;
      string dappDescHash;
    }

    mapping(address=>bytes32) govBlocksDappByAddress;
    mapping(bytes32=>GBDapps) govBlocksDapps;
    mapping(address=>string) govBlocksUser;
    
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
      updateGBMAddress(address(this));
    } 

    function changeAuthorizedGB(bytes32 dAppName,address _memberAddress)
    {
      if(authGBOwner == 0x00)
        authGBOwner = _memberAddress;
      else
        require(msg.sender == govBlocksDapps[dAppName].authGBAddress);
        govBlocksDapps[dAppName].authGBAddress = _memberAddress;
    }

    function isAuthorizedGBOwner(bytes32 dAppName,address _memberAddress)constant returns(uint auth)
    {
       if(govBlocksDapps[dAppName].authGBAddress == _memberAddress)
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
          address masterAddress = govBlocksDapps[allGovBlocksUsers[i]].masterAddress;
          MS=Master(masterAddress);
          MS.changeGBTAddress(_GBTContractAddress);
        }
        changeGBTTokenInController(_GBTContractAddress);  
    }

    function updateGBTControllerAddress(address _GBTConrollerAddress) onlyOwner
    {
        GBTControllerAddress=_GBTConrollerAddress;
        for(uint i=0;i<allGovBlocksUsers.length; i++)
        {
            address masterAddress = govBlocksDapps[allGovBlocksUsers[i]].masterAddress;
            MS=Master(masterAddress);
            MS.changeGBTControllerAddress(_GBTConrollerAddress);
        }
        changeGBTControllerInToken(_GBTConrollerAddress);
    }

    function updateGBMAddress(address _newGBMAddress) onlyOwner
    {
        for(uint i=0;i<allGovBlocksUsers.length; i++)
        {
            address masterAddress = govBlocksDapps[allGovBlocksUsers[i]].masterAddress;
            MS=Master(masterAddress);
            MS.changeGBMAddress(_newGBMAddress);
        }

        GBTC=GBTController(GBTControllerAddress);
        GBTS=GBTStandardToken(GBTAddress);
        GBTC.changeGBMAddress(_newGBMAddress);
        GBTS.changeGBMAddress(_newGBMAddress);
    }

    function changeGBTTokenInController(address _newGBTToken) internal
    {
        GBTC=GBTController(GBTControllerAddress);
        GBTC.changeGBTtokenAddress(GBTAddress);
    }

    function changeGBTControllerInToken(address _newGBTController) internal
    {
        GBTC=GBTController(GBTControllerAddress);
        GBTC.changeGBTtokenAddress(GBTAddress);
    }


    function addGovBlocksUser(bytes32 _gbUserName,address _dappTokenAddress,string _dappDescriptionHash) 
    {
        require(govBlocksDapps[_gbUserName].masterAddress==0x00);
        address _newMasterAddress = new Master(address(this),_gbUserName);
        allGovBlocksUsers.push(_gbUserName);  
        govBlocksDapps[_gbUserName].masterAddress = _newMasterAddress;
        govBlocksDapps[_gbUserName].tokenAddress = _dappTokenAddress;
        govBlocksDapps[_gbUserName].dappDescHash = _dappDescriptionHash;
        govBlocksDappByAddress[_newMasterAddress] = _gbUserName;
        govBlocksDappByAddress[_dappTokenAddress] = _gbUserName;
        MS=Master(_newMasterAddress);
        MS.setOwner(msg.sender);
    }

    function changeDappMasterAddress(bytes32 _gbUserName,address _newMasterAddress)
    {
       if( govBlocksDapps[_gbUserName].masterAddress == 0x000)
        {       
            govBlocksDapps[_gbUserName].masterAddress = _newMasterAddress;
            govBlocksDappByAddress[_newMasterAddress] = _gbUserName;
        }
       else
        {            
            if(msg.sender ==  govBlocksDapps[_gbUserName].masterAddress)
            {
                govBlocksDapps[_gbUserName].masterAddress = _newMasterAddress;
                govBlocksDappByAddress[_newMasterAddress] = _gbUserName;
            }
            else
                throw;
        }   
    }

    function changeDappTokenAddress(bytes32 _gbUserName,address _dappTokenAddress)
    {
       if( govBlocksDapps[_gbUserName].tokenAddress == 0x000)
       {
            govBlocksDapps[_gbUserName].tokenAddress = _dappTokenAddress;
            govBlocksDappByAddress[_dappTokenAddress] = _gbUserName;
        }
       else
        {            
            if(msg.sender ==  govBlocksDapps[_gbUserName].masterAddress)
            {
                govBlocksDapps[_gbUserName].tokenAddress = _dappTokenAddress;
                govBlocksDappByAddress[_dappTokenAddress] = _gbUserName;
            }
            else
                throw;
        }   
    }

    function changeDappDescHash(bytes32 _gbUserName,string _dappDescriptionHash)
    { 
        if(msg.sender ==  govBlocksDapps[_gbUserName].masterAddress)
        {
            govBlocksDapps[_gbUserName].dappDescHash = _dappDescriptionHash;
        }
        else
            throw;
    }

    function setByteCodeAndAbi(string _byteCodeHash,string _abiHash) onlyOwner
    {
        byteCodeHash = _byteCodeHash;
        contractsAbiHash = _abiHash;
    }

    // function changeAllAddress(address _GDAddress,address _SVAddress,address _GOVAddress) onlyOwner
    // {
    //    GDAddress = _GDAddress;
    //    SVAddress = _SVAddress;
    //    GOVAddress = _GOVAddress;
    // }

    function setDappUser(string _hash)
    {
       govBlocksUser[msg.sender] = _hash;
    }

    function getByteCodeAndAbi()constant returns(string byteCode, string abiHash)
    {
       return (byteCodeHash,contractsAbiHash);
    }

    function getGovBlocksUserDetails(bytes32 _gbUserName) constant returns(bytes32 GbUserName,address masterContractAddress,string allContractsbyteCodeHash,string allCcontractsAbiHash,uint versionNo)
    {
        address master = govBlocksDapps[_gbUserName].masterAddress;
        if(master == 0x00)
            return(GbUserName,0x00,"","",0);
        else
            MS=Master(master);
            versionNo = MS.versionLength();
            return (_gbUserName,govBlocksDapps[_gbUserName].masterAddress,byteCodeHash,contractsAbiHash,versionNo);
    }

    function getGovBlocksUserDetailsByIndex(uint _index) constant returns(uint index,bytes32 GbUserName,address MasterContractAddress)
    {
       return (_index,allGovBlocksUsers[_index],govBlocksDapps[allGovBlocksUsers[_index]].masterAddress);
    }

    function getGovBlocksUserDetails1(bytes32 _gbUserName)constant returns(bytes32 GbUserName,address masterContractAddress,address dappTokenAddress,string allContractsbyteCodeHash,string allCcontractsAbiHash,uint versionNo)
    {
        address master = govBlocksDapps[_gbUserName].masterAddress;
        if(master == 0x00)
            return(GbUserName,0x00,0x00,"","",0);
        else
            MS=Master(master);
            versionNo = MS.versionLength();
            return (_gbUserName,govBlocksDapps[_gbUserName].masterAddress,govBlocksDapps[_gbUserName].tokenAddress,byteCodeHash,contractsAbiHash,versionNo);
    }

    function getGovBlocksUserDetails2(address _Address)constant returns(bytes32 dappName,address masterContractAddress,address dappTokenAddress)
    {
       dappName = govBlocksDappByAddress[_Address];
       return (dappName,govBlocksDapps[dappName].masterAddress,govBlocksDapps[dappName].tokenAddress);
    }

    function getDappDescHash(bytes32 _gbUserName)constant returns(string)
    {
        return govBlocksDapps[_gbUserName].dappDescHash;
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

    function getDappUser()constant returns (string)
    {
       return (govBlocksUser[msg.sender]);
    }

    function getDappMasterAddress(bytes32 _gbUserName)constant returns(address masterAddress)
    {
        return (govBlocksDapps[_gbUserName].masterAddress);
    }

    function getDappTokenAddress(bytes32 _gbUserName)constant returns(address tokenAddres)
    {
        return (govBlocksDapps[_gbUserName].tokenAddress);
    }

    function getDappNameByAddress(address _contractAddress)constant returns(bytes32)
    {
            return govBlocksDappByAddress[_contractAddress];
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

    // function getGDAddress()constant returns(address)
    // {
    //   return GDAddress;
    // }

    // function getSVAddress()constant returns(address)
    // {
    //    return SVAddress;
    // }

    // function getGOVAddress()constant returns(address)
    // {
    //   return GOVAddress;
    // }


    // ACTION AFTER PROPOSAL PASS function


    function addNewMemberRoleGB(bytes32 _gbUserName,bytes32 _newRoleName,string _newDescHash) 
    {
        require(isAuthorizedGBOwner(_gbUserName,msg.sender) == 1);
        address master = govBlocksDapps[_gbUserName].masterAddress; address MRAddress;
        MS=Master(master);
        uint versionNo = MS.versionLength()-1; 
        (,MRAddress) = MS.allContractVersions(versionNo,2);
        MR=memberRoles(MRAddress);
        MR.addNewMemberRole(_newRoleName,_newDescHash);
    }

    function updateMemberRoleGB(bytes32 _gbUserName,address _memberAddress,uint _memberRoleId,uint8 _typeOf) 
    {
        require(isAuthorizedGBOwner(_gbUserName,msg.sender) == 1);
        address master = govBlocksDapps[_gbUserName].masterAddress; address MRAddress;
        MS=Master(master);
        uint versionNo = MS.versionLength()-1; 
        (,MRAddress) = MS.allContractVersions(versionNo,2);
        MR=memberRoles(MRAddress);
        MR.updateMemberRole(_memberAddress,_memberRoleId,_typeOf);
    }
    
    function addNewCategoryGB(bytes32 _gbUserName,string _descHash) 
    {
        require(isAuthorizedGBOwner(_gbUserName,msg.sender) == 1);
        address master = govBlocksDapps[_gbUserName].masterAddress; address PCAddress;
        MS=Master(master);
        uint versionNo = MS.versionLength()-1; 
        (,PCAddress) = MS.allContractVersions(versionNo,3);
        PC=ProposalCategory(PCAddress);
        // PC.addNewCategory(_descHash);
    }

    function updateCategoryGB(bytes32 _gbUserName,uint _categoryId,string _categoryData) 
    {
        require(isAuthorizedGBOwner(_gbUserName,msg.sender) == 1);
        address master = govBlocksDapps[_gbUserName].masterAddress; address PCAddress;
        MS=Master(master);
        uint versionNo = MS.versionLength()-1; 
        (,PCAddress) = MS.allContractVersions(versionNo,3);
        PC=ProposalCategory(PCAddress);
        PC.updateCategory(_categoryId,_categoryData);
    }

    function configureGlobalParameters(bytes32 _gbUserName,bytes16 _typeOf,uint _value)
    {
        require(isAuthorizedGBOwner(_gbUserName,msg.sender) == 1);
        address master = govBlocksDapps[_gbUserName].masterAddress; address GDAddress;
        MS=Master(master);
        uint versionNo = MS.versionLength()-1; 
        (,GDAddress) = MS.allContractVersions(versionNo,1);
        GD=governanceData(GDAddress);

        if(_typeOf == "APO")
        {
          GD.changeProposalOwnerAdd(_value);
        }
        else if(_typeOf == "AOO")
        {
          GD.changeOptionOwnerAdd(_value);
        }
        else if(_typeOf == "AVM")
        {
          GD.changeMemberAdd(_value);
        }
        else if(_typeOf == "SPO")
        {
          GD.changeProposalOwnerSub(_value);
        }
        else if(_typeOf == "SOO")
        {
          GD.changeOptionOwnerSub(_value);
        }
        else if(_typeOf == "SVM")
        {
          GD.changeMemberSub(_value);
        }//
        else if(_typeOf == "GBTS")
        {
          GD.changeGBTStakeValue(_value);
        }
        else if(_typeOf == "RF")
        {
          GD.changeGlobalRiskFactor(_value);
        }
         else if(_typeOf == "MSF")
        {
          GD.changeMembershipScalingFator(_value);
        }
        else if(_typeOf == "SW")
        {
          GD.changeScalingWeight(_value);
        }
        else if(_typeOf == "QP")
        {
          GD.changeQuorumPercentage(_value);
        }
    }
}