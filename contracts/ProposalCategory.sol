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
import "./memberRoles.sol";

contract ProposalCategory
{
    uint8 public constructorCheck;

    struct category
    {
        string categoryDescHash;
        uint8[] memberRoleSequence;
        uint[] memberRoleMajorityVote;
        uint24[] closingTime;
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
    address MRAddress;
    address masterAddress;
    address GBMAddress;

     modifier onlyInternal {
        M1=Master(masterAddress);
        require(M1.isInternal(msg.sender) == 1);
        _; 
    }

     modifier onlyOwner {
        M1=Master(masterAddress);
        require(M1.isOwner(msg.sender) == 1);
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

    function changeGBMAddress(address _GBMAddress) onlyGBM
    {
        GBMAddress = _GBMAddress;
    }
    
    /// @dev Change master's contract address
    function changeMasterAddress(address _masterContractAddress) 
    {
        if(masterAddress == 0x000)
            masterAddress = _masterContractAddress;
        else
        {
            M1=Master(masterAddress);
            require(M1.isInternal(msg.sender) == 1);
                masterAddress = _masterContractAddress;
        }
    }

    function changeAllContractsAddress(address _MRAddress) onlyInternal
    {
        MRAddress= _MRAddress;
    }

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

    function addNewCategory(string _categoryData,uint8[] _memberRoleSequence,uint[] _memberRoleMajorityVote,uint24[] _closingTime,uint8 _minStake,uint8 _maxStake,uint8 _defaultIncentive) 
    {
        require(msg.sender == GBMAddress);
        require(_memberRoleSequence.length == _memberRoleMajorityVote.length && _memberRoleSequence.length == _closingTime.length);
        allCategory.push(category(_categoryData,_memberRoleSequence,_memberRoleMajorityVote,_closingTime,_minStake,_maxStake,_defaultIncentive,0,0,0));    
    }

    function updateCategory(uint _categoryId,string _categoryData) 
    {
        require(msg.sender == GBMAddress);
            allCategory[_categoryId].categoryDescHash = _categoryData;
    }

    function setClosingTime(uint _categoryId,uint24 _time)
    {
        allCategory[_categoryId].closingTime.push(_time);
    }

    function setRoleSequence(uint _categoryId,uint8 _roleSequence)
    {
        allCategory[_categoryId].memberRoleSequence.push(_roleSequence);
    }

    function setMajorityVote(uint _categoryId,uint _majorityVote)
    {
        allCategory[_categoryId].memberRoleMajorityVote.push(_majorityVote);
    }

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

    function changeRoleNameById(uint _categoryId,uint8[] _roleName)
    {
        allCategory[_categoryId].memberRoleSequence=new uint8[](_roleName.length);
        for(uint i=0; i<_roleName.length; i++)
        {
            allCategory[_categoryId].memberRoleSequence[i] = _roleName[i];
        }
    }

    function changeMajorityVoteById(uint _categoryId,uint[] _majorityVote)
    {
        allCategory[_categoryId].memberRoleMajorityVote=new uint[](_majorityVote.length);
        for(uint i=0; i<_majorityVote.length; i++)
        {
            allCategory[_categoryId].memberRoleMajorityVote[i] = _majorityVote[i];
        }
    }    

    function changeClosingTimeById(uint _categoryId,uint24[] _closingTime)
    {
        allCategory[_categoryId].closingTime=new uint24[](_closingTime.length);
        for(uint i=0; i<_closingTime.length; i++)
        {
            allCategory[_categoryId].closingTime[i] = _closingTime[i];
        }
    }

    function changeMinStakeById(uint _categoryId,uint8 _minStake)
    {
        allCategory[_categoryId].minStake = _minStake;
    }

    function changeMaxStakeById(uint _categoryId,uint8 _maxStake)
    {
        allCategory[_categoryId].maxStake = _maxStake;
    }
    
    function changeIncentiveById(uint _categoryId,uint _incentive)
    {
        allCategory[_categoryId].defaultIncentive = _incentive;
    }

    function changeLockPercProposal(uint _categoryId,uint _value)
    {
        allCategory[_categoryId].lockPercProposal = _value;
    }

    function changeLockPercOption(uint _categoryId,uint _value)
    {
        allCategory[_categoryId].lockPercOption = _value;    
    }

    function changeLockPercVote(uint _categoryId,uint _value)
    {
        allCategory[_categoryId].lockPercVote = _value;
    }

    function getLockPercProposal(uint _categoryId)constant returns(uint)
    {
        return allCategory[_categoryId].lockPercProposal;
    }

    function getLockPercOption(uint _categoryId)constant returns(uint)
    {
        return allCategory[_categoryId].lockPercOption;
    }

    function (uint _categoryId)constant returns(uint)
    {
        return allCategory[_categoryId].lockPercVote;
    }

    function getCategoryData2(uint _categoryId) constant returns(uint category,bytes32[] roleName,uint[] majorityVote,uint24[] closingTime)
    {
        MR=memberRoles(MRAddress);
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

    function getCategoryDetails(uint _categoryId) public constant returns (uint cateId,uint8[] memberRoleSequence,uint[] memberRoleMajorityVote,uint24[] closingTime,uint minStake,uint maxStake,uint incentive)
    {    
        cateId = _categoryId;
        memberRoleSequence = allCategory[_categoryId].memberRoleSequence;
        memberRoleMajorityVote = allCategory[_categoryId].memberRoleMajorityVote;
        closingTime = allCategory[_categoryId].closingTime;
        minStake = allCategory[_categoryId].minStake;
        maxStake = allCategory[_categoryId].maxStake;
        incentive = allCategory[_categoryId].defaultIncentive; 
    } 

    function getMinStake(uint _categoryId)constant returns(uint8) 
    {
        return allCategory[_categoryId].minStake;
    }

    function getMaxStake(uint _categoryId) constant returns(uint8)
    {
        return allCategory[_categoryId].maxStake;
    }

    function getRoleMajorityVotelength(uint _categoryId) constant returns(uint index,uint majorityVoteLength)
    {
        index = _categoryId;
        majorityVoteLength= allCategory[_categoryId].memberRoleMajorityVote.length;
    }

    function getClosingTimeLength(uint _categoryId) constant returns(uint index,uint closingTimeLength)
    {
        index = _categoryId;
        closingTimeLength = allCategory[_categoryId].closingTime.length;
    }

    function getRoleSequencLength(uint _categoryId) constant returns(uint roleLength)
    {
        roleLength = allCategory[_categoryId].memberRoleSequence.length;
    }

    function getClosingTimeAtIndex(uint _categoryId,uint _index) constant returns(uint24 closeTime)
    {
        return allCategory[_categoryId].closingTime[_index];
    }

    function getRoleSequencAtIndex(uint _categoryId,uint _index) constant returns(uint roleId)
    {
        return allCategory[_categoryId].memberRoleSequence[_index];
    }

    function getRoleMajorityVoteAtIndex(uint _categoryId,uint _index) constant returns(uint majorityVote)
    {
        return allCategory[_categoryId].memberRoleMajorityVote[_index];
    }
 
    function getCatIncentive(uint _categoryId)constant returns(uint incentive)
    {
        incentive = allCategory[_categoryId].defaultIncentive;
    }

    function getCategoryIncentive(uint _categoryId)constant returns(uint category,uint incentive)
    {
        category = _categoryId;
        incentive = allCategory[_categoryId].defaultIncentive;
    }

    function getCategoryLength()constant returns(uint)
    {
        return allCategory.length;
    }

    function getCategoryData1(uint _categoryId) constant returns(string)
    {
        return allCategory[_categoryId].categoryDescHash;
    }    
}