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

pragma solidity ^ 0.4.8;
import "./governanceData.sol";
import "./ProposalCategory.sol";
import "./memberRoles.sol";
import "./Upgradeable.sol";
import "./Master.sol";
import "./SafeMath.sol";
import "./Pool.sol";

contract Action is Upgradeable{
    using SafeMath for uint;

    address masterAddress;
    GBTStandardToken GBTS;
    Master MS;
    memberRoles MR;
    ProposalCategory PC;
    governanceData GD;
    Pool P1;

    modifier onlyMaster {
        require(msg.sender == masterAddress);
        _;
    }

    function changeMasterAddress(address _masterContractAddress) {
        if (masterAddress == 0x000)
            masterAddress = _masterContractAddress;
        else {
            MS = Master(masterAddress);
            require(MS.isInternal(msg.sender) == true);
            masterAddress = _masterContractAddress;
        }
    }

    /// @dev updates dependancies
    function updateDependencyAddresses() {
        MS = Master(masterAddress);
        GD = governanceData(MS.getLatestAddress("GD"));
        MR = memberRoles(MS.getLatestAddress("MR"));
        PC = ProposalCategory(MS.getLatestAddress("PC"));
        P1 = Pool(MS.getLatestAddress("PL"));
    }

    /// @dev Changes GBT controller address
    /// @param _GBTSAddress New GBT controller address
    function changeGBTSAddress(address _GBTSAddress) onlyMaster {
        GBTS = GBTStandardToken(_GBTSAddress);
    }

    /// @dev Adds new member roles in dApp existing member roles
    /// @param _newRoleName Role name to add in dApp
    /// @param _roleDescription Description hash of this particular Role
    function addNewMemberRoleGB(bytes32 _newRoleName, string _roleDescription, address _canAddMembers) {
        MR.addNewMemberRole(_newRoleName, _roleDescription, _canAddMembers);
    }

    /// @dev Update existing Role data in dApp i.e. Assign/Remove any member from given role
    /// @param _gbUserName dApp name
    /// @param _memberAddress Address of who needs to be added/remove from specific role
    /// @param _memberRoleId Role id that details needs to be updated.
    /// @param _typeOf typeOf is set to be True if we want to assign this role to member, False otherwise!
    function updateMemberRoleGB(bytes32 _gbUserName, address _memberAddress, uint32 _memberRoleId, bool _typeOf) {
        MR.updateMemberRole(_memberAddress, _memberRoleId, _typeOf);
    }

    /// @dev Adds new category in dApp existing categories
    /// @param _gbUserName dApp name
    /// @param _descHash dApp description hash
    function addNewCategoryGB(bytes32 _gbUserName, string _descHash, uint8[] _memberRoleSequence, uint8[] _memberRoleMajorityVote, uint32[] _closingTime, uint64[] _stakeAndIncentive, uint8[] _rewardPercentage) {
        PC.addNewCategory(_descHash, _memberRoleSequence, _memberRoleMajorityVote, _closingTime, _stakeAndIncentive, _rewardPercentage);
    }

    /// @dev Updates category in dApp
    /// @param _gbUserName dApp name
    /// @param _categoryId Category id that details needs to be updated 
    /// @param _categoryData Category description hash having all the details 
    /// @param _roleName Voting Layer sequence in which the voting has to be performed.
    /// @param _majorityVote Majority Vote threshhold for Each voting layer
    /// @param _closingTime Vote closing time for Each voting layer
    /// @param _stakeAndIncentive array of minstake maxstake and incentive required against each category
    /// @param _rewardPercentage array of reward percentages for Proposal, Solution and Voting.
    function updateCategoryGB(bytes32 _gbUserName, uint _categoryId, string _categoryData, uint8[] _roleName, uint8[] _majorityVote, uint32[] _closingTime, uint64[] _stakeAndIncentive, uint8[] _rewardPercentage) {
        PC.updateCategory(_categoryId, _categoryData, _roleName, _majorityVote, _closingTime, _stakeAndIncentive, _rewardPercentage);
    }

    /// @dev Adds new sub category in GovBlocks
    /// @param _gbUserName dApp name
    /// @param _categoryName Name of the category
    /// @param _actionHash Automated Action hash has Contract Address and function name i.e. Functionality that needs to be performed after proposal acceptance.
    /// @param _mainCategoryId Id of main category
    function addNewSubCategoryGB(bytes32 _gbUserName, string _categoryName, string _actionHash, uint8 _mainCategoryId) {
        PC.addNewSubCategory(_categoryName, _actionHash, _mainCategoryId);
    }

    /// @dev Updates category in dApp
    /// @param _gbUserName dApp name
    /// @param _subCategoryId Id of subcategory that needs to be updated
    /// @param _actionHash Updated Automated Action hash i.e. Either contract address or function name is changed.
    function updateSubCategoryGB(bytes32 _gbUserName, uint8 _subCategoryId, string _actionHash) {
        PC.updateSubCategory(_subCategoryId, _actionHash);
    }

    /// @dev Configures global parameters against dApp i.e. Voting or Reputation parameters
    /// @param _gbUserName dApp name
    /// @param _typeOf Passing intials of the parameter name which value needs to be updated
    /// @param _value New value that needs to be updated    
    function configureGlobalParameters(bytes32 _gbUserName, bytes4 _typeOf, uint32 _value) {
        if (_typeOf == "APO") {
            GD.changeProposalOwnerAdd(_value);
        } else if (_typeOf == "AOO") {
            GD.changeSolutionOwnerAdd(_value);
        } else if (_typeOf == "AVM") {
            GD.changeMemberAdd(_value);
        } else if (_typeOf == "SPO") {
            GD.changeProposalOwnerSub(_value);
        } else if (_typeOf == "SOO") {
            GD.changeSolutionOwnerSub(_value);
        } else if (_typeOf == "SVM") {
            GD.changeMemberSub(_value);
        } else if (_typeOf == "GBTS") {
            GD.changeGBTStakeValue(_value);
        } else if (_typeOf == "MSF") {
            GD.changeMembershipScalingFator(_value);
        } else if (_typeOf == "SW") {
            GD.changeScalingWeight(_value);
        } else if (_typeOf == "QP") {
            GD.changeQuorumPercentage(_value);
        }
    }

    /// @dev converts pool eth to GBT
    /// @param _gbt number of GBT to buy
    function buyPoolGBT(uint _gbt) {
        P1.buyPoolGBT(_gbt);
    }
}