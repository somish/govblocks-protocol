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
import "./SafeMath.sol";
import "./Master.sol";
import "./GBTStandardToken.sol";
import "./Governance.sol";

contract governanceData {
  
    event Proposal(address indexed proposalOwner,uint256 indexed proposalId,uint256 dateAdd,string proposalDescHash);
    event Solution(uint256 indexed proposalId,address indexed solutionOwner,string solutionDescHash,uint256 dateAdd,uint256 solutionStake);
    event Reputation(address indexed from,uint256 indexed proposalId, string description, uint32 reputationPoints,bytes4 typeOf);
    event Vote(address indexed from,uint256 indexed proposalId,uint256 dateAdd,uint256 voteStakeGBT,uint256 voteId);
    event Reward(address indexed to,uint256 indexed proposalId,string description,uint256 amount);
    event Penalty(address indexed to,uint256 indexed proposalId,string description,uint256 amount);
    event OraclizeCall(address indexed proposalOwner,uint256 indexed proposalId,uint256 dateAdd,uint256 closingTime);    
    event ProposalStatus(uint256 indexed proposalId,uint256 proposalStatus,uint256 dateAdd);
    event ProposalVersion(uint256 indexed proposalId,uint256 indexed versionNumber,string proposalDescHash,uint256 dateAdd);
    event ProposalStake(address indexed proposalOwner,uint256 indexed proposalId,uint dateUpd,uint256 proposalStake);
    event ProposalWithSolution(address indexed proposalOwner,uint256 proposald,string proposalDescHash, string solutionDescHash, uint256 dateAdd,uint stake)
    
    function callProposalWithSolutionEvent(address indexed proposalOwner,uint256 proposald,string proposalDescHash, string solutionDescHash, uint256 dateAdd,uint stake)
    {
        ProposalWithSolution(proposalOwner,proposald,proposalDescHash,solutionDescHash,dateAdd,stake);
    }

    function callProposalStakeEvent(address _proposalOwner,uint _proposalId,uint _dateUpd,uint _proposalStake)
    {
        ProposalStake(_proposalOwner,_proposalId,_dateUpd,_proposalStake);
    }   

    /// @dev Calls proposal version event
    /// @param proposalId Proposal id
    /// @param versionNumber Version number
    /// @param proposalDescHash Proposal description hash
    /// @param dateAdd Date when proposal version was added
    function callProposalVersionEvent(uint256 proposalId,uint256 versionNumber,string proposalDescHash,uint256 dateAdd) onlyInternal
    {
        ProposalVersion(proposalId,versionNumber,proposalDescHash,dateAdd);
    }

    /// @dev Calls solution event
    /// @param proposalId Proposal id
    /// @param solutionOwner Solution owner
    /// @param solutionDescHash Solution description hash
    /// @param dateAdd Date the solution was added
    /// @param solutionStake Stake of the solution provider
    function callSolutionEvent(uint256 proposalId,address solutionOwner,string solutionDescHash,uint256 dateAdd,uint256 solutionStake) onlyInternal
    {
        Solution(proposalId,solutionOwner,solutionDescHash,dateAdd,solutionStake);
    }

    /// @dev Calls proposal event
    /// @param _proposalOwner Proposal owner
    /// @param _proposalId Proposal id
    /// @param _dateAdd Date when proposal was added
    /// @param _proposalDescHash Proposal description hash
    function callProposalEvent(address _proposalOwner,uint _proposalId,uint _dateAdd,string _proposalDescHash) onlyInternal
    {
        Proposal(_proposalOwner,_proposalId,_dateAdd,_proposalDescHash);   
    }

    /// @dev Calls event to update the reputation of the member
    /// @param _from Whose reputation is getting updated
    /// @param _proposalId Proposal id
    /// @param _description Description
    /// @param _reputationPoints Reputation points
    /// @param _typeOf Type of credit/debit of reputation
    function callReputationEvent(address _from,uint256 _proposalId,string _description,uint32 _reputationPoints,bytes4 _typeOf) onlyInternal
    {
        Reputation(_from, _proposalId, _description,_reputationPoints,_typeOf);
    }
    
    /// @dev Calls vote event
    /// @param _from Whose account the vote is added
    /// @param _voteId Vote id
    function callVoteEvent(address _from,uint _proposalId,uint _dateAdd,uint _voteStakeGBT,uint256 _voteId) onlyInternal
    {
        Vote(_from,_proposalId,_dateAdd,_voteStakeGBT,_voteId);
    }
    
    /// @dev Calls reward event
    /// @param _to Address of the receiver of the award
    /// @param _proposalId Proposal id
    /// @param _description Description of the event
    /// @param _amount Amount of reward
    function callRewardEvent(address _to,uint256 _proposalId,string _description,uint256 _amount) onlyInternal 
    {
        Reward(_to, _proposalId, _description,_amount);
    }

    /// @dev Calls penalty event
    /// @param _to Address to whom penalty is charged
    /// @param _proposalId Proposal id
    /// @param _description Description of the event
    /// @param _amount Amount of penalty
    function callPenaltyEvent(address _to,uint256 _proposalId,string _description,uint256 _amount) onlyInternal 
    {
        Penalty(_to, _proposalId, _description,_amount);
    }

    /// @dev Calls Oraclize call event
    /// @param _proposalId Proposal id
    /// @param _dateAdd Date proposal was added
    /// @param _closingTime Closing time of the proposal
    function callOraclizeCallEvent(uint256 _proposalId,uint256 _dateAdd,uint256 _closingTime) onlyInternal
    {
        OraclizeCall(allProposal[_proposalId].owner, _proposalId, _dateAdd,_closingTime);
    }
    
    /// @dev Calls proposal status event
    /// @param _proposalId Proposal id
    /// @param _proposalStatus Proposal status
    /// @param _dateAdd Date when proposal was added
    function callProposalStatusEvent(uint256 _proposalId,uint _proposalStatus,uint _dateAdd) onlyInternal
    {
        ProposalStatus(_proposalId,_proposalStatus,_dateAdd);
    }   
    
    using SafeMath for uint;
    struct proposal
    {
        address owner;
        uint date_upd;
        address votingTypeAddress;
    }

    struct proposalData
    {
        uint8 currVotingStatus;
        uint8 propStatus;  
        uint8 category;
        uint8 finalVerdict;
        uint8 currentVerdict;
        uint8 versionNumber;
        uint totalVoteValue;
        uint totalreward;
        uint commonIncentive;
    }

    struct votingTypeDetails
    {
        bytes32 votingTypeName;
        address votingTypeAddress;
    }

    struct proposalVote 
    {
        address voter;
        uint[] solutionChosen;
        uint voteValue;
    }

    struct lastReward
    {
        uint lastReward_proposalId;
        uint lastReward_solutionProposalId;
        uint lastReward_voteId;
    }

    struct deposit
    {
        uint amount;
        uint8 returned;
    }
    
    mapping(uint=>proposalData) allProposalData;
    mapping(uint=>address[]) allProposalSolutions;
    mapping(address=>uint32) allMemberReputationByAddress;
    mapping(address=>mapping(uint=>uint)) AddressProposalVote; 
    mapping(uint=>mapping(uint=>uint[])) ProposalRoleVote; 
    mapping(address=>uint[]) allProposalByMember;
    mapping(address=>mapping(uint=>mapping(bytes4=>deposit))) allMemberDepositTokens;
    mapping(address=>lastReward) lastRewardDetails ;

    uint public quorumPercentage;
    uint public pendingProposalStart;
    uint public GBTStakeValue; 
    uint public membershipScalingFactor;
    uint public scalingWeight;
    uint public allVotesTotal;
    bool public constructorCheck;
    uint public depositPercProposal;
    uint public depositPercSolution;
    uint public depositPercVote;
    uint public tokenHoldingTime;
    uint32 addProposalOwnerPoints;
    uint32 addSolutionOwnerPoints;
    uint32 addMemberPoints;
    uint32 subProposalOwnerPoints;
    uint32 subSolutionOwnerPoints;
    uint32 subMemberPoints;
    
    string[]  status;
    proposal[] allProposal;
    proposalVote[] allVotes;
    votingTypeDetails[] allVotingTypeDetails;
    

    Master MS;
    GBTStandardToken GBTS;
    Governance GOV;
    address masterAddress;
    address GBMAddress;
    address GBTSAddress;
    address constant null_address = 0x00;

    modifier onlyInternal {
        MS=Master(masterAddress);
        require(MS.isInternal(msg.sender) == true);
        _; 
    }
    
     modifier onlyOwner 
    {
        MS=Master(masterAddress);
        require(MS.isOwner(msg.sender) == true);
        _; 
    }

    modifier onlyMaster 
    {
        require(msg.sender == masterAddress);
        _; 
    }

    modifier onlyGBM
    {
        require(msg.sender == GBMAddress);
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

    /// @dev Changes GovBlocks master address
    /// @param _GBMAddress new GovBlocks master address
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
    
    /// @dev Changes Global objects of the contracts || Uses latest version
    /// @param contractName Contract name 
    /// @param contractAddress Contract addresses
    function changeAddress(bytes4 contractName, address contractAddress) onlyInternal
    {
        if(contractName == 'GV'){
          GOV = Governance(contractAddress);
        } 
        else if(contractName == 'SV'){
          editVotingTypeDetails(0,contractAddress);
        } 
        else  if(contractName == 'RB'){
          editVotingTypeDetails(1,contractAddress);
        } 
        else if(contractName == 'FW'){
          editVotingTypeDetails(2,contractAddress);
        }
    }
    
    /// @dev Initiates governance data
    /// @param _GBMAddress GovBlocks master address
    function GovernanceDataInitiate(address _GBMAddress) 
    {
        require(constructorCheck == false);
            GBMAddress = _GBMAddress;
            setGlobalParameters();
            addStatus();
            addMemberReputationPoints();
            setVotingTypeDetails("Simple Voting",null_address);
            setVotingTypeDetails("Rank Based Voting",null_address);
            setVotingTypeDetails("Feature Weighted Voting",null_address);
            allVotes.push(proposalVote(0X00,new uint[](0),0));
            uint _totalVotes = SafeMath.add(allVotesTotal,1);  
            allVotesTotal=_totalVotes;
            constructorCheck=true;
    }

    /// @dev Adds points to add or subtract in member reputation when proposal/Solution/vote gets denied or accepted
    function addMemberReputationPoints() internal
    {
        addProposalOwnerPoints = 5;
        addSolutionOwnerPoints = 5;
        addMemberPoints = 1;
        subProposalOwnerPoints = 1;
        subSolutionOwnerPoints = 1;
        subMemberPoints = 1;
    }

    /// @dev Changes points to add or subtract in member reputation when proposal/Solution/vote gets denied or accepted
    /// @param _addProposalOwnerPoints Add proposal owner's points
    /// @param _addSolutionOwnerPoints Add Solution owner's points
    /// @param _addMemberPoints Add member points
    /// @param _subProposalOwnerPoints Subtract proposal owner points
    /// @param _subSolutionOwnerPoints Subtract Solution owner points
    /// @param _subMemberPoints Subtract member points
    function changeMemberReputationPoints(uint32 _addProposalOwnerPoints,uint32  _addSolutionOwnerPoints, uint32 _addMemberPoints,uint32 _subProposalOwnerPoints,uint32  _subSolutionOwnerPoints, uint32 _subMemberPoints) onlyOwner
    {
        addProposalOwnerPoints = _addProposalOwnerPoints;
        addSolutionOwnerPoints= _addSolutionOwnerPoints;
        addMemberPoints = _addMemberPoints;
        subProposalOwnerPoints = _subProposalOwnerPoints;
        subSolutionOwnerPoints= _subSolutionOwnerPoints;
        subMemberPoints = _subMemberPoints;
    }

    /// @dev Adds status 
    function addStatus() internal
    {
        status.push("Draft for discussion"); // 0
        status.push("Draft Ready for submission"); // 1
        status.push("Voting started");  // 2
        status.push("Proposal Decision - Accepted by Majority Voting");  // 3
        status.push("Proposal Decision - Rejected by Majority voting"); // 4
        status.push("Proposal Accepted - Majority Voting not reached But Accepted by previous Voting"); // 5
        status.push("Proposal Denied, Threshold not reached"); // 6
        status.push("Proposal Accepted - Threshold not reached But Accepted by Previous Voting");  // 7
    }

    /// @dev Sets global parameters that will help in distributing reward
    function setGlobalParameters() internal
    {
        pendingProposalStart=0;
        quorumPercentage=25;
        GBTStakeValue=0;
        membershipScalingFactor=1;
        scalingWeight=1;
        depositPercProposal=30;
        depositPercSolution=30;
        depositPercVote=40;
    }
    


// VERSION 2.0 : Last Reward Distribution details.



    /// @dev Sets last rewards for proposal
    /// @param _memberAddress Member address
    /// @param _proposalId Proposal id
    function setLastRewardId_ofCreatedProposals(address _memberAddress,uint _proposalId) onlyInternal
    {
        lastRewardDetails[_memberAddress].lastReward_proposalId =_proposalId;
    }

    /// @dev Sets last reward for solution
    /// @param _memberAddress Member address
    /// @param _proposalId Proposal id
    function setLastRewardId_ofSolutionProposals(address _memberAddress, uint _proposalId) onlyInternal
    {
        lastRewardDetails[_memberAddress].lastReward_solutionProposalId = _proposalId;
    }

    /// @dev Sets last reward for proposal vote
    /// @param _memberAddress Member address
    /// @param _voteId Vote id
    function setLastRewardId_ofVotes(address _memberAddress,uint _voteId) onlyInternal
    {
        lastRewardDetails[_memberAddress].lastReward_voteId = _voteId;
    }

    /// @dev Gets reward for last created proposal of member
    function getLastRewardId_ofCreatedProposals(address _memberAddress) constant returns(uint)
    {
        return lastRewardDetails[_memberAddress].lastReward_proposalId;
    }

    /// @dev Gets reward for last solution created by member
    function getLastRewardId_ofSolutionProposals(address _memberAddress) constant returns(uint)
    {
        return lastRewardDetails[_memberAddress].lastReward_solutionProposalId;
    }

    /// @dev Gets proposal vote created by member
    function getLastRewardId_ofVotes(address _memberAddress) constant returns(uint)
    {
        return lastRewardDetails[_memberAddress].lastReward_voteId;
    }

    /// @dev Gets id of last reward of a member address
    function getAllidsOfLastReward(address _memberAddress)constant returns(uint lastRewardId_ofCreatedProposal,uint lastRewardid_ofSolution,uint lastRewardId_ofVote)
    {
        return (lastRewardDetails[_memberAddress].lastReward_proposalId,lastRewardDetails[_memberAddress].lastReward_solutionProposalId,lastRewardDetails[_memberAddress].lastReward_voteId);
    }

    /// @dev Sets deposit tokens out of the total tokens when given member address, proposal id
    function setDepositTokens(address _memberAddress,uint _proposalId,bytes4 _typeOf,uint _depositAmount) onlyInternal
    {
        allMemberDepositTokens[_memberAddress][_proposalId][_typeOf].amount = _depositAmount;
    }

    /// @dev Gets deposited tokens from the total token when given member address, proposal id
    function getDepositedTokens(address _memberAddress,uint _proposalId,bytes4 _typeOf) constant returns(uint) 
    {
        return allMemberDepositTokens[_memberAddress][_proposalId][_typeOf].amount;
    }

    /// @dev Gets returned tokens to fetch if member has claimed the reward
    function getReturnedTokensFlag(address _memberAddress,uint _proposalId,bytes4 _typeOf)constant returns(uint8)
    {
        return allMemberDepositTokens[_memberAddress][_proposalId][_typeOf].returned;
    }

    /// @dev Sets returned tokens in case the member has claimed the reward
    function setReturnedTokensFlag(address _memberAddress,uint _proposalId,bytes4 _typeOf,uint8 _returnedIndex) onlyInternal
    {
        allMemberDepositTokens[_memberAddress][_proposalId][_typeOf].returned = _returnedIndex ;
    }

    /// @dev user can calim the tokens rewarded them till now.
    function claimReward() public
    {
        uint rewardToClaim = GOV.calculateMemberReward(msg.sender);
        if(rewardToClaim != 0)
        { 
            GBTS.transfer_message(address(this),rewardToClaim,"GBT Stake - Received");
            GBTS.transfer_message(msg.sender,rewardToClaim,"GBT Stake claimed - Returned");
        }
    }



// VERSION 2.0 : VOTE DETAILS 


    /// @dev Sets vote id against member
    /// @param _memberAddress Member address
    /// @param _proposalId Proposal id
    /// @param _voteId Vote id
    function setVoteId_againstMember(address _memberAddress,uint _proposalId,uint _voteId) onlyInternal
    {
        AddressProposalVote[_memberAddress][_proposalId] = _voteId;
    }

    /// @dev Sets vote id against proposal role
    /// @param _proposalId Proposal id
    /// @param _roleId Role id
    /// @param _voteId Vote id
    function setVoteId_againstProposalRole(uint _proposalId,uint _roleId,uint _voteId) onlyInternal
    {
        ProposalRoleVote[_proposalId][_roleId].push(_voteId);
    }

    //// @dev Sets vote value for vote id=_voteId
    function setVoteValue(uint _voteId,uint _voteValue) onlyInternal
    {
        allVotes[_voteId].voteValue = _voteValue;
    }

    /// @dev Sets all the voting type names and their addresses
    function setVotingTypeDetails(bytes32 _votingTypeName,address _votingTypeAddress) internal
    {
        allVotingTypeDetails.push(votingTypeDetails(_votingTypeName,_votingTypeAddress)); 
    }

    /// @dev Edits voting type of voting type id=_votingTypeId and voting type address=_votingTypeAddress
    function editVotingTypeDetails(uint _votingTypeId,address _votingTypeAddress) internal
    {
        allVotingTypeDetails[_votingTypeId].votingTypeAddress = _votingTypeAddress;
    }

    /// @dev Gets vote details by id
    /// @param _voteid Vote id
    /// @return voter Voter address
    /// @return solutionChosen Solution chosen
    /// @return voteValue Vote value
    function getVoteDetailById(uint _voteid) public constant returns(address voter,uint[] solutionChosen,uint voteValue)
    {
       return(allVotes[_voteid].voter,allVotes[_voteid].solutionChosen,allVotes[_voteid].voteValue);
    }

    /// @dev Gets vote id against member
    /// @param _memberAddress Member address
    /// @param _proposalId Proposal id
    /// @return voteId Vote id
    function getVoteId_againstMember(address _memberAddress,uint _proposalId) constant returns(uint voteId)
    {
        voteId = AddressProposalVote[_memberAddress][_proposalId];
    }

    function checkVoteId_againstMember(address _memberAddress,uint _proposalId)constant returns(bool)
    {
        voteId = AddressProposalVote[_memberAddress][_proposalId];
        if(voteId == 0)
            return false;
        else
            return true;
    }

    /// @dev Gets voter address
    /// @param _voteId Vote id
    /// @return _voterAddress Voter address
    function getVoterAddress(uint _voteId) constant returns(address _voterAddress)
    {
        return (allVotes[_voteId].voter);
    }
    
    /// @dev Gets vote array against role
    /// @param _proposalId Proposal id
    /// @param _roleId Role id
    /// @return totalVotes Total votes count
    function getAllVoteIds_byProposalRole(uint _proposalId,uint _roleId) constant returns(uint[] totalVotes)
    {
        return ProposalRoleVote[_proposalId][_roleId];
    }

    /// @dev Gets vote length
    /// @param _proposalId Proposal id
    /// @param _roleId Role id
    /// @return length Vote length
    function getAllVoteIdsLength_byProposalRole(uint _proposalId,uint _roleId)constant returns(uint length)
    {
        return ProposalRoleVote[_proposalId][_roleId].length;
    }
    
    /// @dev Gets vote id of proposal id=_proposalId against role id=_roleId and index=_index
    /// @param _proposalId Proposal id
    /// @param _roleId Role index
    /// @param _index Index for the role 
    function getVoteId_againstProposalRole(uint _proposalId,uint _roleId,uint _index)constant returns(uint)
    {
        return (ProposalRoleVote[_proposalId][_roleId][_index]);
    }

    /// @dev Gets vote value for vote id=_voteId
    /// @param _voteId Vote id
    /// @return allVotes[_voteId].voteValue All votes value
    function getVoteValue(uint _voteId)constant returns(uint)
    {
        return (allVotes[_voteId].voteValue);
    }

    /// @dev Gets voting type length
    function getVotingTypeLength() public constant returns(uint) 
    {
        return allVotingTypeDetails.length;
    }

    /// @dev Gets voting type details by voting type id=_votingTypeId
    function getVotingTypeDetailsById(uint _votingTypeId) public constant returns(uint votingTypeId,bytes32 VTName,address VTAddress)
    {
        return (_votingTypeId,allVotingTypeDetails[_votingTypeId].votingTypeName,allVotingTypeDetails[_votingTypeId].votingTypeAddress);
    }

    /// @dev Gets voting type address by voting type id=_votingTypeId
    function getVotingTypeAddress(uint _votingTypeId)constant returns (address votingAddress)
    {
        return (allVotingTypeDetails[_votingTypeId].votingTypeAddress);
    }


// VERSION 2.0 : SOLUTION DETAILS


      
    /// @dev Sets Solution chosen by vote id
    /// @param _voteId Vote id
    /// @param _value Solution chosen
    function setSolutionChosen(uint _voteId,uint _value) onlyInternal
    {
        allVotes[_voteId].solutionChosen.push(_value);
    }

    function setSolutionAdded(uint _proposalId,address _memberAddress) onlyInternal
    {
        allProposalSolutions[_proposalId].push(_memberAddress);
    }

    /// @dev Gets Solution chosen by vote id
    /// @param _voteId Vote id
    /// @return solutionChosen Solution chosen
    function getSolutionByVoteId(uint _voteId) constant returns(uint[] solutionChosen)
    {
        return (allVotes[_voteId].solutionChosen);
    }
  
    /// @dev Gets Solution chosen on vote id= _voteId
    /// @param _voteId Vote id
    /// @param _solutionChosenId Solution chosen id
    /// @return solution Solution 
    function getSolutionByVoteIdAndIndex(uint _voteId,uint _solutionChosenId)constant returns(uint solution)
    {
        return (allVotes[_voteId].solutionChosen[_solutionChosenId]);
    }

    /// @dev Gets the address of member whosoever added the verdict when given proposal id and verdict index.
    function getSolutionAddedByProposalId(uint _proposalId,uint _Index) constant returns(address memberAddress)
    {
        return allProposalSolutions[_proposalId][_Index];
    }

    

// VERSION 2.0 : Configurable parameters.


    /// @dev Changes stake value that helps in calculation of reward distribution
    function changeGBTStakeValue(uint _GBTStakeValue) onlyGBM 
    {
        GBTStakeValue = _GBTStakeValue;
    }

    /// @dev Changes member scaling factor that helps in calculation of reward distribution
    function changeMembershipScalingFator(uint _membershipScalingFactor) onlyGBM
    {
        membershipScalingFactor = _membershipScalingFactor;
    }
    
    /// @dev Changes scaling weight that helps in calculation of reward distribution
    function changeScalingWeight(uint _scalingWeight)  onlyGBM 
    {
        scalingWeight = _scalingWeight;
    }

    /// @dev Changes quoram percentage. Value required to pass proposal.
    function changeQuorumPercentage(uint _quorumPercentage) onlyGBM
    {
        quorumPercentage = _quorumPercentage;
    }

     /// @dev Gets reputation points to proceed with updating the member reputation level
    function getMemberReputationPoints() constant returns(uint32 addProposalOwnPoints,uint32 addSolutionOwnerPoints,uint32 addMemPoints,uint32 subProposalOwnPoints,uint32 subSolutionOwnPoints,uint32 subMemPoints)
    {
        return (addProposalOwnerPoints,addSolutionOwnerPoints,addMemberPoints,subProposalOwnerPoints,subSolutionOwnerPoints,subMemberPoints);
    } 

    /// @dev Changes proposal owner reputation points
    function changeProposalOwnerAdd(uint32 _repPoints) onlyGBM
    {
        addProposalOwnerPoints = _repPoints;
    }

    /// @dev Adds proposal owner reputation points    
    function changeSolutionOwnerAdd(uint32 _repPoints) onlyGBM
    {
        addSolutionOwnerPoints = _repPoints;
    }

    /// @dev Subtracts proposal owner reputation points    
    function changeProposalOwnerSub(uint32 _repPoints) onlyGBM
    {
        subProposalOwnerPoints = _repPoints;
    } 
    
    /// @dev Subtracts solution owner reputation points    
    function changeSolutionOwnerSub(uint32 _repPoints) onlyGBM
    {
        subSolutionOwnerPoints = _repPoints;
    }

    /// @dev Adds member points
    function changeMemberAdd(uint32 _repPoints) onlyGBM
    {
        addMemberPoints = _repPoints;
    }  

    /// @dev Subtracts member points
    function changeMemberSub(uint32 _repPoints) onlyGBM
    {
        subMemberPoints = _repPoints;
    }  



// VERSION 2.0 // PROPOSAL DETAILS



    /// @dev Sets proposal category for proposal id=_proposalId
    function setProposalCategory(uint _proposalId,uint8 _categoryId) onlyInternal
    {
        allProposalData[_proposalId].category = _categoryId;
    }

    /// @dev Updates status of an existing proposal(id = _id)
    function updateProposalStatus(uint _id ,uint8 _status)  internal 
    {
        allProposalData[_id].propStatus = _status;
        allProposal[_id].date_upd = now;
    }
    
    /// @dev Sets proposal incentive/reward for proposal id=_proposalId
    function setProposalIncentive(uint _proposalId,uint _reward) onlyInternal
    {
        allProposalData[_proposalId].commonIncentive = _reward;  
    }
    
    /// @dev Changes the status of a given proposal.
    function changeProposalStatus(uint _id,uint8 _status) onlyInternal
    {
        require(allProposalData[_id].category != 0);
        ProposalStatus(_id,_status,now);
        updateProposalStatus(_id,_status);
    }
    
    /// @dev Sets proposal current voting id
    function setProposalCurrentVotingId(uint _proposalId,uint8 _currVotingStatus) onlyInternal
    {
        allProposalData[_proposalId].currVotingStatus = _currVotingStatus;
    }

    /// @dev Updates proposal's major details
    function setProposalIntermediateVerdict(uint _proposalId,uint8 _intermediateVerdict) onlyInternal 
    {
        allProposalData[_proposalId].currentVerdict = _intermediateVerdict;
    }

    /// @dev Sets proposal's final verdict
    function setProposalFinalVerdict(uint _proposalId,uint8 _finalVerdict) onlyInternal
    {
        allProposalData[_proposalId].finalVerdict = _finalVerdict;
    }

    /// @dev Sets member reputation 
    function setMemberReputation(string _description,uint _proposalId,address _memberAddress,uint32 _repPoints,uint32 _repPointsEventLog,bytes4 _typeOf) onlyInternal
    {
        allMemberReputationByAddress[_memberAddress] = _repPoints;
        Reputation(_memberAddress, _proposalId, _description,_repPointsEventLog,_typeOf);
    }

    /// @dev Stores the information of version number of a given proposal. Maintains the record of all the versions of a proposal.
    function storeProposalVersion(uint _proposalId,string _proposalDescHash) onlyInternal 
    {
        uint8 versionNo = allProposalData[_proposalId].versionNumber + 1;
        ProposalVersion(_proposalId,versionNo,_proposalDescHash,now);
        setProposalVersion(_proposalId,versionNo);
    }

    /// @dev Sets proposal description 
    function setProposalDetailsAfterEdit(uint _proposalId,string _proposalDescHash) onlyInternal
    {
        Proposal(allProposal[_proposalId].owner,_proposalId,now,_proposalDescHash);   
    }

    /// @dev Sets proposal's uploaded date
    function setProposalDateUpd(uint _proposalId) onlyInternal
    {
        allProposal[_proposalId].date_upd = now;
    }

    /// @dev Sets proposal's version
    function setProposalVersion(uint _proposalId,uint8 _versionNum) internal
    {
        allProposalData[_proposalId].versionNumber = _versionNum;
    }

    /// @dev Fetch details of proposal by giving proposal Id
    function getProposalDetailsById1(uint _proposalId) public constant returns (uint id,address owner,uint date_upd,uint8 versionNum,uint8 propStatus)
    {
        return (_proposalId,allProposal[_proposalId].owner,allProposal[_proposalId].date_upd,allProposalData[_proposalId].versionNumber,allProposalData[_proposalId].propStatus);
    }

    /// @dev Get the category of given proposal. 
    function getProposalDetailsById2(uint _proposalId) public constant returns(uint id,uint8 category,uint8 currentVotingId,uint8 intermediateVerdict,uint8 finalVerdict,address votingTypeAddress,uint totalSolutions) 
    {
        return (_proposalId,allProposalData[_proposalId].category,allProposalData[_proposalId].currVotingStatus,allProposalData[_proposalId].currentVerdict,allProposalData[_proposalId].finalVerdict,allProposal[_proposalId].votingTypeAddress,allProposalSolutions[_proposalId].length); 
    }

    /// @dev Gets proposal details of given proposal id
    function getProposalDetailsById3(uint _proposalId) constant returns(uint proposalIndex,string propStatus,uint8 propCategory,uint8 propStatusId,uint8 finalVerdict)
    {
        return (_proposalId,status[allProposalData[_proposalId].propStatus],allProposalData[_proposalId].category,allProposalData[_proposalId].propStatus,allProposalData[_proposalId].finalVerdict);
    }

    /// @dev Gets proposal details of given proposal id
    function getProposalDetailsById4(uint _proposalId)constant returns(uint totalTokenToDistribute,uint totalVoteValue)
    {
        return(allProposalData[_proposalId].totalreward,allProposalData[_proposalId].totalVoteValue);
    }

    /// @dev Gets proposal details of given proposal id
    function getProposalDetailsById5(uint _proposalId)public constant returns(uint proposalStatus,uint finalVerdict)
    {
        return (allProposalData[_proposalId].propStatus,allProposalData[_proposalId].finalVerdict);
    }

    /// @dev Gets date when proposal is updated
    function getProposalDateUpd(uint _proposalId)constant returns(uint)
    {
        return allProposal[_proposalId].date_upd;
    }

    /// @dev Gets member address who created the proposal
    function getProposalOwner(uint _proposalId) public constant returns(address)
    {
        return allProposal[_proposalId].owner;
    }

    /// @dev Gets proposal incentive
    function getProposalIncentive(uint _proposalId)constant returns(uint commonIncentive)
    {
        return allProposalData[_proposalId].commonIncentive;
    }

    /// @dev Gets proposal current voting id
    function getProposalCurrentVotingId(uint _proposalId)constant returns(uint8 _currVotingStatus)
    {
        return (allProposalData[_proposalId].currVotingStatus);
    }
    
     function getProposalTotalReward(uint _proposalId)constant returns(uint)
    {
        return allProposalData[_proposalId].totalreward;
    }

    /// @dev Get Total number of Solutions against proposal.
    function getTotalSolutions(uint _proposalId) constant returns(uint)
    {
        return allProposalSolutions[_proposalId].length;
    }

    /// @dev Get Current Status of proposal when given proposal Id
    function getProposalStatus(uint _proposalId) constant returns (uint propStatus)
    {
        return allProposalData[_proposalId].propStatus;
    }

    /// @dev Gets proposal voting type when given proposal id
    function getProposalVotingType(uint _proposalId)constant returns(address)
    {
        return (allProposal[_proposalId].votingTypeAddress);
    }

    /// @dev Gets proposal category when given proposal id
    function getProposalCategory(uint _proposalId) constant returns(uint8 categoryId)
    {
        return allProposalData[_proposalId].category;
    }

    /// @dev If member's decision is final decision, member's reputation is set accordingly
    function getMemberReputation(address _memberAddress) constant returns(uint32 memberPoints)
    {
        if(allMemberReputationByAddress[_memberAddress] == 0)
            memberPoints = 1;
        else
            memberPoints = allMemberReputationByAddress[_memberAddress];
    }

    /// @dev Gets total vote values when given proposal id
    function getProposalTotalVoteValue(uint _proposalId) constant returns(uint voteValue)
    {
        voteValue = allProposalData[_proposalId].totalVoteValue;
    }

    /// @dev Gets all proposals length
    function getProposalLength()constant returns(uint)
    {  
        return (allProposal.length);
    }  

    /// @dev Get Latest updated version of proposal.
    function getProposalVersion(uint _proposalId,uint8 _versionNum)constant returns(uint)
    {
        return allProposalData[_proposalId].versionNumber;
    }

    /// @dev Sets proposal's total vote value of a proposal id
    function setProposalTotalVoteValue(uint _proposalId,uint _voteValue) onlyInternal
    {
        allProposalData[_proposalId].totalVoteValue = _voteValue;
    }
    
    /// @dev Sets proposal's total token to distribute
    function setProposalTotalReward(uint _proposalId,uint _totalreward) onlyInternal
    {
        allProposalData[_proposalId].totalreward = _totalreward;
    }


    /// @dev Changes status from pending proposal to start proposal
    function changePendingProposalStart(uint _value) onlyInternal
    {
        pendingProposalStart = _value;
    }

    /// @dev Adds new proposal
    function addNewProposal(uint _proposalId,address _memberAddress,string _proposalDescHash,uint8 _categoryId,address _votingTypeAddress,uint _dateAdd) onlyInternal
    {
        allProposalData[_proposalId].category = _categoryId;
        createProposal1(_proposalId,_memberAddress,_proposalDescHash,_votingTypeAddress,_dateAdd);
    }  
    
    /// @dev Creates new proposal
    function createProposal1(uint _proposalId,address _memberAddress,string _proposalDescHash,address _votingTypeAddress,uint _dateAdd) onlyInternal
    {
        allProposal.push(proposal(_memberAddress,_dateAdd,_votingTypeAddress));
        Proposal(_memberAddress,_proposalId,_dateAdd,_proposalDescHash);
    }

    /// @dev Gets final solution index won after majority voting.
    function getProposalFinalVerdict(uint _proposalId) constant returns(uint finalSolutionIndex)
    {
        finalSolutionIndex = allProposalData[_proposalId].finalVerdict;
    }

    /// @dev Gets Intermidiate solution index;
    function getProposalIntermediateVerdict(uint _proposalId) constant returns(uint8)
    {
        return allProposalData[_proposalId].currentVerdict;
    }

    function changeTokenHoldingTime(uint _time) onlyOwner
    {
       tokenHoldingTime = _time;
    }

    /// @dev Get total deposit tokens against member and proposal Id with type of (proposal/solution/vote); 
    function getDepositTokens_byAddressProposal(address _memberAddress,uint _proposalId)constant returns(uint,uint depositFor_creatingProposal,uint depositFor_proposingSolution,uint depositFor_castingVote)
    {
        return (_proposalId,getDepositedTokens(_memberAddress,_proposalId,"P"),getDepositedTokens(_memberAddress,_proposalId,"S"),getDepositedTokens(_memberAddress,_proposalId,"V"));
    }


// UPDATED CONTRACTS :




    // /// @dev Get Array of All vote id's against a given proposal when given _proposalId.
    // function getVoteArrayById(uint _proposalId) constant returns(uint id,uint[] totalVotes)
    // {
    //     return (_proposalId,allProposalVotes[_proposalId]);
    // }

    // /// @dev Get Vote id one by one against a proposal when given proposal Id and Index to traverse vote array.
    // function getVoteIdById(uint _proposalId,uint _voteArrayIndex) constant returns (uint voteId)
    // {
    //     return (allProposalVotes[_proposalId][_voteArrayIndex]);
    // }

    // function setProposalAnsByAddress(uint _proposalId,address _memberAddress) onlyInternal
    // {
    //     allProposalOption[_memberAddress].push(_proposalId); 
    // }

    // function getProposalAnsLength(address _memberAddress)constant returns(uint)
    // {
    //     return (allProposalOption[_memberAddress].length);
    // }

    // function getProposalAnsId(address _memberAddress, uint _optionArrayIndex)constant returns (uint) // return proposId to which option added.   {
    // {
    //     return (allProposalOption[_memberAddress][_optionArrayIndex]);
    // }

    // function getOptionIdAgainstProposalByAddress(address _memberAddress,uint _optionArrayIndex)constant returns(uint proposalId,uint optionId,uint proposalStatus,uint finalVerdict)
    // {
    //     proposalId = allProposalOption[_memberAddress][_optionArrayIndex];
    //     optionId = allOptionDataAgainstMember[_memberAddress][proposalId];
    //     proposalStatus = allProposal[proposalId].propStatus;
    //     finalVerdict = allProposal[proposalId].finalVerdict;
    // }

    /// @dev Set the Deatils of added verdict i.e. Verdict Stake, Verdict value and Address of the member whoever added the verdict.
    // function setOptionIdByAddress(uint _proposalId,address _memberAddress) onlyInternal
    // {
    //     allOptionDataAgainstMember[_memberAddress][_proposalId] = getTotalVerdictOptions(_proposalId);
    // }

    // function getOptionIdByAddress(uint _proposalId,address _memberAddress) constant returns(uint optionIndex)
    // {
    //     return (allOptionDataAgainstMember[_memberAddress][_proposalId]);
    // }

    // function setOptionAddress(uint _proposalId,address _memberAddress) onlyInternal
    // {
    //     allProposalCategory[_proposalId].optionAddedByAddress.push(_memberAddress);
    // }

    // function setOptionValue(uint _proposalId,uint _optionValue) onlyInternal
    // {
    //     allProposalCategory[_proposalId].valueOfOption.push(_optionValue);
    // }

    // function setOptionHash(uint _proposalId,string _optionHash) onlyInternal
    // {
    //     allProposalCategory[_proposalId].optionHash.push(_optionHash);
    // }

    // function setOptionDateAdded(uint _proposalId,uint _dateAdd) onlyInternal
    // {
    //     allProposalCategory[_proposalId].optionDateAdd.push(_dateAdd);
    // }

    // function getOptionDateAdded(uint _proposalId,uint _optionIndex)constant returns(uint)
    // {
    //     return (allProposalCategory[_proposalId].optionDateAdd[_optionIndex]);
    // }

    // function setProposalValue(uint _proposalId,uint _proposalValue) onlyInternal
    // {
    //     allProposal[_proposalId].proposalValue = _proposalValue;
    // }

    // /// @dev Stores the status information of a given proposal.
    // function pushInProposalStatus(uint _proposalId , uint8 _status) onlyInternal
    // {
    //     ProposalStatus(_proposalId,_status,now);
    //     // proposalStatus[_proposalId].push(Status(_status,now));
    // }

    // function setInitialOptionsAdded(uint _proposalId) onlyInternal
    // {
    //     require (initialOptionsAdded[_proposalId] == 0);
    //         initialOptionsAdded[_proposalId] = 1;
    // }

    // function getInitialOptionsAdded(uint _proposalId) constant returns (uint)
    // {
    //     if(initialOptionsAdded[_proposalId] == 1)
    //         return 1;
    // }

    // function setTotalOptions(uint _proposalId) onlyInternal
    // {
    //     allProposalCategory[_proposalId].verdictOptions = allProposalCategory[_proposalId].verdictOptions +1;
    // }

    // function setCategorizedBy(uint _proposalId,address _memberAddress) onlyInternal
    // {
    //     allProposalCategory[_proposalId].categorizedBy = _memberAddress;
    // }

    // function setProposalLevel(uint _proposalId,uint8 _proposalComplexityLevel) onlyInternal
    // {
    //      allProposal[_proposalId].complexityLevel = _proposalComplexityLevel;
    // }

    // /// @dev Get proposal Value when given proposal Id.
    // function getProposalValue(uint _proposalId) constant  returns(uint proposalValue) 
    // {
    //     proposalValue = allProposal[_proposalId].proposalValue;
    // }

    // /// @dev Get proposal Stake by member when given proposal Id.
    // function getProposalStake(uint _proposalId) constant returns(uint proposalStake)
    // {
    //     proposalStake = allProposal[_proposalId].proposalStake;
    // }

    /// @dev Fetch Total length of Member address array That added number of verdicts against proposal.
    // function getOptionAddedAddressLength(uint _proposalId) constant returns(uint length)
    // {
    //     return  allProposalCategory[_proposalId].optionAddedByAddress.length;
    // }

    // function getOptionHashByProposalId(uint _proposalId,uint _optionIndex) constant returns(string)
    // {
    //     return allProposalCategory[_proposalId].optionHash[_optionIndex];
    // }

    // /// @dev Get the Stake of verdict when given Proposal Id and Verdict index.
    // function getOptionStakeById(uint _proposalId,uint _optionIndex) constant returns(uint optionStake)
    // {
    //     optionStake = allProposalCategory[_proposalId].stakeOnOption[_optionIndex];
    // }

    /// @dev Get the value of verdict when given Proposal Id and Verdict Index.
    // function getOptionValueByProposalId(uint _proposalId,uint _optionIndex) constant returns(uint optionValue)
    // {
    //     optionValue = allProposalCategory[_proposalId].valueOfOption[_optionIndex];
    // }

    // function addInTotalVotes(address _memberAddress,uint _voteId)
    // {
    //     allMemberVotes[_memberAddress].push(_voteId);
    // }

    // function getVoteArrayByAddress(address _memberAddress) constant returns(uint[] totalVoteArray)
    // {
    //     return (allMemberVotes[_memberAddress]);
    // }

    // function getVoteIdByIndex(address _memberAddress,uint _index)constant returns(uint)
    // {
    //     return getVoteArrayByAddress[_memberAddress].length;
    // }

    // function addTotalProposal(uint _proposalId,address _memberAddress) onlyInternal
    // {
    //     allProposalMember[_memberAddress].push(_proposalId);
    // }

    // function getTotalProposal(address _memberAddress) constant returns(uint)
    // {
    //     return allProposalMember[_memberAddress].length;
    // }

    // function getProposalIdByAddress(address _memberAddress,uint _index)constant returns(uint)
    // {
    //     return (allProposalMember[_memberAddress][_index]);
    // }

    // function getProposalDetailsByAddress(address _memberAddress,uint _index)constant returns(uint proposalId,uint categoryId,uint finalVerdict,uint propStatus)
    // {
    //     proposalId = allProposalMember[_memberAddress][_index];
    //     categoryId = allProposal[proposalId].category;
    //     finalVerdict = allProposal[proposalId].finalVerdict;
    //     proposalStatus = allProposal[proposalId].propStatus;
    // }

    // function getProposalTotalReward(uint _proposalId)constant returns(uint)
    // {
    //     return allProposal[_proposalId].totalreward;
    // }

    // function setProposalBlockNo(uint _proposalId,uint _blockNumber) onlyInternal
    // {
    //     allProposal[_proposalId].blocknumber = _blockNumber;
    // }

    // function setOptionReward(uint _proposalId,uint _reward,uint _optionIndex) onlyInternal
    // {
    //     allProposalCategory[_proposalId].rewardOption[_optionIndex] = _reward;
    // }

    // function getOptionReward(uint _proposalId,uint _optionIndex)constant returns(uint)
    // {
    //     return (allProposalCategory[_proposalId].rewardOption[_optionIndex]);
    // }



    // function getProposalVoteValueById(uint _proposalId) constant returns(uint propStake,uint voteValue)
    // {
    //     return(allProposal[_proposalId].proposalStake,allProposal[_proposalId].totalVoteValue);
    // }

    // function getProposalDescHash(uint _proposalId)constant returns(string)
    // {
    //     return (allProposal[_proposalId].proposalDescHash);
    // }  
    
    /// @dev Set Vote Id against given proposal.
    // function setVoteIdAgainstProposal(uint _proposalId,uint _voteId) onlyInternal
    // {
    //     allProposalVotes[_proposalId].push(_voteId);
    // }

    // function getVoteValuebyOption_againstProposal(uint _proposalId,uint _roleId,uint _optionIndex) constant returns(uint totalVoteValue)
    // {
    //     totalVoteValue = allProposalVoteAndToken[_proposalId].totalVoteCountValue[_roleId][_optionIndex];
    // }

    // function setProposalVoteCount(uint _proposalId,uint _roleId,uint _option,uint _finalVoteValue) onlyInternal
    // {
    //     allProposalVoteAndToken[_proposalId].totalVoteCountValue[_roleId][_option] = SafeMath.add(allProposalVoteAndToken[_proposalId].totalVoteCountValue[_roleId][_option],_finalVoteValue);
    // }

    // function setProposalTokenCount(uint _proposalId,uint _roleId,address _memberAddress) onlyInternal
    // {
    //     GBTS=GBTStandardToken(GBTSAddress);
    //     allProposalVoteAndToken[_proposalId].totalTokenCount[_roleId] = SafeMath.add(allProposalVoteAndToken[_proposalId].totalTokenCount[_roleId],GBTS.balanceOf(_memberAddress));
    // }
 
    // function editProposalVoteCount(uint _proposalId,uint _roleId,uint _option,uint _VoteValue) onlyInternal
    // {
    //     allProposalVoteAndToken[_proposalId].totalVoteCountValue[_roleId][_option] = SafeMath.sub(allProposalVoteAndToken[_proposalId].totalVoteCountValue[_roleId][_option],_VoteValue);
    // }

    // function editProposalTokenCount(uint _proposalId,uint _roleId,address _memberAddress) onlyInternal
    // {
    //     GBTS=GBTStandardToken(GBTSAddress);
    //     allProposalVoteAndToken[_proposalId].totalTokenCount[_roleId] = SafeMath.sub(allProposalVoteAndToken[_proposalId].totalTokenCount[_roleId],GBTS.balanceOf(_memberAddress));
    // }

    // /// @dev Get the vote count for options of proposal when giving Proposal id and Option index.
    // function getProposalVoteAndTokenCountByRoleId(uint _proposalId,uint _roleId,uint _optionIndex) public constant returns(uint totalVoteValue,uint totalToken)
    // {
    //     totalVoteValue = allProposalVoteAndToken[_proposalId].totalVoteCountValue[_roleId][_optionIndex];
    //     totalToken = allProposalVoteAndToken[_proposalId].totalTokenCount[_roleId];
    // }

    // // mapping(uint => proposalVoteAndTokenCount) allProposalVoteAndToken;
    // // mapping(uint=>uint8) initialOptionsAdded; // get Option details by +1 as first option is always the deny one..
    // // mapping(uint=>uint[]) allProposalVotes; // CAN OPTIMIZE THIS // Total votes againt proposal . can get this by ProposalRoleVote
    
    // mapping(address=>uint[]) allProposalMember; // Proposal Against Member // can get from AddressProposalVote. 
    // mapping(address=>uint[]) allProposalOption; // Total Proposals against Member, array contains proposalIds to which solution being provided
    // mapping(address=>uint[]) allMemberVotes; // Total Votes given by member till now..
    // mapping(address=>mapping(uint=>uint)) allOptionDataAgainstMember; // AddressProposalOptionId // Replaced functions using this mapping;
 
    // struct proposalVoteAndTokenCount 
    // {
    //     mapping(uint=>mapping(uint=>uint)) totalVoteCountValue; // PROPOSAL ROLE OPTION VOTEVALUE
    //     mapping(uint=>uint) totalTokenCount;  // PROPOSAL ROLE TOKEN
    // }

    // struct proposalCategory
    // {
        // address categorizedBy;
        // uint8 verdictOptions;
        // address[] optionAddedByAddress;
        // uint[] valueOfOption;
        // uint[] stakeOnOption;
        // string[] optionHash;
        // uint[] optionDateAdd;
        // mapping(uint=>uint) rewardOption;
    // }

    // struct proposalVersionData
    // {
    //     uint versionNum;
    //     string proposalDescHash;
    //     uint date_add;
    // }

    // struct Status
    // {
    //     uint statusId;
    //     uint date;
    // }

}  

 

