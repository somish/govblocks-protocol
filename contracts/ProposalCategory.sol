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
import "./Master.sol";
import "./GovernanceData.sol";
import "./MemberRoles.sol";
import "./Upgradeable.sol";


contract ProposalCategory {
    bool public constructorCheck;
    
    struct Category {
        string name;
        uint8[] memberRoleSequence;
        uint8[] memberRoleMajorityVote;
        uint32[] closingTime;
        uint64 minStake;
        uint64 maxStake;
        uint64 defaultIncentive;
        uint8 rewardPercProposal;
        uint8 rewardPercSolution;
        uint8 rewardPercVote;
    }

    struct SubCategory {
        string categoryName;
        string actionHash;
        uint8 categoryId;
        address contractAddress;
    }

    SubCategory[] public allSubCategory;
    Category[] public allCategory;
    // mapping(uint8=>uint8) categoryIdBySubId; // Given SubcategoryidThen CategoryId
    mapping(uint8 => uint[]) private allSubIdByCategory;

    Master private master;
    MemberRoles private memberRole;
    GovernanceData private governanceDat;
    address private masterAddress;

    modifier onlyInternal {
        master = Master(masterAddress);
        require(master.isInternal(msg.sender));
        _;
    }

    modifier onlyOwner {
        master = Master(masterAddress);
        require(master.isOwner(msg.sender));
        _;
    }

    modifier onlyMaster {
        require(msg.sender == masterAddress);
        _;
    }

    modifier onlyGBM(uint8[] arr1, uint8[] arr2, uint32[] arr3) {
        master = Master(masterAddress);
        require(master.isGBM(msg.sender));
        require(arr1.length == arr2.length && arr1.length == arr3.length);
        _;
    }

    modifier onlyGBMSubCategory() {
        master = Master(masterAddress);
        require(master.isGBM(msg.sender));
        _;
    }

    modifier onlySV {
        master = Master(masterAddress);
        require(master.getLatestAddress("SV") == msg.sender || master.isInternal(msg.sender) || master.isOwner(msg.sender));
        _;
    }

    /// @dev Changes master's contract address
    /// @param _masterContractAddress New master contract address
    function changeMasterAddress(address _masterContractAddress) public {
        if (masterAddress == 0x000)
            masterAddress = _masterContractAddress;
        else {
            master = Master(masterAddress);
            require(master.isInternal(msg.sender));
            masterAddress = _masterContractAddress;
        }
    }

    /// @dev updates all dependency addresses to latest ones from Master
    function updateDependencyAddresses() public onlyInternal {
        if (!constructorCheck)
            proposalCategoryInitiate();
        master = Master(masterAddress);
        governanceDat = GovernanceData(master.getLatestAddress("GD"));
        memberRole = MemberRoles(master.getLatestAddress("MR"));
    }

    /// @dev just to adhere to the interface
    function changeGBTSAddress(address _gbtAddress) public {
    }

    /// @dev Initiates Default settings for Proposal Category contract (Adding default categories)
    function proposalCategoryInitiate() public {
        require(constructorCheck == false);
        
        master = Master(masterAddress);
        
        uint8[] memory roleSeq = new uint8[](1);
        uint8[] memory majVote = new uint8[](1);
        uint32[] memory closeTime = new uint32[](1);
        
        roleSeq[0] = 1;
        majVote[0] = 50;
        closeTime[0] = 1800;
        
        allCategory.push(Category("Uncategorized", roleSeq, majVote, closeTime, 0, 0, 0, 0, 0, 0));
        allCategory.push(Category("Change to member role", roleSeq, majVote, closeTime, 0, 100, 10, 20, 20, 20));
        allCategory.push(Category("Changes to categories", roleSeq, majVote, closeTime, 0, 100, 0, 20, 20, 20));
        allCategory.push(Category("Changes in parameters", roleSeq, majVote, closeTime, 0, 100, 0, 20, 20, 20));
        allCategory.push(Category("Others not specified", roleSeq, majVote, closeTime, 0, 10, 0, 20, 20, 20));
        
        allSubIdByCategory[0].push(0);
        allSubCategory.push(SubCategory("Uncategorized", "", 0, 0x00));
        allSubIdByCategory[1].push(1);
        allSubCategory.push(SubCategory(
                "Add new member role",
                "QmbUTUHF6S7Mz1wDatYt39Tf8R9tjc54UzDZddX1zXYpvm",
                1,
                master.getLatestAddress("MR")
            )
        );
        allSubIdByCategory[1].push(2);
        allSubCategory.push(SubCategory(
                "Update member role",
                "QmXQdhxFohAvkWKPLF9Zddt8EM2jjex5RqVSuTQ3hqSpAE",
                1,
                master.getLatestAddress("MR")
            )
        );

        addInitialSubCategories1();
        
        constructorCheck = true;
    }

    /// @dev Adds new category
    /// @param _categoryData Category hash created in IPFS having all the details
    /// @param _memberRoleSequence Voting Layer sequence in which the voting has to be performed.
    /// @param _memberRoleMajorityVote Majority Vote threshhold for Each voting layer
    /// @param _closingTime Vote closing time for Each voting layer
    /// @param _stakeAndIncentive array of minstake maxstake and incentive required against each category
    /// @param _rewardPercentage array of reward percentages for Proposal, Solution and Voting.
    function addNewCategory(
        string _categoryData, 
        uint8[] _memberRoleSequence, 
        uint8[] _memberRoleMajorityVote, 
        uint32[] _closingTime,
        uint64[] _stakeAndIncentive, 
        uint8[] _rewardPercentage
    ) 
        public
        onlySV 
    {
        require(_memberRoleSequence.length == _memberRoleMajorityVote.length && _memberRoleMajorityVote.length == _closingTime.length);
        allCategory.push(Category(
                _categoryData, 
                _memberRoleSequence, 
                _memberRoleMajorityVote, 
                _closingTime, 
                _stakeAndIncentive[0], 
                _stakeAndIncentive[1], 
                _stakeAndIncentive[2], 
                _rewardPercentage[0], 
                _rewardPercentage[1], 
                _rewardPercentage[2]
            )
        );
    }

    /// @dev Updates category details
    /// @param _categoryId Category id that needs to be updated
    /// @param _roleName Updated Role sequence to vote i.e. Updated voting layer sequence
    /// @param _majorityVote Updated Majority threshhold value against each voting layer.
    /// @param _closingTime Updated Vote closing time against each voting layer
    /// @param _stakeAndIncentive array of minstake maxstake and incentive
    /// @param _rewardPercentage array of reward percentages for Proposal, Solution and Voting.
    function updateCategory(
        uint _categoryId, 
        string _descHash, 
        uint8[] _roleName, 
        uint8[] _majorityVote, 
        uint32[] _closingTime, 
        uint64[] _stakeAndIncentive, 
        uint8[] _rewardPercentage
    )
        public 
        onlySV
    {
        require(_roleName.length == _majorityVote.length && _majorityVote.length == _closingTime.length);
        allCategory[_categoryId].name = _descHash;
        allCategory[_categoryId].minStake = _stakeAndIncentive[0];
        allCategory[_categoryId].maxStake = _stakeAndIncentive[1];
        allCategory[_categoryId].defaultIncentive = _stakeAndIncentive[2];
        allCategory[_categoryId].rewardPercProposal = _rewardPercentage[0];
        allCategory[_categoryId].rewardPercSolution = _rewardPercentage[1];
        allCategory[_categoryId].rewardPercVote = _rewardPercentage[2];
        allCategory[_categoryId].memberRoleSequence = new uint8[](_roleName.length);
        allCategory[_categoryId].memberRoleMajorityVote = new uint8[](_majorityVote.length);
        allCategory[_categoryId].closingTime = new uint32[](_closingTime.length);

        for (uint i = 0; i < _roleName.length; i++) {
            allCategory[_categoryId].memberRoleSequence[i] = _roleName[i];
            allCategory[_categoryId].memberRoleMajorityVote[i] = _majorityVote[i];
            allCategory[_categoryId].closingTime[i] = _closingTime[i];
        }
    }

    /// @dev Add new sub category against category.
    /// @param _categoryName Name of the main category
    /// @param _actionHash Automated Action hash has Contract Address and function name 
    /// i.e. Functionality that needs to be performed after proposal acceptance.
    /// @param _mainCategoryId Id of main category
    function addNewSubCategory(
        string _categoryName, 
        string _actionHash, 
        uint8 _mainCategoryId, 
        address _contractAddress
    ) 
        public
        onlySV 
    {
        allSubIdByCategory[_mainCategoryId].push(allSubCategory.length);
        allSubCategory.push(SubCategory(_categoryName, _actionHash, _mainCategoryId, _contractAddress));
    }

    /// @dev Update Sub category of a specific category.
    /// @param _subCategoryId Id of subcategory that needs to be updated
    /// @param _actionHash Updated Automated Action hash i.e. Either contract address or function name is changed.
    function updateSubCategory(string _categoryName, string _actionHash, uint _subCategoryId, address _contractAddress) public onlySV {
        allSubCategory[_subCategoryId].categoryName = _categoryName;
        allSubCategory[_subCategoryId].actionHash = _actionHash;
        allSubCategory[_subCategoryId].contractAddress = _contractAddress;
    }

    /// @dev Get Sub category details such as Category name, Automated action hash and Main category id
    function getSubCategoryDetails(uint _subCategoryId) public constant returns(string, string, uint, address) {
        return (
            allSubCategory[_subCategoryId].categoryName, 
            allSubCategory[_subCategoryId].actionHash, 
            allSubCategory[_subCategoryId].categoryId, 
            allSubCategory[_subCategoryId].contractAddress
        );
    }

    /// @dev Get Sub category name 
    function getSubCategoryName(uint _subCategoryId) public constant returns(uint, string) {
        return (_subCategoryId, allSubCategory[_subCategoryId].categoryName);
    }

    /// @dev Get contractAddress 
    function getContractAddress(uint _subCategoryId) public constant returns(address _contractAddress) {
        _contractAddress = allSubCategory[_subCategoryId].contractAddress;
    }

    /// @dev Get Sub category id at specific index when giving main category id 
    /// @param _categoryId Id of main category
    /// @param _index Get subcategory id at particular index in all subcategory array
    function getSubCategoryIdAtIndex(uint8 _categoryId, uint _index) public constant returns(uint _subCategoryId) {
        return allSubIdByCategory[_categoryId][_index];
    }

    /// @dev Get Sub categories array against main category
    function getAllSubIdsByCategory(uint8 _categoryId) public constant returns(uint[]) {
        return allSubIdByCategory[_categoryId];
    }

    /// @dev Get Total number of sub categories against main category
    function getAllSubIdsLengthByCategory(uint8 _categoryId) public constant returns(uint) {
        return allSubIdByCategory[_categoryId].length;
    }

    /// @dev Gets Main category when giving sub category id. 
    function getCategoryIdBySubId(uint8 _subCategoryId) public constant returns(uint8) {
        return allSubCategory[_subCategoryId].categoryId;
    }

    /// @dev Gets remaining vote closing time against proposal 
    /// i.e. Calculated closing time from current voting index to the last layer.
    /// @param _proposalId Proposal Id
    /// @param _categoryId Category of proposal.
    /// @param _index Current voting status id works as index here in voting layer sequence. 
    /// @return totalTime Total time that left for proposal closing.
    function getRemainingClosingTime(uint _proposalId, uint _categoryId, uint _index) 
        public 
        constant 
        returns(uint totalTime) 
    {
        uint pClosingTime;
        for (uint i = _index; i < getCloseTimeLength(_categoryId); i++) {
            pClosingTime = pClosingTime + getClosingTimeAtIndex(_categoryId, i);
        }

        totalTime = pClosingTime 
            + governanceDat.tokenHoldingTime() 
            + governanceDat.getProposalDateUpd(_proposalId)
            - now;
    }
    
    /// @dev Gets Total vote closing time against category i.e. 
    /// Calculated Closing time from first voting layer where current voting index is 0.
    /// @param _categoryId Main Category id
    /// @return totalTime Total time before the voting gets closed
    function getMaxCategoryTokenHoldTime(uint _categoryId) public constant returns(uint totalTime) {
        uint pClosingTime;
        for (uint i = 0; i < getCloseTimeLength(_categoryId); i++) {
            pClosingTime = pClosingTime + getClosingTimeAtIndex(_categoryId, i);
        }

        totalTime = pClosingTime + governanceDat.tokenHoldingTime();
        return totalTime;
    }

    /// @dev Gets reward percentage for Proposal to distribute stake on proposal acceptance
    function getRewardPercProposal(uint _categoryId) public constant returns(uint) {
        return allCategory[_categoryId].rewardPercProposal;
    }

    /// @dev Gets reward percentage for Solution to distribute stake on proposing favourable solution
    function getRewardPercSolution(uint _categoryId) public constant returns(uint) {
        return allCategory[_categoryId].rewardPercSolution;
    }

    /// @dev Gets reward percentage for Voting to distribute stake on casting vote on winning solution  
    function getRewardPercVote(uint _categoryId) public constant returns(uint) {
        return allCategory[_categoryId].rewardPercVote;
    }

    /// @dev Gets Category details - Voting layer sequence details with majority threshold and closing time 
    function getCategoryData2(uint _categoryId) 
        public
        constant 
        returns(uint, bytes32[] roleName, uint8[] majorityVote, uint32[] closingTime) 
    {
        // MR=memberRoles(MRAddress);
        uint roleLength = getRoleSequencLength(_categoryId);
        roleName = new bytes32[](roleLength);
        for (uint8 i = 0; i < roleLength; i++) {
            bytes32 name;
            (, name) = memberRole.getMemberRoleNameById(getRoleSequencAtIndex(_categoryId, i));
            roleName[i] = name;
        }

        majorityVote = allCategory[_categoryId].memberRoleMajorityVote;
        closingTime = allCategory[_categoryId].closingTime;
        return (_categoryId, roleName, majorityVote, closingTime);
    }

    /// @dev Gets Category details - Voting layer sequence details with Minimum and Maximum stake needed for category.
    function getCategoryDetails(uint _categoryId) 
        public 
        constant 
        returns(
            uint cateId, 
            uint8[] memberRoleSequence, 
            uint8[] memberRoleMajorityVote, 
            uint32[] closingTime, 
            uint minStake, 
            uint maxStake, 
            uint incentive
        ) 
    {
        cateId = _categoryId;
        memberRoleSequence = allCategory[_categoryId].memberRoleSequence;
        memberRoleMajorityVote = allCategory[_categoryId].memberRoleMajorityVote;
        closingTime = allCategory[_categoryId].closingTime;
        minStake = allCategory[_categoryId].minStake;
        maxStake = allCategory[_categoryId].maxStake;
        incentive = allCategory[_categoryId].defaultIncentive;
    }

    /// @dev Gets minimum stake for category id
    function getMinStake(uint _categoryId) public constant returns(uint) {
        return allCategory[_categoryId].minStake;
    }

    /// @dev Gets maximum stake for category id
    function getMaxStake(uint _categoryId) public constant returns(uint) {
        return allCategory[_categoryId].maxStake;
    }

    /// @dev Gets Majority threshold array length when giving main category id
    function getRoleMajorityVotelength(uint _categoryId) public constant returns(uint index, uint majorityVoteLength) {
        index = _categoryId;
        majorityVoteLength = allCategory[_categoryId].memberRoleMajorityVote.length;
    }

    /// @dev Gets Closing time array length when giving main category id
    function getClosingTimeLength(uint _categoryId) public constant returns(uint index, uint closingTimeLength) {
        index = _categoryId;
        closingTimeLength = allCategory[_categoryId].closingTime.length;
    }

    /// @dev Gets role sequence length by category id
    function getRoleSequencLength(uint _categoryId) public constant returns(uint roleLength) {
        roleLength = allCategory[_categoryId].memberRoleSequence.length;
    }

    /// @dev Gets Closing time array length when giving main category id
    function getCloseTimeLength(uint _categoryId) public constant returns(uint) {
        return allCategory[_categoryId].closingTime.length;
    }

    /// @dev Gets Closing time at particular index from Closing time array
    /// @param _categoryId Id of main category
    /// @param _index Current voting status againt proposal act as an index here
    function getClosingTimeAtIndex(uint _categoryId, uint _index) public constant returns(uint closeTime) {
        return allCategory[_categoryId].closingTime[_index];
    }

    /// @dev Gets Voting layer role sequence at particular index from Role sequence array
    /// @param _categoryId Id of main category
    /// @param _index Current voting status againt proposal act as an index here
    function getRoleSequencAtIndex(uint _categoryId, uint _index) public constant returns(uint32 roleId) {
        return allCategory[_categoryId].memberRoleSequence[_index];
    }

    /// @dev Gets Majority threshold value at particular index from Majority Vote array
    /// @param _categoryId Id of main category
    /// @param _index Current voting status againt proposal act as an index here
    function getRoleMajorityVoteAtIndex(uint _categoryId, uint _index) public constant returns(uint majorityVote) {
        return allCategory[_categoryId].memberRoleMajorityVote[_index];
    }

    /// @dev Gets Default incentive to be distributed against category.
    function getCatIncentive(uint _categoryId) public constant returns(uint incentive) {
        incentive = allCategory[_categoryId].defaultIncentive;
    }

    /// @dev Gets Default incentive to be distributed against category.
    function getCategoryIncentive(uint _categoryId) public constant returns(uint category, uint incentive) {
        category = _categoryId;
        incentive = allCategory[_categoryId].defaultIncentive;
    }

    /// @dev Gets Total number of categories added till now
    function getCategoryLength() public constant returns(uint) {
        return allCategory.length;
    }

    /// @dev Gets Cateory description hash when giving category id
    function getCategoryName(uint _categoryId) public constant returns(uint, string) {
        return (_categoryId, allCategory[_categoryId].name);
    }

    /// @dev Gets Category data depending upon current voting index in Voting sequence.
    /// @param _categoryId Category id
    /// @param _currVotingIndex Current voting Id in voting seqeunce.
    /// @return Next member role to vote with its closing time and majority vote.
    function getCategoryData3(uint _categoryId, uint _currVotingIndex) 
        public
        constant 
        returns(uint8 roleSequence, uint majorityVote, uint closingTime) 
    {
        return (
            allCategory[_categoryId].memberRoleSequence[_currVotingIndex], 
            allCategory[_categoryId].memberRoleMajorityVote[_currVotingIndex], 
            allCategory[_categoryId].closingTime[_currVotingIndex]
        );
    }

    /// @dev Gets Category and SubCategory name from Proposal ID.
    function getCatAndSubNameByPropId(uint _proposalId) 
        public 
        constant 
        returns(string categoryName, string subCategoryName) 
    {
        categoryName = allCategory[getCategoryIdBySubId(governanceDat.getProposalCategory(_proposalId))].name;
        subCategoryName = allSubCategory[governanceDat.getProposalCategory(_proposalId)].categoryName;
    }

    /// @dev Gets Category ID from Proposal ID.
    function getCatIdByPropId(uint _proposalId) public constant returns(uint8 catId) {
        catId = getCategoryIdBySubId(governanceDat.getProposalCategory(_proposalId));
    }

    /// @dev adds second half of the inital categories
    function addInitialSubCategories1() internal {
        master = Master(masterAddress);
        
        allSubIdByCategory[2].push(3);
        allSubCategory.push(SubCategory(
                "Add new category",
                "QmchfnafX5dZXcpivStWQepfDrpeTskNxftkNHAZuWhDFK",
                2,
                master.getLatestAddress("PC")
            )
        );
        allSubIdByCategory[2].push(4);
        allSubCategory.push(SubCategory(
                "Edit category",
                "QmSdBuXa3UQiWqqdyponEGnwX2AGShqHEMEBXdZv4gmPAN",
                2,
                master.getLatestAddress("PC")
            )
        );
        allSubIdByCategory[2].push(5);
        allSubCategory.push(SubCategory(
                "Add new sub category",
                "QmYFBALQHBSyKQVnUxSRSHwbv6Ct8yeC1vLRRuvUkMSC2L",
                2,
                master.getLatestAddress("PC")
            )
        );
        allSubIdByCategory[2].push(6);
        allSubCategory.push(SubCategory(
                "Edit sub category",
                "QmesRxLedQDxZmnXr8667VhHaoJ5DEGUW8ryUGUy69SQeq",
                2,
                master.getLatestAddress("PC")
            )
        );
        allSubIdByCategory[3].push(7);
        allSubCategory.push(SubCategory(
                "Configure parameters",
                "QmYzP1MKehbfaAYBkfuTckXd4DN5WSEwnzKqpTBeWB253M",
                3,
                masterAddress
            )
        );
        allSubIdByCategory[4].push(8);
        allSubCategory.push(SubCategory("Others, not specified", "", 4, 0x00));
    }

    // /// @dev Sets closing time for the category
    // /// @param _categoryId Category id
    // /// @param _time Closing time
    // function setClosingTime(uint _categoryId,uint24 _time)
    // {
    //     allCategory[_categoryId].closingTime.push(_time);
    // }

    // /// @dev Sets role sequence for categoryId=_categoryId and role sequence=_roleSequence
    // function setRoleSequence(uint _categoryId,uint8 _roleSequence)
    // {
    //     allCategory[_categoryId].memberRoleSequence.push(_roleSequence);
    // }

    // /// @dev Sets majority vote for category id=_categoryId and majority value=_majorityVote
    // function setMajorityVote(uint _categoryId,uint _majorityVote)
    // {
    //     allCategory[_categoryId].memberRoleMajorityVote.push(_majorityVote);
    // }

    // /// @dev Changes role name by category id
    // /// @param _categoryId Category id
    // /// @param _roleName Role name 
    // function changeRoleNameById(uint _categoryId,uint8[] _roleName) internal
    // {
    //     allCategory[_categoryId].memberRoleSequence=new uint8[](_roleName.length);
    //     for(uint i=0; i<_roleName.length; i++)
    //     {
    //         allCategory[_categoryId].memberRoleSequence[i] = _roleName[i];
    //     }
    // }

    // /// @dev Changes majority of vote of a category by id
    // /// @param _categoryId Category id
    // /// @param _majorityVote Majority of votes
    // function changeMajorityVoteById(uint _categoryId,uint[] _majorityVote) internal
    // {
    //     allCategory[_categoryId].memberRoleMajorityVote=new uint[](_majorityVote.length);
    //     for(uint i=0; i<_majorityVote.length; i++)
    //     {
    //         allCategory[_categoryId].memberRoleMajorityVote[i] = _majorityVote[i];
    //     }
    // }    

    // /// @dev Changes closing time by cateory id
    // /// @param _categoryId Category id
    // /// @param _closingTime Closing time
    // function changeClosingTimeById(uint _categoryId,uint24[] _closingTime) internal
    // {
    //     allCategory[_categoryId].closingTime=new uint24[](_closingTime.length);
    //     for(uint i=0; i<_closingTime.length; i++)
    //     {
    //         allCategory[_categoryId].closingTime[i] = _closingTime[i];
    //     }
    // }

    // /// @dev Changes minimum stake by id
    // /// @param _categoryId Category id
    // /// @param _minStake Minimum stake
    // function changeMinStakeById(uint _categoryId,uint8 _minStake) internal
    // {
    //     allCategory[_categoryId].minStake = _minStake;
    // }

    // /// @dev Changes maximum stake by category id
    // function changeMaxStakeById(uint _categoryId,uint8 _maxStake) internal
    // {
    //     allCategory[_categoryId].maxStake = _maxStake;
    // }

    // /// @dev Changes incentive by category id
    // function changeIncentiveById(uint _categoryId,uint _incentive) internal
    // {
    //     allCategory[_categoryId].defaultIncentive = _incentive;
    // }

    // /// @dev Changes reward percentage proposal by category id
    // /// @param _categoryId Category id
    // /// @param _value Reward percentage value
    // function changeRewardPercProposal(uint _categoryId,uint _value) internal
    // {
    //     allCategory[_categoryId].rewardPercProposal = _value;
    // }

    // /// @dev Changes reward percentage option by category id
    // /// @param _categoryId Category id
    // /// @param _value Reward percentage value
    // function changeRewardPercSolution(uint _categoryId,uint _value) internal
    // {
    //     allCategory[_categoryId].rewardPercSolution = _value;    
    // }

    // /// @dev Changes reward percentage vote by category id
    // /// @param _categoryId Category id
    // /// @param _value 
    // function changeRewardPercVote(uint _categoryId,uint _value) internal
    // {
    //     allCategory[_categoryId].rewardPercVote = _value;
    // }

}