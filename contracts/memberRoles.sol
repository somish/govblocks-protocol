/* Copyright (C) 2017 NexusMutual.io

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
import "./BasicToken.sol";
import "./SafeMath.sol";

contract  memberRoles
{
  event MemberRole(uint256 indexed roleId, bytes32 roleName, string roleDescription);
  using SafeMath for uint;
  bytes32[] memberRole;
  uint8 authorizedAddress_toCategorize;
  bool public constructorCheck;
  address public masterAddress;
  Master MS; 
  BasicToken BT;

  struct memberRoleDetails
  {
    uint32 memberCounter;
    mapping(address=>bool) memberActive;
    address[] memberAddress;
  }

  mapping(uint=>address) authorizedAddress_againstRole;
  mapping(uint32=>memberRoleDetails) memberRoleData;

  /// @dev Initiates member roles
  function MemberRolesInitiate()
  {
    require(constructorCheck == false);
        memberRole.push("");
        memberRole.push("Advisory Board");
        memberRole.push("Token Holder");
        authorizedAddress_toCategorize=1;
        setOwnerRole();
        constructorCheck = true;
  }

   modifier onlyInternal 
   {
      MS=Master(masterAddress);
      require(MS.isInternal(msg.sender) == true);
      _; 
   }
  
   modifier onlyOwner 
   {
      MS=Master(masterAddress);
      require(MS.isOwner(msg.sender) == true);
      _; 
   }
  
    modifier onlyMaster {
        require(msg.sender == masterAddress);
        _; 
    }

    modifier onlyGBM {
        MS=Master(masterAddress);
        require(MS.isGBM(msg.sender) == true);
        _;
    }

    modifier checkRoleAuthority(uint _memberRoleId){
      MS=Master(masterAddress);
      require(MS.isGBM(msg.sender) == true || msg.sender == authorizedAddress_againstRole[_memberRoleId]);
       _;
    }

  /// @dev Changes master's contract address
  /// @param _masterContractAddress New master address
  function changeMasterAddress(address _masterContractAddress) 
  {
      if(masterAddress == 0x000)
          masterAddress = _masterContractAddress;
      else
      {
          MS=Master(masterAddress);
          require(MS.isInternal(msg.sender) == true);
              masterAddress = _masterContractAddress;
      }
  }

  function setOwnerRole()internal
  {
      MS=Master(masterAddress);
      address ownAddress = MS.owner();
      memberRoleData[1].memberCounter =  SafeMath.add32(memberRoleData[1].memberCounter,1);
      memberRoleData[1].memberActive[ownAddress] = true;
      memberRoleData[1].memberAddress.push(ownAddress);
  }

  function getRoleIdLengthByAddress(address _memberAddress) internal constant  returns(uint8 count)
  {
      uint length = getTotalMemberRoles();
      for(uint8 i=0; i<length; i++)
      {
         if(memberRoleData[i].memberActive[_memberAddress] == true)
           count++;
      }
      return count;
  }

  function getRoleIdByAddress(address _memberAddress)constant returns(uint32[] assignedRoles)
  {
      uint8 length = getRoleIdLengthByAddress(_memberAddress);uint8 j=0;
      assignedRoles = new uint32[](length);
      for(uint8 i=0; i<getTotalMemberRoles(); i++)
      {
          if(memberRoleData[i].memberActive[_memberAddress] == true)
          {
            assignedRoles[j] = i;
            j++;
          }
      }
      return assignedRoles;
  }

  function checkRoleId_byAddress(address _memberAddress,uint32 _roleId)constant returns(bool)
  {
    if(memberRoleData[_roleId].memberActive[_memberAddress] == true)
      return true;
    else 
      return false;
  }

  /// @dev Updates member role
  /// @param _memberAddress Member address
  /// @param _memberRoleId Member role id
  /// @param _typeOf Type of role id of the member
  function updateMemberRole(address _memberAddress,uint32 _memberRoleId,bool _typeOf) checkRoleAuthority(_memberRoleId)
  {
      if(_typeOf == true)
      {
        require(memberRoleData[_memberRoleId].memberActive[_memberAddress] == false);
        memberRoleData[_memberRoleId].memberCounter =  SafeMath.add32(memberRoleData[_memberRoleId].memberCounter,1);
        memberRoleData[_memberRoleId].memberActive[_memberAddress] = true;
        memberRoleData[_memberRoleId].memberAddress.push(_memberAddress);
      }
      else
      {
        require(memberRoleData[_memberRoleId].memberActive[_memberAddress] == true);
        memberRoleData[_memberRoleId].memberCounter = SafeMath.sub32(memberRoleData[_memberRoleId].memberCounter,1);
        memberRoleData[_memberRoleId].memberActive[_memberAddress] = false;
      }
  }

  /// @dev Changes member role id's changable member 
  /// @param _memberRoleId Member role id
  /// @param _newCanAddMember New authorized address against role id. (Responsible to assign/remove any address from Role)
  function changeCanAddMember(uint32 _memberRoleId, address _newCanAddMember) checkRoleAuthority(_memberRoleId)
  {
      authorizedAddress_againstRole[_memberRoleId] = _newCanAddMember;
  }

  /// @dev Changes the role id of the member who is authorized to categorize the proposal
  /// @param _roleId Role id of that member
  function changeAuthorizedMemberId(uint8 _roleId) onlyOwner public
  {
     authorizedAddress_toCategorize = _roleId;
  }

  /// @dev Adds new member role
  /// @param _newRoleName New role name
  /// @param _roleDescription New description hash
  /// @param _canAddMembers Authorized member against every role id
  function addNewMemberRole(bytes32 _newRoleName,string _roleDescription, address _canAddMembers) onlyGBM
  {
      uint rolelength = getTotalMemberRoles();
      memberRole.push(_newRoleName);  
      authorizedAddress_againstRole[rolelength] = _canAddMembers;
      MemberRole(rolelength, _newRoleName, _roleDescription);
  }

  /// @dev Gets the member addresses assigned by a specific role
  /// @param _memberRoleId Member role id
  /// @return roleId Role id
  /// @return allMemberAddress Member addresses of specified role id
  function getAllAddressByRoleId(uint32 _memberRoleId) public constant returns(uint32,address[] allMemberAddress)
  {
      uint length = getAllMemberLength(_memberRoleId);uint8 j=0;
      allMemberAddress = new address[](length);
      for(uint8 i=0; i<length; i++)
      {
          address member = memberRoleData[_memberRoleId].memberAddress[i];
          if(memberRoleData[_memberRoleId].memberActive[member] == true)
           {
              allMemberAddress[j] = member;
              j++;
           }
      }
      return (_memberRoleId,allMemberAddress);
  }

  /// @dev Gets all members' length
  /// @param _memberRoleId Member role id
  /// @return memberRoleData[_memberRoleId].memberAddress.length Member length
  function getAllMemberLength(uint32 _memberRoleId) public constant returns(uint)
  {
     return memberRoleData[_memberRoleId].memberCounter;    
  }

  function getAllMemberAddressById(uint32 _memberRoleId,uint _index)constant returns(address)
  {
     return memberRoleData[_memberRoleId].memberAddress[_index];
  }

  function getAuthrizedMember_againstRole(uint32 _memberRoleId)constant returns(address)
  {
     return authorizedAddress_againstRole[_memberRoleId];
  }

  /// @dev Gets the role name when given role id
  /// @param _memberRoleId Member role id
  /// @return  roleId Role id
  /// @return memberRoleName Member role name
  function getMemberRoleNameById(uint32 _memberRoleId) public constant returns(uint32 roleId,bytes32 memberRoleName)
  {
      memberRoleName = memberRole[_memberRoleId];
      roleId = _memberRoleId;
  }
  
  /// @dev Gets roles and members
  /// @return roleName Role name
  /// @return totalMembers Total members
  function getRolesAndMember()constant returns(bytes32[] roleName,uint[] totalMembers)
  {
      roleName=new bytes32[](memberRole.length);
      totalMembers=new uint[](memberRole.length);
      for(uint32 i=0; i < memberRole.length; i++)
      {
          bytes32 Name;
          (,Name) = getMemberRoleNameById(i);
          roleName[i]=Name;
          totalMembers[i] = getAllMemberLength(i);
      }
  }

  /// @dev Gets the role id which is authorized to categorize a proposal
  /// @return roleId Role id of the authorized member
  function getAuthorizedMemberId() public constant returns(uint8 roleId)
  {
       roleId = authorizedAddress_toCategorize;
  }

  /// @dev Gets total number of member roles available
  /// @return length Total member roles' length
  function getTotalMemberRoles() public constant returns(uint)
  {
    return memberRole.length;
  }
}