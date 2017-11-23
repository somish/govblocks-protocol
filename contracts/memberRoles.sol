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
// import "./Ownable.sol";
import "./zeppelin-solidity/contracts/ownership/Ownable.sol";


contract  memberRoles is Ownable{

  string[] memberRole;
  uint public categorizeAuthRoleid;

  mapping (address=>uint) memberAddressToMemberRole;
  mapping (uint=>address) memberRoleToMemberAddress;

  function memberRoles()
  {
    memberRole.push("Member");
    memberRole.push("Advisory Board");
    memberRole.push("Expert");
    categorizeAuthRoleid=1;
  }

  /// @dev Get the role id assigned to a member when giving memberAddress
  function getMemberRoleIdByAddress(address _memberAddress) public constant returns(uint memberRoleId)
  {
     memberRoleId = memberAddressToMemberRole[_memberAddress];
  }

  /// @dev Get that member address assigned as a specific role when giving member role Id.
  function getMemberAddressByRoleId(uint _memberRoleId) public constant returns(address memberAddress)
  {
      memberAddress = memberRoleToMemberAddress[_memberRoleId];
  }

  /// @dev Add new member role for governance.
  function addNewMemberRole(string _newRoleName) onlyOwner
  {
      memberRole.push(_newRoleName);  
  }
  
  /// @dev Get the role name whem giving role Id.
  function getMemberRoleNameById(uint _memberRoleId) public constant returns(string memberRoleName)
  {
      memberRoleName = memberRole[_memberRoleId];
  }
  
  /// @dev Assign role to a member when giving member address and role id
  function assignMemberRole(address _memberAddress,uint _memberRoleId) onlyOwner
  {
      memberAddressToMemberRole[_memberAddress] = 1;
      memberRoleToMemberAddress[_memberRoleId] = _memberAddress;
  }

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


}
