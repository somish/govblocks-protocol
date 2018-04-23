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
import "./GBTStandardToken.sol";
import "./memberRoles.sol";
import "./governanceData.sol";

contract ProposalCategory
{
    uint8 public constructorCheck;

    struct category
    {
        string categoryDescHash;
        uint8[] memberRoleSequence;
        uint[] memberRoleMajorityVote;
        uint[] closingTime;
        uint8 minStake;
        uint8 maxStake;
        uint defaultIncentive;
        uint rewardPercProposal;
        uint rewardPercOption;
        uint rewardPercVote;
    }

    category[] public allCategory;
    Master M1;  
    memberRoles MR;
    GBTStandardToken GBTS;
    governanceData GD;
    address masterAddress;
    address GBMAddress;
    address GBTSAddress;

    modifier onlyInternal {
        M1=Master(masterAddress);
        require(M1.isInternal(msg.sender) == true);
        _; 
    }
    
     modifier onlyOwner {
        M1=Master(masterAddress);
        require(M1.isOwner(msg.sender) == true);
        _; 
    }
    
    modifier onlyGBM
    {
        require(msg.sender == GBMAddress);
        _;
    }

    modifier onlyMaster {
        require(msg.sender == masterAddress);
        _; 
    }

    /// @dev Changes GovBlocks master address
    /// @param _GBMAddress New GovBlocks master address
    function changeGBMAddress(address _GBMAddress) onlyGBM
    {
        GBMAddress = _GBMAddress;
    }
    
    /// @dev Changes GovBlocks standard token address
    /// @param _GBTAddress New GovBlocks token address
    function changeGBTSAddress(address _GBTAddress) onlyMaster
    {
        GBTSAddress = _GBTAddress;
    }   

    /// @dev Changes master's contract address
    /// @param _masterContractAddress New master contract address
    function changeMasterAddress(address _masterContractAddress) 
    {
        if(masterAddress == 0x000)
            masterAddress = _masterContractAddress;
        else
        {
            M1=Master(masterAddress);
            require(M1.isInternal(msg.sender) == true);
                masterAddress = _masterContractAddress;
        }
    }

    // /// @dev Changes all contracts' addresses
   // /// @param _MRAddress New member roles contract address
    // function changeAllContractsAddress(address _MRAddress) onlyInternal
    // {
    //     MRAddress= _MRAddress;
    // }

    function changeAddress(bytes4 contractName, address contractAddress){
        if(contractName == 'MR'){
            MR = memberRoles(contractAddress);
        }
    }

    /// @dev Initiates proposal category
    /// @param _GBMAddress New GovBlocks master address
    function ProposalCategoryInitiate(address _GBMAddress)
    {
        require(constructorCheck == 0);
        GBMAddress = _GBMAddress;
        // addNewCategory("QmcEP2ELejTFsaLCeiukMNS9HSg6mxitFubHEuuLDSLbYt");
        // addNewCategory("QmeX5jkkSFPrsehqsit7zMWmTXB6pTeSHscE3HRiA1R9t5");
        // addNewCategory("Qmb2RQ4t6b7BEevbMqF4jjjZxEbp5bspHAX8ZdL8s7t8N8");
        // addNewCategory("QmeYFNJvVH6nkk2fFjnzgxQm9szxV3ocpFnKE2wBWaVhDN");
        // addNewCategory("QmcAiWumEJaF6jLg14eaLU9WgdKLSy8bzPLNHMCSUZxU9a");
        // addNewCategory("QmWTbFV1TW3Pw79tCwuJUwNyXKZVkxzkW1xW4sL9CYzUmA");
        // addNewCategory("QmWjCR7sMyxHa3MwExSYkEZNdiugUvqukz2wkiVqFvEVu8");
        constructorCheck =1;
    }

    /// @dev Adds new category
    /// @param _categoryData Category data
    /// @param _memberRoleSequence Member role sequence
    /// @param _memberRoleMajorityVote Majority of votes of a particular member role
    /// @param _closingTime Closing time of category
    /// @param _minStake Minimum stake
    /// @param _maxStake Maximum stake
    /// @param _defaultIncentive Default incentive
    function addNewCategory(string _categoryData,uint8[] _memberRoleSequence,uint[] _memberRoleMajorityVote,uint[] _closingTime,uint8 _minStake,uint8 _maxStake,uint8 _defaultIncentive) 
    {
        require(msg.sender == GBMAddress);
        require(_memberRoleSequence.length == _memberRoleMajorityVote.length && _memberRoleSequence.length == _closingTime.length);
        allCategory.push(category(_categoryData,_memberRoleSequence,_memberRoleMajorityVote,_closingTime,_minStake,_maxStake,_defaultIncentive,0,0,0));    
    }

    /// @dev Updates category
    /// @param _categoryId Category id
    /// @param _categoryData Category data
    function updateCategory(uint _categoryId,string _categoryData) 
    {
        require(msg.sender == GBMAddress);
            allCategory[_categoryId].categoryDescHash = _categoryData;
    }

    /// @dev Sets closing time for the category
    /// @param _categoryId Category id
    /// @param _time Closing time
    function setClosingTime(uint _categoryId,uint24 _time)
    {
        allCategory[_categoryId].closingTime.push(_time);
    }

    /// @dev Sets role sequence for categoryId=_categoryId and role sequence=_roleSequence
    function setRoleSequence(uint _categoryId,uint8 _roleSequence)
    {
        allCategory[_categoryId].memberRoleSequence.push(_roleSequence);
    }

    /// @dev Sets majority vote for category id=_categoryId and majority value=_majorityVote
    function setMajorityVote(uint _categoryId,uint _majorityVote)
    {
        allCategory[_categoryId].memberRoleMajorityVote.push(_majorityVote);
    }

    /// @dev Updates category details
    /// @param _categoryId Category id
    /// @param _roleName Role name
    /// @param _majorityVote Majority of votes
    /// @param _closingTime Closing time
    /// @param _minStake Minimum stake
    /// @param _maxStake Maximum stake
    /// @param _defaultIncentive Default incentive
    function updateCategoryDetails(uint _categoryId,uint8[] _roleName,uint[] _majorityVote,uint24[] _closingTime,uint8 _minStake,uint8 _maxStake, uint _defaultIncentive)
    {
        require(_roleName.length == _majorityVote.length && _roleName.length == _closingTime.length);
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

    /// @dev Changes role name by category id
    /// @param _categoryId Category id
    /// @param _roleName Role name 
    function changeRoleNameById(uint _categoryId,uint8[] _roleName)
    {
        allCategory[_categoryId].memberRoleSequence=new uint8[](_roleName.length);
        for(uint i=0; i<_roleName.length; i++)
        {
            allCategory[_categoryId].memberRoleSequence[i] = _roleName[i];
        }
    }

    /// @dev Changes majority of vote of a category by id
    /// @param _categoryId Category id
    /// @param _majorityVote Majority of votes
    function changeMajorityVoteById(uint _categoryId,uint[] _majorityVote)
    {
        allCategory[_categoryId].memberRoleMajorityVote=new uint[](_majorityVote.length);
        for(uint i=0; i<_majorityVote.length; i++)
        {
            allCategory[_categoryId].memberRoleMajorityVote[i] = _majorityVote[i];
        }
    }    

    /// @dev Changes closing time by cateory id
    /// @param _categoryId Category id
    /// @param _closingTime Closing time
    function changeClosingTimeById(uint _categoryId,uint24[] _closingTime)
    {
        allCategory[_categoryId].closingTime=new uint24[](_closingTime.length);
        for(uint i=0; i<_closingTime.length; i++)
        {
            allCategory[_categoryId].closingTime[i] = _closingTime[i];
        }
    }

    /// @dev Changes minimum stake by id
    /// @param _categoryId Category id
    /// @param _minStake Minimum stake
    function changeMinStakeById(uint _categoryId,uint8 _minStake)
    {
        allCategory[_categoryId].minStake = _minStake;
    }

    /// @dev Changes maximum stake by category id
    function changeMaxStakeById(uint _categoryId,uint8 _maxStake)
    {
        allCategory[_categoryId].maxStake = _maxStake;
    }
    
    /// @dev Changes incentive by category id
    function changeIncentiveById(uint _categoryId,uint _incentive)
    {
        allCategory[_categoryId].defaultIncentive = _incentive;
    }

    /// @dev Changes reward percentage proposal by category id
    /// @param _categoryId Category id
    /// @param _value Reward percentage value
    function changeRewardPercProposal(uint _categoryId,uint _value)
    {
        allCategory[_categoryId].rewardPercProposal = _value;
    }

    /// @dev Changes reward percentage option by category id
    /// @param _categoryId Category id
    /// @param _value Reward percentage value
    function changeRewardPercOption(uint _categoryId,uint _value)
    {
        allCategory[_categoryId].rewardPercOption = _value;    
    }

    /// @dev Changes reward percentage vote by category id
    /// @param _categoryId Category id
    /// @param _value 
    function changeRewardPercVote(uint _categoryId,uint _value)
    {
        allCategory[_categoryId].rewardPercVote = _value;
    }

    /// @dev Gets remaining closing time
    /// @param _proposalId Proposal id
    /// @param _categoryId Category id
    /// @param _index Index of categories
    /// @return totalTime Total time remaining before closing
    function getRemainingClosingTime(uint _proposalId,uint _categoryId,uint _index) constant returns (uint totalTime)
    {
        GBTS=GBTStandardToken(GBTSAddress);
        
        uint pClosingTime;
        for(uint i=0; i<getCloseTimeLength(_categoryId); i++)
        {
            pClosingTime = pClosingTime + getClosingTimeAtIndex(_categoryId,_index);
        }
    // date Add in events ASK HERE
        totalTime = (pClosingTime+GBTS.tokenHoldingTime()+GD.getProposalDateUpd(_proposalId))-now; 
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
        return allCategory[_categoryId].rewardPercOption;
    }

    /// @dev Gets reward percentage vote by category id    
    function getRewardPercVote(uint _categoryId)constant returns(uint)
    {
        return allCategory[_categoryId].rewardPercVote;
    }

    /// @dev Gets category data for category id
    /// @param category Category id  
    /// @param roleName Role name
    /// @param majorityVote Majority vote  
    /// @param closingTime Closing time of category  
    function getCategoryData2(uint _categoryId) constant returns(uint category,bytes32[] roleName,uint[] majorityVote,uint[] closingTime)
    {
        // MR=memberRoles(MRAddress);
        category = _categoryId;
        roleName=new bytes32[]( allCategory[_categoryId].memberRoleSequence.length);
        for(uint8 i=0; i < allCategory[_categoryId].memberRoleSequence.length; i++)
        {
            bytes32 name;
            (,name) = MR.getMemberRoleNameById(allCategory[_categoryId].memberRoleSequence[i]);
            roleName[i] = name;
        }
        
        majorityVote = allCategory[_categoryId].memberRoleMajorityVote;
        closingTime =  allCategory[_categoryId].closingTime;
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
    function getRoleSequencAtIndex(uint _categoryId,uint _index) constant returns(uint roleId)
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
        return allCategory[_categoryId].categoryDescHash;
    }

    /// @dev Gets Category data depending upon current voting index in Voting sequence.
    /// @param _categoryId Category id
    /// @param _currVotingIndex Current voting index in voting seqeunce.
    /// @return Next member role to vote with its closing time and majority vote.
    function getCategoryData3(uint _categoryId,uint _currVotingIndex)constant returns(uint8 roleSequence,uint majorityVote,uint closingTime)
    {
        return (allCategory[_categoryId].memberRoleSequence[_currVotingIndex],allCategory[_categoryId].memberRoleMajorityVote[_currVotingIndex],allCategory[_categoryId].closingTime[_currVotingIndex]);
    }
}