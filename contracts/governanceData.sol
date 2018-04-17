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

contract governanceData {
  
    event Proposal(address indexed proposalOwner,uint256 proposalId,uint256 dateAdd,string proposalDescHash);
    event Solution(uint256 indexed proposalId,address indexed solutionOwner,string solutionDescHash,uint256 dateAdd,uint256 solutionStake);
    event Reputation(address indexed from,uint256 indexed proposalId, string description, uint reputationPoints,bytes4 typeOf);
    event Vote(address indexed from,address indexed proposalId,uint256 dateAdd,uint256 voteStakeGBT,uint256 voteId);
    event Reward(address indexed to,uint256 indexed proposalId,string description,uint256 amount);
    event Penalty(address indexed to,uint256 indexed proposalId,string description,uint256 amount);
    event OraclizeCall(address indexed proposalOwner,uint256 indexed proposalId,uint256 dateAdd,uint256 closingTime);    
    event ProposalStatus(uint256 indexed proposalId,uint256 proposalStatus,uint256 dateAdd);
    event ProposalVersion(uint256 indexed proposalId,uint256 indexed versionNumber,string proposalDescHash,uint256 dateAdd);

    function callProposalVersionEvent(uint256 proposalId,uint256 versionNumber,string proposalDescHash,uint256 dateAdd)
    {
        ProposalVersion(proposalId,versionNumber,proposalDescHash,dateAdd);
    }

    function callSolutionEvent(uint256 proposalId,address solutionOwner,string solutionDescHash,uint256 dateAdd,uint256 solutionStake)
    {
        Solution(proposalId,solutionOwner,solutionDescHash,dateAdd,solutionStake);
    }

    function callProposalEvent(address _proposalOwner,uint _proposalId,uint _dateAdd,string _proposalDescHash)
    {
        Proposal(_proposalOwner,_proposalId,_dateAdd,_proposalDescHash);   
    }

    function callReputationEvent(address _from,uint256 _proposalId,string _description,uint _reputationPoints,bytes4 _typeOf) onlyInternal
    {
        Reputation(_from, _proposalId, _description,_reputationPoints,_typeOf);
    }
    
    function callVoteEvent(address _from,uint _proposalId,uint _dateAdd,uint _voteStakeGBT,uint256 _voteId) onlyInternal
    {
        Vote(_from,_proposalId,_dateAdd,_voteStakeGBT,_voteId);
    }
    
    function callRewardEvent(address _to,uint256 _proposalId,string _description,uint256 _amount) onlyInternal
    {
        Reward(_to, _proposalId, _description,_amount);
    }

    function callPenaltyEvent(address _to,uint256 _proposalId,string _description,uint256 _amount) onlyInternal
    {
        Penalty(_to, _proposalId, _description,_amount);
    }

    function callOraclizeCallEvent(uint256 _proposalId,uint256 _dateAdd,uint256 _closingTime) onlyInternal
    {
        OraclizeCall(allProposal[_proposalId].owner, _proposalId, _dateAdd,_closingTime);
    }

    function callProposalStatusEvent(uint256 _proposalId,uint _proposalStatus,uint _dateAdd)
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
        uint[] optionChosen;
        uint voteValue;
    }

    struct lastReward
    {
        uint proposalCreate;
        uint optionCreate;
        uint proposalVote;
    }

    struct deposit
    {
        uint amount;
        uint8 returned;
    }
    
    mapping(uint=>proposalData) allProposalData;
    mapping(uint=>address[]) allProposalOptions;
    mapping(address=>uint32) allMemberReputationByAddress;
    mapping(address=>mapping(uint=>uint)) AddressProposalVote; 
    mapping(uint=>mapping(uint=>uint[])) ProposalRoleVote; 
    mapping(address=>mapping(uint=>mapping(bytes4=>deposit))) allMemberDepositTokens;
    mapping(address=>lastReward);

    uint public quorumPercentage;
    uint public pendingProposalStart;
    uint public GBTStakeValue; 
    uint public globalRiskFactor; 
    uint public membershipScalingFactor;
    uint public scalingWeight;
    uint public allVotesTotal;
    uint public constructorCheck;
    uint public depositPercProposal;
    uint public depositPercOption;
    uint public depositPercVote;
    uint addProposalOwnerPoints;
    uint addOptionOwnerPoints;
    uint addMemberPoints;
    uint subProposalOwnerPoints;
    uint subOptionOwnerPoints;
    uint subMemberPoints;

    proposal[] allProposal;
    proposalVote[] allVotes;
    votingTypeDetails[] allVotingTypeDetails;

    Master MS;
    GBTStandardToken GBTS;
    address masterAddress;
    address GBMAddress;
    address GBTSAddress;
    address constant null_address = 0x00;

    modifier onlyInternal {
        MS=Master(masterAddress);
        require(MS.isInternal(msg.sender) == 1);
        _; 
    }
    
     modifier onlyOwner 
    {
        MS=Master(masterAddress);
        require(MS.isOwner(msg.sender) == 1);
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

    function changeMasterAddress(address _masterContractAddress) 
    {
        if(masterAddress == 0x000)
            masterAddress = _masterContractAddress;
        else
        {
            MS=Master(masterAddress);
            require(MS.isInternal(msg.sender) == 1);
                masterAddress = _masterContractAddress;
        }
    }

    function changeGBMAddress(address _GBMAddress) onlyGBM
    {
        GBMAddress = _GBMAddress;
    }
    
    function changeGBTSAddress(address _GBTAddress) onlyMaster
    {
        GBTSAddress = _GBTAddress;
    }   
    
    function GovernanceDataInitiate(address _GBMAddress) 
    {
        require(constructorCheck == 0);
            GBMAddress = _GBMAddress;
            setGlobalParameters();
            addStatus();
            addMemberReputationPoints();
            setVotingTypeDetails("Simple Voting",null_address);
            setVotingTypeDetails("Rank Based Voting",null_address);
            setVotingTypeDetails("Feature Weighted Voting",null_address);
            allVotes.push(proposalVote(0X00,new uint[](0),0);
            uint _totalVotes = SafeMath.add(allVotesTotal,1);  
            allVotesTotal=_totalVotes;
            constructorCheck=1;
    }

    /// @dev Add points to add or subtract in memberReputation when proposal/option/vote gets denied or accepted.
    function addMemberReputationPoints() internal
    {
        addProposalOwnerPoints = 5;
        addOptionOwnerPoints = 5;
        addMemberPoints = 1;
        subProposalOwnerPoints = 1;
        subOptionOwnerPoints = 1;
        subMemberPoints = 1;
    }

    /// @dev Change points to add or subtract in memberReputation when proposal/option/vote gets denied or accepted.
    function changeMemberReputationPoints(uint _addProposalOwnerPoints,uint  _addOptionOwnerPoints, uint _addMemberPoints,uint _subProposalOwnerPoints,uint  _subOptionOwnerPoints, uint _subMemberPoints) onlyOwner
    {
        addProposalOwnerPoints = _addProposalOwnerPoints;
        addOptionOwnerPoints= _addOptionOwnerPoints;
        addMemberPoints = _addMemberPoints;
        subProposalOwnerPoints = _subProposalOwnerPoints;
        subOptionOwnerPoints= _subOptionOwnerPoints;
        subMemberPoints = _subMemberPoints;
    }

    /// @dev add status.
    function addStatus() internal
    {
        status.push("Draft for discussion"); 
        status.push("Draft Ready for submission");
        status.push("Voting started"); 
        status.push("Proposal Decision - Accepted by Majority Voting"); 
        status.push("Proposal Decision - Rejected by Majority voting"); 
        status.push("Proposal Denied, Threshold not reached"); 
    }

    /// @dev Set Parameters value that will help in Distributing reward.
    function setGlobalParameters() internal
    {
        pendingProposalStart=0;
        quorumPercentage=25;
        GBTStakeValue=0;
        globalRiskFactor=5;
        membershipScalingFactor=1;
        scalingWeight=1;
        depositPercProposal=30;
        depositPercOption=30;
        depositPercVote=40;
    }

    function setProposalCreate(address _memberAddress,uint _proposalId) onlyInternal
    {
        lastReward[_memberAddress].proposalCreate =_proposalId;
    }

    function setOptionCreate(address _memberAddress, uint _proposalId) onlyInternal
    {
        lastReward[_memberAddress].optionCreate = _proposalId;
    }

    function setProposalVote(address _memberAddress,uint _voteId) onlyInternal
    {
        lastReward[_memberAddress].proposalVote = _voteId;
    }

    function getProposalCreate(address _memberAddress) constant returns(uint)
    {
        return lastReward[_memberAddress].proposalCreate;
    }

    function getOptionCreate(address _memberAddress) constant returns(uint)
    {
        return lastReward[_memberAddress].optionCreate;
    }

    function getProposalVote(address _memberAddress) constant returns(uint)
    {
        return lastReward[_memberAddress].proposalVote;
    }

    function getIdOfLastReward(address _memberAddress)constant returns(uint lastPCid,uint lastOCid,uint lastPVid)
    {
        return (lastReward[_memberAddress].proposalCreate,lastReward[_memberAddress].optionCreate,lastReward[_memberAddress].proposalVote);
    }

    function setDepositTokens(address _memberAddress,uint _proposalId,bytes4 _typeOf,uint _depositAmount) onlyInternal
    {
        allMemberDepositTokens[_memberAddress][_proposalId][_typeOf].amount = _depositAmount;
    }

    function getDepositedTokens(address _memberAddress,uint _proposalId,bytes4 _typeOf) constant returns(uint) 
    {
        return allMemberDepositTokens[_memberAddress][_proposalId][_typeOf].amount;
    }

    function getReturnedTokens(address _memberAddress,uint _proposalId,bytes4 _typeOf)constant returns(uint8)
    {
        return allMemberDepositTokens[_memberAddress][_proposalId][_typeOf].returned;
    }

    function setReturnedTokens(address _memberAddress,uint _proposalId,bytes4 _typeOf,uint8 _returnedIndex) onlyInternal
    {
        return allMemberDepositTokens[_memberAddress][_proposalId][_typeOf].returned = _returnedIndex ;
    }

    function claimReward()
    {
        GBTS=GBTStandardToken(GBTSAddress);
        G1=Governance(G1Address);
        uint rewardToClaim = G1.calculateMemberReward(msg.sender);
        if(rewardToClaim != 0)
        { 
            GBTS.addInBalance(address(this),rewardToClaim);
            GBTS.transfer(_memberAddress,_amount);
            GBTS.callTransferGBTEvent(address(this),_memberAddress,_amount,"GBT Stake claimed - Returned");
        }
    }

    function addInVote(address _memberAddress,uint _proposalId,uint[] _optionChosen,uint _GBTPayableTokenAmount,uint _finalVoteValue) onlyInternal
    {
        allVotes.push(proposalVote(_memberAddress,_optionChosen,_finalVoteValue));
        Vote(_memberAddress,_proposalId,now,_GBTPayableTokenAmount,_voteId);
        increaseTotalVotes();
    }

    function increaseTotalVotes() internal returns (uint _totalVotes) 
    {
        _totalVotes = SafeMath.add(allVotesTotal,1);  
        allVotesTotal=_totalVotes;
    } 

    function setVoteId_againstMember(address _memberAddress,uint _proposalId,uint _voteId) onlyInternal
    {
        AddressProposalVote[_memberAddress][_proposalId] = _voteId;
    }

    function setVoteIdAgainstProposalRole(uint _proposalId,uint _roleId,uint _voteId) onlyInternal
    {
        ProposalRoleVote[_proposalId][_roleId].push(_voteId);
    }

    function getVoteDetailByid(uint _voteid) public constant returns(address voter,uint[] optionChosen,uint voteValue)
    {
        return(allVotes[_voteid].voter,allVotes[_voteid].optionChosen,allVotes[_voteid].voteValue);
    }

      function getVoteId_againstMember(address _memberAddress,uint _proposalId) constant returns(uint voteId)
    {
        voteId = AddressProposalVote[_memberAddress][_proposalId];
    }

    function getOptionChosenById(uint _voteId) constant returns(uint[] optionChosen)
    {
        return (allVotes[_voteId].optionChosen);
    }
    
    function setOptionChosen(uint _voteId,uint _value) onlyInternal
    {
        allVotes[_voteId].optionChosen.push(_value);
    }

    function getOptionById(uint _voteId,uint _optionChosenId)constant returns(uint option)
    {
        return (allVotes[_voteId].optionChosen[_optionChosenId]);
    }
    
    function getVoterAddress(uint _voteId) constant returns(address _voterAddress)
    {
        return (allVotes[_voteId].voter);
    }
    
      function getVoteArrayAgainstRole(uint _proposalId,uint _roleId) constant returns(uint[] totalVotes)
    {
        return ProposalRoleVote[_proposalId][_roleId];
    }

    function getVoteLength(uint _proposalId,uint _roleId)constant returns(uint length)
    {
        return ProposalRoleVote[_proposalId][_roleId].length;
    }
    
    function getVoteIdAgainstRole(uint _proposalId,uint _roleId,uint _index)constant returns(uint)
    {
        return (ProposalRoleVote[_proposalId][_roleId][_index]);
    }

    function getVoteValue(uint _voteId)constant returns(uint)
    {
        return (allVotes[_voteId].voteValue);
    }

    function setVoteValue(uint _voteId,uint _voteValue) onlyInternal
    {
        allVotes[_voteId].voteValue = _voteValue;
    }

    /// @dev Set all the voting type names and thier addresses.
    function setVotingTypeDetails(bytes32 _votingTypeName,address _votingTypeAddress) onlyOwner
    {
        allVotingTypeDetails.push(votingTypeDetails(_votingTypeName,_votingTypeAddress)); 
    }

    function editVotingType(uint _votingTypeId,address _votingTypeAddress) onlyInternal
    {
        allVotingTypeDetails[_votingTypeId].votingTypeAddress = _votingTypeAddress;
    }

    function getVotingTypeLength() public constant returns(uint) 
    {
        return allVotingTypeDetails.length;
    }

    function getVotingTypeDetailsById(uint _votingTypeId) public constant returns(uint votingTypeId,bytes32 VTName,address VTAddress)
    {
        return (_votingTypeId,allVotingTypeDetails[_votingTypeId].votingTypeName,allVotingTypeDetails[_votingTypeId].votingTypeAddress);
    }

    function getVotingTypeAddress(uint _votingTypeId)constant returns (address votingAddress)
    {
        return (allVotingTypeDetails[_votingTypeId].votingTypeAddress);
    }

    /// @dev Change Variables that helps in Calculation of reward distribution. Risk Factor, GBT Stak Value, Scaling Factor,Scaling weight.
    function changeGlobalRiskFactor(uint _riskFactor) onlyGBM
    {
        globalRiskFactor = _riskFactor;
    }

    function changeGBTStakeValue(uint _GBTStakeValue) onlyGBM
    {
        GBTStakeValue = _GBTStakeValue;
    }

    function changeMembershipScalingFator(uint _membershipScalingFactor) onlyGBM
    {
        membershipScalingFactor = _membershipScalingFactor;
    }

    function changeScalingWeight(uint _scalingWeight)  onlyGBM
    {
        scalingWeight = _scalingWeight;
    }

    /// @dev Change quoram percentage. Value required to proposal pass.
    function changeQuorumPercentage(uint _quorumPercentage) onlyGBM
    {
        quorumPercentage = _quorumPercentage;
    }

    function getAllVoteIdsAgainstRole(uint _proposalId,uint _roleId) constant returns(uint[] allVoteIds)
    {
        for(uint i=0; i< ProposalRoleVote[_proposalId][_roleId].length; i++)
        {
            allVoteIds.push(ProposalRoleVote[_proposalId][_roleId][i]);
        }
    }

    /// @dev Get Total votes against a proposal when given proposal id.
    function getVoteLengthById(uint _proposalId) constant returns(uint totalVotesLength)
    {
        return (allProposalVotes[_proposalId].length);
    }

    /// @dev Get Total votes against a proposal when given proposal id.
    function getVoteLengthById(uint _proposalId) constant returns(uint totalVotes)
    {
        MR=memberRoles(MRAddress);
        uint length = MR.getAllMemberLength();
        for(uint i =0; i<length; i++)
        {
            totalVotes = totalVotes + ProposalRoleVote[_proposalId][i].length;
        }
    }

    function getProposalAnsByAddress(address _memberAddress)constant returns(uint[] proposalIds) // ProposalIds to which solutions being provided
    {
        return (allProposalOption[_memberAddress]);
    }

    function getProposalAnsByAddress(address _memberAddress)constant returns(uint[] proposalIds, uint[]solutionIds,uint totalProposal,uint totalSolution) // ProposalIds to which solutions being provided
    {
        uint length = getProposalLength();
        for(uint i=0; i<length; i++)
        {
            for(uint j=0; j<allProposalOptions[i].length; j++)
            {
                if(_memberAddress = allProposalOptions[i][j])
                {
                    proposalIds.push(i);
                    solutionIds.push(j);
                }
            }
        }
        totalProposal = proposalIds.length;
        totalSolution = solutionIds.length;
    }

    function getOptionIdAgainstProposalByAddress(address _memberAddress,uint _proposalId)constant returns(uint proposalId,uint optionId,uint proposalStatus,uint finalVerdict)
    {
        for(uint i=0; i<allProposalOption[_proposalId].length; i++)
        {
            if(_memberAddress == allProposalOption[_proposalId][i])
                optionId = i;
        }

        proposalId = _proposalId
        proposalStatus = allProposal[proposalId].propStatus;
        finalVerdict = allProposal[proposalId].finalVerdict;
    }

    function setOptionStake(uint _proposalId,uint _memberAddress,uint _stakeValue,string _optionHash,uint _dateAdd) onlyInternal
    {
        Solution(proposalId,_memberAddress,_optionHash,_dateAdd,_stakeValue);
    }

    function setProposalCategory(uint _proposalId,uint8 _categoryId) onlyInternal
    {
        allProposalData[_proposalId].category = _categoryId;
    }

    function setProposalStake(uint _proposalId,uint _memberStake) onlyInternal
    {
        allProposal[_proposalId].proposalStake = _memberStake;
    }

    /// @dev Updates  status of an existing proposal.
    function updateProposalStatus(uint _id ,uint8 _status)  internal
    {
        allProposalData[_id].propStatus = _status;
        allProposal[_id].date_upd = now;
    }

    function setProposalIncentive(uint _proposalId,uint _reward) onlyInternal
    {
        allProposalData[_proposalId].commonIncentive = _reward;  
    }

    /// @dev Changes the status of a given proposal.
    function changeProposalStatus(uint _id,uint8 _status) onlyInternal
    {
        require(allProposal[_id].category != 0);
        ProposalStatus(_proposalId,_proposalStatus,_dateAdd);
        updateProposalStatus(_id,_status);
    }

    function setProposalCurrentVotingId(uint _proposalId,uint8 _currVotingStatus) onlyInternal
    {
        allProposalData[_proposalId].currVotingStatus = _currVotingStatus;
    }

    /// @dev Updating proposal's Major details (Called from close proposal Vote).
    function setProposalIntermediateVerdict(uint _proposalId,uint8 _intermediateVerdict) onlyInternal 
    {
        allProposalData[_proposalId].currentVerdict = _intermediateVerdict;
    }

    function setProposalFinalVerdict(uint _proposalId,uint8 _finalVerdict) onlyInternal
    {
        allProposalData[_proposalId].finalVerdict = _finalVerdict;
    }

    function setMemberReputation(string _description,uint _proposalId,address _memberAddress,uint _repPoints,uint _repPointsEventLog,bytes4 _typeOf) onlyInternal
    {
        allMemberReputationByAddress[_memberAddress] = _repPoints;
        Reputation(_memberAddress, _proposalId, _description,_repPointsEventLog,_typeOf);
    }

    /// @dev Stores the information of a given version number of a given proposal. Maintains the record of all the versions of a proposal.
    function storeProposalVersion(uint _proposalId,string _proposalDescHash) onlyInternal 
    {
        uint8 versionNo = allProposalData[_proposalId].versionNumber + 1;
        ProposalVersion(_proposalId,versionNo,_proposalDescHash,now);
        setProposalVersion(_proposalId);
    }

    function setProposalDesc(uint _proposalId,string _hash) onlyInternal
    {
        Proposal(allProposal[_proposalId].owner,_proposalId,_dateAdd,_hash);   
    }

    function setProposalDateUpd(uint _proposalId) onlyInternal
    {
        allProposal[_proposalId].date_upd = now;
    }

    function setProposalVersion(uint _proposalId) internal
    {
        allProposalData[_proposalId].versionNum = allProposalData[_proposalId].versionNum+1;
    }

    /// @dev Fetch details of proposal by giving proposal Id
    function getProposalDetailsById1(uint _proposalId) public constant returns (uint id,address owner,uint date_upd,uint versionNum,uint propStatus)
    {
        return (_proposalId,allProposal[_proposalId].owner,allProposal[_proposalId].date_upd,allProposalData[_proposalId].versionNum,allProposalData[_proposalId].propStatus);
    }

    /// @dev Get the category, of given proposal. 
    function getProposalDetailsById2(uint _proposalId) public constant returns(uint id,uint8 category,uint8 currentVotingId,uint8 intermediateVerdict,uint8 finalVerdict,address votingTypeAddress) 
    {
        return (_proposalId,allProposalData[_proposalId].category,allProposalData[_proposalId].currVotingStatus,allProposalData[_proposalId].currentVerdict,allProposalData[_proposalId].finalVerdict,allProposal[_proposalId].votingTypeAddress); 
    }

    function getProposalDetailsById3(uint _proposalId) constant returns(uint proposalIndex,string propStatus,uint propCategory)
    {
        return (_proposalId,allProposal[_proposalId].date_add,status[allProposalData[_proposalId].propStatus],allProposalData[_proposalId].category,allProposalVotes[_proposalId].length,allProposalCategory[_proposalId].verdictOptions);
    }

    function getProposalDetailsById4(uint _proposalId)constant returns(uint totalTokenToDistribute,uint totalVoteValue)
    {
        return(allProposalData[_proposalId].totalreward,allProposalData[_proposalId].totalVoteValue);
    }

    function getProposalDetailsById5(uint _proposalId)public constant returns(uint proposalStatus,uint uint finalVerdict)
    {
        return (allProposal[_proposalId].propStatus,allProposal[_proposalId].finalVerdict);
    }

    /// @dev Gets version details of a given proposal id.
    function getProposalDetailsByIdAndVersion(uint _proposalId,uint _versionNum) public constant returns(uint id,uint versionNum,string proposalDescHash,uint date_add)
    {
        return (_proposalId,proposalVersions[_proposalId][_versionNum].versionNum,proposalVersions[_proposalId][_versionNum].proposalDescHash,proposalVersions[_proposalId][_versionNum].date_add);
    }
   
    function getProposalDateUpd(uint _proposalId)constant returns(uint)
    {
        return allProposal[_proposalId].date_upd;
    }

    /// @dev Get member address who created the proposal.
    function getProposalOwner(uint _proposalId) public constant returns(address)
    {
        return allProposal[_proposalId].owner;
    }

    function getProposalIncentive(uint _proposalId)constant returns(uint commonIncentive)
    {
        commonIncentive = allProposalData[_proposalId].commonIncentive;
    }

    function getProposalCurrentVotingId(uint _proposalId)constant returns(uint8 _currVotingStatus)
    {
        return (allProposalDataal[_proposalId].currVotingStatus);
    }

    /// @dev Get Total number of verdict options against proposal.
    function getTotalVerdictOptions(uint _proposalId) constant returns(uint8 verdictOptions)
    {
        verdictOptions = allProposalOptions[_proposalId].length;
    }

    /// @dev Get Current Status of proposal when given proposal Id
    function getProposalStatus(uint _proposalId) constant returns (uint propStatus)
    {
        propStatus = allProposalData[_proposalId].propStatus;
    }

    function getProposalVotingType(uint _proposalId)constant returns(address)
    {
        return (allProposal[_proposalId].votingTypeAddress);
    }

    function getProposalCategory(uint _proposalId) constant returns(uint8 categoryId)
    {
        return allProposalData[_proposalId].category;
    }

    /// @dev Member Reputation is set according to if Member's Decision is Final decision.
    function getMemberReputation(address _memberAddress) constant returns(uint memberPoints)
    {
        if(allMemberReputationByAddress[_memberAddress] == 0)
            memberPoints = 1;
        else
            memberPoints = allMemberReputationByAddress[_memberAddress];
    }

    function getTotalVoteValueById(uint _proposalId) constant returns(uint voteValue)
    {
        voteValue = allProposal[_proposalId].totalVoteValue;
    }

    /// @dev Get the Address of member whosoever added the verdict when given Proposal Id and Verdict Index.
    function getOptionAddressByProposalId(uint _proposalId,uint _optionIndex) constant returns(address memberAddress)
    {
        memberAddress = allProposalOptions[_proposalId][_optionIndex];
    }

    function getProposalLength()constant returns(uint)
    {  
        return (allProposal.length);
    }  

    function getVoteArrayByAddress(address _memberAddress) constant returns(uint[] totalVoteArray)
    {
        uint length= getProposalLength();

        for(uint i=0; i<length; i++)
        {
            uint voteId = AddressProposalVote[_memberAddress][i];
            if(voteId != 0)
                totalVoteArray.push(voteId);
        }
    }

    function getTotalVotesByAddress(address _memberAddress)constant returns(uint)
    {
        uint totalVoteLength = getVoteArrayByAddress(_memberAddress)
        return (getVoteArrayByAddress_memberAddress].length);
    }

    
    function getProposalDetailsByVoteId(address _memberAddress,uint _voteArrayIndex,uint _optionChosenId)constant returns(uint voteId,uint proposalId,uint optionChosen,uint proposalStatus,uint finalVerdict)
    {
        voteId = allMemberVotes[_memberAddress][_index];
        proposalId = allVotes[_voteid].proposalId;
        optionChosen = allVotes[_voteId].optionChosen[_optionChosenId];
        proposalStatus = allProposal[proposalId].propStatus;
        finalVerdict = allProposal[proposalId].finalVerdict;
    }

    function getTotalProposal(address _memberAddress) constant returns(uint[] totalProposalCreated)
    {
        uint length = getProposalLength();
        for(uint i=0; i<length; i++)
        {
            if(_memberAddress == allProposal[i].owner)
                totalProposalCreated[]
        }
    }

    function setProposalTotalVoteValue(uint _proposalId,uint _voteValue) onlyInternal
    {
        allProposalData[_proposalId].totalVoteValue = _voteValue;
    }

        /// @dev Get points to proceed with updating the member reputation level.
    function getMemberReputationPoints() constant returns(uint addProposalOwnPoints,uint addOptionOwnPoints,uint addMemPoints,uint subProposalOwnPoints,uint subOptionOwnPoints,uint subMemPoints)
    {
        return (addProposalOwnerPoints,addOptionOwnerPoints,addMemberPoints,subProposalOwnerPoints,subOptionOwnerPoints,subMemberPoints);
    } 

    function changeProposalOwnerAdd(uint _repPoints) onlyGBM
    {
        addProposalOwnerPoints = _repPoints;
    }

    function changeOptionOwnerAdd(uint _repPoints) onlyGBM
    {
        addOptionOwnerPoints = _repPoints;
    }

    function changeProposalOwnerSub(uint _repPoints) onlyGBM
    {
        subProposalOwnerPoints = _repPoints;
    }

    function changeOptionOwnerSub(uint _repPoints) onlyGBM
    {
        subOptionOwnerPoints = _repPoints;
    }  

    function changeMemberAdd(uint _repPoints) onlyGBM
    {
        addMemberPoints = _repPoints;
    }  

    function changeMemberSub(uint _repPoints) onlyGBM
    {
        subMemberPoints = _repPoints;
    }  

    function changePendingProposalStart(uint _value) onlyInternal
    {
        pendingProposalStart = _value;
    }

    function addNewProposal(uint _proposalId,address _memberAddress,string _proposalDescHash,uint8 _categoryId,address _votingTypeAddress,uint _dateAdd) 
    {
        allProposalData[_proposalId].categoryId = _categoryId;
        createProposal1(_proposalId,_memberAddress,_proposalDescHash,_votingTypeAddress,_dateAdd);
    }  
    
    function createProposal1(uint _proposalId,address _memberAddress,string _proposalDescHash,address _votingTypeAddress,uint _dateAdd)
    {
        allProposal.push(proposal(_memberAddress,_dateAdd,_votingTypeAddress));
        Proposal(_memberAddress,_proposalId,_dateAdd,_proposalDescHash);
    }

    function getProposalDetailsByAddress(address _memberAddress,uint _index)constant returns(uint proposalId,uint categoryId,uint finalVerdict,uint propStatus)
    {
        proposalId = allProposalMember[_memberAddress][_index];
        categoryId = allProposal[proposalId].category;
        finalVerdict = allProposal[proposalId].finalVerdict;
        proposalStatus = allProposal[proposalId].propStatus;
    }



//// UPDATED CONTRACTS :


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

    // function getProposalFinalOption(uint _proposalId) constant returns(uint finalOptionIndex)
    // {
    //     finalOptionIndex = allProposalData[_proposalId].finalVerdict;
    // }

    // function getProposalVoteValueById(uint _proposalId) constant returns(uint propStake,uint voteValue)
    // {
    //     return(allProposal[_proposalId].proposalStake,allProposal[_proposalId].totalVoteValue);
    // }

    // function getProposalDescHash(uint _proposalId)constant returns(string)
    // {
    //     return (allProposal[_proposalId].proposalDescHash);
    // }  
    
      // // @dev Set Vote Id against given proposal.
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

 

