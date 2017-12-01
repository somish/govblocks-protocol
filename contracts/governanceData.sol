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
import "./zeppelin-solidity/contracts/token/BasicToken.sol";
import "./zeppelin-solidity/contracts/token/MintableToken.sol";
import "./VotingType.sol";
import "./memberRoles.sol";
import "./ProposalCategory.sol";
// import "./BasicToken.sol";
// import "./MintableToken.sol";
// import "./VotingType.sol";

contract governanceData is Ownable,VotingType {
    using SafeMath for uint;
    struct proposal{
        address owner;
        string shortDesc;
        string longDesc;
        uint date_add;
        uint date_upd;
        uint versionNum;
        uint currVotingStatus;
        uint propStatus;  
        uint category;
        uint finalVerdict;
        uint currentVerdict;
        address votingTypeAddress;
    }

    struct proposalCategory{
        address categorizedBy;
        uint[] paramInt;
        bytes32[] paramBytes32;
        address[] paramAddress;
        uint verdictOptions;
    }

    struct proposalVersionData{
        uint versionNum;
        string shortDesc;
        string longDesc;
        uint date_add;
    }

    struct Status{
        uint statusId;
        uint date;
    }
    
    struct proposalPriority 
    {
        uint8 complexityLevel;
        uint[] levelReward;
    }

    function governanceData () 
    {
        proposalVoteClosingTime = 20;
        pendingProposalStart=0;
        quorumPercentage=25;
        addStatus();
        uint[] verdictOption;
        allVotes.push(proposalVote(0x00,0,verdictOption,now,0));
    }

    mapping(uint=>proposalCategory) allProposalCategory;
    mapping(uint=>proposalVersionData[]) proposalVersions;
    mapping(uint=>Status[]) proposalStatus;
    mapping(uint=>proposalPriority) allProposalPriority;
    mapping (uint=>address) allVotingTypesAddress;
    
    uint public proposalVoteClosingTime;
    uint public quorumPercentage;
    uint public pendingProposalStart;
    string[] public status;
    proposal[] allProposal;

    address BTAddress;
    BasicToken BT;
    address MRAddress;
    address PCAddress;
    address VTAddress;
    VotingType VT;
    memberRoles MR;
    ProposalCategory Pcategory;

    /// @dev Transfer reward after proposal Decision.
    function transferTokenAfterFinalReward(address _memberAddress, uint _value)
    {
        BT=BasicToken(BTAddress);
        BT.transfer(_memberAddress,_value);
    }

    /// @dev Set voting type's address to follow for a given proposal.
    function setVotingTypesAddress(uint[] _votingTypeId,address[] _votingTypesAddress) onlyOwner
    {
        require(_votingTypeId.length == _votingTypesAddress.length);
        for(uint i=0; i<_votingTypesAddress.length; i++)
        {
            allVotingTypesAddress[_votingTypeId[i]] = _votingTypesAddress[i];
        }
    }

    /// @dev Get voting type address when giving Voting type id.
    function getVotingTypeAddressById(uint _id) public constant returns(address)
    {
        return allVotingTypesAddress[_id];
    }

    /// @dev Fetch user balance when giving member address.
    function getBalanceOfMember(address _memberAddress) public constant returns (uint totalBalance)
    {
        BT=BasicToken(BTAddress);
        totalBalance = BT.balanceOf(_memberAddress);
    }

    /// @dev change all contract's addresses.
    function changeAllContractsAddress(address _BTcontractAddress, address _MRcontractAddress, address _PCcontractAddress,address _VTcontractAddress) public
    {
        BTAddress = _BTcontractAddress;
        MRAddress = _MRcontractAddress;
        PCAddress = _PCcontractAddress;
        VTAddress = _VTcontractAddress;
    }
    
    function addInAllVotes()
    {
        VT=VotingType(VTAddress);
        
        VT.finalReward(12);
    }

    /// @dev add status.
    function addStatus() 
    {
        status.push("Draft for discussion"); 
        status.push("Draft Ready for submission");
        status.push("Voting started"); 
        status.push("Proposal Decision - Accepted by Majority Voting"); 
        status.push("Proposal Decision - Rejected by Majority voting"); 
        status.push("Proposal Denied, Threshold not reached"); 
    }
    /// @dev Changes the status of a given proposal to open it for voting. // wil get called when we submit the proposal on submit button
    function openProposalForVoting(uint _proposalId) onlyOwner public
    {
        require(allProposal[_proposalId].category != 0);
        pushInProposalStatus(_proposalId,2);
        updateProposalStatus(_proposalId,2);
    }
    /// @dev Changes the time(in seconds) after which proposal voting is closed.
    function changeProposalVoteClosingTime(uint _closingTime) onlyOwner public
    {
        proposalVoteClosingTime = _closingTime;   
    }
    /// @dev Checks if voting time of a given proposal should be closed or not. 
    function checkProposalVoteClosing(uint _proposalId) constant returns(uint8 closeValue)
    {
        require(SafeMath.add(allProposal[_proposalId].date_upd,proposalVoteClosingTime) <= now);
        closeValue=1;
    }
    /// @dev fetch the parameter details for the final verdict (Option having maximum votes)
    function getProposalFinalVerdictDetails(uint _proposalId) public constant returns(uint paramint, bytes32 parambytes32,address paramaddress)
    {
        uint category = allProposal[_proposalId].category;
        uint verdictChosen = allProposal[_proposalId].finalVerdict;
        if(allProposalCategory[_proposalId].paramInt.length != 0)
        {
             paramint = allProposalCategory[_proposalId].paramInt[verdictChosen];
        }

        if(allProposalCategory[_proposalId].paramBytes32.length != 0)
        {
            parambytes32 = allProposalCategory[_proposalId].paramBytes32[verdictChosen];
        }

        if(allProposalCategory[_proposalId].paramAddress.length != 0)
        {
            paramaddress = allProposalCategory[_proposalId].paramAddress[verdictChosen];
        }  
    }

    /// @dev Change pending proposal start variable
    function changePendingProposalStart() public
    {
        uint pendingPS = pendingProposalStart;
        uint proposalLength = allProposal.length;
        for(uint j=pendingPS; j<proposalLength; j++)
        {
            if(allProposal[j].propStatus > 3)
                pendingPS = SafeMath.add(pendingPS,1);
            else
                break;
        }
        if(j!=pendingPS)
        {
            pendingProposalStart = j;
        }
    }
    /// @dev Check if the member who wants to change in contracts, is owner.
    function isOwner(address _memberAddress) returns(uint checkOwner)
    {
        require(owner == _memberAddress);
            checkOwner=1;
    }
    /// @dev Change current owner
    function changeOwner(address _memberAddress) onlyOwner public
    {
        transferOwnership(_memberAddress);
    }

    /// @dev Creates a new proposal 
    function addNewProposal(string _shortDesc,string _longDesc,uint _votingTypeId) public
    {
        require(getBalanceOfMember(msg.sender) != 0);
        address votingTypeAddress = allVotingTypesAddress[_votingTypeId];
        allProposal.push(proposal(msg.sender,_shortDesc,_longDesc,now,now,0,0,0,0,0,0,votingTypeAddress));   
    }
    /// @dev Fetch details of proposal by giving proposal Id
    function getProposalDetailsById1(uint _id) public constant returns (address owner,string shortDesc,string longDesc,uint date_add,uint date_upd,uint versionNum,uint propStatus)
    {
        return (allProposal[_id].owner,allProposal[_id].shortDesc,allProposal[_id].longDesc,allProposal[_id].date_add,allProposal[_id].date_upd,allProposal[_id].versionNum,allProposal[_id].propStatus);
    }
    /// @dev Get the category, of given proposal. 
    function getProposalDetailsById2(uint _proposalId) public constant returns(uint category,uint currentVotingId,uint intermediateVerdict,uint finalVerdict,address votingTypeAddress) 
    {
        category = allProposal[_proposalId].category;
        currentVotingId = allProposal[_proposalId].currVotingStatus;
        intermediateVerdict = allProposal[_proposalId].currentVerdict; 
        finalVerdict = allProposal[_proposalId].finalVerdict;
        votingTypeAddress = allProposal[_proposalId].votingTypeAddress;   
    }
    /// @dev Edits a proposal and Only owner of a proposal can edit it.
    function editProposal(uint _proposalId , string _shortDesc, string _longDesc) onlyOwner public
    {
        storeProposalVersion(_proposalId);
        updateProposal(_proposalId,_shortDesc,_longDesc);
        changeProposalStatus(_proposalId,1);
        
        require(allProposal[_proposalId].category > 0);
            uint category;
            (category,,,,) = getProposalDetailsById2(_proposalId); 
            uint verdictOptions = allProposalCategory[_proposalId].verdictOptions;
            uint8 paramInt; uint8 paramBytes32; uint8 paramAddress;
            Pcategory=ProposalCategory(PCAddress);
            (,,,paramInt,paramBytes32,paramAddress,,) = Pcategory.getCategoryDetails(category);
            if(SafeMath.mul(verdictOptions,paramInt) != 0  )
            {
                allProposalCategory[_proposalId].paramInt=new uint[](verdictOptions);     
            }
    
            if(SafeMath.mul(verdictOptions,paramBytes32) != 0  )
            {
                allProposalCategory[_proposalId].paramBytes32=new bytes32[](verdictOptions);   
            }
    
            if(SafeMath.mul(verdictOptions,paramAddress) != 0  )
            {
                allProposalCategory[_proposalId].paramAddress=new address[](verdictOptions);        
            }

            allProposal[_proposalId].category = 0;
    }
    /// @dev Stores the information of a given version number of a given proposal. Maintains the record of all the versions of a proposal.
    function storeProposalVersion(uint _id) internal 
    {
        proposalVersions[_id].push(proposalVersionData(allProposal[_id].versionNum,allProposal[_id].shortDesc,allProposal[_id].longDesc,allProposal[_id].date_add));            
    }
    /// @dev Edits the details of an existing proposal and creates new version.
    function updateProposal(uint _id,string _shortDesc,string _longDesc) internal
    {
        allProposal[_id].shortDesc = _shortDesc;
        allProposal[_id].longDesc = _longDesc;
        allProposal[_id].date_upd = now;
        allProposal[_id].versionNum = SafeMath.add(allProposal[_id].versionNum,1);
    }

    /// @dev Gets version details of a given proposal id.
    function getProposalDetailsByIdAndVersion(uint _id,uint _versionNum) public constant returns( uint versionNum,string shortDesc,string longDesc,uint date_add)
    {
        return (proposalVersions[_id][_versionNum].versionNum,proposalVersions[_id][_versionNum].shortDesc,proposalVersions[_id][_versionNum].longDesc,proposalVersions[_id][_versionNum].date_add);
    }

    /// @dev Changes the status of a given proposal.
    function changeProposalStatus(uint _id,uint _status) 
    {
        require(allProposal[_id].category != 0);
        pushInProposalStatus(_id,_status);
        updateProposalStatus(_id,_status);
    }

    /// @dev Updates  status of an existing proposal.
    function updateProposalStatus(uint _id ,uint _status) internal
    {
        allProposal[_id].propStatus = _status;
        allProposal[_id].date_upd = now;
    }

    /// @dev Stores the status information of a given proposal.
    function pushInProposalStatus(uint _proposalId , uint _status) internal
    {
        proposalStatus[_proposalId].push(Status(_status,now));
    }

    /// @dev Get the category paramets given against a proposal after categorizing the proposal.
    function getProposalCategoryParams(uint _proposalId) constant returns(uint[] paramsInt,bytes32[] paramsBytes,address[] paramsAddress,uint verdictOptions)
    {
        paramsInt = allProposalCategory[_proposalId].paramInt;
        paramsBytes = allProposalCategory[_proposalId].paramBytes32;
        paramsAddress = allProposalCategory[_proposalId].paramAddress;
        verdictOptions = allProposalCategory[_proposalId].verdictOptions;
    }

    function setProposalCategoryParams(uint _proposalId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress,uint _verdictOptions) 
    {
        uint i;
        allProposalCategory[_proposalId].verdictOptions = _verdictOptions;
        for(i=0;i<_paramInt.length;i++)
        {
            allProposalCategory[_proposalId].paramInt.push(_paramInt[i]);
        }

        for(i=0;i<_paramBytes32.length;i++)
        {
            allProposalCategory[_proposalId].paramBytes32.push(_paramBytes32[i]);
        }

        for(i=0;i<_paramAddress.length;i++)
        {
            allProposalCategory[_proposalId].paramAddress.push(_paramAddress[i]);
        }   
    }

    /// @dev Proposal's complexity level and reward is added 
    function addComplexityLevelAndReward(uint _proposalId,uint _category,uint8 _proposalComplexityLevel,uint[] _levelReward) internal
    {
        Pcategory=ProposalCategory(PCAddress);
        uint votingLength = Pcategory.getRoleSequencLength(_category);
        require(votingLength == _levelReward.length);
        allProposalPriority[_proposalId].complexityLevel = _proposalComplexityLevel;
        for(uint i=0; i<_levelReward.length; i++)
        {
            allProposalPriority[_proposalId].levelReward.push(_levelReward[i]);
        }
           
    }

    /// @dev categorizing proposal to proceed further.
    function categorizeProposal(uint _proposalId , uint _categoryId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress,uint _verdictOptions,uint8 _proposalComplexityLevel,uint[] _levelReward) public
    {
        MR = memberRoles(MRAddress); uint i;
        Pcategory=ProposalCategory(PCAddress);
        require(MR.getMemberRoleIdByAddress(msg.sender) == MR.getAuthorizedMemberId());
        require(allProposal[_proposalId].propStatus == 1 || allProposal[_proposalId].propStatus == 0);
        addComplexityLevelAndReward(_proposalId,_categoryId,_proposalComplexityLevel,_levelReward);
        
        uint8 paramInt; uint8 paramBytes32; uint8 paramAddress;

        if(_paramInt.length != 0  )
        {
            allProposalCategory[_proposalId].paramInt=new uint[](_verdictOptions+1);
            allProposalCategory[_proposalId].paramInt[0]=0;
        }

        if(_paramBytes32.length != 0  )
        {
            allProposalCategory[_proposalId].paramBytes32=new bytes32[](_verdictOptions+1);   
            allProposalCategory[_proposalId].paramBytes32[0]="";
        }

        if(_paramAddress.length != 0  )
        {
            allProposalCategory[_proposalId].paramAddress=new address[](_verdictOptions+1);        
            allProposalCategory[_proposalId].paramAddress[0]=0x00;
        }
        (,,,paramInt,paramBytes32,paramAddress,,) = Pcategory.getCategoryDetails(_categoryId);

        if(paramInt*_verdictOptions == _paramInt.length && paramBytes32*_verdictOptions == _paramBytes32.length && paramAddress*_verdictOptions == _paramAddress.length)
        {
            allProposalCategory[_proposalId].verdictOptions = SafeMath.add(_verdictOptions,1);
            allProposalCategory[_proposalId].categorizedBy = msg.sender;
            allProposal[_proposalId].category = _categoryId;
           
                for(i=0; i<_paramInt.length; i++)
                {
                    allProposalCategory[_proposalId].paramInt[i+1]=_paramInt[i];
                }
        
                for(i=0; i<_paramBytes32.length; i++)
                {
                    allProposalCategory[_proposalId].paramBytes32[i+1]=_paramBytes32[i];
                }
        
                for(i=0; i<_paramAddress.length; i++)
                {
                    allProposalCategory[_proposalId].paramAddress[i+1]=_paramAddress[i];
                }
            
        } 
    }
    /// @dev function to get called after Proposal Pass
    function categoryFunction(uint256 _proposalId) public
    {
        uint _categoryId;
        (_categoryId,,,,)= getProposalDetailsById2(_proposalId);
        uint paramint;
        bytes32 parambytes32;
        address paramaddress;
        (paramint,parambytes32,paramaddress) = getProposalFinalVerdictDetails(_proposalId);
        // add your functionality here;
        // gd1.updateCategoryMVR(_categoryId);
    } 

    function updateProposalDetails(uint _proposalId,uint _currVotingStatus, uint _intermediateVerdict,uint _finalVerdict)
    {
        allProposal[_proposalId].currVotingStatus = _currVotingStatus;
        allProposal[_proposalId].currentVerdict = _intermediateVerdict;
        allProposal[_proposalId].finalVerdict = _finalVerdict;
    }

    function getProposalRewardAndComplexity(uint _proposalId,uint _rewardIndex) public constant returns (uint reward)
    {
       reward = allProposalPriority[_proposalId].levelReward[_rewardIndex];
    }

}  




