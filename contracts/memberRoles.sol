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

contract  memberRoles{

  string[] memberRole;
  uint public categorize_auth_roleid;

  mapping (address=>uint) memberAddressToMemberRole;
  mapping (uint=>address) memberRoleToMemberAddress;

  function memberRoles()
  {
    memberRole.push("Member");
    memberRole.push("Advisory Board");
    memberRole.push("Expert");
    categorize_auth_roleid=1;
  }

  function getMemberRoleIdByAddress(address _memberAddress) public constant returns(uint memberRoleId)
  {
     memberRoleId = memberAddressToMemberRole[_memberAddress];
  }

  function getMemberAddressByRoleId(uint _memberRoleId) public constant returns(address memberAddress)
  {
      memberAddress = memberRoleToMemberAddress[_memberRoleId];
  }

  function addNewMemberRole(string _newRoleName)
  {
      memberRole.push(_newRoleName);  
  }
  
  function getMemberRoleNameById(uint _memberRoleId) public constant returns(string memberRoleName)
  {
      memberRoleName = memberRole[_memberRoleId];
  }
  
  function assignMemberRole(address _memberAddress,uint _memberRoleId)
  {
      memberAddressToMemberRole[_memberAddress] = 1;
      memberRoleToMemberAddress[_memberRoleId] = _memberAddress;
  }

 function getAuthorizedMemberId() public constant returns(uint roleId)
 {
     roleId = categorize_auth_roleid;
 }
 


}
