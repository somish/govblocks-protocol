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

pragma solidity ^0.4.24;
import "./Master.sol";
import "./SafeMath.sol";
import "./Upgradeable.sol";


contract MemberRoles is Upgradeable {
    event MemberRole(uint256 indexed roleId, bytes32 roleName, string roleDescription, bool limitedValidity);
    using SafeMath for uint;
    uint public authorizedAddressToCategorize;
    address public masterAddress;
    Master internal master;
    uint constant UINT_MAX = uint256(0) - uint256(1);

    struct MemberRoleDetails {
        bytes32 roleName;
        uint memberCounter;
        mapping(address => bool) memberActive;
        bool limitedValidity;
        mapping(address => uint) validity;
        address[] memberAddress;
    }

    mapping(uint => address) public authorizedAddressAgainstRole;
    MemberRoleDetails[] public memberRoleData;
    mapping(address => uint16[]) public memberRoles;

    modifier onlyInternal {
        master = Master(masterAddress);
        require(master.isInternal(msg.sender));
        _;
    }

    modifier checkRoleAuthority(uint _memberRoleId) {
        master = Master(masterAddress);
        require(msg.sender == authorizedAddressAgainstRole[_memberRoleId] || master.isOwner(msg.sender));
        _;
    }

    modifier onlySV { //isInternal only for debugging, will be removed before launch
        master = Master(masterAddress);
        require( 
            master.isInternal(msg.sender) 
            || master.getLatestAddress("SV") == msg.sender
        );
        _;
    }

    /// @dev Returns true if the caller address is Master's contract address
    function isMaster() public view returns(bool) {
        if (msg.sender == masterAddress)
            return true;
    }

    /// @dev Changes Master's contract address 
    /// @param _masterContractAddress New master address
    function changeMasterAddress(address _masterContractAddress) public {
        if (masterAddress == address(0))
            masterAddress = _masterContractAddress;
        else {
            master = Master(masterAddress);
            require(master.isInternal(msg.sender));
            masterAddress = _masterContractAddress;
        }
    }

    /// @dev just to adhere to the interface
    function changeGBTSAddress(address _gbtAddress) public {
    }

    /// @dev To Initiate default settings whenever the contract is regenerated!
    function updateDependencyAddresses() public {
    }

    function getValidity(address _memberAddress, uint32 _roleId) public view returns (uint) {
        return memberRoleData[_roleId].validity[_memberAddress];
    }

    /// @dev Returns true if the given role id is assigned to a member.
    /// @param _memberAddress Address of member
    /// @param _roleId Checks member's authenticity with the roleId. 
    /// i.e. Returns true if this roleId is assigned to member
    function checkRoleIdByAddress(address _memberAddress, uint _roleId) public view returns(bool) {
        if (memberRoleData[_roleId].memberActive[_memberAddress] 
            && (!memberRoleData[_roleId].limitedValidity || memberRoleData[_roleId].validity[_memberAddress] > now))
            return true;
        else
            return false;
    }

    /// @dev Assign or Delete a member from specific role.
    /// @param _memberAddress Address of Member
    /// @param _roleId RoleId to update 
    /// @param _typeOf typeOf is set to be True if we want to assign this role to member, False to remove!

    function updateMemberRole(
        address _memberAddress, 
        uint32 _roleId, 
        bool _typeOf,
        uint _validity
    ) 
        public 
        checkRoleAuthority(_roleId) 
    {
        if (_typeOf) {
            require(!memberRoleData[_roleId].memberActive[_memberAddress]);
            memberRoleData[_roleId].memberCounter = memberRoleData[_roleId].memberCounter + 1;
            memberRoleData[_roleId].memberActive[_memberAddress] = true;
            memberRoleData[_roleId].memberAddress.push(_memberAddress);
            memberRoleData[_roleId].validity[_memberAddress] = _validity;
        } else {
            require(memberRoleData[_roleId].memberActive[_memberAddress]);
            memberRoleData[_roleId].memberCounter = memberRoleData[_roleId].memberCounter - 1;
            memberRoleData[_roleId].memberActive[_memberAddress] = false;
        }
    }

    /// @dev Change Member Address who holds the authority to Add/Delete any member from specific role.
    /// @param _roleId roleId to update its Authorized Address
    /// @param _newCanAddMember New authorized address against role id
    function changeCanAddMember(uint32 _roleId, address _newCanAddMember) public {
        if (authorizedAddressAgainstRole[_roleId] == address(0))
            authorizedAddressAgainstRole[_roleId] = _newCanAddMember;
        else {
            require(msg.sender == authorizedAddressAgainstRole[_roleId]);
            authorizedAddressAgainstRole[_roleId] = _newCanAddMember;
        }
    }

    /// @dev Changes the role id of the member who is authorized to categorize the proposal
    /// @param _roleId Role id of that member
    function changeAuthorizedMemberId(uint _roleId) public onlyOwner {
        authorizedAddressToCategorize = _roleId;
    }

    /// @dev Adds new member role
    /// @param _newRoleName New role name
    /// @param _roleDescription New description hash
    /// @param _canAddMembers Authorized member against every role id
    function addNewMemberRole(bytes32 _newRoleName, string _roleDescription, address _canAddMembers, bool _limitedValidity) 
        public 
        onlySV 
    {
        uint rolelength = getTotalMemberRoles();
        memberRoleData.push(new memberRoleData());
        memberRoleData[rolelength].limitedValidity = _limitedValidity;
        authorizedAddressAgainstRole[rolelength] = _canAddMembers;
        emit MemberRole(rolelength, _newRoleName, _roleDescription, _limitedValidity);
    }

    /// @dev Gets all members' length
    /// @param _memberRoleId Member role id
    /// @return memberRoleData[_memberRoleId].memberAddress.length Member length
    function getAllMemberLength(uint32 _memberRoleId) public view returns(uint) {
        return memberRoleData[_memberRoleId].memberCounter;
    }

    /// @dev Return Member address at specific index against Role id.
    function getAllMemberAddressById(uint32 _memberRoleId, uint _index) public view returns(address) {
        return memberRoleData[_memberRoleId].memberAddress[_index];
    }

    /// @dev Return member address who holds the right to add/remove any member from specific role.
    function getAuthrizedMemberAgainstRole(uint32 _memberRoleId) public view returns(address) {
        return authorizedAddressAgainstRole[_memberRoleId];
    }

    /// @dev Gets the role name when given role id
    /// @param _memberRoleId Role id to get the Role name details
    /// @return  roleId Same role id
    /// @return memberRoleName Role name against that role id.
    function getMemberRoleNameById(uint32 _memberRoleId) 
        public 
        view 
        returns(uint32 roleId, bytes32 memberRoleName) 
    {
        memberRoleName = memberRole[_memberRoleId];
        roleId = _memberRoleId;
    }

    /// @dev Return total number of members assigned against each role id.
    /// @return roleName Role name array is returned
    /// @return totalMembers Total members in particular role id
    function getRolesAndMember() public view returns(bytes32[] roleName, uint[] totalMembers) {
        roleName = new bytes32[](memberRole.length);
        totalMembers = new uint[](memberRole.length);
        for (uint32 i = 0; i < memberRole.length; i++) {
            bytes32 name;
            (, name) = getMemberRoleNameById(i);
            roleName[i] = name;
            totalMembers[i] = getAllMemberLength(i);
        }
    }

    /// @dev Gets the role id which is authorized to categorize a proposal
    function getAuthorizedMemberId() public view returns(uint8 roleId) {
        roleId = authorizedAddressToCategorize;
    }

    /// @dev Gets total number of member roles available
    function getTotalMemberRoles() public view returns(uint) {
        return memberRoleData.length;
    }

    /// @dev Add dApp Owner in Advisory Board Members.
    function setOwnerRole() internal {
        master = Master(masterAddress);
        address ownAddress = master.owner();
        memberRoleData[1].memberCounter = SafeMath.add32(memberRoleData[1].memberCounter, 1);
        memberRoleData[1].memberActive[ownAddress] = true;
        memberRoleData[1].memberAddress.push(ownAddress);
        memberRoleData[1].validity[ownAddress] = UINT_MAX;
    }

    /// @dev Get Total number of role ids that has been assigned to a member so far.
    function getRoleIdLengthByAddress(address _memberAddress) public view returns(uint64 count) {
        return memberRoles[_memberAddress].length;
    }
}
