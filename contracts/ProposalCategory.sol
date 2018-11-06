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
import "./imports/govern/Governed.sol";
import "./ProposalCategoryAdder.sol";


contract ProposalCategory is Governed {
    bool public constructorCheck;
    bool public adderCheck;
    address public officialPCA;

    struct Category {
        string name;
        uint memberRoleSequence;
        uint memberRoleMajorityVote;
        uint[] allowedToCreateProposal;
        uint closingTime;
        uint tokenHoldingTime;
        uint minStake;
        uint defaultIncentive;
        uint8 rewardPercProposal;
        uint8 rewardPercSolution;
        uint8 rewardPercVote;
        string actionHash;
        address contractAddress;
        bytes2 contractName;
    }

    // struct CategoryAction{
    //     uint categoryId;
        
    // }

    Category[] internal allCategory;
    // CategoryAction[] internal allCategoryAction;

    //// @dev Adds new category
    //// @param _name Category name
    //// @param _memberRoleSequence Voting Layer sequence in which the voting has to be performed.
    //// @param _allowedToCreateProposal Member roles allowed to create the proposal
    //// @param _memberRoleMajorityVote Majority Vote threshhold for Each voting layer
    //// @param _closingTime Vote closing time for Each voting layer
    function addNewCategory(
        string _name, 
        uint _memberRoleSequence,
        uint _memberRoleMajorityVote, 
        uint[] _allowedToCreateProposal,
        uint _closingTime,
        string _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint _tokenHoldingTime,
        uint[2] _incentives,
        uint8[3] _rewards
    ) 
        external
        onlyAuthorizedToGovern 
    {
        addCategoryDetails(_name,_memberRoleSequence,_memberRoleMajorityVote,_allowedToCreateProposal,_closingTime,_tokenHoldingTime);
        addCategoryActionDetails(_actionHash,_incentives,_rewards,_contractAddress,_contractName);
    }

    function addCategoryDetails(
        string _name, 
        uint _memberRoleSequence,
        uint _memberRoleMajorityVote, 
        uint[] _allowedToCreateProposal,
        uint _closingTime,
        uint _tokenHoldingTime
    ) internal onlyAuthorizedToGovern{

    }

    function addCategoryActionDetails(
        string _actionHash,
        uint[2] _incentives,
        uint8[3] _rewards,
        address _contractAddress,
        bytes2 _contractName
    ) internal onlyAuthorizedToGovern{
        allCategory[0].actionHash = _actionHash;
        allCategory[0].contractAddress = _contractAddress;
        allCategory[0].contractName = _contractName;
        allCategory[0].minStake = _incentives[0];
        allCategory[0].defaultIncentive = _incentives[1];
        allCategory[0].rewardPercProposal =  _rewards[0];
        allCategory[0].rewardPercSolution = _rewards[1];
        allCategory[0].rewardPercVote = _rewards[2];
    }

    //// @dev Updates category details
    //// @param _categoryId Category id that needs to be updated
    //// @param _roleName Updated Role sequence to vote i.e. Updated voting layer sequence
    //// @param _majorityVote Updated Majority threshhold value against each voting layer.
    //// @param _allowedToCreateProposal Member roles allowed to create the proposal
    //// @param _closingTime Updated Vote closing time against each voting layer
    function updateCategory(
        uint _categoryId, 
        string _name, 
        uint _roleName, 
        uint _majorityVote, 
        uint[] _allowedToCreateProposal,
        uint _closingTime,
        uint _tokenHoldingTime,
        string _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint[2] _incentives,
        uint8[3] _rewards
    )
        public
        onlyAuthorizedToGovern
    { 
        allCategory[_categoryId].name = _name;
        allCategory[_categoryId].memberRoleSequence = _roleName;
        allCategory[_categoryId].memberRoleMajorityVote = _majorityVote;
        allCategory[_categoryId].closingTime = _closingTime;
        allCategory[_categoryId].allowedToCreateProposal = _allowedToCreateProposal; 
        allCategory[_categoryId].tokenHoldingTime = _tokenHoldingTime;
        allCategory[_categoryId].minStake = _incentives[0];
        allCategory[_categoryId].defaultIncentive = _incentives[1];
        allCategory[_categoryId].rewardPercProposal = _rewards[0];
        allCategory[_categoryId].rewardPercSolution = _rewards[1];
        allCategory[_categoryId].rewardPercVote = _rewards[2];
        allCategory[_categoryId].actionHash = _actionHash;
        allCategory[_categoryId].contractAddress = _contractAddress;
        allCategory[_categoryId].contractName = _contractName;
        // updateCategoryData(_categoryId,_name,_roleName,_majorityVote,_allowedToCreateProposal,_closingTime,_incentives,_tokenHoldingTime,_actionHash,_contractAddress,_contractName,_rewards);
        // updateCategoryAction(_categoryId);
    }

    // function updateCategoryData(uint _categoryId, 
    //     string _name, 
    //     uint _roleName, 
    //     uint _majorityVote, 
    //     uint[] _allowedToCreateProposal,
    //     uint _closingTime,
    //     uint[2] _incentives,
    //     uint _tokenHoldingTime, string _actionHash,address _contractAddress,bytes2 _contractName,
    //     uint8[3] _rewards
    // ) internal onlyAuthorizedToGovern{
    //     allCategory[_categoryId].name = _name;
    //     allCategory[_categoryId].memberRoleSequence = _roleName;
    //     allCategory[_categoryId].memberRoleMajorityVote = _majorityVote;
    //     allCategory[_categoryId].closingTime = _closingTime;
    //     allCategory[_categoryId].allowedToCreateProposal = _allowedToCreateProposal; 
    //     allCategory[_categoryId].tokenHoldingTime = _tokenHoldingTime;
    //     allCategory[_categoryId].minStake = _incentives[0];
    //     allCategory[_categoryId].defaultIncentive = _incentives[1];
    //     allCategory[_categoryId].rewardPercProposal = _rewards[0];
    //     allCategory[_categoryId].rewardPercSolution = _rewards[1];
    //     allCategory[_categoryId].rewardPercVote = _rewards[2];
    //     allCategory[_categoryId].actionHash = _actionHash;
    //     allCategory[_categoryId].contractAddress = _contractAddress;
    //     allCategory[_categoryId].contractName = _contractName;
    // }

    // function updateCategoryAction(uint _categoryId,address _contractAddress,bytes2 _contractName) internal onlyAuthorizedToGovern{
    // }

    //// @dev gets category details
    function getCategoryDetails(uint _categoryId) public view returns(string, uint, uint, uint[], uint, uint) {
        return(
            allCategory[_categoryId].name,
            allCategory[_categoryId].memberRoleSequence,
            allCategory[_categoryId].memberRoleMajorityVote,
            allCategory[_categoryId].allowedToCreateProposal,
            allCategory[_categoryId].closingTime,
            allCategory[_categoryId].tokenHoldingTime
        );
    }

    function getCategoryActionDetails(uint _categoryId) public view returns(string, address, bytes2, uint[2], uint8[3]){
        return(
            allCategory[_categoryId].actionHash,
            allCategory[_categoryId].contractAddress,
            allCategory[_categoryId].contractName,
            [allCategory[_categoryId].minStake, allCategory[_categoryId].defaultIncentive],
            [allCategory[_categoryId].rewardPercProposal, allCategory[_categoryId].rewardPercSolution, allCategory[_categoryId].rewardPercVote]
        );
    }

    //// @dev Get contractName
    function getContractName(uint _categoryId) public view returns(bytes2) {
        return allCategory[_categoryId].contractName;
    }  

    //// @dev Get contractAddress 
    function getContractAddress(uint _categoryId) public view returns(address) {
        return allCategory[_categoryId].contractAddress;
    } 

    //// @dev Get Member Roles allowed to create proposal by category
    function getMRAllowed(uint _categoryId) public view returns(uint[]) {
        return allCategory[_categoryId].allowedToCreateProposal;
    }

    function isCategoryExternal(uint _category) public view returns(bool ext) {
        return _isCategoryExternal(_category);
    }

    function getRequiredStake(uint _categoryId) public view returns(uint, uint) {
        return (
            allCategory[_categoryId].minStake, 
            allCategory[_categoryId].tokenHoldingTime
        );
    }

    function getTokenHoldingTime(uint _categoryId) public view returns(uint) {
        return allCategory[_categoryId].tokenHoldingTime;
    }

    //// @dev Gets reward percentage for Proposal to distribute stake on proposal acceptance
    function getRewardPercProposal(uint _categoryId) public view returns(uint) {
        return allCategory[_categoryId].rewardPercProposal;
    }

    //// @dev Gets reward percentage for Solution to distribute stake on proposing favourable solution
    function getRewardPercSolution(uint _categoryId) public view returns(uint) {
        return allCategory[_categoryId].rewardPercSolution;
    }

    //// @dev Gets reward percentage for Voting to distribute stake on casting vote on winning solution  
    function getRewardPercVote(uint _categoryId) public view returns(uint) {
        return allCategory[_categoryId].rewardPercVote;
    }

    //// @dev Gets minimum stake for sub category id
    function getMinStake(uint _categoryId) public view returns(uint) {
        return allCategory[_categoryId].minStake;
    }

    //// @dev Gets Majority threshold array length when giving main category id
    function getRoleMajorityVotelength(uint _categoryId) public view returns(uint index, uint majorityVoteLength) {
        index = _categoryId;
        majorityVoteLength = 1;
    }

    //// @dev Gets role sequence length by category id
    function getRoleSequencLength(uint _categoryId) public view returns(uint roleLength) {
        roleLength = 1;
    }

    //// @dev Gets Closing time array length when giving main category id
    function getCloseTimeLength(uint _categoryId) public view returns(uint) {
        return 1;
    }

    //// @dev Gets Closing time at particular index from Closing time array
    //// @param _categoryId Id of main category
    //// @param _index Current voting status againt proposal act as an index here
    function getClosingTimeAtIndex(uint _categoryId, uint _index) public view returns(uint ct) {
        return allCategory[_categoryId].closingTime;
    }

    //// @dev Gets Voting layer role sequence at particular index from Role sequence array
    //// @param _categoryId Id of main category
    //// @param _index Current voting status againt proposal act as an index here
    function getRoleSequencAtIndex(uint _categoryId, uint _index) public view returns(uint roleId) {
        return allCategory[_categoryId].memberRoleSequence;
    }

    //// @dev Gets Majority threshold value at particular index from Majority Vote array
    //// @param _categoryId Id of main category
    //// @param _index Current voting status againt proposal act as an index here
    function getRoleMajorityVoteAtIndex(uint _categoryId, uint _index) public view returns(uint majorityVote) {
        return allCategory[_categoryId].memberRoleMajorityVote;
    }

    //// @dev Gets Default incentive to be distributed against category.
    function getCatIncentive(uint _categoryId) public view returns(uint) {
        return allCategory[_categoryId].defaultIncentive;
    }

    //// @dev Gets Total number of categories added till now
    function getCategoryLength() public view returns(uint) {
        return allCategory.length;
    }

    //// @dev Gets Total number of sub categories added till now
    // function getSubCategoryLength() public view returns(uint) {
    //     return allSubCategory.length;
    // }

    //// @dev Gets Cateory description hash when giving category id
    function getCategoryName(uint _categoryId) public view returns(uint, string) {
        return (_categoryId, allCategory[_categoryId].name);
    }

    //// @dev Gets Category data depending upon current voting index in Voting sequence.
    //// @param _categoryId Category id
    //// @param _currVotingIndex Current voting Id in voting seqeunce.
    //// @return Next member role to vote with its closing time and majority vote.
    function getCategoryData3(uint _categoryId, uint _currVotingIndex) 
        public
        view 
        returns(uint  rsuence, uint majorityVote, uint closingTime) 
    {
        return (
            allCategory[_categoryId].memberRoleSequence, 
            allCategory[_categoryId].memberRoleMajorityVote, 
            allCategory[_categoryId].closingTime
        );
    }

    function getMRSequenceBySubCat(uint _categoryId, uint _currVotingIndex) public view returns (uint) {
        // uint category = allCategory[_categoryId].categoryId;
        return allCategory[_categoryId].memberRoleSequence;
    }

    function addInitialCategories(
        string _name, 
        uint _roleName, 
        uint _majorityVote, 
        uint[] _allowedToCreateProposal,
        uint _closingTime,
        string _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint _tokenHoldingTime,
        uint[] _incentives,
        uint8[] _rewards
    ) 
        public 
    {
        require(allCategory.length <= 21);
        require(msg.sender == officialPCA || officialPCA == address(0));
        // allSubIdByCategory[_mainCategoryId].push(allSubCategory.length);        
        allCategory.push(Category(
                 _name, 
                 _roleName, 
                 _majorityVote, 
                 _allowedToCreateProposal,
                 _closingTime,
                 _tokenHoldingTime,
                 _incentives[0],
                 _incentives[1],
                 _rewards[0],
                 _rewards[1],
                 _rewards[2],
                _actionHash,
                _contractAddress,
                _contractName
            )
        );
    }

    //// @dev Initiates Default settings for Proposal Category contract (Adding default categories)
    function proposalCategoryInitiate(bytes32 _dAppName) public {
        require(!constructorCheck);
        dappName = _dAppName;

        if (_getCodeSize(0x31475F356a415FE6cB19E450FF8E49C9B6eF9819) > 0)        //kovan testnet
            officialPCA = 0x31475F356a415FE6cB19E450FF8E49C9B6eF9819;

        constructorCheck = true;
    }

    function addDefaultCategories() public {
        require(!adderCheck);
        uint rs;
        uint[] memory al = new uint[](2);
        uint[] memory alex = new uint[](1);
        uint mv;
        uint ct;
        
        rs = 1;
        mv = 50;
        al[0] = 1;
        al[1] = 2;
        alex[0] = 0;
        ct = 72000;
        
        allCategory.push(Category("Uncategorized", rs, mv, al, ct, 0, 0, 0, 0, 0, 0, "", address(0), "EX"));
        // allCategoryAction.push(CategoryAction());
        // allCategory.push(Category("Member role", rs, mv, al, ct));
        // allCategory.push(Category("Categories", rs, mv, al, ct));
        // allCategory.push(Category("Parameters", rs, mv, al, ct));
        // allCategory.push(Category("Transfer Assets", rs, mv, al, ct));
        // allCategory.push(Category("Critical Actions", rs, mv, al, ct));
        // allCategory.push(Category("Immediate Actions", rs, mv, al, ct));
        // allCategory.push(Category("External Feedback", rs, mv, alex, ct));
        // allCategory.push(Category("Others", rs, mv, al, ct));

        // allSubIdByCategory[0].push(0);
        // allSubCategory.push(SubCategory(
        //         "Uncategorized",
        //         "", 
        //         0, 
        //         address(0), 
        //         "EX", 
        //         0,
        //         0,
        //         0,
        //         0,
        //         0,
        //         0
        //     )
        // );

        adderCheck = true;
    }

    ////@dev just to follow the interface
    function updateDependencyAddresses() public pure { //solhint-disable-line
    }

    //// @dev just to adhere to GovBlockss' Upgradeable interface
    function changeMasterAddress(address _masterAddress) public pure { //solhint-disable-line
    }

    function _getCodeSize(address _addr) internal view returns(uint _size) {
        assembly { //solhint-disable-line
            _size := extcodesize(_addr)
        }
    }

    function _isCategoryExternal(uint _category) internal view returns(bool ext) {
        for (uint i = 0; i < allCategory[_category].allowedToCreateProposal.length; i++) {
            if (allCategory[_category].allowedToCreateProposal[i] == 0)
                ext = true;
        }        
    }
}