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
import "./interfaces/IProposalCategory.sol";
import "./imports/govern/Governed.sol";


contract ProposalCategory is IProposalCategory, Governed {

    bool internal constructorCheck;

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
        string _name, 
        uint _memberRoleToVote,
        uint _majorityVotePerc, 
        uint _quorumPerc,
        uint[] _allowedToCreateProposal,
        uint _closingTime,
        string _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint[] _incentives
    ) 
        external
        onlyAuthorizedToGovern 
    {
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
        string _name, 
        uint _memberRoleToVote, 
        uint _majorityVotePerc, 
        uint _quorumPerc,
        uint[] _allowedToCreateProposal,
        uint _closingTime,
        string _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint[] _incentives
    )
        public
        onlyAuthorizedToGovern //solhint-disable
    { 
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
    function category(uint _categoryId) external view returns(uint, uint, uint, uint, uint[], uint, uint) {
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

    function categoryAction(uint _categoryId) external view returns(uint, address, bytes2, uint) {
        return(
            _categoryId,
            categoryActionData[_categoryId].contractAddress,
            categoryActionData[_categoryId].contractName,
            categoryActionData[_categoryId].defaultIncentive
        );
    }

    /// @dev Gets Total number of categories added till now
    function totalCategories() external view returns(uint) {
        return allCategory.length;
    }

    ///@dev just to follow the interface
    function updateDependencyAddresses() public { //solhint-disable-line
        if (!constructorCheck) {
            proposalCategoryInitiate();
            constructorCheck = true;
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

    /// @dev Initiates Default settings for Proposal Category contract (Adding default categories)
    function proposalCategoryInitiate() internal { //solhint-disable-line
        addInitialCategories("Uncategorized", "", "EX");
        addInitialCategories("Add new member role", "QmQFnBep7AyMYU3LJDuHSpTYatnw65XjHzzirrghtZoR8U", "MR");
        addInitialCategories("Update member role", "QmXMzSViLBJ22P9oj51Zz7isKTRnXWPHZcQ5hzGvvWD3UV", "MR");
        addInitialCategories("Add new category", "QmYzBtW5mRMwHwKQUmRnwdXgq733WNzN5fo2yNPpkVG9Ng", "PC");
        addInitialCategories("Edit category", "QmcVNykyhjni7GFk8x1GrL3idzc6vxz4vNJLHPS9vJ79Qc", "PC");
        addInitialCategories("Change dApp Token Proxy", "QmPR9K6BevCXRVBxWGjF9RV7Pmtxr7D4gE3qsZu5bzi8GK", "MS");
        addInitialCategories("Transfer Ether", "QmRUmxw4xmqTN6L2bSZEJfmRcU1yvVWoiMqehKtqCMAaTa", "GV");
        addInitialCategories("Transfer Token", "QmbvmcW3zcAnng3FWgP5bHL4ba9kMMwV9G8Y8SASqrvHHB", "GV");
        addInitialCategories("Add new version", "QmeMBNn9fs5xYVFVsN8HgupMTfgXdyz4vkLPXakWd2BY3w", "MS");
        addInitialCategories("Add new contract", "QmWP3P58YcmveHeXqgsBCRmDewTYV1QqeQqBmRkDujrDLR", "MS");
        addInitialCategories(
            "Upgrade a contract Implementation",
            "Qme4hGas6RuDYk9LKE2XkK9E46LNeCBUzY12DdT5uQstvh",
            "MS"
        );
        addInitialCategories(
            "Upgrade a contract proxy",
            "QmUNGEn7E2csB3YxohDxBKNqvzwa1WfvrSH4TCCFD9DZsg",
            "MS"
        );
        addInitialCategories("Resume Proposal", "QmQPWVjmv2Gt2Dzt1rxmFkHCptFSdtX4VC5g7VVNUByLv1", "GV");
        addInitialCategories("Pause Proposal", "QmWWoiRZCmi61LQKpGyGuKjasFVpq8JzbLPvDhU8TBS9tk", "GV");
        addInitialCategories("Others, not specified", "", "EX");
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
        string _name, 
        uint _memberRoleToVote,
        uint _majorityVotePerc, 
        uint _quorumPerc,
        uint[] _allowedToCreateProposal,
        uint _closingTime,
        string _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint[] _incentives
    ) 
        internal
    {
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

    function addInitialCategories(
        string _name,
        string _actionHash,
        bytes2 _contractName
    ) 
        internal 
    {
        uint[] memory allowedToCreateProposal = new uint[](2);
        uint[] memory stake_incentive = new uint[](2);        
        allowedToCreateProposal[0] = 1;
        allowedToCreateProposal[1] = 2;
        stake_incentive[0] = 0;
        stake_incentive[1] = 0;
        _addCategory(
                _name,
                1,
                50,
                25,
                allowedToCreateProposal,
                72000,
                _actionHash,
                address(0),
                _contractName,
                stake_incentive
            );
    }


}