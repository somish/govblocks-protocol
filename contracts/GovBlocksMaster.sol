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
import "./memberRoles.sol";
import "./ProposalCategory.sol";
import "./governanceData.sol";

contract GovBlocksMaster 
{
    Master MS;
    memberRoles MR;
    ProposalCategory PC;
    governanceData GD;
    address public owner;
    address GBTAddress;
    

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

    /// @dev Initializes GovBlocks master
    /// @param _GBTAddress GBT address
    function GovBlocksMasterInit(address _GBTAddress) 
    {
      require(owner == 0x00);
      owner = msg.sender; 
      GBTAddress = _GBTAddress;
    //   updateGBMAddress(address(this));  
    } 

    /// @dev Changes authorized GovBlocks owner
    /// @param dAppName dApp username
    /// @param _memberAddress Address of the member
    function changedAppAuthorizedGB(bytes32 dAppName,address _memberAddress)
    {
        require(msg.sender == govBlocksDapps[dAppName].authGBAddress);
        govBlocksDapps[dAppName].authGBAddress = _memberAddress;
    }

    /// @dev Checks for authorized GovBlocks owner
    /// @param dAppName dApp username
    /// @param _memberAddress Member's address to be checked for GovBlocks owner
    /// @return auth Authentication flag
    function isAuthorizedGBOwner(bytes32 dAppName,address _memberAddress)constant returns(bool)
    {
       if(govBlocksDapps[dAppName].authGBAddress == _memberAddress)
        return true;
    } 

    /// @dev Transfers ownership to new owner (of GBT contract address)
    /// @param _newOwner Address of new owner
    function transferOwnership(address _newOwner) onlyOwner  
    {
      owner = _newOwner;
    }

    /// @dev Updates GBT contract address
    /// @param _GBTContractAddress New GBT contract address
    function updateGBTAddress(address _GBTContractAddress) onlyOwner
    {
        GBTAddress=_GBTContractAddress;
        for(uint i=0;i<allGovBlocksUsers.length; i++)
        {
          address masterAddress = govBlocksDapps[allGovBlocksUsers[i]].masterAddress;
          MS=Master(masterAddress);
          if(MS.versionLength()>0)
            MS.changeGBTAddress(_GBTContractAddress);
        }  
    }


    /// @dev Updates GovBlocks master address
    /// @param _newGBMAddress New GovBlocks master address
    function updateGBMAddress(address _newGBMAddress) internal
    {
        for(uint i=0;i<allGovBlocksUsers.length; i++)
        {
            address masterAddress = govBlocksDapps[allGovBlocksUsers[i]].masterAddress;
            MS=Master(masterAddress);
            if(MS.versionLength()>0)
                MS.changeGBMAddress(_newGBMAddress);
        }
    }

    /// @dev Adds GovBlocks user
    /// @param _gbUserName  GovBlocks username
    /// @param _dappTokenAddress dApp token address
    /// @param _dappDescriptionHash dApp description hash
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
        govBlocksDapps[_gbUserName].authGBAddress = owner;
        MS=Master(_newMasterAddress);
        MS.setOwner(msg.sender);
    }

    /// @dev Changes dApp master address
    /// @param _gbUserName GovBlocks username
    /// @param _newMasterAddress dApp new master address
    function changeDappMasterAddress(bytes32 _gbUserName,address _newMasterAddress)
    {
        require(msg.sender ==  govBlocksDapps[_gbUserName].authGBAddress);
        govBlocksDapps[_gbUserName].masterAddress = _newMasterAddress;
        govBlocksDappByAddress[_newMasterAddress] = _gbUserName; 
    }

    /// @dev Changes dApp token address
    /// @param _gbUserName  GovBlocks username
    /// @param _dappTokenAddress dApp new token address
    function changeDappTokenAddress(bytes32 _gbUserName,address _dappTokenAddress)
    {
        require(msg.sender ==  govBlocksDapps[_gbUserName].authGBAddress);
            govBlocksDapps[_gbUserName].tokenAddress = _dappTokenAddress;
            govBlocksDappByAddress[_dappTokenAddress] = _gbUserName;   
    }

    /// @dev Sets byte code and abi
    /// @param _byteCodeHash Byte code hash
    /// @param _abiHash Abi hash
    function setByteCodeAndAbi(string _byteCodeHash,string _abiHash) onlyOwner
    {
        byteCodeHash = _byteCodeHash;
        contractsAbiHash = _abiHash;
    }

    /// @dev Sets hash value for dApp user
    /// @param _hash Hash value 
    function setDappUser(string _hash)
    {
       govBlocksUser[msg.sender] = _hash;
    }

    /// @dev Gets byte code and abi hash
    /// @param byteCode Byte code 
    /// @param abiHash Application binary interface hash
    function getByteCodeAndAbi()constant returns(string byteCode, string abiHash)
    {
      return (byteCodeHash,contractsAbiHash);
    }

    function getDappAuthorizedAddress(bytes32 _gbUserName)constant returns(address)
    {
        return govBlocksDapps[_gbUserName].authGBAddress;
    }

    /// @dev Gets GovBlocks user details
    /// @param _gbUserName GovBlocks username
    /// @return GbUserName GovBlocks username
    /// @return masterContractAddress Master contract address of dApp
    /// @return allContractsbyteCodeHash All contracts byte code hash
    /// @return allCcontractsAbiHash All contracts abi hash
    /// @return versionNo Verson number of dApp
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

    /// @dev Gets GovBlocks user details by index
    /// @param _index Index to fetch user details
    /// @return index Index
    /// @return GbUserName GovBlocks username
    /// @return MasterContractAddress Master contract address
    function getGovBlocksUserDetailsByIndex(uint _index) constant returns(uint index,bytes32 GbUserName,address MasterContractAddress)
    {
       return (_index,allGovBlocksUsers[_index],govBlocksDapps[allGovBlocksUsers[_index]].masterAddress);
    }

    /// @dev Gets GovBlocks user details (another function)
    /// @param _gbUserName GovBlocks username whose details need to be fetched
    /// @return GbUserName GovBlocks username 
    /// @return masterContractAddress Master contract address
    /// @return dappTokenAddress dApp token address
    /// @return allContractsbyteCodeHash All contracts byte code hash
    /// @return allCcontractsAbiHash All contract abi hash
    /// @return versionNo Version number
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

    /// @dev Gets GovBlocks user details (another function)
    /// @param _Address Address of the dApp whose details need to be fetched
    /// @return dappName dApp name
    /// @return masterContractAddress Master contract address of dApp
    /// @return dappTokenAddress dApp's token address
    function getGovBlocksUserDetails2(address _Address)constant returns(bytes32 dappName,address masterContractAddress,address dappTokenAddress)
    {
       dappName = govBlocksDappByAddress[_Address];
       return (dappName,govBlocksDapps[dappName].masterAddress,govBlocksDapps[dappName].tokenAddress);
    }

    /// @dev Gets dApp description hash
    /// @param _gbUserName GovBlocks username
    /// @return govBlocksDapps[_gbUserName].dappDescHash GovBlocks description hash
    function getDappDescHash(bytes32 _gbUserName)constant returns(string)
    {
        return govBlocksDapps[_gbUserName].dappDescHash;
    }

    /// @dev Gets all GovBlocks users length
    /// @return allGovBlocksUsers.length All GovBlocks users length
    function getAllDappLength()constant returns(uint)
    {
       return (allGovBlocksUsers.length);
    }

    /// @dev Gets dApps users by index
    function getAllDappById(uint _gbIndex)constant returns (bytes32 _gbUserName)
    {
       return (allGovBlocksUsers[_gbIndex]);
    }

    /// @dev Gets all dApps users
    function getAllDappArray()constant returns(bytes32[])
    {
       return (allGovBlocksUsers);
    }

    /// @dev Gets dApp username
    function getDappUser()constant returns (string)
    {
       return (govBlocksUser[msg.sender]);
    }

    /// @dev Gets dApp master address of dApp (username=govBlocksUser)
    function getDappMasterAddress(bytes32 _gbUserName)constant returns(address masterAddress)
    {
        return (govBlocksDapps[_gbUserName].masterAddress);
    }

    /// @dev Gets dApp token address of dApp (username=govBlocksUser)
    function getDappTokenAddress(bytes32 _gbUserName)constant returns(address tokenAddres)
    {
        return (govBlocksDapps[_gbUserName].tokenAddress);
    }

    /// @dev Gets dApp username by address
    function getDappNameByAddress(address _contractAddress)constant returns(bytes32)
    {
            return govBlocksDappByAddress[_contractAddress];
    }

    /// @dev Gets GBT address 
    function getGBTAddress()constant returns(address)
    {
       return GBTAddress;
    }

    
    // ACTION AFTER PROPOSAL PASS function


    function getContractInstance_byDapp(bytes32 _gbUserName,bytes2 _typeOf) internal constant returns(address contractAddress) 
    {
        require(isAuthorizedGBOwner(_gbUserName,msg.sender) == true);
        address master = govBlocksDapps[_gbUserName].masterAddress; 
        MS=Master(master);
        uint16 versionNo = MS.versionLength()-1; 
        contractAddress = MS.allContractVersions(versionNo,_typeOf);
        return contractAddress;
    }

    /// @dev Adds new member roles in GovBlocks
    /// @param _gbUserName GovBlocks new username
    /// @param _newRoleName GovBlocks new role name
    /// @param _roleDescription GovBlocks new description hash
    function addNewMemberRoleGB(bytes32 _gbUserName,bytes32 _newRoleName,string _roleDescription, address _canAddMembers) 
    {
        address MRAddress = getContractInstance_byDapp(_gbUserName,"MR");
        MR=memberRoles(MRAddress);
        MR.addNewMemberRole(_newRoleName, _roleDescription, _canAddMembers);
    }

    /// @dev Updates member roles in GovBlocks
    /// @param _gbUserName GovBlocks new username
    /// @param _memberAddress New members address
    /// @param _memberRoleId New members role id
    /// @param _typeOf Typeof role of the member
    function updateMemberRoleGB(bytes32 _gbUserName,address _memberAddress,uint32 _memberRoleId,bool _typeOf) 
    {
        address MRAddress = getContractInstance_byDapp(_gbUserName,"MR");
        MR=memberRoles(MRAddress);
        MR.updateMemberRole(_memberAddress,_memberRoleId,_typeOf);
    }
    
    /// @dev Adds new category in GovBlocks
    /// @param _gbUserName GovBlocks username
    /// @param _descHash GovBlocks description hash
    function addNewCategoryGB(bytes32 _gbUserName,string _descHash,uint8[] _memberRoleSequence,uint[] _memberRoleMajorityVote,uint[] _closingTime,uint8 _minStake,uint8 _maxStake,uint8 _defaultIncentive) 
    {
        address PCAddress = getContractInstance_byDapp(_gbUserName,"PC");
        PC=ProposalCategory(PCAddress);
        PC.addNewCategory(_descHash,_memberRoleSequence,_memberRoleMajorityVote,_closingTime,_minStake,_maxStake,_defaultIncentive);
    }

    /// @dev Updates category in GovBlocks
    /// @param _gbUserName GovBlocks username
    /// @param _categoryId Category id 
    /// @param _categoryData Category data
    function updateCategoryGB(bytes32 _gbUserName,uint _categoryId,string _categoryData,uint8[] _roleName,uint[] _majorityVote,uint[] _closingTime,uint8 _minStake,uint8 _maxStake, uint _defaultIncentive) 
    {
        address PCAddress = getContractInstance_byDapp(_gbUserName,"PC");
        PC=ProposalCategory(PCAddress);
        PC.updateCategory(_categoryId,_categoryData,_roleName,_majorityVote,_closingTime,_minStake,_maxStake,_defaultIncentive);
    }

    /// @dev Adds new category in GovBlocks
    /// @param _gbUserName GovBlocks username
    function addNewSubCategoryGB(bytes32 _gbUserName,string _categoryName,string _actionHash,uint8 _mainCategoryId) 
    {
        address PCAddress = getContractInstance_byDapp(_gbUserName,"PC");
        PC=ProposalCategory(PCAddress);
        PC.addNewSubCategory(_categoryName,_actionHash,_mainCategoryId);
    }

    /// @dev Updates category in GovBlocks
    /// @param _gbUserName GovBlocks username
    function updateSubCategoryGB(bytes32 _gbUserName,uint8 _subCategoryId,string _actionHash) 
    {
        address PCAddress =getContractInstance_byDapp(_gbUserName,"PC");
        PC=ProposalCategory(PCAddress);
        PC.updateSubCategory(_subCategoryId,_actionHash);
    }

    /// @dev Configures global parameters for reputation weights
    /// @param _gbUserName GovBlocks username
    /// @param _typeOf Typeof role of the member
    /// @param _value Quorum percentage value
    function configureGlobalParameters(bytes32 _gbUserName,bytes4 _typeOf,uint32 _value)
    {
        address GDAddress = getContractInstance_byDapp(_gbUserName,"GD");
        GD=governanceData(GDAddress);

        if(_typeOf == "APO")
        {
          GD.changeProposalOwnerAdd(_value);
        }
        else if(_typeOf == "AOO")
        {
          GD.changeSolutionOwnerAdd(_value);
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
          GD.changeSolutionOwnerSub(_value);
        }
        else if(_typeOf == "SVM")
        {
          GD.changeMemberSub(_value);
        }
        else if(_typeOf == "GBTS")
        {
          GD.changeGBTStakeValue(_value);
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