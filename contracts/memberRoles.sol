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
import "./Ownable.sol";
import "./governanceData.sol";
import "./BasicToken.sol";
// import "./zeppelin-solidity/contracts/ownership/Ownable.sol";

contract  memberRoles
{

  bytes32[] memberRole;
  uint categorizeAuthRoleid;
  string memberRoleDescHash;
  uint8 public constructorCheck;
  Master M1; 
  address masterAddress;
  address GDAddress;
  address BTAddress;
  BasicToken BT;
  governanceData GD;

  struct memberRoleDetails
  {
    uint memberCounter;
    mapping(address=>uint)  memberActive;
    address[] memberAddress;
  }

  mapping(uint=>memberRoleDetails) memberRoleData;
  mapping (address=>uint) memberAddressToMemberRole;

  function MemberRolesInitiate()
  {
    require(constructorCheck == 0);
        memberRole.push("");
        memberRole.push("Advisory Board");
        memberRole.push("Token Holder");
        categorizeAuthRoleid=1;
        M1=Master(masterAddress);
        address ownAddress = M1.owner();
        updateMemberRole(ownAddress,1,1);
        setRoleDescHash("QmTDisHekKVCBc4JNHfdiiZNgFRqdPoNn69QbD2vwTeo9L");
        constructorCheck =1;
  }

  modifier onlyInternal {
      M1=Master(masterAddress);
      require(M1.isInternal(msg.sender) == 1);
      _; 
  }
  
  modifier onlyOwner {
      M1=Master(masterAddress);
      require(M1.isOwner(msg.sender) == 1);
      _; 
  }
  
  /// @dev Change master's contract address
  function changeMasterAddress(address _masterContractAddress) 
  {
      if(masterAddress == 0x000)
          masterAddress = _masterContractAddress;
      else
      {
          M1=Master(masterAddress);
          require(M1.isInternal(msg.sender) == 1);
              masterAddress = _masterContractAddress;
      }
  }

  function changeAllContractAddress(address _GDAddress)
  {
    GDAddress = _GDAddress;
  }

  function getRoleDescHash()constant returns(string)
  {
    return memberRoleDescHash;
  }

  /// @dev Get the role id assigned to a member when giving memberAddress
  function getMemberRoleIdByAddress(address _memberAddress) public constant returns(uint memberRoleId)
  {
      M1=Master(masterAddress); address tokenAddress;
      tokenAddress=M1.getDappTokenAddress();
      BT=BasicToken(tokenAddress);
      // memberRoleId = memberAddressToMemberRole[_memberAddress];
      
      if(memberRoleId >=1)
          memberRoleId = memberAddressToMemberRole[_memberAddress];
      else if(BT.balanceOf(_memberAddress) <= 0)
          memberRoleId = memberAddressToMemberRole[_memberAddress];
      else
          memberRoleId = 2;
  }

  /// @dev Get that member address assigned as a specific role when giving member role Id.
  function getMemberAddressByRoleId(uint _memberRoleId) public constant returns(uint roleId,address[] allMemberAddress)
  {
      roleId = _memberRoleId;
      return (roleId,memberRoleData[_memberRoleId].memberAddress);
  }

  function getAllMemberLength(uint _memberRoleId) public constant returns(uint)
  {
    return memberRoleData[_memberRoleId].memberAddress.length;    
  }
  
  /// @dev Add new member role for governance.
  function addNewMemberRole(bytes32 _newRoleName,string _newDescHash) 
  {
      memberRole.push(_newRoleName);
      memberRoleDescHash = _newDescHash;  
  }

  function setRoleDescHash(string _newDescHash)
  {
     memberRoleDescHash = _newDescHash;
  }
  
  /// @dev Get the role name whem giving role Id.
  function getMemberRoleNameById(uint _memberRoleId) public constant returns(uint roleId,bytes32 memberRoleName)
  {
      memberRoleName = memberRole[_memberRoleId];
      roleId = _memberRoleId;
  }
  
  function getRolesAndMember()constant returns(bytes32[] roleName,uint[] totalMembers)
  {
      roleName=new bytes32[](memberRole.length);
      totalMembers=new uint[](memberRole.length);
      for(uint i=0; i < memberRole.length; i++)
      {
          bytes32 Name;
          (,Name) = getMemberRoleNameById(i);
          roleName[i]=Name;
          totalMembers[i] = getAllMemberLength(i);
      }
  }

  function updateMemberRole(address _memberAddress,uint _memberRoleId,uint8 _typeOf)
  {
      if(_typeOf == 1)
      {
        require(memberRoleData[_memberRoleId].memberActive[_memberAddress] == 0);
        memberRoleData[_memberRoleId].memberCounter = memberRoleData[_memberRoleId].memberCounter+1;
        memberRoleData[_memberRoleId].memberActive[_memberAddress] = 1;
        memberAddressToMemberRole[_memberAddress] = _memberRoleId;
        memberRoleData[_memberRoleId].memberAddress.push(_memberAddress);
      }
      else
      {
        require(memberRoleData[_memberRoleId].memberActive[_memberAddress] == 0);
        memberRoleData[_memberRoleId].memberCounter = memberRoleData[_memberRoleId].memberCounter+1;
        memberRoleData[_memberRoleId].memberActive[_memberAddress] = 1;
        memberAddressToMemberRole[_memberAddress] = _memberRoleId;
        memberRoleData[_memberRoleId].memberAddress.push(_memberAddress);
      }
  }

  // /// @dev Assign role to a member when giving member address and role id
  // function assignMemberRole(address _memberAddress,uint _memberRoleId) onlyOwner
  // {
  //     require(memberRoleData[_memberRoleId].memberActive[_memberAddress] == 0);
  //     memberRoleData[_memberRoleId].memberCounter = memberRoleData[_memberRoleId].memberCounter+1;
  //     memberRoleData[_memberRoleId].memberActive[_memberAddress] = 1;
  //     memberAddressToMemberRole[_memberAddress] = _memberRoleId;
  //     memberRoleData[_memberRoleId].memberAddress.push(_memberAddress);
  // }

  // function removeMember(address _memberAddress,uint _memberRoleId) onlyOwner
  // {
  //     require(memberRoleData[_memberRoleId].memberActive[_memberAddress] == 1);
  //     memberRoleData[_memberRoleId].memberCounter = memberRoleData[_memberRoleId].memberCounter-1;
  //     memberRoleData[_memberRoleId].memberActive[_memberAddress] = 0;
  //     memberAddressToMemberRole[_memberAddress] = 0;
  //     // memberRoleData[_memberRoleId].memberAddress.push(_memberAddress);
  // }

  /// @dev Get the role id which is authorized to categorize a proposal.
  function getAuthorizedMemberId() public constant returns(uint roleId)
  {
       roleId = categorizeAuthRoleid;
  }

  /// @dev Change the role id that is authorized to categorize the proposal. (Only owner can do that)
  function changeAuthorizedMemberId(uint _roleId) onlyOwner public
  {
     categorizeAuthRoleid = _roleId;
  }

  /// @dev Get Total number of member Roles available.
  function getTotalMemberRoles() public constant returns(uint length)
  {
    return memberRole.length;
  }


}