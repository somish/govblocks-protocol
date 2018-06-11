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
pragma solidity ^0.4.8;
import "./Master.sol";
import "./governanceData.sol";
import "./memberRoles.sol";

contract ProposalCategory
{
    bool public constructorCheck;
    struct category
    {
        string name;
        uint8[] memberRoleSequence;
        uint[] memberRoleMajorityVote;
        uint[] closingTime;
        uint8 minStake;
        uint8 maxStake;
        uint defaultIncentive;
        uint rewardPercProposal;
        uint rewardPercSolution;
        uint rewardPercVote;
    }

    struct subCategory
    {
        string categoryName;
        string actionHash;
        uint8 categoryId;
    }

    subCategory[] public allSubCategory;
    category[] public allCategory;
    // mapping(uint8=>uint8) categoryIdBySubId; // Given SubcategoryidThen CategoryId
    mapping(uint8=>uint[]) allSubId_byCategory;
    
    Master MS;  
    memberRoles MR;
    governanceData GD;
    address masterAddress;

    modifier onlyInternal {
        MS=Master(masterAddress);
        require(MS.isInternal(msg.sender) == true);
        _; 
    }
    
    modifier onlyOwner {
        MS=Master(masterAddress);
        require(MS.isOwner(msg.sender) == true);
        _; 
    }
    
    modifier onlyMaster {
        require(msg.sender == masterAddress);
        _; 
    }
    
    modifier onlyGBM(uint8[] arr1,uint[] arr2,uint[]arr3) {
        MS=Master(masterAddress);
        require(MS.isGBM(msg.sender) == true);
        require(arr1.length == arr2.length && arr1.length == arr3.length);
        _;
    }

    modifier onlyGBMSubCategory() 
    { 
            MS=Master(masterAddress);
            require(MS.isGBM(msg.sender) == true);
        _; 
    }

    /// @dev Changes master's contract address
    /// @param _masterContractAddress New master contract address
    function changeMasterAddress(address _masterContractAddress) 
    {
        if(masterAddress == 0x000)
            masterAddress = _masterContractAddress;
        else
        {
            MS=Master(masterAddress);
            require(MS.isInternal(msg.sender) == true);
                masterAddress = _masterContractAddress;
        }
    }

    function changeAddress(bytes4 contractName, address contractAddress) onlyInternal
    {
        if(contractName == 'MR'){
            MR = memberRoles(contractAddress);
        }
        else if(contractName == 'GD'){
            GD = governanceData(contractAddress);
        }
    }

    /// @dev Initiates proposal category
    function ProposalCategoryInitiate()
    {
        require(constructorCheck == false);
        uint8[] memory roleSeq=new uint8[](1); 
        uint[] memory majVote=new uint[](1);
        uint[] memory closeTime=new uint[](1);
        roleSeq[0]=1;
        majVote[0]=50;
        closeTime[0]=1800;
        
        allCategory.push(category("Uncategorized",roleSeq,majVote,closeTime,0,0,0,0,0,0));
        allCategory.push(category("Change to member role",roleSeq,majVote,closeTime,0,100,10,20,20,20));
        //allCategory.push(category("QmYGFMsRq2MyW9eDutHij6Wa8CARygxhCASLyYm5GpeksQ",roleSeq,majVote,closeTime,0,100,0,20,20,20));
        allCategory.push(category("Changes to categories",roleSeq,majVote,closeTime,0,100,0,20,20,20));
        // allCategory.push(category("QmfQvZmENE3SLa6AKSFgWCBrMy6akBiXfGfCMVc5q1mBW9",roleSeq,majVote,closeTime,0,100,0,20,20,20));
        allCategory.push(category("Changes in governance parameters",roleSeq,majVote,closeTime,0,100,0,20,20,20));
        allCategory.push(category("Others not specified",roleSeq,majVote,closeTime,0,10,0,20,20,20));
        
        allSubId_byCategory[0].push(0);
        allSubCategory.push(subCategory("Uncategorized","",0));
        
        allSubId_byCategory[1].push(1);
        allSubCategory.push(subCategory("Add new member role","QmZUeoP9g1hNzKQ8WHGkkwmMLq3fTeSFJPwSPKXJ49wG6G",1));
        
        allSubId_byCategory[1].push(0);
        allSubCategory.push(subCategory("Update member role","QmYGFMsRq2MyW9eDutHij6Wa8CARygxhCASLyYm5GpeksQ",1));
        
        allSubId_byCategory[2].push(0);
        allSubCategory.push(subCategory("Add new category","QmZ59ZaioUCw2pM3hERiZaFE8LNMZSC4d6xVN28D95R6qs",2));
        
        allSubId_byCategory[2].push(1);
        allSubCategory.push(subCategory("Edit category","QmfQvZmENE3SLa6AKSFgWCBrMy6akBiXfGfCMVc5q1mBW9",2));
        
        allSubId_byCategory[3].push(0);
        allSubCategory.push(subCategory("Configure parameters","QmRuxEtR7jNyh9urbraFSsCVurxSTkyx7DgTTZkERqa3BW",3));
        
        allSubId_byCategory[4].push(0);
        allSubCategory.push(subCategory("Others, not specified","",4));
        
        constructorCheck = true;
    }

    /// @dev Adds new category
    /// @param _categoryData Category data
    /// @param _memberRoleSequence Member role sequence
    /// @param _memberRoleMajorityVote Majority of votes of a particular member role
    /// @param _closingTime Closing time of category
    /// @param _minStake Minimum stake
    /// @param _maxStake Maximum stake
    /// @param _defaultIncentive Default incentive
    function addNewCategory(string _categoryData,uint8[] _memberRoleSequence,uint[] _memberRoleMajorityVote,uint[] _closingTime,uint8 _minStake,uint8 _maxStake,uint8 _defaultIncentive) onlyGBM(_memberRoleSequence,_memberRoleMajorityVote,_closingTime)
    {
        allCategory.push(category(_categoryData,_memberRoleSequence,_memberRoleMajorityVote,_closingTime,_minStake,_maxStake,_defaultIncentive,0,0,0));    
    }

    /// @dev Updates category details
    /// @param _categoryId Category id
    /// @param _roleName Role name
    /// @param _majorityVote Majority of votes
    /// @param _closingTime Closing time
    /// @param _minStake Minimum stake
    /// @param _maxStake Maximum stake
    /// @param _defaultIncentive Default incentive
    function updateCategory(uint _categoryId,string _descHash,uint8[] _roleName,uint[] _majorityVote,uint[] _closingTime,uint8 _minStake,uint8 _maxStake, uint _defaultIncentive) onlyGBM(_roleName,_majorityVote,_closingTime)
    {
        allCategory[_categoryId].name = _descHash;
        allCategory[_categoryId].minStake = _minStake;
        allCategory[_categoryId].maxStake = _maxStake;
        allCategory[_categoryId].defaultIncentive = _defaultIncentive;

        allCategory[_categoryId].memberRoleSequence=new uint8[](_roleName.length);
        allCategory[_categoryId].memberRoleMajorityVote=new uint[](_majorityVote.length);
        allCategory[_categoryId].closingTime = new uint24[](_closingTime.length);

        for(uint i=0; i<_roleName.length; i++)
        {
            allCategory[_categoryId].memberRoleSequence[i] =_roleName[i];
            allCategory[_categoryId].memberRoleMajorityVote[i] = _majorityVote[i];
            allCategory[_categoryId].closingTime[i] = _closingTime[i];
        }
    }

    function addNewSubCategory(string _categoryName,string actionHash,uint8 _mainCategoryId) onlyGBMSubCategory
    {
        allSubId_byCategory[_mainCategoryId].push(allSubCategory.length);
        allSubCategory.push(subCategory(_categoryName,actionHash,_mainCategoryId));
    }

    function updateSubCategory(uint8 _subCategoryId,string _actionHash) onlyGBMSubCategory
    {
        allSubCategory[_subCategoryId].actionHash=_actionHash;
        
    }

    function getSubCategoryDetails(uint8 _subCategoryId)constant returns(string,string,uint8)
    {
        return (allSubCategory[_subCategoryId].categoryName,allSubCategory[_subCategoryId].actionHash,allSubCategory[_subCategoryId].categoryId);
    }
    
    function getSubCategoryId_atIndex(uint8 _categoryId,uint _index)constant returns(uint _subCategoryId)
    {
       return allSubId_byCategory[_categoryId][_index];     
    }

    function getAllSubIds_byCategory(uint8 _categoryId)constant returns(uint[])
    {
        return allSubId_byCategory[_categoryId];
    }

    function getAllSubIdsLength_byCategory(uint8 _categoryId)constant returns(uint)
    {
        return allSubId_byCategory[_categoryId].length;
    }

    function getCategoryId_bySubId(uint8 _subCategoryId)constant returns(uint8)
    {
        return allSubCategory[_subCategoryId].categoryId;
    }

    /// @dev Gets remaining closing time
    /// @param _proposalId Proposal id
    /// @param _categoryId Category id
    /// @param _index Index of categories
    /// @return totalTime Total time remaining before closing
    function getRemainingClosingTime(uint _proposalId,uint _categoryId,uint _index) constant returns (uint totalTime)
    {      
        uint pClosingTime;
        for(uint i=_index; i<getCloseTimeLength(_categoryId); i++)
        {
            pClosingTime = pClosingTime + getClosingTimeAtIndex(_categoryId,i);
        }

        totalTime = (pClosingTime+GD.tokenHoldingTime()+GD.getProposalDateUpd(_proposalId))-now; 
        return totalTime;
    }

    /// @dev Gets reward percentage proposal by category id
    function getRewardPercProposal(uint _categoryId)constant returns(uint)
    {
        return allCategory[_categoryId].rewardPercProposal;
    }

    /// @dev Gets reward percentage option by category id
    function getRewardPercSolution(uint _categoryId)constant returns(uint)
    {
        return allCategory[_categoryId].rewardPercSolution;
    }

    /// @dev Gets reward percentage vote by category id    
    function getRewardPercVote(uint _categoryId)constant returns(uint)
    {
        return allCategory[_categoryId].rewardPercVote;
    }

    /// @dev Gets category data for category id
    /// @param roleName Role name
    /// @param majorityVote Majority vote  
    /// @param closingTime Closing time of category  
    function getCategoryData2(uint _categoryId) constant returns(uint,bytes32[] roleName,uint[] majorityVote,uint[] closingTime)
    {
        // MR=memberRoles(MRAddress);
        uint roleLength = getRoleSequencLength(_categoryId);
        roleName=new bytes32[](roleLength);
        for(uint8 i=0; i < roleLength; i++)
        {
            bytes32 name;
            (,name) = MR.getMemberRoleNameById(getRoleSequencAtIndex(_categoryId,i));
            roleName[i] = name;
        }
        
        majorityVote = allCategory[_categoryId].memberRoleMajorityVote;
        closingTime =  allCategory[_categoryId].closingTime;
        return (_categoryId,roleName,majorityVote,closingTime);
    }

    /// @dev Gets category details
    /// @param closingTime Closing time of category
    /// @return cateId Category id
    /// @return memberRoleSequence Member role sequence for voting
    /// @return cateId Category id
    function getCategoryDetails(uint _categoryId) public constant returns (uint cateId,uint8[] memberRoleSequence,uint[] memberRoleMajorityVote,uint[] closingTime,uint minStake,uint maxStake,uint incentive)
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
    function getMinStake(uint _categoryId)constant returns(uint8) 
    {
        return allCategory[_categoryId].minStake;
    }

    /// @dev Gets maximum stake for category id
    function getMaxStake(uint _categoryId) constant returns(uint8)
    {
        return allCategory[_categoryId].maxStake;
    }

    /// @dev Gets member role's majority vote length
    /// @param _categoryId Category id
    /// @return index Category index
    /// @return majorityVoteLength Majority vote length
    function getRoleMajorityVotelength(uint _categoryId) constant returns(uint index,uint majorityVoteLength)
    {
        index = _categoryId;
        majorityVoteLength= allCategory[_categoryId].memberRoleMajorityVote.length;
    }

    /// @dev Gets closing time length
    /// @param _categoryId Category id
    /// @return index Category index
    /// @return closingTimeLength Closing time length
    function getClosingTimeLength(uint _categoryId) constant returns(uint index,uint closingTimeLength)
    {
        index = _categoryId;
        closingTimeLength = allCategory[_categoryId].closingTime.length;
    }

    /// @dev Gets closing time length by category id
    function getCloseTimeLength(uint _categoryId)constant returns(uint)
    {
        return allCategory[_categoryId].closingTime.length;
    }

    /// @dev Gets role sequence length by category id
    function getRoleSequencLength(uint _categoryId) constant returns(uint roleLength)
    {
        roleLength = allCategory[_categoryId].memberRoleSequence.length;
    }

    /// @dev Gets closing time of index= _index by category id
    function getClosingTimeAtIndex(uint _categoryId,uint _index) constant returns(uint closeTime)
    {
        return allCategory[_categoryId].closingTime[_index];
    }

    /// @dev Gets role sequence of index= _index by category id  
    function getRoleSequencAtIndex(uint _categoryId,uint _index) constant returns(uint32 roleId)
    {
        return allCategory[_categoryId].memberRoleSequence[_index];
    }

    /// @dev Gets majority of votes at index= _index by category id
    function getRoleMajorityVoteAtIndex(uint _categoryId,uint _index) constant returns(uint majorityVote)
    {
        return allCategory[_categoryId].memberRoleMajorityVote[_index];
    }
 
    /// @dev Gets category incentive at index= _index by category id
    function getCatIncentive(uint _categoryId)constant returns(uint incentive)
    {
        incentive = allCategory[_categoryId].defaultIncentive;
    }

    /// @dev Gets category id and incentive at index= _index by category id
    function getCategoryIncentive(uint _categoryId)constant returns(uint category,uint incentive)
    {
        category = _categoryId;
        incentive = allCategory[_categoryId].defaultIncentive;
    }

    /// @dev Gets category length
    /// @return allCategory.length Category length
    function getCategoryLength()constant returns(uint)
    {
        return allCategory.length;
    }

    /// @dev Gets category data of a given category id
    /// @param _categoryId Category id
    /// @return allCategory[_categoryId].categoryDescHash Hash of description of category id '_categoryId'
    function getCategoryData1(uint _categoryId) constant returns(string)
    {
        return allCategory[_categoryId].name;
    }

    /// @dev Gets Category data depending upon current voting index in Voting sequence.
    /// @param _categoryId Category id
    /// @param _currVotingIndex Current voting index in voting seqeunce.
    /// @return Next member role to vote with its closing time and majority vote.
    function getCategoryData3(uint _categoryId,uint _currVotingIndex)constant returns(uint8 roleSequence,uint majorityVote,uint closingTime)
    {
        return (allCategory[_categoryId].memberRoleSequence[_currVotingIndex],allCategory[_categoryId].memberRoleMajorityVote[_currVotingIndex],allCategory[_categoryId].closingTime[_currVotingIndex]);
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