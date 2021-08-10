// SPDX-License-Identifier: GNU

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

pragma solidity 0.8.0;

import "./interfaces/IMemberRoles.sol";
import "./external/lockable-token/LockableToken.sol";
import "./external/govern/Governed.sol";


contract MemberRoles is IMemberRoles, Governed {

    enum Role {
        UnAssigned,
        AdvisoryBoard,
        TokenHolder
    }

    LockableToken public dAppToken;

    struct MemberRoleDetails {
        mapping(address => bool) memberActive;
        address[] memberAddress;
        address authorized;
    }

    MemberRoleDetails[] internal memberRoleData;
    mapping ( uint => mapping (address => uint)) internal memberRoleIndex;
    bool internal constructorCheck;

    modifier checkRoleAuthority(uint _memberRoleId) {
        if (memberRoleData[_memberRoleId].authorized != address(0))
            require(msg.sender == memberRoleData[_memberRoleId].authorized);
        else
            require(isAuthorizedToGovern(msg.sender), "Not Authorized");
        _;
    }

    /// @dev To Initiate default settings whenever the contract is regenerated!
    function updateDependencyAddresses() public pure { //solhint-disable-line
    }

    /// @dev just to adhere to GovBlockss' Upgradeable interface
    function changeMasterAddress(address _masterAddress) public { //solhint-disable-line
        if (masterAddress == address(0)) {
            masterAddress = _masterAddress;
        } else {
            require(msg.sender == masterAddress);
            masterAddress = _masterAddress;
        }
    }

    function memberRolesInitiate(address _dAppToken, address _firstAB) external {
        require(!constructorCheck);
        dAppToken = LockableToken(_dAppToken);
        addInitialMemberRoles(_firstAB);
        constructorCheck = true;
    }

    function addInitialMemberRoles(address _firstAB) internal {
        _addRole("Unassigned", "Unassigned", address(0));
        _addRole(
            "Advisory Board",
            "Selected few members that are deeply entrusted by the dApp. An ideal advisory board should be a mix of skills of domain, governance, research, technology, consulting etc to improve the performance of the dApp.", //solhint-disable-line
            address(0)
        );
        _addRole(
            "Token Holder",
            "Represents all users who hold dApp tokens. This is the most general category and anyone holding token balance is a part of this category by default.", //solhint-disable-line
            address(0)
        );
        _updateRole(_firstAB, 1, true);
    }

    /// @dev Adds new member role
    /// @param _roleName New role name
    /// @param _roleDescription New description hash
    /// @param _authorized Authorized member against every role id
    function addRole( //solhint-disable-line
        bytes32 _roleName,
        string calldata _roleDescription,
        address _authorized
    )
    public
    override
    onlyAuthorizedToGovern {
        _addRole(_roleName, _roleDescription, _authorized);
    }

    /// @dev Assign or Delete a member from specific role.
    /// @param _memberAddress Address of Member
    /// @param _roleId RoleId to update
    /// @param _active active is set to be True if we want to assign this role to member, False otherwise!
    function updateRole( //solhint-disable-line
        address _memberAddress,
        uint _roleId,
        bool _active
    )
    public
    override
    checkRoleAuthority(_roleId) {
        _updateRole(_memberAddress, _roleId, _active);
    }

    /// @dev Return number of member roles
    function totalRoles() public override view returns(uint256) { //solhint-disable-line
        return memberRoleData.length;
    }

    /// @dev Change Member Address who holds the authority to Add/Delete any member from specific role.
    /// @param _roleId roleId to update its Authorized Address
    /// @param _newAuthorized New authorized address against role id
    function changeAuthorized(uint _roleId, address _newAuthorized) external override checkRoleAuthority(_roleId) { //solhint-disable-line
        memberRoleData[_roleId].authorized = _newAuthorized;
    }

    /// @dev Gets the member addresses assigned by a specific role
    /// @param _memberRoleId Member role id
    /// @return roleId Role id
    /// @return memberArray allMemberAddress Member addresses of specified role id
    function members(uint _memberRoleId) public override view returns(uint, address[] memory memberArray) { //solhint-disable-line
        // uint length = memberRoleData[_memberRoleId].memberAddress.length;
        // uint i;
        // uint j;
        // memberArray = new address[](memberRoleData[_memberRoleId].memberCounter);
        // for (i = 0; i < length; i++) {
        //     address member = memberRoleData[_memberRoleId].memberAddress[i];
        //     if (memberRoleData[_memberRoleId].memberActive[member] && ! _checkMemberInArray(member, memberArray)) { //solhint-disable-line
        //         memberArray[j] = member;
        //         j++;
        //     }
        // }
        
        return (_memberRoleId, memberRoleData[_memberRoleId].memberAddress);
        // return (_memberRoleId, memberArray);
    }

    /// @dev Gets all members' length
    /// @param _memberRoleId Member role id
    /// @return memberRoleData[_memberRoleId].memberCounter Member length
    function numberOfMembers(uint _memberRoleId) public override view returns(uint) { //solhint-disable-line
        return memberRoleData[_memberRoleId].memberAddress.length - 1;
        // return memberRoleData[_memberRoleId].memberCounter;
    }

    /// @dev Return member address who holds the right to add/remove any member from specific role.
    function authorized(uint _memberRoleId) public override view returns(address) { //solhint-disable-line
        return memberRoleData[_memberRoleId].authorized;
    }

    /// @dev Get All role ids array that has been assigned to a member so far.
    function roles(address _memberAddress) public override view returns(uint[] memory assignedRoles) { //solhint-disable-line
        uint length = memberRoleData.length;
        uint j = 0;
        uint i;
        uint[] memory tempAllMemberAddress = new uint[](length);
        for (i = 1; i < length; i++) {
            if (memberRoleIndex[i][_memberAddress] > 0) {
                tempAllMemberAddress[j] = i;
                j++;
            }
        }
        if (dAppToken.totalBalanceOf(_memberAddress) > 0) {
            tempAllMemberAddress[j] = uint(Role.TokenHolder);
            j++;
        }

        assignedRoles = new uint256[](j);
        for (i = 0; i < j; i++) {
            assignedRoles[i] = tempAllMemberAddress[i];
        }
        return assignedRoles;
    }

    /// @dev Returns true if the given role id is assigned to a member.
    /// @param _memberAddress Address of member
    /// @param _roleId Checks member's authenticity with the roleId.
    /// i.e. Returns true if this roleId is assigned to member
    function checkRole(address _memberAddress, uint _roleId) public override view returns(bool) { //solhint-disable-line
        if (_roleId == uint(Role.UnAssigned))
            return true;
        else if (_roleId == uint(Role.TokenHolder)) {
            if (dAppToken.totalBalanceOf(_memberAddress) > 0)
                return true;
            else
                return false;
        } else
            if (memberRoleIndex[_roleId][_memberAddress] > 0)
            // if (memberRoleData[_roleId].memberActive[_memberAddress]) //solhint-disable-line
                return true;
            else
                return false;
    }

    /// @dev Return total number of members assigned against each role id.
    /// @return totalMembers Total members in particular role id
    function getMemberLengthForAllRoles() public view returns(uint[] memory totalMembers) { //solhint-disable-line
        totalMembers = new uint[](memberRoleData.length);
        for (uint i = 0; i < memberRoleData.length; i++) {
            totalMembers[i] = numberOfMembers(i);
        }
    }

    /// @dev Internal call of update role
    function _updateRole(address _memberAddress,
        uint _roleId,
        bool _active) internal {
        require(_roleId != uint(Role.TokenHolder), "Membership to Token holder is detected automatically");
        uint memberIndex = memberRoleIndex[_roleId][_memberAddress];
        if (_active) {
            require(memberIndex == 0, "Member already exist");
            memberRoleIndex[_roleId][_memberAddress] = memberRoleData[_roleId].memberAddress.length;
            memberRoleData[_roleId].memberAddress.push(_memberAddress);
        } else {
            require(memberIndex > 0, "Member Doesn't exist");
            delete memberRoleIndex[_roleId][_memberAddress];
            if(memberRoleData[_roleId].memberAddress.length >2) {
                memberRoleData[_roleId].memberAddress[memberIndex] =
                    memberRoleData[_roleId].memberAddress[memberRoleData[_roleId].memberAddress.length - 1];
                memberRoleIndex[_roleId][memberRoleData[_roleId].memberAddress[memberIndex]] = memberIndex;
            }
            memberRoleData[_roleId].memberAddress.pop();
        }
    }

    /// @dev Adds new member role
    /// @param _roleName New role name
    /// @param _roleDescription New description hash
    /// @param _authorized Authorized member against every role id
    function _addRole(
        bytes32 _roleName,
        string memory _roleDescription,
        address _authorized
    ) internal {
        emit MemberRole(memberRoleData.length, _roleName, _roleDescription);
        MemberRoleDetails storage _newMemberRoleDetails = memberRoleData.push();
        _newMemberRoleDetails.memberAddress = new address[](1);
        _newMemberRoleDetails.authorized = _authorized;
    }

}