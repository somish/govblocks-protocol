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
import "./governanceData.sol";

contract  memberRoles
{
  event MemberRole(uint256 indexed roleId, bytes32 roleName, string roleDescription);
    
  bytes32[] memberRole;
  uint categorizeAuthRoleid;
  string memberRoleDescHash;
  uint8 public constructorCheck;
  Master M1; 
  governanceData GD;
  address masterAddress;
//   address GDAddress;
//   address BTAddress;
  address GBMAddress;
  BasicToken BT;

  struct memberRoleDetails
  {
    uint memberCounter;
    mapping(address=>uint)  memberActive;
    address[] memberAddress;
  }

  mapping(uint=>address) updateMemberRoles;
  mapping(uint=>memberRoleDetails) memberRoleData;
  mapping (address=>uint) memberAddressToMemberRole;


  /// @dev Initiates member roles
  /// @param _GBMAddress GovBlocks master address
  function MemberRolesInitiate(address _GBMAddress)
  {
    require(constructorCheck == 0);
        memberRole.push("");
        memberRole.push("Advisory Board");
        memberRole.push("Token Holder");
        categorizeAuthRoleid=1;
        M1=Master(masterAddress);
        address ownAddress = M1.owner();
        updateMemberRole(ownAddress,1,1);
        // changeRoleDescHash("QmTDisHekKVCBc4JNHfdiiZNgFRqdPoNn69QbD2vwTeo9L");
        GBMAddress = _GBMAddress;
        constructorCheck =1;
  }

  modifier onlyInternal 
  {
      M1=Master(masterAddress);
      require(M1.isInternal(msg.sender) == true);
      _; 
  }
  
  modifier onlyOwner 
  {
      M1=Master(masterAddress);
      require(M1.isOwner(msg.sender) == true);
      _; 
  }
  
  modifier onlyGBM
  {
        require(msg.sender == GBMAddress);
      _;
  }
  
  /// @dev Changes GovBlocks master address
  /// @param _GBMAddress New GovBlocks master address
  function changeGBMAddress(address _GBMAddress) onlyGBM
  {
      require(GBMAddress != 0x00);
      GBMAddress = _GBMAddress;
  }

  /// @dev Changes master's contract address
  /// @param _masterContractAddress New master address
  function changeMasterAddress(address _masterContractAddress) 
  {
      if(masterAddress == 0x000)
          masterAddress = _masterContractAddress;
      else
      {
          M1=Master(masterAddress);
          require(M1.isInternal(msg.sender) == true);
              masterAddress = _masterContractAddress;
      }
  }

//   function changeAllContractAddress(address _GDAddress) onlyInternal
//   {
//     GDAddress = _GDAddress;
//   }

  function changeAddress(bytes4 contractName, address contractAddress){
        if(contractName == 'GD'){
            GD = governanceData(contractAddress);
        }
    }

  /// @dev Gets role description hash
  /// @return memberRoleDescHash Member role description hash
  function getRoleDescHash()constant returns(string)
  {
    return memberRoleDescHash;
  }

  /// @dev Gets the role id assigned to a member when given member address
  /// @param _memberAddress Member address
  /// @return memberRoleId Role id of the member address
  function getMemberRoleIdByAddress(address _memberAddress) public constant returns(uint memberRoleId)
  {
      M1=Master(masterAddress); 
      address tokenAddress;
      tokenAddress=M1.getDappTokenAddress();
      BT=BasicToken(tokenAddress);
      memberRoleId = memberAddressToMemberRole[_memberAddress];
      
      if(memberRoleId >=1)
          memberRoleId = memberAddressToMemberRole[_memberAddress];
      else if(BT.balanceOf(_memberAddress) <= 0)
          memberRoleId = memberAddressToMemberRole[_memberAddress];
      else
          memberRoleId = 2;
  }

  /// @dev Gets the member addresses assigned by a specific role
  /// @param _memberRoleId Member role id
  /// @return roleId Role id
  /// @return allMemberAddress Member addresses of specified role id
  function getMemberAddressByRoleId(uint _memberRoleId) public constant returns(uint roleId,address[] allMemberAddress)
  {
      roleId = _memberRoleId;
      return (roleId,memberRoleData[_memberRoleId].memberAddress);
  }

  /// @dev Gets all members' length
  /// @param _memberRoleId Member role id
  /// @return memberRoleData[_memberRoleId].memberAddress.length Member length
  function getAllMemberLength(uint _memberRoleId) public constant returns(uint)
  {
    return memberRoleData[_memberRoleId].memberAddress.length;    
  }
  
  /// @dev Adds new member role
  /// @param _newRoleName New role name
  /// @param _roleDescription New description hash
  /// @param _canAddMembers Authorized member against every role id
  function addNewMemberRole(bytes32 _newRoleName,string _roleDescription, address _canAddMembers) 
  {
      require(msg.sender == GBMAddress);
      uint totalMembers = getTotalMemberRoles();
      memberRole.push(_newRoleName);  
      updateMemberRoles[totalMembers] = _canAddMembers;
      MemberRole(totalMembers, _newRoleName, _roleDescription);
  }
  
  /// @dev Changes member role id's changable member 
  /// @param _memberRoleId Member role id
  /// @param _newCanAddMember New canAddMember address
  function changeCanAddMember(uint _memberRoleId, address _newCanAddMember){
      require(msg.sender == updateMemberRoles[_memberRoleId]);
      updateMemberRoles[_memberRoleId] = _newCanAddMember;
  }
  
  /// @dev Gets the role name when given role id
  /// @param _memberRoleId Member role id
  /// @return  roleId Role id
  /// @return memberRoleName Member role name
  function getMemberRoleNameById(uint _memberRoleId) public constant returns(uint roleId,bytes32 memberRoleName)
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
      for(uint i=0; i < memberRole.length; i++)
      {
          bytes32 Name;
          (,Name) = getMemberRoleNameById(i);
          roleName[i]=Name;
          totalMembers[i] = getAllMemberLength(i);
      }
  }

  /// @dev Updates member role
  /// @param _memberAddress Member address
  /// @param _memberRoleId Member role id
  /// @param _typeOf Type of role id of the member
  function updateMemberRole(address _memberAddress,uint _memberRoleId,uint8 _typeOf)
  {
      require(msg.sender == GBMAddress || msg.sender == updateMemberRoles[_memberRoleId]);
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

  /// @dev Gets the role id which is authorized to categorize a proposal
  /// @return roleId Role id of the authorized member
  function getAuthorizedMemberId() public constant returns(uint roleId)
  {
       roleId = categorizeAuthRoleid;
  }

  /// @dev Changes the role id of the member who is authorized to categorize the proposal
  /// @param _roleId Role id of that member
  function changeAuthorizedMemberId(uint _roleId) onlyOwner public
  {
     categorizeAuthRoleid = _roleId;
  }

  /// @dev Gets total number of member roles available
  /// @return length Total member roles' length
  function getTotalMemberRoles() public constant returns(uint length)
  {
    return memberRole.length;
  }
}