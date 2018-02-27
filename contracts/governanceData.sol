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
import "./Pool.sol";
import "./GBTStandardToken.sol";
import "./GBTController.sol";
import "./ProposalCategory.sol";

contract GovernanceData {
  
    event Reputation(address indexed from,uint256 indexed proposalId, string description, uint reputationPoints,bytes4 typeOf);
    event Vote(address indexed from,address indexed votingTypeAddress,uint256 voteId);
    event Reward(address indexed to,uint256 indexed proposalId,string description,uint256 amount);
    

    function callReputationEvent(address _from,uint256 _proposalId,string _description,uint _reputationPoints,bytes4 _typeOf) 
    {
        Reputation(_from, _proposalId, _description,_reputationPoints,_typeOf);
    }
    
    function callVoteEvent(address _from,address _votingTypeAddress,uint256 _voteId) 
    {
        Vote(_from, _votingTypeAddress, _voteId);
    }
    
    function callRewardEvent(address _to,uint256 _proposalId,string _description,uint256 _amount) 
    {
        Reward(_to, _proposalId, _description,_amount);
    }
    
    using SafeMath for uint;
    struct proposal
    {
        address owner;
        string proposalDescHash;
        uint date_add;
        uint date_upd;
        uint8 versionNum;
        uint8 currVotingStatus;
        uint8 propStatus;  
        uint8 category;
        uint8 finalVerdict;
        uint8 currentVerdict;
        address votingTypeAddress;
        uint proposalValue;
        uint proposalStake;
        uint proposalReward;
        uint totalreward;
        uint blocknumber;
        uint8 complexityLevel;
        uint commonIncentive;
    }

    struct proposalCategory{
        address categorizedBy;
        uint[] paramInt;
        bytes32[] paramBytes32;
        address[] paramAddress;
        uint8 verdictOptions;
        address[] optionAddedByAddress;
        uint[] valueOfOption;
        uint[] stakeOnOption;
        string[] optionDescHash;
        uint[] optionDateAdd;
        mapping(uint=>uint) rewardOption;
    }

    struct proposalCategoryParams
    {
        mapping(bytes32=>uint[]) optionNameIntValue;
        mapping(bytes32=>bytes32[]) optionNameBytesValue;
        mapping(bytes32=>address[]) optionNameAddressValue;
    }

    struct proposalVersionData{
        uint versionNum;
        string proposalDescHash;
        uint date_add;
    }

    struct Status{
        uint statusId;
        uint date;
    }
    
    struct votingTypeDetails
    {
        bytes32 votingTypeName;
        address votingTypeAddress;
    }

    struct proposalVote {
        address voter;
        uint proposalId;
        uint[] optionChosen;
        uint dateSubmit;
        uint voterTokens;
        uint voteStakeGBT;
        uint voteValue;
        uint reward;
    }

    struct proposalVoteAndTokenCount 
    {
        mapping(uint=>mapping(uint=>uint)) totalVoteCountValue; // PROPOSAL ROLE OPTION VOTEVALUE
        mapping(uint=>uint) totalTokenCount;  // PROPOSAL ROLE TOKEN
    }
    
    mapping(uint => proposalVoteAndTokenCount) allProposalVoteAndToken;
    mapping(uint=>mapping(uint=>uint[])) ProposalRoleVote;
    mapping(address=>mapping(uint=>uint)) AddressProposalVote; 

    mapping(uint=>proposalCategoryParams) allProposalCategoryParams;
    mapping(uint=>proposalCategory) allProposalCategory;
    mapping(uint=>proposalVersionData[]) proposalVersions;
    mapping(uint=>Status[]) proposalStatus;
    mapping(address=>uint) allMemberReputationByAddress;
    mapping(uint=>uint[]) allProposalVotes; // CAN OPTIMIZE THIS
    mapping(address=>uint[]) allProposalMember; // Proposal Against Member
    mapping(address=>uint[]) allProposalOption; // Total Proposals against Member, array contains proposalIds to which solution being provided
    mapping(address=>uint[]) allMemberVotes; // Total Votes given by member till now..
    mapping(uint=>uint8) initialOptionsAdded;
    mapping(address=>mapping(uint=>uint)) allOptionDataAgainstMember; // AddressProposalOptionId

    uint public quorumPercentage;
    uint public pendingProposalStart;
    uint public GBTStakeValue; 
    uint public globalRiskFactor; 
    uint public membershipScalingFactor;
    uint public scalingWeight;
    uint public allVotesTotal;
    uint addProposalOwnerPoints;
    uint addOptionOwnerPoints;
    uint addMemberPoints;
    uint subProposalOwnerPoints;
    uint subOptionOwnerPoints;
    uint subMemberPoints;
    uint constructorCheck;

    string[]  status;
    proposal[] allProposal;
    proposalVote[] allVotes;
    votingTypeDetails[] allVotingTypeDetails;

    address GBTSAddress;
    address PoolAddress;
    address PCAddress;
    address owner;
    address GBTCAddress;
    ProposalCategory PC;
    GBTController GBTC;
    Pool P1;
    GBTStandardToken GBTS;
    // Master MS;
    // address masterAddress;


    modifier onlyInternal {
        // MS=Master(masterAddress);
        // require(MS.isInternal(msg.sender) == 1);
        
        _; 
    }
    
     modifier onlyOwner {
        // MS=Master(masterAddress);
        // require(MS.isOwner(msg.sender) == 1);
        _; 
    }
    
    /// @dev Change master's contract address
    function changeMasterAddress(address _masterContractAddress) 
    {
        // if(masterAddress == 0x000)
        //     masterAddress = _masterContractAddress;
        // else
        // {
        //     MS=Master(masterAddress);
        //     require(MS.isInternal(msg.sender) == 1);
        //         masterAddress = _masterContractAddress;
        // }
    }

    function GovernanceDataInitiate() 
    {
        require(constructorCheck == 0);
            setGlobalParameters();
            addStatus();
            addMemberReputationPoints();
            setVotingTypeDetails("Simple Voting",0x54e741a0fa3d730382da31c3ecf9740cb4909261);
            setVotingTypeDetails("Rank Based Voting",0xe67e2ad4f9fa99d916100faca93b4d01b378a8ab);
            setVotingTypeDetails("Feature Weighted Voting",0xb09361753359460091e0fd61f07477523bf8c3b0);
            allVotes.push(proposalVote(0X00,0,new uint[](0),0,0,0,0,0));
            constructorCheck=1;
    }

    /// @dev change all contract's addresses.
    function changeAllContractsAddress(address _poolAddress,address _PCAddress) onlyInternal
    {
        PoolAddress = _poolAddress;
        PCAddress = _PCAddress;
    }

    /// @dev Changes GBT contract Address. //NEW
    function changeGBTtokenAddress(address _GBTcontractAddress) onlyInternal
    {
        GBTSAddress = _GBTcontractAddress;
    }

    function changeGBTControllerAddress(address _GBTCAddress)
    {
        GBTCAddress = _GBTCAddress;
    }

    function addInVote(address _memberAddress,uint _proposalId,uint[] _optionChosen,uint _GBTPayableTokenAmount,uint _finalVoteValue)
    {
        allVotes.push(proposalVote(_memberAddress,_proposalId,_optionChosen,now,getBalanceOfMember(_memberAddress),_GBTPayableTokenAmount,_finalVoteValue,0));
        increaseTotalVotes();
    }

    function increaseTotalVotes() internal returns (uint _totalVotes)
    {
        _totalVotes = SafeMath.add(allVotesTotal,1);  
        allVotesTotal=_totalVotes;
    } 

    function setVoteId_againstMember(address _memberAddress,uint _proposalId,uint _voteId)
    {
        AddressProposalVote[_memberAddress][_proposalId] = _voteId;
    }

    function setVoteIdAgainstProposalRole(uint _proposalId,uint _roleId,uint _voteId)
    {
        ProposalRoleVote[_proposalId][_roleId].push(_voteId);
    }

    function getVoteDetailByid(uint _voteid) public constant returns(address voter,uint proposalId,uint[] optionChosen,uint dateSubmit,uint voterTokens,uint voteStakeGBT,uint voteValue)
    {
        return(allVotes[_voteid].voter,allVotes[_voteid].proposalId,allVotes[_voteid].optionChosen,allVotes[_voteid].dateSubmit,allVotes[_voteid].voterTokens,allVotes[_voteid].voteStakeGBT,allVotes[_voteid].voteValue);
    }

    function setProposalVoteCount(uint _proposalId,uint _roleId,uint _option,uint _finalVoteValue)
    {
        allProposalVoteAndToken[_proposalId].totalVoteCountValue[_roleId][_option] = SafeMath.add(allProposalVoteAndToken[_proposalId].totalVoteCountValue[_roleId][_option],_finalVoteValue);
    }

    function setProposalTokenCount(uint _proposalId,uint _roleId,address _memberAddress)
    {
        allProposalVoteAndToken[_proposalId].totalTokenCount[_roleId] = SafeMath.add(allProposalVoteAndToken[_proposalId].totalTokenCount[_roleId],getBalanceOfMember(_memberAddress));
    }

    function editProposalVoteCount(uint _proposalId,uint _roleId,uint _option,uint _VoteValue)
    {
        allProposalVoteAndToken[_proposalId].totalVoteCountValue[_roleId][_option] = SafeMath.sub(allProposalVoteAndToken[_proposalId].totalVoteCountValue[_roleId][_option],_VoteValue);
    }

    function editProposalTokenCount(uint _proposalId,uint _roleId,address _memberAddress)
    {
        allProposalVoteAndToken[_proposalId].totalTokenCount[_roleId] = SafeMath.sub(allProposalVoteAndToken[_proposalId].totalTokenCount[_roleId],getBalanceOfMember(_memberAddress));
    }

    /// @dev Get the vote count for options of proposal when giving Proposal id and Option index.
    function getProposalVoteAndTokenCountByRoleId(uint _proposalId,uint _roleId,uint _optionIndex) public constant returns(uint totalVoteValue,uint totalToken)
    {
        totalVoteValue = allProposalVoteAndToken[_proposalId].totalVoteCountValue[_roleId][_optionIndex];
        totalToken = allProposalVoteAndToken[_proposalId].totalTokenCount[_roleId];
    }

    function getVoteId_againstMember(address _memberAddress,uint _proposalId) constant returns(uint voteId)
    {
        voteId = AddressProposalVote[_memberAddress][_proposalId];
    }

    function getVoteValuebyOption_againstProposal(uint _proposalId,uint _roleId,uint _optionIndex) constant returns(uint totalVoteValue)
    {
        totalVoteValue = allProposalVoteAndToken[_proposalId].totalVoteCountValue[_roleId][_optionIndex];
    }
    
    function getOptionChosenById(uint _voteId) constant returns(uint[] optionChosen)
    {
        return (allVotes[_voteId].optionChosen);
    }
    
    function setOptionChosen(uint _voteId,uint _value)
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

    function setVoteReward(uint _voteId,uint _reward)
    {
        allVotes[_voteId].reward = _reward ;
    }

    function getVoteReward(uint _voteId)constant returns(uint reward)
    {
        return (allVotes[_voteId].reward);
    }

    function getVoteValue(uint _voteId)constant returns(uint)
    {
        return (allVotes[_voteId].voteValue);
    }

    function setVoteStake(uint _voteId,uint _voteStake)
    {
        allVotes[_voteId].voteStakeGBT = _voteStake;
    }

    function setVoteValue(uint _voteId,uint _voteValue)
    {
        allVotes[_voteId].voteValue = _voteValue;
    }

    function getVoteStake(uint _voteId)constant returns(uint)
    {
        return (allVotes[_voteId].voteStakeGBT);
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
    }

    /// @dev Set Vote Id against given proposal.
    function setVoteIdAgainstProposal(uint _proposalId,uint _voteId) 
    {
        allProposalVotes[_proposalId].push(_voteId);
    }

    /// @dev Get Total votes against a proposal when given proposal id.
    function getVoteLengthById(uint _proposalId) constant returns(uint totalVotesLength)
    {
        return (allProposalVotes[_proposalId].length);
    }

    /// @dev Get Array of All vote id's against a given proposal when given _proposalId.
    function getVoteArrayById(uint _proposalId) constant returns(uint id,uint[] totalVotes)
    {
        return (_proposalId,allProposalVotes[_proposalId]);
    }

    /// @dev Get Vote id one by one against a proposal when given proposal Id and Index to traverse vote array.
    function getVoteIdById(uint _proposalId,uint _voteArrayIndex) constant returns (uint voteId)
    {
        return (allProposalVotes[_proposalId][_voteArrayIndex]);
    }

    /// @dev Set all the voting type names and thier addresses.
    function setVotingTypeDetails(bytes32 _votingTypeName,address _votingTypeAddress) onlyOwner
    {
        allVotingTypeDetails.push(votingTypeDetails(_votingTypeName,_votingTypeAddress)); 
    }

    function editVotingType(uint _votingTypeId,address _votingTypeAddress)
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

    function setProposalAnsByAddress(uint _proposalId,address _memberAddress)
    {
        allProposalOption[_memberAddress].push(_proposalId); 
    }

    function getProposalAnsByAddress(address _memberAddress)constant returns(uint[]) // ProposalIds to which solutions being provided
    {
        return (allProposalOption[_memberAddress]);
    }

    function getProposalAnsLength(address _memberAddress)constant returns(uint)
    {
        return (allProposalOption[_memberAddress].length);
    }

    function getProposalAnsId(address _memberAddress, uint _index)constant returns (uint) // return proposId to which option added.
    {
        return (allProposalOption[_memberAddress][_index]);
    }

    /// @dev Set the Deatils of added verdict i.e. Verdict Stake, Verdict value and Address of the member whoever added the verdict.
    function setOptionIdByAddress(uint _proposalId,address _memberAddress) 
    {
        allOptionDataAgainstMember[_memberAddress][_proposalId] = getTotalVerdictOptions(_proposalId);
    }

    function getOptionIdByAddress(uint _proposalId,address _memberAddress) constant returns(uint optionIndex)
    {
        return (allOptionDataAgainstMember[_memberAddress][_proposalId]);
    }

    function setOptionAddress(uint _proposalId,address _memberAddress)
    {
        allProposalCategory[_proposalId].optionAddedByAddress.push(_memberAddress);
    }

    function setOptionStake(uint _proposalId,uint _stakeValue)
    {
        allProposalCategory[_proposalId].stakeOnOption.push(_stakeValue);
    }

    function setOptionValue(uint _proposalId,uint _optionValue)
    {
        allProposalCategory[_proposalId].valueOfOption.push(_optionValue);
    }

    function setOptionDesc(uint _proposalId,string _optionHash)
    {
        allProposalCategory[_proposalId].optionDescHash.push(_optionHash);
    }

    function setOptionDateAdded(uint _proposalId)
    {
        allProposalCategory[_proposalId].optionDateAdd.push(now);
    }

    function getOptionDateAdded(uint _proposalId,uint _optionIndex)constant returns(uint)
    {
        return (allProposalCategory[_proposalId].optionDateAdd[_optionIndex]);
    }

    function setOptionIntParameter(uint _proposalId,uint _param)
    {
        allProposalCategory[_proposalId].paramInt.push(_param);
    }
    
    function setOptionBytesParameter(uint _proposalId,bytes32 _param)
    {
        allProposalCategory[_proposalId].paramBytes32.push(_param);
    }   
    
    function setOptionAddressParameter(uint _proposalId,address _param)
    {
        allProposalCategory[_proposalId].paramAddress.push(_param);
    }
       
    function setProposalCategory(uint _proposalId,uint8 _categoryId)
    {
        allProposal[_proposalId].category = _categoryId;
    }

    function setProposalStake(uint _proposalId,uint _memberStake)
    {
        allProposal[_proposalId].proposalStake = _memberStake;
    }

    function setProposalValue(uint _proposalId,uint _proposalValue)
    {
        allProposal[_proposalId].proposalValue = _proposalValue;
    }

    /// @dev Updates  status of an existing proposal.
    function updateProposalStatus(uint _id ,uint8 _status) 
    {
        allProposal[_id].propStatus = _status;
        allProposal[_id].date_upd = now;
    }

    /// @dev Stores the status information of a given proposal.
    function pushInProposalStatus(uint _proposalId , uint8 _status) 
    {
        proposalStatus[_proposalId].push(Status(_status,now));
    }

    function setInitialOptionsAdded(uint _proposalId)
    {
        require (initialOptionsAdded[_proposalId] == 0);
            initialOptionsAdded[_proposalId] = 1;
    }

    function getInitialOptionsAdded(uint _proposalId) constant returns (uint)
    {
        if(initialOptionsAdded[_proposalId] == 1)
            return 1;
    }

    function setTotalOptions(uint _proposalId)
    {
        allProposalCategory[_proposalId].verdictOptions = allProposalCategory[_proposalId].verdictOptions +1;
    }

    function setProposalIncentive(uint _proposalId,uint _reward)
    {
        allProposal[_proposalId].commonIncentive = _reward;  
    }

    function setCategorizedBy(uint _proposalId,address _memberAddress)
    {
        allProposalCategory[_proposalId].categorizedBy = _memberAddress;
    }

    function setProposalLevel(uint _proposalId,uint8 _proposalComplexityLevel)
    {
         allProposal[_proposalId].complexityLevel = _proposalComplexityLevel;
    }

  
    /// @dev Changes the status of a given proposal.
    function changeProposalStatus(uint _id,uint8 _status) onlyInternal
    {
        require(allProposal[_id].category != 0);
        pushInProposalStatus(_id,_status);
        updateProposalStatus(_id,_status);
    }

    /// @dev Change Variables that helps in Calculation of reward distribution. Risk Factor, GBT Stak Value, Scaling Factor,Scaling weight.
    function changeGlobalRiskFactor(uint _riskFactor) onlyOwner
    {
        globalRiskFactor = _riskFactor;
    }

    function changeGBTStakeValue(uint _GBTStakeValue) onlyOwner
    {
        GBTStakeValue = _GBTStakeValue;
    }

    function changeMembershipScalingFator(uint _membershipScalingFactor) onlyOwner
    {
        membershipScalingFactor = _membershipScalingFactor;
    }

    function changeScalingWeight(uint _scalingWeight) onlyOwner
    {
        scalingWeight = _scalingWeight;
    }

    /// @dev Change quoram percentage. Value required to proposal pass.
    function changeQuorumPercentage(uint _quorumPercentage) onlyOwner
    {
        quorumPercentage = _quorumPercentage;
    }

    function setProposalCurrentVotingId(uint _proposalId,uint8 _currVotingStatus)
    {
        allProposal[_proposalId].currVotingStatus = _currVotingStatus;
    }

    /// @dev Updating proposal's Major details (Called from close proposal Vote).
    function setProposalIntermediateVerdict(uint _proposalId,uint8 _intermediateVerdict) onlyInternal 
    {
        allProposal[_proposalId].currentVerdict = _intermediateVerdict;
    }

    function setProposalFinalVerdict(uint _proposalId,uint8 _finalVerdict)
    {
        allProposal[_proposalId].finalVerdict = _finalVerdict;
    }

    function setMemberReputation(string _description,uint _proposalId,address _memberAddress,uint _repPoints,uint _repPointsEventLog,bytes4 _typeOf)
    {
        allMemberReputationByAddress[_memberAddress] = _repPoints;
        Reputation(_memberAddress, _proposalId, _description,_repPointsEventLog,_typeOf);
    }

    /// @dev Stores the information of a given version number of a given proposal. Maintains the record of all the versions of a proposal.
    function storeProposalVersion(uint _proposalId) onlyInternal 
    {
        proposalVersions[_proposalId].push(proposalVersionData(allProposal[_proposalId].versionNum,allProposal[_proposalId].proposalDescHash,allProposal[_proposalId].date_add));            
    }

    function setProposalDesc(uint _proposalId,string _hash)
    {
        allProposal[_proposalId].proposalDescHash = _hash;
    }

    function setProposalDateUpd(uint _proposalId)
    {
        allProposal[_proposalId].date_upd = now;
    }

    function setProposalVersion(uint _proposalId)
    {
        allProposal[_proposalId].versionNum = allProposal[_proposalId].versionNum+1;

    }
    
    /// @dev Fetch user balance when giving member address.
    function getBalanceOfMember(address _memberAddress) public constant returns (uint totalBalance)
    {
        GBTS=GBTStandardToken(GBTSAddress);
        totalBalance = GBTS.balanceOf(_memberAddress);
    }

    /// @dev Fetch details of proposal by giving proposal Id
    function getProposalDetailsById1(uint _proposalId) public constant returns (uint id,address owner,string proposalDescHash,uint date_add,uint date_upd,uint versionNum,uint propStatus)
    {
        return (_proposalId,allProposal[_proposalId].owner,allProposal[_proposalId].proposalDescHash,allProposal[_proposalId].date_add,allProposal[_proposalId].date_upd,allProposal[_proposalId].versionNum,allProposal[_proposalId].propStatus);
    }

    /// @dev Get the category, of given proposal. 
    function getProposalDetailsById2(uint _proposalId) public constant returns(uint id,uint8 category,uint8 currentVotingId,uint8 intermediateVerdict,uint8 finalVerdict,address votingTypeAddress) 
    {
        return (_proposalId,allProposal[_proposalId].category,allProposal[_proposalId].currVotingStatus,allProposal[_proposalId].currentVerdict,allProposal[_proposalId].finalVerdict,allProposal[_proposalId].votingTypeAddress); 
    }

    function getProposalDetailsById3(uint _proposalId) constant returns(uint proposalIndex,string proposalDescHash,uint dateAdded,string propStatus,uint propCategory,uint totalVotes,uint8 totalOption)
    {
        return (_proposalId,allProposal[_proposalId].proposalDescHash,allProposal[_proposalId].date_add,status[allProposal[_proposalId].propStatus],allProposal[_proposalId].category,allProposalVotes[_proposalId].length,allProposalCategory[_proposalId].verdictOptions);
    }

    function getProposalDetailsById4(uint _proposalId)constant returns(uint totalTokenToDistribute,uint numberBlock,uint propReward)
    {
        return(allProposal[_proposalId].totalreward,allProposal[_proposalId].blocknumber,allProposal[_proposalId].proposalReward);
    }

    /// @dev Get proposal Reward and complexity level Against proposal
    function getProposalDetails(uint _proposalId) public constant returns (uint id,uint proposalValue,uint proposalStake,uint incentive,uint complexity)
    {
        return (_proposalId,allProposal[_proposalId].proposalValue,allProposal[_proposalId].proposalStake,allProposal[_proposalId].commonIncentive,allProposal[_proposalId].complexityLevel);
    }

    /// @dev Gets version details of a given proposal id.
    function getProposalDetailsByIdAndVersion(uint _proposalId,uint _versionNum) public constant returns(uint id,uint versionNum,string proposalDescHash,uint date_add)
    {
        return (_proposalId,proposalVersions[_proposalId][_versionNum].versionNum,proposalVersions[_proposalId][_versionNum].proposalDescHash,proposalVersions[_proposalId][_versionNum].date_add);
    }
   
    /// @dev Get member address who created the proposal.
    function getProposalOwner(uint _proposalId) public constant returns(address)
    {
        return allProposal[_proposalId].owner;
    }

    function getProposalIncentive(uint _proposalId)constant returns(uint reward)
    {
        reward = allProposal[_proposalId].commonIncentive;
    }

    function getProposalComplexity(uint _proposalId)constant returns(uint level)
    {
        level =  allProposal[_proposalId].complexityLevel;
    }

    /// @dev Get Total number of verdict options against proposal.
    function getTotalVerdictOptions(uint _proposalId) constant returns(uint8 verdictOptions)
    {
        verdictOptions = allProposalCategory[_proposalId].verdictOptions;
    }

    /// @dev Get Current Status of proposal when given proposal Id
    function getProposalStatus(uint _proposalId) constant returns (uint proposalStatus)
    {
        proposalStatus = allProposal[_proposalId].propStatus;
    }

    function getProposalVotingType(uint _proposalId)constant returns(address)
    {
        return (allProposal[_proposalId].votingTypeAddress);
    }

    function getProposalCategory(uint _proposalId) constant returns(uint8 categoryId)
    {
        return allProposal[_proposalId].category;
    }

    /// @dev Get the number of tokens already distributed among members.
    function getTotalTokenInSupply() constant returns(uint _totalSupplyToken)
    {
        GBTS=GBTStandardToken(GBTSAddress);
        _totalSupplyToken = GBTS.totalSupply();
    }

    /// @dev Member Reputation is set according to if Member's Decision is Final decision.
    function getMemberReputation(address _memberAddress) constant returns(uint memberPoints)
    {
        if(allMemberReputationByAddress[_memberAddress] == 0)
            memberPoints = 1;
        else
            memberPoints = allMemberReputationByAddress[_memberAddress];
    }

    /// @dev Get proposal Value when given proposal Id.
    function getProposalValue(uint _proposalId) constant  returns(uint proposalValue) 
    {
        proposalValue = allProposal[_proposalId].proposalValue;
    }

    /// @dev Get proposal Stake by member when given proposal Id.
    function getProposalStake(uint _proposalId) constant returns(uint proposalStake)
    {
        proposalStake = allProposal[_proposalId].proposalStake;
    }

    function getProposalReward(uint _proposalId) constant returns(uint proposalReward)
    {
        proposalReward = allProposal[_proposalId].proposalReward;
    }

    /// @dev Fetch Total length of Member address array That added number of verdicts against proposal.
    function getOptionAddedAddressLength(uint _proposalId) constant returns(uint length)
    {
        return  allProposalCategory[_proposalId].optionAddedByAddress.length;
    }

    function getOptionDescByProposalId(uint _proposalId,uint _optionIndex) constant returns(string)
    {
        return allProposalCategory[_proposalId].optionDescHash[_optionIndex];
    }

    /// @dev Get the Stake of verdict when given Proposal Id and Verdict index.
    function getOptionStakeById(uint _proposalId,uint _optionIndex) constant returns(uint optionStake)
    {
        optionStake = allProposalCategory[_proposalId].stakeOnOption[_optionIndex];
    }

    /// @dev Get the value of verdict when given Proposal Id and Verdict Index.
    function getOptionValueByProposalId(uint _proposalId,uint _optionIndex) constant returns(uint optionValue)
    {
        optionValue = allProposalCategory[_proposalId].valueOfOption[_optionIndex];
    }

    /// @dev Get the Address of member whosoever added the verdict when given Proposal Id and Verdict Index.
    function getOptionAddressByProposalId(uint _proposalId,uint _optionIndex) constant returns(address memberAddress)
    {
        memberAddress = allProposalCategory[_proposalId].optionAddedByAddress[_optionIndex];
    }

    /// @dev Get the category parameters given against a proposal after categorizing the proposal.
    function getProposalOptionAll(uint _proposalId) constant returns(uint id,uint[] paramsInt,bytes32[] paramsBytes,address[] paramsAddress,uint8 verdictOptions)
    {
        id = _proposalId;
        return (id,allProposalCategory[_proposalId].paramInt,allProposalCategory[_proposalId].paramBytes32,allProposalCategory[_proposalId].paramAddress,allProposalCategory[_proposalId].verdictOptions);
    }
    
    /// @dev Fetch the parameter details for final option won (Final Verdict) when giving Proposal ID and Parameter Name Against proposal.
    function getProposalOptionAllByParameter(uint _proposalId,bytes32 _parameterNameUint,bytes32 _parameterNameBytes,bytes32 _parameterNameAddress) constant returns (uint id,uint[] intParameter,bytes32[] bytesParameter,address[] addressParameter)
    {   
        id = _proposalId;
        return (id,getParameterDetails1(_proposalId,_parameterNameUint),getParameterDetails2(_proposalId,_parameterNameBytes),getParameterDetails3(_proposalId,_parameterNameAddress));
    }

    function getParameterDetailsById1(uint _proposalId,bytes32 _parameterName,uint _index)constant returns(uint result)
    {   
        uint optionIndex = _index-1;
        return (allProposalCategoryParams[_proposalId].optionNameIntValue[_parameterName][optionIndex]);
    }

    function getParameterDetailsById2(uint _proposalId,bytes32 _parameterName,uint _index)constant returns(bytes32 result)
    {   
        uint optionIndex = _index-1;
        return (allProposalCategoryParams[_proposalId].optionNameBytesValue[_parameterName][optionIndex]);
    }

    function getParameterDetailsById3(uint _proposalId,bytes32 _parameterName,uint _index)constant returns(address result)
    {   
        uint optionIndex = _index-1;
        return (allProposalCategoryParams[_proposalId].optionNameAddressValue[_parameterName][optionIndex]);
    }

    /// @dev Fetch the Integer parameter details by parameter name against the final option.
    function getParameterDetails1(uint _proposalId,bytes32 _parameterName)  constant returns (uint[] intParameter)
    {   
        return (allProposalCategoryParams[_proposalId].optionNameIntValue[_parameterName]);
    }

    /// @dev Fetch the Bytes parameter details by parameter name against the final option.
    function getParameterDetails2(uint _proposalId,bytes32 _parameterName) constant returns (bytes32[] bytesParameter)
    {   
        return (allProposalCategoryParams[_proposalId].optionNameBytesValue[_parameterName]);
    }

    /// @dev Fetch the Address parameter details by parameter name against the final option.
    function getParameterDetails3(uint _proposalId,bytes32 _parameterName) constant returns (address[] addressParameter)
    {   
        return (allProposalCategoryParams[_proposalId].optionNameAddressValue[_parameterName]);
    }

    function setParameterDetails1(uint _proposalId,bytes32 parameterName,uint _paramInt)
    {
        allProposalCategoryParams[_proposalId].optionNameIntValue[parameterName].push(_paramInt);
    }

    function setParameterDetails2(uint _proposalId,bytes32 parameterName,bytes32 _paramBytes32)
    {
        allProposalCategoryParams[_proposalId].optionNameBytesValue[parameterName].push(_paramBytes32);
    }

    function setParameterDetails3(uint _proposalId,bytes32 parameterName,address _paramAddress)
    {
        allProposalCategoryParams[_proposalId].optionNameAddressValue[parameterName].push(_paramAddress);  
    }

    function getProposalLength()constant returns(uint)
    {  
        return (allProposal.length);
    }  

    function addInTotalVotes(address _memberAddress,uint _voteId)
    {
        allMemberVotes[_memberAddress].push(_voteId);
    }

    function getVoteArrayByAddress(address _memberAddress) constant returns(uint[] totalVoteArray)
    {
        return (allMemberVotes[_memberAddress]);
    }

    function getTotalVotesByAddress(address _memberAddress)constant returns(uint)
    {
        return (allMemberVotes[_memberAddress].length);
    }

    function addTotalProposal(uint _proposalId,address _memberAddress)
    {
        allProposalMember[_memberAddress].push(_proposalId);
    }

    function getTotalProposal(address _memberAddress) constant returns(uint)
    {
        return allProposalMember[_memberAddress].length;
    }

    function getProposalsbyAddress(address _memberAddress) constant returns(uint[] proposalid)
    {
       return  allProposalMember[_memberAddress];
    }

    function getProposalIdByAddress(address _memberAddress,uint _index)constant returns(uint)
    {
        return (allProposalMember[_memberAddress][_index]);
    }

    function setProposalTotalToken(uint _proposalId,uint _totalTokenToDistribute)
    {
        allProposal[_proposalId].totalreward = _totalTokenToDistribute;
    }

    function setProposalBlockNo(uint _proposalId,uint _blockNumber)
    {
        allProposal[_proposalId].blocknumber = _blockNumber;
    }

    function steProposalReward(uint _proposalId,uint _reward)
    {
        allProposal[_proposalId].proposalReward = _reward;
    }

    function setOptionReward(uint _proposalId,uint _reward,uint _optionIndex)
    {
        allProposalCategory[_proposalId].rewardOption[_optionIndex] = _reward;
    }

    function getOptionReward(uint _proposalId,uint _optionIndex)constant returns(uint)
    {
        return (allProposalCategory[_proposalId].rewardOption[_optionIndex]);
    }

    function getProposalFinalOption(uint _proposalId) constant returns(uint finalOptionIndex)
    {
        finalOptionIndex = allProposal[_proposalId].finalVerdict;
    }

    function getProposalRewardById(uint _proposalId) constant returns(uint propStake,uint propReward)
    {
        return(allProposal[_proposalId].proposalStake,allProposal[_proposalId].proposalReward);
    }

    function getProposalDescHash(uint _proposalId)constant returns(string)
    {
        return (allProposal[_proposalId].proposalDescHash);
    }  
    
    /// @dev Get points to proceed with updating the member reputation level.
    function getMemberReputationPoints() constant returns(uint addProposalOwnPoints,uint addOptionOwnPoints,uint addMemPoints,uint subProposalOwnPoints,uint subOptionOwnPoints,uint subMemPoints)
    {
        return (addProposalOwnerPoints,addOptionOwnerPoints,addMemberPoints,subProposalOwnerPoints,subOptionOwnerPoints,subMemberPoints);
    } 

    function changeProposalOwnerAdd(uint _repPoints)
    {
        addProposalOwnerPoints = _repPoints;
    }

    function changeOptionOwnerAdd(uint _repPoints)
    {
        addOptionOwnerPoints = _repPoints;
    }

    function changeProposalOwnerSub(uint _repPoints)
    {
        subProposalOwnerPoints = _repPoints;
    }

    function changeOptionOwnerSub(uint _repPoints)
    {
        subOptionOwnerPoints = _repPoints;
    }  

    function changeMemberAdd(uint _repPoints)
    {
        addMemberPoints = _repPoints;
    }  

    function changeMemberSub(uint _repPoints)
    {
        subMemberPoints = _repPoints;
    }  

    function addNewProposal(address _memberAddress,string _proposalDescHash,uint8 _categoryId,address _votingTypeAddress)
    {
        allProposal.push(proposal(_memberAddress,_proposalDescHash,now,now,0,0,0,_categoryId,0,0,_votingTypeAddress,0,0,0,0,0,0,0));               
    }  
    
    function changePendingProposalStart(uint _value)
    {
        pendingProposalStart = _value;
    }
}  

 

