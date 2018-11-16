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

pragma solidity 0.4.24;
import "./imports/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./imports/openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "./imports/govern/Governed.sol";


contract MemberRoles is Governed {
    event MemberRole(uint256 indexed roleId, bytes32 roleName, string roleDescription);
    using SafeMath for uint;
    enum Role { UnAssigned, AdvisoryBoard, TokenHolder }

    StandardToken public dAppToken;

    struct MemberRoleDetails {
        uint memberCounter;
        mapping(address => bool) memberActive;
        address[] memberAddress;
    }

    mapping(uint => address) internal authorizedAddressAgainstRole;
    mapping(uint => MemberRoleDetails) internal memberRoleData;
    uint public memberRoleLength;
    bool internal constructorCheck;
    
    modifier checkRoleAuthority(uint _memberRoleId) {
        if (authorizedAddressAgainstRole[_memberRoleId] != address(0))
            require(msg.sender == authorizedAddressAgainstRole[_memberRoleId]);
        else
            require(isAuthorizedToGovern(msg.sender));
        _;
    }

    function memberRolesInitiate(bytes32 _dAppName, address _dAppToken, address _firstAB) public {
        require(!constructorCheck);
        dappName = _dAppName;
        dAppToken = StandardToken(_dAppToken);
        addInitialMemberRoles(_firstAB);
        constructorCheck = true;
    }

    function addInitialMemberRoles(address _firstAB) internal {
        emit MemberRole(uint(Role.UnAssigned), "Everyone", "Professionals that are a part of the GBT network");
        emit MemberRole(
            uint(Role.AdvisoryBoard),
            "Advisory Board",
            "Selected few members that are deeply entrusted by the dApp. An ideal advisory board should be a mix of skills of domain, governance,research, technology, consulting etc to improve the performance of the dApp."); //solhint-disable-line
        emit MemberRole(
            uint(Role.TokenHolder),
            "Token Holder",
            "Represents all users who hold dApp tokens. This is the most general category and anyone holding token balance is a part of this category by default."); //solhint-disable-line
        memberRoleLength = 3;

        memberRoleData[1].memberCounter++;
        memberRoleData[1].memberActive[_firstAB] = true;
        memberRoleData[1].memberAddress.push(_firstAB);
    }

    /// @dev To Initiate default settings whenever the contract is regenerated!
    function updateDependencyAddresses() public pure { //solhint-disable-line
    }

    /// @dev just to adhere to GovBlockss' Upgradeable interface
    function changeMasterAddress(address _masterAddress) public pure { //solhint-disable-line
    }

    /// @dev Get All role ids array that has been assigned to a member so far.
    function getRoleIdByAddress(address _memberAddress) public view returns(uint[] assignedRoles) {
        uint length = memberRoleLength;
        uint j = 0;
        assignedRoles = new uint[](length);
        for (uint i = 1; i < length; i++) {
            if (memberRoleData[i].memberActive[_memberAddress]) {
                assignedRoles[j] = i;
                j++;
            }
        }
        if (dAppToken.balanceOf(_memberAddress) > 0) {
            assignedRoles[j] = uint(Role.TokenHolder);
        }

        return assignedRoles;
    }

    /// @dev Returns true if the given role id is assigned to a member.
    /// @param _memberAddress Address of member
    /// @param _roleId Checks member's authenticity with the roleId.
    /// i.e. Returns true if this roleId is assigned to member
    function checkRoleIdByAddress(address _memberAddress, uint _roleId) public view returns(bool) {
        if (_roleId == uint(Role.UnAssigned))
            return true;
        else if (_roleId == uint(Role.TokenHolder)) {
            if (dAppToken.balanceOf(_memberAddress) > 0)
                return true;
            else
                return false;
        }
        else if (memberRoleData[_roleId].memberActive[_memberAddress]) //solhint-disable-line
            return true;
        else
            return false;
    }

    /// @dev Assign or Delete a member from specific role.
    /// @param _memberAddress Address of Member
    /// @param _roleId RoleId to update
    /// @param _typeOf typeOf is set to be True if we want to assign this role to member, False otherwise!
    function updateMemberRole(
        address _memberAddress,
        uint _roleId,
        bool _typeOf
    )
        public
        checkRoleAuthority(_roleId)
    {
        require( _roleId != uint(Role.TokenHolder),"Membership to Token holder is detected automatically");
        if (_typeOf) {
            if (!memberRoleData[_roleId].memberActive[_memberAddress]) {
                memberRoleData[_roleId].memberCounter = SafeMath.add(memberRoleData[_roleId].memberCounter, 1);
                memberRoleData[_roleId].memberActive[_memberAddress] = true;
                memberRoleData[_roleId].memberAddress.push(_memberAddress);
            }
        } else {
            require(memberRoleData[_roleId].memberActive[_memberAddress]);
            memberRoleData[_roleId].memberCounter = SafeMath.sub(memberRoleData[_roleId].memberCounter, 1);
            delete memberRoleData[_roleId].memberActive[_memberAddress];
        }
    }

    /// @dev Change Member Address who holds the authority to Add/Delete any member from specific role.
    /// @param _roleId roleId to update its Authorized Address
    /// @param _newCanAddMember New authorized address against role id
    function changeCanAddMember(uint _roleId, address _newCanAddMember) public checkRoleAuthority(_roleId) {
        authorizedAddressAgainstRole[_roleId] = _newCanAddMember;
    }

    /// @dev Adds new member role
    /// @param _newRoleName New role name
    /// @param _roleDescription New description hash
    /// @param _canAddMembers Authorized member against every role id
    function addNewMemberRole(
        bytes32 _newRoleName, 
        string _roleDescription, 
        address _canAddMembers
    )
        public
        onlyAuthorizedToGovern
    {
        authorizedAddressAgainstRole[memberRoleLength] = _canAddMembers;
        emit MemberRole(memberRoleLength, _newRoleName, _roleDescription);
        SafeMath.add(memberRoleLength,1);
    }

    /// @dev Gets the member addresses assigned by a specific role
    /// @param _memberRoleId Member role id
    /// @return roleId Role id
    /// @return allMemberAddress Member addresses of specified role id
    function getAllAddressByRoleId(uint _memberRoleId) public view returns(uint, address[] allMemberAddress) {
        uint length = memberRoleData[_memberRoleId].memberAddress.length;
        uint j;
        uint i;
        address[] memory tempAllMemberAddress = new address[](memberRoleData[_memberRoleId].memberCounter);
        for (i = 0; i < length; i++) {
            address member = memberRoleData[_memberRoleId].memberAddress[i];
            if (memberRoleData[_memberRoleId].memberActive[member]) //solhint-disable-line
            {
                tempAllMemberAddress[j] = member;
                j++;
            }
        }
        allMemberAddress = new address[](j);
        for (i = 0; i < j; i++) {
            allMemberAddress[i] = tempAllMemberAddress[i];
        }
        return (_memberRoleId, allMemberAddress);
    }

    /// @dev Gets all members' length
    /// @param _memberRoleId Member role id
    /// @return memberRoleData[_memberRoleId].memberAddress.length Member length
    function getAllMemberLength(uint _memberRoleId) public view returns(uint) {
        return memberRoleData[_memberRoleId].memberCounter;
    }

    /// @dev Return Member address at specific index against Role id.
    function getMemberAddressByRoleAndIndex(uint _memberRoleId, uint _index) public view returns(address) {
        return memberRoleData[_memberRoleId].memberAddress[_index];
    }

    /// @dev Return member address who holds the right to add/remove any member from specific role.
    function getAuthrizedMemberAgainstRole(uint _memberRoleId) public view returns(address) {
        return authorizedAddressAgainstRole[_memberRoleId];
    }

   
    /// @dev Return total number of members assigned against each role id.
    /// @return totalMembers Total members in particular role id
    function getMemberLengthForAllRoles() public view returns(uint[] totalMembers) {
        totalMembers = new uint[](memberRoleLength);
        for (uint i = 0; i < memberRoleLength; i++) {
            totalMembers[i] = getAllMemberLength(i);
        }
    }
    
}