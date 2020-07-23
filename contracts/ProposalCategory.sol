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
import "./external/govern/Governed.sol";
import "./MemberRoles.sol";


contract ProposalCategory is IProposalCategory, Governed {

    bool internal constructorCheck;
    MemberRoles internal mr;
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
    mapping (uint => bytes) public categoryActionHashes;
    
    bool public categoryActionHashUpdated;
    
    /**
    * @dev Adds new category
    * @param _name Category name
    * @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
    * @param _majorityVotePerc Majority Vote threshold for Each voting layer
    * @param _quorumPerc minimum threshold percentage required in voting to calculate result
    * @param _allowedToCreateProposal Member roles allowed to create the proposal
    * @param _closingTime Vote closing time for Each voting layer
    * @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
    * @param _contractAddress address of contract to call after proposal is accepted
    * @param _contractName name of contract to be called after proposal is accepted
    * @param _incentives rewards to distributed after proposal is accepted
    * @param _functionHash function signature to be executed
    */
    function newCategory(
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
        onlyAuthorizedToGovern 
    {

        require(_quorumPerc <= 100 && _majorityVotePerc <= 100, "Invalid percentage");

        require((_contractName == "EX" && _contractAddress == address(0)) || bytes(_functionHash).length > 0);

        require(_verifyMemberRoles(_memberRoleToVote, _allowedToCreateProposal) == 0, "Invalid Role");

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


        if (bytes(_functionHash).length > 0 && abi.encodeWithSignature(_functionHash).length == 4) {
            categoryActionHashes[allCategory.length - 1] = abi.encodeWithSignature(_functionHash);
        }
    }

    /**
    * @dev Updates category details
    * @param _categoryId Category id that needs to be updated
    * @param _name Category name
    * @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
    * @param _allowedToCreateProposal Member roles allowed to create the proposal
    * @param _majorityVotePerc Majority Vote threshold for Each voting layer
    * @param _quorumPerc minimum threshold percentage required in voting to calculate result
    * @param _closingTime Vote closing time for Each voting layer
    * @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
    * @param _contractAddress address of contract to call after proposal is accepted
    * @param _contractName name of contract to be called after proposal is accepted
    * @param _incentives rewards to distributed after proposal is accepted
    * @param _functionHash function signature to be executed
    */
    function editCategory(
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
        onlyAuthorizedToGovern
    {
        require(_verifyMemberRoles(_memberRoleToVote, _allowedToCreateProposal) == 1, "Invalid Role");

        require(_quorumPerc <= 100 && _majorityVotePerc <= 100, "Invalid percentage");

        require((_contractName == "EX" && _contractAddress == address(0)) || bytes(_functionHash).length > 0);

        delete categoryActionHashes[_categoryId];

        if (bytes(_functionHash).length > 0 && abi.encodeWithSignature(_functionHash).length == 4) {
            categoryActionHashes[_categoryId] = abi.encodeWithSignature(_functionHash);
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
        emit Category(_categoryId, _name, _actionHash);    }


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

    /**
     * @dev Gets the category acion details of a category id 
     * @param _categoryId is the category id in concern
     * @return the category id
     * @return the contract address
     * @return the contract name
     * @return the default incentive
     * @return action function hash
     */
    function categoryActionDetails(uint _categoryId) external view returns(uint, address, bytes2, uint, bytes) {
        return(
            _categoryId,
            categoryActionData[_categoryId].contractAddress,
            categoryActionData[_categoryId].contractName,
            categoryActionData[_categoryId].defaultIncentive,
            categoryActionHashes[_categoryId]
        );
    }

    /// @dev Gets Total number of categories added till now
    function totalCategories() external view returns(uint) {
        return allCategory.length;
    }

    ///@dev just to follow the interface
    function updateDependencyAddresses() public { //solhint-disable-line
        ms = IMaster(masterAddress);
        mr = MemberRoles(ms.getLatestAddress('MR'));
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

    function _verifyMemberRoles(uint _memberRoleToVote, uint[] memory _allowedToCreateProposal) 
    internal view returns(uint) { 
        uint totalRoles = mr.totalRoles();
        if (_memberRoleToVote >= totalRoles) {
            return 1;
        }
        for (uint i = 0; i < _allowedToCreateProposal.length; i++) {
            if (_allowedToCreateProposal[i] >= totalRoles) {
                return 1;
            }
        }
        return 0;
    }

    /// @dev Initiates Default settings for Proposal Category contract (Adding default categories)
    function proposalCategoryInitiate() internal { //solhint-disable-line
        require(!categoryActionHashUpdated, "Category action hashes already updated");
        categoryActionHashUpdated = true;
        categoryActionHashes[1] = abi.encodeWithSignature("addRole(bytes32,string,address)");
        categoryActionHashes[2] = abi.encodeWithSignature("updateRole(address,uint256,bool)");
        categoryActionHashes[3] = abi.encodeWithSignature("newCategory(string,uint256,uint256,uint256,uint256[],uint256,string,address,bytes2,uint256[],string)");//solhint-disable-line
        categoryActionHashes[4] = abi.encodeWithSignature("editCategory(uint256,string,uint256,uint256,uint256,uint256[],uint256,string,address,bytes2,uint256[],string)");//solhint-disable-line
        categoryActionHashes[5] = abi.encodeWithSignature("upgradeContractImplementation(bytes2,address)");
        categoryActionHashes[6] = abi.encodeWithSignature("startEmergencyPause()");
        categoryActionHashes[7] = abi.encodeWithSignature("addEmergencyPause(bool,bytes4)");
        categoryActionHashes[8] = abi.encodeWithSignature("burnCAToken(uint256,uint256,address)");
        categoryActionHashes[9] = abi.encodeWithSignature("setUserClaimVotePausedOn(address)");
        categoryActionHashes[12] = abi.encodeWithSignature("transferEther(uint256,address)");
        categoryActionHashes[13] = abi.encodeWithSignature("addInvestmentAssetCurrency(bytes4,address,bool,uint64,uint64,uint8)");//solhint-disable-line
        categoryActionHashes[14] = abi.encodeWithSignature("changeInvestmentAssetHoldingPerc(bytes4,uint64,uint64)");
        categoryActionHashes[15] = abi.encodeWithSignature("changeInvestmentAssetStatus(bytes4,bool)");
        categoryActionHashes[16] = abi.encodeWithSignature("swapABMember(address,address)");
        
        addInitialCategories("Uncategorized", "", "EX");
        addInitialCategories("Add new member role", "QmQFnBep7AyMYU3LJDuHSpTYatnw65XjHzzirrghtZoR8U", "MR");
        addInitialCategories("Update member role", "QmXMzSViLBJ22P9oj51Zz7isKTRnXWPHZcQ5hzGvvWD3UV", "MR");
        addInitialCategories("Add new category", "QmYzBtW5mRMwHwKQUmRnwdXgq733WNzN5fo2yNPpkVG9Ng", "PC"); // 3
        addInitialCategories("Edit category", "QmcVNykyhjni7GFk8x1GrL3idzc6vxz4vNJLHPS9vJ79Qc", "PC");
        addInitialCategories("Change dApp Token Proxy", "QmPR9K6BevCXRVBxWGjF9RV7Pmtxr7D4gE3qsZu5bzi8GK", "MS");
        addInitialCategories("Transfer Ether", "QmRUmxw4xmqTN6L2bSZEJfmRcU1yvVWoiMqehKtqCMAaTa", "GV");
        addInitialCategories("Transfer Token", "QmbvmcW3zcAnng3FWgP5bHL4ba9kMMwV9G8Y8SASqrvHHB", "GV"); // 7
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
        ); // 11
        addInitialCategories("Resume Proposal", "QmQPWVjmv2Gt2Dzt1rxmFkHCptFSdtX4VC5g7VVNUByLv1", "GV");
        addInitialCategories("Pause Proposal", "QmWWoiRZCmi61LQKpGyGuKjasFVpq8JzbLPvDhU8TBS9tk", "GV");
        addInitialCategories("Change role authority", "QmWWoiRZCmi61LQKpGyGuKjasFVpq8JzbLPvDhU8TBS9tk", "MR");
        addInitialCategories("Update governance parameters", "QmWWoiRZCmi61LQKpGyGuKjasFVpq8JzbLPvDhU8TBS9tk", "GV"); // 15
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