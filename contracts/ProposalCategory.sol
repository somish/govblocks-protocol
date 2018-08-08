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
import "./Master.sol";
import "./GovernanceData.sol";
import "./MemberRoles.sol";
import "./Upgradeable.sol";
import "./ProposalCategoryAdder.sol";

contract ProposalCategory is Upgradeable {
    bool public constructorCheck;
    struct Category {
        string name;
        uint[] memberRoleSequence;
        uint[] memberRoleMajorityVote;
        uint[] allowedToCreateProposal;
        uint[] closingTime;
    }

    struct SubCategory {
        string categoryName;
        string actionHash;
        uint categoryId;
        address contractAddress;
        bytes2 contractName;
        uint minStake;
        uint tokenHoldingTime;
        uint defaultIncentive;
        uint8 rewardPercProposal;
        uint8 rewardPercSolution;
        uint8 rewardPercVote; 
    }

    SubCategory[] public allSubCategory;
    Category[] public allCategory;
    mapping(uint => uint[]) internal allSubIdByCategory;

    MemberRoles internal memberRole;
    GovernanceData internal governanceDat;

    modifier onlySV {   //Owner for debugging only, will be removed before launch 
        require(master.getLatestAddress("SV") == msg.sender  
            || master.owner() == msg.sender
        );
        _;
    }

    /// @dev updates all dependency addresses to latest ones from Master
    function updateDependencyAddresses() public {
        governanceDat = GovernanceData(master.getLatestAddress("GD"));
        memberRole = MemberRoles(master.getLatestAddress("MR"));
    }

    /// @dev Initiates Default settings for Proposal Category contract (Adding default categories)
    function proposalCategoryInitiate() public {
        require(!constructorCheck);
        uint[] memory rs = new uint[](1);
        uint[] memory al = new uint[](1);
        uint[] memory mv = new uint[](1);
        uint[] memory ct = new uint[](1);
        
        rs[0] = 1;
        mv[0] = 50;
        al[0] = 0;
        ct[0] = 1800;
        
        allCategory.push(Category("Uncategorized", rs, mv, al, ct));
        allCategory.push(Category("Member role", rs, mv, al, ct));
        allCategory.push(Category("Categories", rs, mv, al, ct));
        allCategory.push(Category("Parameters", rs, mv, al, ct));
        allCategory.push(Category("Transfer Assets", rs, mv, al, ct));
        allCategory.push(Category("New contracts", rs, mv, al, ct));
        allCategory.push(Category("Others", rs, mv, al, ct));

        addInitialSubCategories();

        constructorCheck = true;
    }

    /// @dev Adds new category
    /// @param _name Category name
    /// @param _memberRoleSequence Voting Layer sequence in which the voting has to be performed.
    /// @param _allowedToCreateProposal Member roles allowed to create the proposal
    /// @param _memberRoleMajorityVote Majority Vote threshhold for Each voting layer
    /// @param _closingTime Vote closing time for Each voting layer
    function addNewCategory(
        string _name, 
        uint[] _memberRoleSequence,
        uint[] _memberRoleMajorityVote, 
        uint[] _allowedToCreateProposal,
        uint[] _closingTime
    ) 
        external
        onlySV 
    {
        require(_memberRoleSequence.length == _memberRoleMajorityVote.length 
            && _memberRoleMajorityVote.length == _closingTime.length
        );
        allCategory.push(Category(
                _name, 
                _memberRoleSequence, 
                _memberRoleMajorityVote, 
                _allowedToCreateProposal,
                _closingTime
            )
        );
    }

    /// @dev Updates category details
    /// @param _categoryId Category id that needs to be updated
    /// @param _roleName Updated Role sequence to vote i.e. Updated voting layer sequence
    /// @param _majorityVote Updated Majority threshhold value against each voting layer.
    /// @param _allowedToCreateProposal Member roles allowed to create the proposal
    /// @param _closingTime Updated Vote closing time against each voting layer
    function updateCategory(
        uint _categoryId, 
        string _name, 
        uint[] _roleName, 
        uint[] _majorityVote, 
        uint[] _allowedToCreateProposal,
        uint[] _closingTime
    )
        external 
        onlySV
    {
        require(_roleName.length == _majorityVote.length && _majorityVote.length == _closingTime.length);
        allCategory[_categoryId].name = _name;
        allCategory[_categoryId].allowedToCreateProposal.length = _allowedToCreateProposal.length;
        allCategory[_categoryId].memberRoleSequence.length = _roleName.length;
        allCategory[_categoryId].memberRoleMajorityVote.length = _majorityVote.length;
        allCategory[_categoryId].closingTime.length = _closingTime.length;
        uint i;

        for (i = 0; i < _roleName.length; i++) {
            allCategory[_categoryId].memberRoleSequence[i] = _roleName[i];
            allCategory[_categoryId].memberRoleMajorityVote[i] = _majorityVote[i];
            allCategory[_categoryId].closingTime[i] = _closingTime[i];
        }
        for (i = 0; i < _allowedToCreateProposal.length; i++) {
            allCategory[_categoryId].allowedToCreateProposal[i] = _allowedToCreateProposal[i];
        }
    }

    /// @dev Add new sub category against category.
    /// @param _subCategoryName Name of the sub category
    /// @param _actionHash Automated Action hash has Contract Address and function name 
    /// i.e. Functionality that needs to be performed after proposal acceptance.
    /// @param _mainCategoryId Id of main category
    function addNewSubCategory(
        string _subCategoryName, 
        string _actionHash, 
        uint _mainCategoryId, 
        address _contractAddress,
        bytes2 _contractName,
        uint[] _stakeAndIncentive, 
        uint8[] _rewardPercentage
    ) 
        external
        onlySV 
    {
        allSubIdByCategory[_mainCategoryId].push(allSubCategory.length);
        allSubCategory.push(SubCategory(
                _subCategoryName, 
                _actionHash, 
                _mainCategoryId, 
                _contractAddress, 
                _contractName,
                _stakeAndIncentive[1],
                _stakeAndIncentive[2],
                _stakeAndIncentive[3],
                _rewardPercentage[1],
                _rewardPercentage[2],
                _rewardPercentage[3]
            )
        );
    }

    /// @dev Update Sub category of a specific category.
    /// @param _subCategoryId Id of subcategory that needs to be updated
    /// @param _actionHash Updated Automated Action hash i.e. Either contract address or function name is changed.
    function updateSubCategory(
        string _subCategoryName, 
        string _actionHash, 
        uint _subCategoryId, 
        address _address, 
        bytes2 _contractName,
        uint[] _stakeAndIncentive, 
        uint8[] _rewardPercentage
    ) 
        external 
        onlySV 
    {
        allSubCategory[_subCategoryId].categoryName = _subCategoryName;
        allSubCategory[_subCategoryId].actionHash = _actionHash;
        allSubCategory[_subCategoryId].contractAddress = _address;
        allSubCategory[_subCategoryId].contractName = _contractName;
        allSubCategory[_subCategoryId].minStake = _stakeAndIncentive[1];
        allSubCategory[_subCategoryId].tokenHoldingTime = _stakeAndIncentive[2];
        allSubCategory[_subCategoryId].defaultIncentive = _stakeAndIncentive[3];
        allSubCategory[_subCategoryId].rewardPercProposal = _rewardPercentage[1];
        allSubCategory[_subCategoryId].rewardPercSolution = _rewardPercentage[2];
        allSubCategory[_subCategoryId].rewardPercVote = _rewardPercentage[3];

    }

    /// @dev Get Sub category name 
    function getSubCategoryName(uint _subCategoryId) public view returns(uint, string) {
        return (_subCategoryId, allSubCategory[_subCategoryId].categoryName);
    }

    /// @dev Get contractAddress 
    function getContractAddress(uint _subCategoryId) public view returns(address _contractAddress) {
        if(allSubCategory[_subCategoryId].contractName == "EX")
            _contractAddress = allSubCategory[_subCategoryId].contractAddress;
        else
            _contractAddress = master.getLatestAddress(allSubCategory[_subCategoryId].contractName);
    }

    /// @dev Get Sub category id at specific index when giving main category id 
    /// @param _categoryId Id of main category
    /// @param _index Get subcategory id at particular index in all subcategory array
    function getSubCategoryIdAtIndex(uint _categoryId, uint _index) public view returns(uint _subCategoryId) {
        return allSubIdByCategory[_categoryId][_index];
    }

    /// @dev Get Sub categories array against main category
    function getAllSubIdsByCategory(uint _categoryId) public view returns(uint[]) {
        return allSubIdByCategory[_categoryId];
    }

    /// @dev Get Total number of sub categories against main category
    function getAllSubIdsLengthByCategory(uint _categoryId) public view returns(uint) {
        return allSubIdByCategory[_categoryId].length;
    }

    /// @dev Gets Main category when giving sub category id. 
    function getCategoryIdBySubId(uint _subCategoryId) public view returns(uint) {
        return allSubCategory[_subCategoryId].categoryId;
    }

    function isCategoryExternal(uint _category) public view returns(bool) {
        if(allCategory[_category].allowedToCreateProposal[0] == 0)
            return true;
    }

    function getRequiredStake(uint _subCategoryId) public view returns(uint, uint) {
        return (
            allSubCategory[_subCategoryId].minStake, 
            allSubCategory[_subCategoryId].tokenHoldingTime
        );
    }

    /// @dev Gets remaining vote closing time against proposal 
    /// i.e. Calculated closing time from current voting index to the last layer.
    /// @param _proposalId Proposal Id
    /// @param _subCategoryId SubCategory of proposal.
    /// @param _index Current voting status id works as index here in voting layer sequence. 
    /// @return totalTime Total time that left for proposal closing.
    function getRemainingClosingTime(uint _proposalId, uint _subCategoryId, uint _index) 
        public 
        view 
        returns(uint totalTime) 
    {
        uint pClosingTime;
        uint categoryId = allSubCategory[_subCategoryId].categoryId;
        for (uint i = _index; i < allCategory[categoryId].closingTime.length; i++) {
            pClosingTime = pClosingTime + allCategory[categoryId].closingTime[i];
        }

        totalTime = pClosingTime 
            + allSubCategory[_subCategoryId].tokenHoldingTime
            + governanceDat.getProposalDateUpd(_proposalId)
            - now;
    }
    
    /// @dev Gets Total vote closing time against sub category i.e. 
    /// Calculated Closing time from first voting layer where current voting index is 0.
    /// @param _subCategoryId Category id
    /// @return totalTime Total time before the voting gets closed
    function getMaxCategoryTokenHoldTime(uint _subCategoryId) public view returns(uint totalTime) {
        uint categoryId = allSubCategory[_subCategoryId].categoryId;
        for (uint i = 0; i < allCategory[categoryId].closingTime.length; i++) {
            totalTime = totalTime + allCategory[categoryId].closingTime[i];
        }
        totalTime = totalTime + allSubCategory[_subCategoryId].tokenHoldingTime;
        return totalTime;
    }

    /// @dev Gets reward percentage for Proposal to distribute stake on proposal acceptance
    function getRewardPercProposal(uint _subCategoryId) public view returns(uint) {
        return allSubCategory[_subCategoryId].rewardPercProposal;
    }

    /// @dev Gets reward percentage for Solution to distribute stake on proposing favourable solution
    function getRewardPercSolution(uint _subCategoryId) public view returns(uint) {
        return allSubCategory[_subCategoryId].rewardPercSolution;
    }

    /// @dev Gets reward percentage for Voting to distribute stake on casting vote on winning solution  
    function getRewardPercVote(uint _subCategoryId) public view returns(uint) {
        return allSubCategory[_subCategoryId].rewardPercVote;
    }

    /// @dev Gets minimum stake for sub category id
    function getMinStake(uint _subCategoryId) public view returns(uint) {
        return allSubCategory[_subCategoryId].minStake;
    }

    /// @dev returns if a member is allowed to vote.
    function allowedToCreateProposal(address _member, uint _category) public view returns (bool) {
        if (allCategory[_category].allowedToCreateProposal[0] == 0)
            return true;
        else {
            for(uint i = 0; i<allCategory[_category].allowedToCreateProposal.length; i++) {
                if (memberRole.checkRoleIdByAddress(_member, allCategory[_category].allowedToCreateProposal[i]))
                    return true;
            }
        }
    }

    /// @dev Gets Majority threshold array length when giving main category id
    function getRoleMajorityVotelength(uint _categoryId) public view returns(uint index, uint majorityVoteLength) {
        index = _categoryId;
        majorityVoteLength = allCategory[_categoryId].memberRoleMajorityVote.length;
    }

    /// @dev Gets Closing time array length when giving main category id
    function getClosingTimeLength(uint _categoryId) public view returns(uint index, uint closingTimeLength) {
        index = _categoryId;
        closingTimeLength = allCategory[_categoryId].closingTime.length;
    }

    /// @dev Gets role sequence length by category id
    function getRoleSequencLength(uint _categoryId) public view returns(uint roleLength) {
        roleLength = allCategory[_categoryId].memberRoleSequence.length;
    }

    /// @dev Gets Closing time array length when giving main category id
    function getCloseTimeLength(uint _categoryId) public view returns(uint) {
        return allCategory[_categoryId].closingTime.length;
    }

    /// @dev Gets Closing time at particular index from Closing time array
    /// @param _categoryId Id of main category
    /// @param _index Current voting status againt proposal act as an index here
    function getClosingTimeAtIndex(uint _categoryId, uint _index) public view returns(uint ct) {
        return allCategory[_categoryId].closingTime[_index];
    }

    /// @dev Gets Voting layer role sequence at particular index from Role sequence array
    /// @param _categoryId Id of main category
    /// @param _index Current voting status againt proposal act as an index here
    function getRoleSequencAtIndex(uint _categoryId, uint _index) public view returns(uint roleId) {
        return allCategory[_categoryId].memberRoleSequence[_index];
    }

    function getRoleSequencByProposal(uint _proposalId, uint _currVotingId) public view returns(uint) {
        uint category = allSubCategory[governanceDat.getProposalCategory(_proposalId)].categoryId;
        return allCategory[category].memberRoleSequence[_currVotingId];
    }

    /// @dev Gets Majority threshold value at particular index from Majority Vote array
    /// @param _categoryId Id of main category
    /// @param _index Current voting status againt proposal act as an index here
    function getRoleMajorityVoteAtIndex(uint _categoryId, uint _index) public view returns(uint majorityVote) {
        return allCategory[_categoryId].memberRoleMajorityVote[_index];
    }

    /// @dev Gets Default incentive to be distributed against sub category.
    function getCatIncentive(uint _subCategoryId) public view returns(uint incentive) {
        incentive = allSubCategory[_subCategoryId].defaultIncentive;
    }

    /// @dev Gets Default incentive to be distributed against sub category.
    function getCategoryIncentive(uint _subCategoryId) public view returns(uint category, uint incentive) {
        category = _subCategoryId;
        incentive = allSubCategory[_subCategoryId].defaultIncentive;
    }

    /// @dev Gets Total number of categories added till now
    function getCategoryLength() public view returns(uint) {
        return allCategory.length;
    }

    /// @dev Gets Cateory description hash when giving category id
    function getCategoryName(uint _categoryId) public view returns(uint, string) {
        return (_categoryId, allCategory[_categoryId].name);
    }

    /// @dev Gets Category data depending upon current voting index in Voting sequence.
    /// @param _categoryId Category id
    /// @param _currVotingIndex Current voting Id in voting seqeunce.
    /// @return Next member role to vote with its closing time and majority vote.
    function getCategoryData3(uint _categoryId, uint _currVotingIndex) 
        public
        view 
        returns(uint  rsuence, uint majorityVote, uint closingTime) 
    {
        return (
            allCategory[_categoryId].memberRoleSequence[_currVotingIndex], 
            allCategory[_categoryId].memberRoleMajorityVote[_currVotingIndex], 
            allCategory[_categoryId].closingTime[_currVotingIndex]
        );
    }

    function getMRSequenceBySubCat(uint _subCategoryId, uint _currVotingIndex) external view returns (uint) {
        uint category = allSubCategory[_subCategoryId].categoryId;
        return allCategory[category].memberRoleSequence[_currVotingIndex];
    }

    function validateStake(uint _proposalId, uint _stake) public view returns (bool result) {
        uint subCat = governanceDat.getProposalCategory(_proposalId);
        if(_stake >= allSubCategory[subCat].minStake)
            result = true;
    }

    /// @dev Gets Category and SubCategory name from Proposal ID.
    function getCatAndSubNameByPropId(uint _proposalId) 
        public 
        view 
        returns(string categoryName, string subCategoryName) 
    {
        categoryName = allCategory[getCategoryIdBySubId(governanceDat.getProposalCategory(_proposalId))].name;
        subCategoryName = allSubCategory[governanceDat.getProposalCategory(_proposalId)].categoryName;
    }

    /// @dev Gets Category ID from Proposal ID.
    function getCatIdByPropId(uint _proposalId) public view returns(uint catId) {
        catId = allSubCategory[governanceDat.getProposalCategory(_proposalId)].categoryId;
    }

    function addInitialSubC(
        string _subCategoryName, 
        string _actionHash, 
        uint _mainCategoryId, 
        address _contractAddress,
        bytes2 _contractName,
        uint[] _stakeAndIncentive, 
        uint8[] _rewardPercentage
    ) 
        external 
    {
        require(allSubCategory.length < 13);
        allSubIdByCategory[_mainCategoryId].push(allSubCategory.length);
        allSubCategory.push(SubCategory(
                _subCategoryName, 
                _actionHash, 
                _mainCategoryId, 
                _contractAddress, 
                _contractName,
                _stakeAndIncentive[0],
                _stakeAndIncentive[1],
                _stakeAndIncentive[2],
                _rewardPercentage[0],
                _rewardPercentage[1],
                _rewardPercentage[2]
            )
        );
    }

    function getCodeSize(address _addr) internal view returns(uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    /// @dev adds second half of the inital categories
    function addInitialSubCategories() internal {
        uint[] memory stakeInecntive = new uint[](3); 
        uint8[] memory rewardPerc = new uint8[](3);
        stakeInecntive[0] = 0;
        stakeInecntive[1] = 604800;
        stakeInecntive[2] = 0;
        rewardPerc[0] = 10;
        rewardPerc[1] = 20;
        rewardPerc[2] = 70;
        allSubIdByCategory[0].push(0);
        allSubCategory.push(SubCategory(
                "Uncategorized",
                "", 
                0, 
                address(0), 
                "EX", 
                stakeInecntive[0], 
                stakeInecntive[1], 
                stakeInecntive[2],
                rewardPerc[0], 
                rewardPerc[1], 
                rewardPerc[2]
            )
        );
        if (getCodeSize(0xe96edEECf546631eAC4E23d73fD8802480a09bB5) > 0)        //kovan testnet
            ProposalCategoryAdder proposalCategoryAdder = ProposalCategoryAdder(0xe96edEECf546631eAC4E23d73fD8802480a09bB5);
        proposalCategoryAdder.addSubC();
    }
}