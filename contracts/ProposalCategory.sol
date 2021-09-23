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

import "./interfaces/IProposalCategory.sol";
import "./external/govern/Governed.sol";
import "./MemberRoles.sol";

// FIXME need concept of quorum? - didn't understand
// FIXME add action hash of the functions
// FIXME need editCategory? - merge update/editCategory from nexus

contract ProposalCategory is IProposalCategory, Governed {

    bool public constructorCheck;
    MemberRoles internal mr;
    // FIXME no need - need
    IMaster internal ms;

    struct CategoryStruct {
        uint memberRoleToVote;
        uint majorityVotePerc;
        uint quorumPerc;
        uint[] allowedToCreateProposal;
        uint closingTime;
        uint minStake;
    }

    struct CategoryAction {
        uint defaultIncentive;
        address contractAddress;
        bytes2 contractName;
    }
    
    CategoryStruct[] internal allCategory;
    mapping (uint => CategoryAction) internal categoryActionData;
    mapping(uint256 => bytes) public categoryActionHashes;

    bool public initiated;

    // FIXME add category action hash - changes from nexus

    // Look if need proposalCategoryInitiate() - prem
    
    /// @dev Adds new category
    /// @param _name Category name
    /// @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
    /// @param _majorityVotePerc Majority Vote threshold for Each voting layer
    /// @param _quorumPerc minimum threshold percentage required in voting to calculate result
    /// @param _allowedToCreateProposal Member roles allowed to create the proposal
    /// @param _closingTime Vote closing time for Each voting layer
    /// @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
    /// @param _contractAddress address of contract to call after proposal is accepted
    /// @param _contractName name of contract to be called after proposal is accepted
    /// @param _incentives rewards to distributed after proposal is accepted
    function addCategory(
        string memory _name, 
        uint _memberRoleToVote,
        uint _majorityVotePerc, 
        uint _quorumPerc,
        uint[] memory _allowedToCreateProposal,
        uint _closingTime,
        string memory _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint[] memory _incentives,
        string memory _functionHash
    ) 
        external
        override
        onlyAuthorizedToGovern
    {
        require(
            _quorumPerc <= 100 && _majorityVotePerc <= 100,
            "Invalid percentage"
        );

        // check if need to add check for valid mr

        require(
            (_contractName == "EX" && _contractAddress == address(0)) ||
                bytes(_functionHash).length > 0,
            "Wrong parameters passed"
        );
        
        _addCategory(
            _name, 
            _memberRoleToVote,
            _majorityVotePerc, 
            _quorumPerc,
            _allowedToCreateProposal,
            _closingTime,
            _actionHash,
            _contractAddress,
            _contractName,
            _incentives
        );

        bytes memory _encodedHash = abi.encodeWithSignature(_functionHash);
        if (
            bytes(_functionHash).length > 0 &&
            _encodedHash.length == 4
        ) {
            
            categoryActionHashes[allCategory.length - 1] = _encodedHash;
        }
    }

    /// @dev Updates category details
    /// @param _categoryId Category id that needs to be updated
    /// @param _name Category name
    /// @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
    /// @param _allowedToCreateProposal Member roles allowed to create the proposal
    /// @param _majorityVotePerc Majority Vote threshold for Each voting layer
    /// @param _quorumPerc minimum threshold percentage required in voting to calculate result
    /// @param _closingTime Vote closing time for Each voting layer
    /// @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
    /// @param _contractAddress address of contract to call after proposal is accepted
    /// @param _contractName name of contract to be called after proposal is accepted
    /// @param _incentives rewards to distributed after proposal is accepted
    function updateCategory(
        uint _categoryId, 
        string memory _name, 
        uint _memberRoleToVote, 
        uint _majorityVotePerc, 
        uint _quorumPerc,
        uint[] memory _allowedToCreateProposal,
        uint _closingTime,
        string memory _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint[] memory _incentives,
        string memory _functionHash
    )
        public
        override
        onlyAuthorizedToGovern //solhint-disable
    { 
        require(_verifyMemberRoles(_memberRoleToVote, _allowedToCreateProposal) == 0, "Invalid Role");

        require(
            _quorumPerc <= 100 && _majorityVotePerc <= 100,
            "Invalid percentage"
        );

        require(
            (_contractName == "EX" && _contractAddress == address(0)) ||
                bytes(_functionHash).length > 0,
            "Wrong parameters passed"
        );

        delete categoryActionHashes[_categoryId];
        if (
            bytes(_functionHash).length > 0 &&
            abi.encodeWithSignature(_functionHash).length == 4
        ) {
            categoryActionHashes[_categoryId] = abi.encodeWithSignature(
                _functionHash
            );
        }
        allCategory[_categoryId].memberRoleToVote = _memberRoleToVote;
        allCategory[_categoryId].majorityVotePerc = _majorityVotePerc;
        allCategory[_categoryId].closingTime = _closingTime;
        allCategory[_categoryId].allowedToCreateProposal = _allowedToCreateProposal;
        allCategory[_categoryId].minStake = _incentives[0];
        allCategory[_categoryId].quorumPerc = _quorumPerc;
        categoryActionData[_categoryId].defaultIncentive = _incentives[1];
        categoryActionData[_categoryId].contractName = _contractName;
        categoryActionData[_categoryId].contractAddress = _contractAddress;
        emit Category(_categoryId, _name, _actionHash);
    }

    /// @dev gets category details
    function category(uint _categoryId) external override view returns(uint, uint, uint, uint, uint[] memory, uint, uint) {
        return(
            _categoryId,
            allCategory[_categoryId].memberRoleToVote,
            allCategory[_categoryId].majorityVotePerc,
            allCategory[_categoryId].quorumPerc,
            allCategory[_categoryId].allowedToCreateProposal,
            allCategory[_categoryId].closingTime,
            allCategory[_categoryId].minStake
        );
    }

    // check if need it or merge it with below
    // function categoryAction(uint _categoryId) external override view returns(uint, address, bytes2, uint) {
    //     return(
    //         _categoryId,
    //         categoryActionData[_categoryId].contractAddress,
    //         categoryActionData[_categoryId].contractName,
    //         categoryActionData[_categoryId].defaultIncentive
    //     );
    // }

    /**
     * @dev Gets the category action details of a category id
     * @param _categoryId is the category id in concern
     * @return the category id
     * @return the contract address
     * @return the contract name
     * @return the default incentive
     * @return action function hash
     */
    function categoryActionDetails(uint256 _categoryId)
        external
        view
        returns (
            uint256,
            address,
            bytes2,
            uint256,
            bytes memory
        )
    {
        return (
            _categoryId,
            categoryActionData[_categoryId].contractAddress,
            categoryActionData[_categoryId].contractName,
            categoryActionData[_categoryId].defaultIncentive,
            categoryActionHashes[_categoryId]
        );
    }

    /// @dev Gets Total number of categories added till now
    function totalCategories() external override view returns(uint) {
        return allCategory.length;
    }

    ///@dev just to follow the interface
    function updateDependencyAddresses() public { //solhint-disable-line
        // FIXME take ms address from msg.sender - anyone can call function
        ms = IMaster(masterAddress);
        mr = MemberRoles(ms.getLatestAddress('MR'));
        if (!constructorCheck) {
            constructorCheck = true;
            proposalCategoryInitiate();
        }
    }

    /// @dev just to adhere to GovBlockss' Upgradeable interface
    function changeMasterAddress(address _masterAddress) public { //solhint-disable-line
        if (address(masterAddress) == address(0))
            masterAddress = _masterAddress;
        else {
            require(msg.sender == masterAddress);
            masterAddress = _masterAddress;
        }
    }

    function _verifyMemberRoles(uint _memberRoleToVote, uint[] memory _allowedToCreateProposal) 
    internal view returns(bool) { 
        uint totalRoles = mr.totalRoles();
        if (_memberRoleToVote >= totalRoles) {
            return false;
        }
        for (uint i = 0; i < _allowedToCreateProposal.length; i++) {
            if (_allowedToCreateProposal[i] >= totalRoles) {
                return false;
            }
        }
        return true;
    }

    //FixME correct func argument - prem
    /// @dev Initiates Default settings for Proposal Category contract (Adding default categories)
    function proposalCategoryInitiate() internal { //solhint-disable-line
        // _addInitialCategories("Uncategorized", "", "EX", 0, 0);
        // _addInitialCategories("Add new member role", "QmQFnBep7AyMYU3LJDuHSpTYatnw65XjHzzirrghtZoR8U", "MR");
        // _addInitialCategories("Update member role", "QmXMzSViLBJ22P9oj51Zz7isKTRnXWPHZcQ5hzGvvWD3UV", "MR");
        // _addInitialCategories("Add new category", "QmYzBtW5mRMwHwKQUmRnwdXgq733WNzN5fo2yNPpkVG9Ng", "PC");
        // _addInitialCategories("Edit category", "QmcVNykyhjni7GFk8x1GrL3idzc6vxz4vNJLHPS9vJ79Qc", "PC");
        // _addInitialCategories("Change dApp Token Proxy", "QmPR9K6BevCXRVBxWGjF9RV7Pmtxr7D4gE3qsZu5bzi8GK", "MS");
        // _addInitialCategories("Transfer Ether", "QmRUmxw4xmqTN6L2bSZEJfmRcU1yvVWoiMqehKtqCMAaTa", "GV");
        // _addInitialCategories("Transfer Token", "QmbvmcW3zcAnng3FWgP5bHL4ba9kMMwV9G8Y8SASqrvHHB", "GV");
        // _addInitialCategories("Add new version", "QmeMBNn9fs5xYVFVsN8HgupMTfgXdyz4vkLPXakWd2BY3w", "MS");
        // _addInitialCategories("Add new contract", "QmWP3P58YcmveHeXqgsBCRmDewTYV1QqeQqBmRkDujrDLR", "MS");
        // _addInitialCategories(
        //     "Upgrade a contract Implementation",
        //     "Qme4hGas6RuDYk9LKE2XkK9E46LNeCBUzY12DdT5uQstvh",
        //     "MS"
        // );
        // _addInitialCategories(
        //     "Upgrade a contract proxy",
        //     "QmUNGEn7E2csB3YxohDxBKNqvzwa1WfvrSH4TCCFD9DZsg",
        //     "MS"
        // );
        // _addInitialCategories("Resume Proposal", "QmQPWVjmv2Gt2Dzt1rxmFkHCptFSdtX4VC5g7VVNUByLv1", "GV");
        // _addInitialCategories("Pause Proposal", "QmWWoiRZCmi61LQKpGyGuKjasFVpq8JzbLPvDhU8TBS9tk", "GV");
        // _addInitialCategories("Others, not specified", "", "EX");
    }

    /// @dev Adds new category
    /// @param _name Category name
    /// @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
    /// @param _majorityVotePerc Majority Vote threshold for Each voting layer
    /// @param _quorumPerc minimum threshold percentage required in voting to calculate result
    /// @param _allowedToCreateProposal Member roles allowed to create the proposal
    /// @param _closingTime Vote closing time for Each voting layer
    /// @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
    /// @param _contractAddress address of contract to call after proposal is accepted
    /// @param _contractName name of contract to be called after proposal is accepted
    /// @param _incentives rewards to distributed after proposal is accepted
    function _addCategory(
        string memory _name, 
        uint _memberRoleToVote,
        uint _majorityVotePerc, 
        uint _quorumPerc,
        uint[] memory _allowedToCreateProposal,
        uint _closingTime,
        string memory _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint[] memory _incentives
    ) 
        internal
    {
        require(
            _verifyMemberRoles(_memberRoleToVote, _allowedToCreateProposal),
            "Invalid Role"
        );
        allCategory.push(
            CategoryStruct(
                _memberRoleToVote,
                _majorityVotePerc,
                _quorumPerc,
                _allowedToCreateProposal,
                _closingTime,
                _incentives[0]
            )
        );
        uint categoryId = allCategory.length - 1;
        categoryActionData[categoryId] = CategoryAction(_incentives[1], _contractAddress, _contractName);
        emit Category(categoryId, _name, _actionHash);
    }

    function _addInitialCategories(
        string memory _name,
        string memory _solutionHash,
        bytes2 _contractName,
        string memory _actionHash,
        uint256 _majorityVotePerc,
        uint256 _memberRoleToVote
    ) 
        internal 
    {
        uint[] memory allowedToCreateProposal = new uint[](2);
        uint[] memory stakeIncentive = new uint[](2);    
        uint256 closingTime = 3 days;    
        allowedToCreateProposal[0] = 1;
        allowedToCreateProposal[1] = 2;
        stakeIncentive[0] = 0;
        stakeIncentive[1] = 0;
        if (bytes(_actionHash).length > 0) {
            categoryActionHashes[allCategory.length] = abi.encodeWithSignature(
                _actionHash
            );
        }
        _addCategory(
                _name,
                _memberRoleToVote,
                _majorityVotePerc,
                25,
                allowedToCreateProposal,
                closingTime,
                _solutionHash,
                address(0),
                _contractName,
                stakeIncentive
            );
    }


}