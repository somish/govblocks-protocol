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
import "./SafeMath.sol";
import "./Master.sol";
import "./Upgradeable.sol";
import "./GBTStandardToken.sol";
import "./Governance.sol";

contract governanceData is Upgradeable{

    event Proposal(address indexed proposalOwner, uint256 indexed proposalId, uint256 dateAdd, string proposalTitle, string proposalSD, string proposalDescHash);
    event Solution(uint256 indexed proposalId, address indexed solutionOwner, uint256 indexed solutionId, string solutionDescHash, uint256 dateAdd, uint256 solutionStake);
    event Reputation(address indexed from, uint256 indexed proposalId, string description, uint32 reputationPoints, bytes4 typeOf);
    event Vote(address indexed from, uint256 indexed proposalId, uint256 dateAdd, uint256 voteStakeGBT, uint256 voteId);
    event Reward(address indexed to, uint256 indexed proposalId, string description, uint256 amount);
    event Penalty(address indexed to, uint256 indexed proposalId, string description, uint256 amount);
    event OraclizeCall(address indexed proposalOwner, uint256 indexed proposalId, uint256 dateAdd, uint256 closingTime);
    event ProposalStatus(uint256 indexed proposalId, uint256 proposalStatus, uint256 dateAdd);
    event ProposalVersion(uint256 indexed proposalId, uint256 indexed versionNumber, string proposalDescHash, uint256 dateAdd);
    event ProposalStake(address indexed proposalOwner, uint256 indexed proposalId, uint dateUpd, uint256 proposalStake);
    event ProposalWithSolution(address indexed proposalOwner, uint256 indexed proposalId, string proposalDescHash, string solutionDescHash, uint256 dateAdd, uint stake);

    /// @dev Calls proposal with solution event 
    /// @param proposalOwner Address of member whosoever has created the proposal
    /// @param proposalId ID or proposal created
    /// @param proposalDescHash Description hash of proposal having short and long description for proposal
    /// @param solutionDescHash Description hash of Solution 
    /// @param dateAdd Date when proposal was created
    /// @param stake GBT stake at the time of proposal creation
    function callProposalWithSolutionEvent(address proposalOwner, uint256 proposalId, string proposalDescHash, string solutionDescHash, uint256 dateAdd, uint stake) {
        ProposalWithSolution(proposalOwner, proposalId, proposalDescHash, solutionDescHash, dateAdd, stake);
    }

    /// @dev Calls proposal with stake event
    /// @param _proposalOwner Address of the member who has created the proposal
    /// @param _proposalId Id of proposal
    /// @param _dateUpd Date when the proposal description was updated
    /// @param _proposalStake Proposal stake in GBT
    function callProposalStakeEvent(address _proposalOwner, uint _proposalId, uint _dateUpd, uint _proposalStake) {
        ProposalStake(_proposalOwner, _proposalId, _dateUpd, _proposalStake);
    }

    /// @dev Calls proposal version event
    /// @param proposalId Id of proposal
    /// @param versionNumber Version number
    /// @param proposalDescHash Proposal description hash on IPFS
    /// @param dateAdd Date when proposal version was added
    function callProposalVersionEvent(uint256 proposalId, uint256 versionNumber, string proposalDescHash, uint256 dateAdd) onlyInternal {
        ProposalVersion(proposalId, versionNumber, proposalDescHash, dateAdd);
    }

    /// @dev Calls solution event
    /// @param proposalId Proposal id
    /// @param solutionOwner Member Address who has provided a solution
    /// @param solutionDescHash Solution description hash
    /// @param dateAdd Date the solution was added
    /// @param solutionStake Stake of the solution provider
    function callSolutionEvent(uint256 proposalId, address solutionOwner, uint solutionId, string solutionDescHash, uint256 dateAdd, uint256 solutionStake) onlyInternal {
        Solution(proposalId, solutionOwner, solutionId, solutionDescHash, dateAdd, solutionStake);
    }

    /// @dev Calls proposal event
    /// @param _proposalOwner Proposal owner
    /// @param _proposalId Proposal id
    /// @param _dateAdd Date when proposal was added
    /// @param _proposalDescHash Proposal description hash
    function callProposalEvent(address _proposalOwner, uint _proposalId, uint _dateAdd, string _proposalTitle, string _proposalSD, string _proposalDescHash) onlyInternal {
        Proposal(_proposalOwner, _proposalId, _dateAdd, _proposalTitle, _proposalSD, _proposalDescHash);
    }

    /// @dev Calls event to update the reputation of the member
    /// @param _from Whose reputation is getting updated
    /// @param _proposalId Proposal id
    /// @param _description Description
    /// @param _reputationPoints Reputation points
    /// @param _typeOf Type of credit/debit of reputation
    function callReputationEvent(address _from, uint256 _proposalId, string _description, uint32 _reputationPoints, bytes4 _typeOf) onlyInternal {
        Reputation(_from, _proposalId, _description, _reputationPoints, _typeOf);
    }

    /// @dev Calls vote event
    /// @param _from Address of the member who has casted a vote
    /// @param _voteId Id of vote
    /// @param _proposalId Id of proposal
    /// @param _dateAdd Date when the vote was casted
    /// @param _voteStakeGBT Stake in GBT against Vote
    function callVoteEvent(address _from, uint _proposalId, uint _dateAdd, uint _voteStakeGBT, uint256 _voteId) onlyInternal {
        Vote(_from, _proposalId, _dateAdd, _voteStakeGBT, _voteId);
    }

    /// @dev Calls reward event
    /// @param _to Address of the receiver of the reward
    /// @param _proposalId Proposal id
    /// @param _description Description of the event
    /// @param _amount Reward amount
    function callRewardEvent(address _to, uint256 _proposalId, string _description, uint256 _amount) onlyInternal {
        Reward(_to, _proposalId, _description, _amount);
    }

    /// @dev Calls penalty event
    /// @param _to Address to whom penalty is charged
    /// @param _proposalId Proposal id
    /// @param _description Tells the cause of penalty against Proposal, Solution or Vote.
    /// @param _amount Penalty amount
    function callPenaltyEvent(address _to, uint256 _proposalId, string _description, uint256 _amount) onlyInternal {
        Penalty(_to, _proposalId, _description, _amount);
    }

    /// @dev Calls Oraclize call event
    /// @param _proposalId Proposal id
    /// @param _dateAdd Date proposal was added
    /// @param _closingTime Closing time of the proposal voting
    function callOraclizeCallEvent(uint256 _proposalId, uint256 _dateAdd, uint256 _closingTime) onlyInternal {
        OraclizeCall(allProposal[_proposalId].owner, _proposalId, _dateAdd, _closingTime);
    }

    /// @dev Calls proposal status event
    /// @param _proposalId Proposal id
    /// @param _proposalStatus Proposal status
    /// @param _dateAdd Date when proposal was added
    function callProposalStatusEvent(uint256 _proposalId, uint _proposalStatus, uint _dateAdd) onlyInternal {
        ProposalStatus(_proposalId, _proposalStatus, _dateAdd);
    }

    using SafeMath for uint;
    struct proposal {
        address owner;
        uint date_upd;
        address votingTypeAddress;
    }

    struct proposalData {
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

    struct votingTypeDetails {
        bytes32 votingTypeName;
        address votingTypeAddress;
    }

    struct proposalVote {
        address voter;
        uint[] solutionChosen;
        uint voteValue;
    }

    struct lastReward {
        uint lastReward_proposalId;
        uint lastReward_solutionProposalId;
        uint lastReward_voteId;
    }

    struct deposit {
        uint amount;
        uint8 returned;
    }

    struct solution {
        address owner;
        bytes action;
    }

    mapping(uint => proposalData) allProposalData;
    mapping(uint => solution[]) allProposalSolutions;
    mapping(address => uint32) allMemberReputationByAddress;
    mapping(address => mapping(uint => uint)) AddressProposalVote;
    mapping(uint => mapping(uint => uint[])) ProposalRoleVote;
    mapping(address => uint[]) allProposalByMember;
    mapping(address => mapping(uint => mapping(bytes4 => deposit))) allMemberDepositTokens;
    mapping(address => lastReward) lastRewardDetails;

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

    string[] status;
    proposal[] allProposal;
    proposalVote[] allVotes;
    votingTypeDetails[] allVotingTypeDetails;

    Master MS;
    GBTStandardToken GBTS;
    Governance GOV;
    address masterAddress;
    address GBTSAddress;
    address constant null_address = 0x00;

    modifier onlyInternal {
        MS = Master(masterAddress);
        require(MS.isInternal(msg.sender) == true);
        _;
    }

    modifier onlyOwner {
        MS = Master(masterAddress);
        require(MS.isOwner(msg.sender) == true);
        _;
    }

    modifier onlyMaster {
        require(msg.sender == masterAddress);
        _;
    }

    modifier onlyGBM {
        MS = Master(masterAddress);
        require(MS.isGBM(msg.sender) == true);
        _;
    }

    /// @dev Changes master's contract address
    /// @param _masterContractAddress New master contract address
    function changeMasterAddress(address _masterContractAddress) {
        if (masterAddress == 0x000)
            masterAddress = _masterContractAddress;
        else {
            MS = Master(masterAddress);
            require(MS.isInternal(msg.sender) == true);
            masterAddress = _masterContractAddress;
        }
    }

    /// @dev Changes GovBlocks standard token address
    /// @param _GBTAddress New GovBlocks token address
    function changeGBTSAddress(address _GBTAddress) onlyMaster {
        GBTSAddress = _GBTAddress;
    }

    /*
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
    }*/
    
    /// @dev updates all dependency addresses to latest ones from Master
    function updateDependencyAddresses() onlyInternal {
        if(!constructorCheck)
            GovernanceDataInitiate();
        MS = Master(masterAddress);
        GOV = Governance(MS.getLatestAddress("GV"));
        GBTSAddress = MS.getLatestAddress("GS");
        editVotingTypeDetails(0, MS.getLatestAddress("SV"));
    }

    /// @dev Initiates governance data
    function GovernanceDataInitiate() {
        require(constructorCheck == false);
        setGlobalParameters();
        addMemberReputationPoints();
        setVotingTypeDetails("Simple Voting", null_address);
        //setVotingTypeDetails("Rank Based Voting", null_address);
        //setVotingTypeDetails("Feature Weighted Voting", null_address);
        allVotes.push(proposalVote(0X00, new uint[](0), 0));
        uint _totalVotes = SafeMath.add(allVotesTotal, 1);
        allVotesTotal = _totalVotes;
        constructorCheck = true;
    }

    /// @dev Adds points to add or subtract in member reputation when proposal/Solution/vote gets denied or accepted
    function addMemberReputationPoints() internal {
        addProposalOwnerPoints = 5;
        addSolutionOwnerPoints = 5;
        addMemberPoints = 1;
        subProposalOwnerPoints = 1;
        subSolutionOwnerPoints = 1;
        subMemberPoints = 1;
    }

    /// @dev Changes points to add or subtract in member reputation when proposal/Solution/vote gets denied or accepted
    /// @param _addProposalOwnerPoints Points that needs to be added in Proposal owner reputation after proposal acceptance
    /// @param _addSolutionOwnerPoints Points that needs to be added in Solution Owner reputation for providing correct solution against proposal
    /// @param _addMemberPoints Points that needs to be added in Other members reputation for casting vote in favour of correct solution
    /// @param _subProposalOwnerPoints Points that needs to be subtracted from Proposal owner reputation in case proposal gets rejected
    /// @param _subSolutionOwnerPoints  Points that needs to be subtracted from Solution Owner reputation for providing wrong solution against proposal
    /// @param _subMemberPoints Points that needs to be subtracted from Other members reputation for casting vote against correct solution
    function changeMemberReputationPoints(uint32 _addProposalOwnerPoints, uint32 _addSolutionOwnerPoints, uint32 _addMemberPoints, uint32 _subProposalOwnerPoints, uint32 _subSolutionOwnerPoints, uint32 _subMemberPoints) onlyOwner {
        addProposalOwnerPoints = _addProposalOwnerPoints;
        addSolutionOwnerPoints = _addSolutionOwnerPoints;
        addMemberPoints = _addMemberPoints;
        subProposalOwnerPoints = _subProposalOwnerPoints;
        subSolutionOwnerPoints = _subSolutionOwnerPoints;
        subMemberPoints = _subMemberPoints;
    }

    /// @dev Sets global parameters that will help in distributing reward
    function setGlobalParameters() internal {
        pendingProposalStart = 0;
        quorumPercentage = 25;
        GBTStakeValue = 0;
        membershipScalingFactor = 1;
        scalingWeight = 1;
        depositPercProposal = 30;
        depositPercSolution = 30;
        depositPercVote = 40;
        tokenHoldingTime = 259200; // In seconds
    }


    // VERSION 2.0 : Last Reward Distribution details.


    /// @dev Sets the Last proposal id till which the reward has been distributed for Proposal Owner (Proposal creation and acceptance Reward)
    function setLastRewardId_ofCreatedProposals(address _memberAddress, uint _proposalId) onlyInternal {
        lastRewardDetails[_memberAddress].lastReward_proposalId = _proposalId;
    }

    /// @dev Sets the last proposal id till which the reward has been distributed for Solution Owner (For providing correct solution Reward)
    function setLastRewardId_ofSolutionProposals(address _memberAddress, uint _proposalId) onlyInternal {
        lastRewardDetails[_memberAddress].lastReward_solutionProposalId = _proposalId;
    }

    /// @dev Sets the last Vote id till which the reward has been distributed for Vote owners (For voting in favour of correct solution Reward)
    function setLastRewardId_ofVotes(address _memberAddress, uint _voteId) onlyInternal {
        lastRewardDetails[_memberAddress].lastReward_voteId = _voteId;
    }

    /// @dev Gets last Proposal id till the reward has been distributed (Proposal creation and acceptance)
    function getLastRewardId_ofCreatedProposals(address _memberAddress) constant returns(uint) {
        return lastRewardDetails[_memberAddress].lastReward_proposalId;
    }

    /// @dev Gets the last proposal id till the reward has been distributed for being Solution Owner
    function getLastRewardId_ofSolutionProposals(address _memberAddress) constant returns(uint) {
        return lastRewardDetails[_memberAddress].lastReward_solutionProposalId;
    }

    /// @dev Gets the last vote id till which the reward has been distributed against member
    function getLastRewardId_ofVotes(address _memberAddress) constant returns(uint) {
        return lastRewardDetails[_memberAddress].lastReward_voteId;
    }

    /// @dev Get all Last Id's till which the reward has been distributed against member
    function getAllidsOfLastReward(address _memberAddress) constant returns(uint lastRewardId_ofCreatedProposal, uint lastRewardid_ofSolution, uint lastRewardId_ofVote) {
        return (lastRewardDetails[_memberAddress].lastReward_proposalId, lastRewardDetails[_memberAddress].lastReward_solutionProposalId, lastRewardDetails[_memberAddress].lastReward_voteId);
    }

    /// @dev Sets the amount being deposited by a member against proposal
    /// @param _typeOf TypeOf is "P" in case of proposal creation, "S" in case of providing solution, "V" in case of casting vote i.e. Stating the stage of proposal
    /// @param _depositAmount Amount to deposit
    function setDepositTokens(address _memberAddress, uint _proposalId, bytes4 _typeOf, uint _depositAmount) onlyInternal {
        allMemberDepositTokens[_memberAddress][_proposalId][_typeOf].amount = _depositAmount;
    }

    /// @dev Gets the amount being deposited against proposal by a member at different stages of proposal  
    /// @param _typeOf typeOf is P for Proposal, S for Solution and V for Voting stage of proposal
    function getDepositedTokens(address _memberAddress, uint _proposalId, bytes4 _typeOf) constant returns(uint) {
        return allMemberDepositTokens[_memberAddress][_proposalId][_typeOf].amount;
    }

    /// @dev Checks if the reward has been distributed for particular proposal at specific stage i.e. returned flag is 0 if reward is not yet distributed
    function getReturnedTokensFlag(address _memberAddress, uint _proposalId, bytes4 _typeOf) constant returns(uint8) {
        return allMemberDepositTokens[_memberAddress][_proposalId][_typeOf].returned;
    }

    /// @dev Sets returned tokens to be 1 in case the member has claimed the reward and we distributed that 
    function setReturnedTokensFlag(address _memberAddress, uint _proposalId, bytes4 _typeOf, uint8 _returnedIndex) onlyInternal {
        allMemberDepositTokens[_memberAddress][_proposalId][_typeOf].returned = _returnedIndex;
    }

    /// @dev user can calim the tokens rewarded them till noW
    function claimReward() public {
        uint rewardToClaim = GOV.calculateMemberReward(msg.sender);
        if (rewardToClaim != 0) {
            GBTS.transfer_message(address(this), rewardToClaim, "GBT Stake Received");
            GBTS.transfer_message(msg.sender, rewardToClaim, "GBT Stake claimed");
        }
    }


    // VERSION 2.0 : VOTE DETAILS 

    /// @dev Add vote details such as Solution id to which he has voted and vote value
    function addVote(address _memberAddress, uint[] _solutionChosen,uint _voteValue) onlyInternal {
        allVotes.push(proposalVote(_memberAddress, _solutionChosen, _voteValue));
    }

    /// @dev Sets vote id against member
    /// @param _memberAddress Member address who casted a vote
    /// @param _proposalId Proposal Id to against which the vote has been casted
    /// @param _voteId Id of vote
    function setVoteId_againstMember(address _memberAddress, uint _proposalId, uint _voteId) onlyInternal {
        AddressProposalVote[_memberAddress][_proposalId] = _voteId;
    }

    /// @dev Sets Vote id against proposal with Role id
    /// @param _roleId Role id of the member who has voted
    function setVoteId_againstProposalRole(uint _proposalId, uint _roleId, uint _voteId) onlyInternal {
        ProposalRoleVote[_proposalId][_roleId].push(_voteId);
    }

    // function setVoteValue(uint _voteId, uint _voteValue) onlyInternal {
    //     allVotes[_voteId].voteValue = _voteValue;
    // }

    /// @dev Sets Voting type details such as Voting type name and address
    function setVotingTypeDetails(bytes32 _votingTypeName, address _votingTypeAddress) internal {
        allVotingTypeDetails.push(votingTypeDetails(_votingTypeName, _votingTypeAddress));
    }

    /// @dev Edits Voting type address when given voting type name
    function editVotingTypeDetails(uint _votingTypeId, address _votingTypeAddress) internal {
        allVotingTypeDetails[_votingTypeId].votingTypeAddress = _votingTypeAddress;
    }

    /// @dev Gets vote details by id such as Vote value, Address of the voter and Solution number to which he has voted.
    function getVoteDetailById(uint _voteid) public constant returns(address voter, uint[] solutionChosen, uint voteValue) {
        return (allVotes[_voteid].voter, allVotes[_voteid].solutionChosen, allVotes[_voteid].voteValue);
    }

    /// @dev Gets Vote id Against proposal when passing proposal id and member addresse
    function getVoteId_againstMember(address _memberAddress, uint _proposalId) constant returns(uint voteId) {
        voteId = AddressProposalVote[_memberAddress][_proposalId];
    }

    /// @dev Check if the member has voted against a proposal. Returns true if vote id exists
    function checkVoteId_againstMember(address _memberAddress, uint _proposalId) constant returns(bool) {
        uint voteId = AddressProposalVote[_memberAddress][_proposalId];
        if (voteId == 0)
            return false;
        else
            return true;
    }

    /// @dev Gets voter address
    function getVoterAddress(uint _voteId) constant returns(address _voterAddress) {
        return (allVotes[_voteId].voter);
    }

    /// @dev Gets All the Role specific vote ids against proposal 
    /// @param _roleId Role id which number of votes to be fetched.
    /// @return totalVotes Total votes casted by this particular role id.
    function getAllVoteIds_byProposalRole(uint _proposalId, uint _roleId) constant returns(uint[] totalVotes) {
        return ProposalRoleVote[_proposalId][_roleId];
    }

    /// @dev Gets Total number of votes of specific role against proposal
    function getAllVoteIdsLength_byProposalRole(uint _proposalId, uint _roleId) constant returns(uint length) {
        return ProposalRoleVote[_proposalId][_roleId].length;
    }

    /// @dev Gets Vote id from the array that contains all role specific votes against proposal
    /// @param _index To get vote id at particular index from array
    function getVoteId_againstProposalRole(uint _proposalId, uint _roleId, uint _index) constant returns(uint) {
        return (ProposalRoleVote[_proposalId][_roleId][_index]);
    }

    /// @dev Gets vote value against Vote id
    function getVoteValue(uint _voteId) constant returns(uint) {
        return (allVotes[_voteId].voteValue);
    }

    /// @dev Gets Total number of voting types has been added till now.
    function getVotingTypeLength() public constant returns(uint) {
        return allVotingTypeDetails.length;
    }

    /// @dev Gets voting type details by passing voting id
    function getVotingTypeDetailsById(uint _votingTypeId) public constant returns(uint votingTypeId, bytes32 VTName, address VTAddress) {
        return (_votingTypeId, allVotingTypeDetails[_votingTypeId].votingTypeName, allVotingTypeDetails[_votingTypeId].votingTypeAddress);
    }

    /// @dev Gets Voting type address when voting type id is passes by
    function getVotingTypeAddress(uint _votingTypeId) constant returns(address votingAddress) {
        return (allVotingTypeDetails[_votingTypeId].votingTypeAddress);
    }


    // VERSION 2.0 : SOLUTION DETAILS

    // function setSolutionChosen(uint _voteId, uint _value) onlyInternal {
    //     allVotes[_voteId].solutionChosen.push(_value);
    // }


    /// @dev Sets the address of member as solution owner whosoever provided the solution
    function setSolutionAdded(uint _proposalId, address _memberAddress, bytes _action) onlyInternal {
        allProposalSolutions[_proposalId].push(solution(_memberAddress,_action));
    }

    /// @dev Returns the solution index that was being voted
    function getSolutionByVoteId(uint _voteId) constant returns(uint[] solutionChosen) {
        return (allVotes[_voteId].solutionChosen);
    }

    /// @dev Gets Solution id against which vote had been casted
    /// @param _solutionChosenId To get solution id at particular index from solutionChosen array i.e. 0 is passed In case of Simple Voting Type.
    function getSolutionByVoteIdAndIndex(uint _voteId, uint _solutionChosenId) constant returns(uint solution) {
        return (allVotes[_voteId].solutionChosen[_solutionChosenId]);
    }

    /// @dev Gets The Address of Solution owner By solution sequence index As a proposal might have n number of solutions.
    function getSolutionAddedByProposalId(uint _proposalId, uint _Index) constant returns(address memberAddress) {
        return allProposalSolutions[_proposalId][_Index].owner;
    }

    /// @dev Gets The Solution Action By solution sequence index As a proposal might have n number of solutions.
    function getSolutionActionByProposalId(uint _proposalId, uint _Index) constant returns(bytes action) {
        return allProposalSolutions[_proposalId][_Index].action;
    }

    // VERSION 2.0 : Configurable parameters.

    /// @dev Changes stake value that helps in calculation of reward distribution
    function changeGBTStakeValue(uint _GBTStakeValue) onlyGBM {
        GBTStakeValue = _GBTStakeValue;
    }

    /// @dev Changes member scaling factor that helps in calculation of reward distribution
    function changeMembershipScalingFator(uint _membershipScalingFactor) onlyGBM {
        membershipScalingFactor = _membershipScalingFactor;
    }

    /// @dev Changes scaling weight that helps in calculation of reward distribution
    function changeScalingWeight(uint _scalingWeight) onlyGBM {
        scalingWeight = _scalingWeight;
    }

    /// @dev Changes quoram percentage. Value required to pass proposal.
    function changeQuorumPercentage(uint _quorumPercentage) onlyGBM {
        quorumPercentage = _quorumPercentage;
    }

    /// @dev Gets reputation points to proceed with updating the member reputation level
    function getMemberReputationPoints() constant returns(uint32 addProposalOwnPoints, uint32 addSolutionOwnerPoints, uint32 addMemPoints, uint32 subProposalOwnPoints, uint32 subSolutionOwnPoints, uint32 subMemPoints) {
        return (addProposalOwnerPoints, addSolutionOwnerPoints, addMemberPoints, subProposalOwnerPoints, subSolutionOwnerPoints, subMemberPoints);
    }

    /// @dev Changes Proposal owner reputation points that needs to be added at proposal acceptance
    function changeProposalOwnerAdd(uint32 _repPoints) onlyGBM {
        addProposalOwnerPoints = _repPoints;
    }

    /// @dev Changes Solution owner reputation points that needs to be added if solution has won. (Upvoted with many votes)
    function changeSolutionOwnerAdd(uint32 _repPoints) onlyGBM {
        addSolutionOwnerPoints = _repPoints;
    }

    /// @dev Change proposal owner reputation points that needs to be subtracted if proposal gets rejected. 
    function changeProposalOwnerSub(uint32 _repPoints) onlyGBM {
        subProposalOwnerPoints = _repPoints;
    }

    /// @dev Changes solution owner reputation points that needs to be subtracted if solution is downvoted with many votes   
    function changeSolutionOwnerSub(uint32 _repPoints) onlyGBM {
        subSolutionOwnerPoints = _repPoints;
    }

    /// @dev Change member points that needs to be added when voting in favour of final solution
    function changeMemberAdd(uint32 _repPoints) onlyGBM {
        addMemberPoints = _repPoints;
    }

    /// @dev Change member points that needs to be subtracted when voted against final solution
    function changeMemberSub(uint32 _repPoints) onlyGBM {
        subMemberPoints = _repPoints;
    }

    // VERSION 2.0 // PROPOSAL DETAILS

    /// @dev Sets proposal category
    function setProposalCategory(uint _proposalId, uint8 _categoryId) onlyInternal {
        allProposalData[_proposalId].category = _categoryId;
    }

    /// @dev Updates status of an existing proposal
    function updateProposalStatus(uint _id, uint8 _status) internal {
        allProposalData[_id].propStatus = _status;
        allProposal[_id].date_upd = now;
    }

    /// @dev Sets proposal incentive/reward that needs to be distributed at the end of proposal closing
    function setProposalIncentive(uint _proposalId, uint _reward) onlyInternal {
        allProposalData[_proposalId].commonIncentive = _reward;
    }

    /// @dev Changes the status of a given proposal.
    function changeProposalStatus(uint _id, uint8 _status) onlyInternal {
        require(allProposalData[_id].category != 0);
        ProposalStatus(_id, _status, now);
        updateProposalStatus(_id, _status);
    }

    /// @dev Sets proposal current voting id i.e. Which Role id is next in row to vote against proposal
    /// @param _currVotingStatus It is the index to fetch the role id from voting sequence array. 
    function setProposalCurrentVotingId(uint _proposalId, uint8 _currVotingStatus) onlyInternal {
        allProposalData[_proposalId].currVotingStatus = _currVotingStatus;
    }

    /// @dev Updates proposal's intermediateVerdict after every voting layer is passed.
    function setProposalIntermediateVerdict(uint _proposalId, uint8 _intermediateVerdict) onlyInternal {
        allProposalData[_proposalId].currentVerdict = _intermediateVerdict;
    }

    /// @dev Sets proposal's final verdict once the final voting layer is crossed and voting is final closed for proposal
    function setProposalFinalVerdict(uint _proposalId, uint8 _finalVerdict) onlyInternal {
        allProposalData[_proposalId].finalVerdict = _finalVerdict;
    }

    /// @dev Update member reputation once the proposal reward is distributed.
    /// @param _description Cause of points being credited/debited from reputation
    /// @param _proposalId Id of proposal
    /// @param _memberAddress Address of member whose reputation is being updated
    /// @param _repPoints Updated reputation of member
    /// @param _repPointsEventLog Actual points being added/subtracted from member's reputation
    /// @param _typeOf typeOf is "C" in case the points is credited, "D" otherwise!
    function setMemberReputation(string _description, uint _proposalId, address _memberAddress, uint32 _repPoints, uint32 _repPointsEventLog, bytes4 _typeOf) onlyInternal {
        allMemberReputationByAddress[_memberAddress] = _repPoints;
        Reputation(_memberAddress, _proposalId, _description, _repPointsEventLog, _typeOf);
    }

    /// @dev Stores the information of version number of a given proposal. Maintains the record of all the versions of a proposal.
    function storeProposalVersion(uint _proposalId, string _proposalDescHash) onlyInternal {
        uint8 versionNo = allProposalData[_proposalId].versionNumber + 1;
        ProposalVersion(_proposalId, versionNo, _proposalDescHash, now);
        setProposalVersion(_proposalId, versionNo);
    }

    /// @dev Sets proposal's date when the proposal last modified
    function setProposalDateUpd(uint _proposalId) onlyInternal {
        allProposal[_proposalId].date_upd = now;
    }

    /// @dev Sets version number of proposal i.e. Version number increases everytime the proposal is modified
    function setProposalVersion(uint _proposalId, uint8 _versionNum) internal {
        allProposalData[_proposalId].versionNumber = _versionNum;
    }

    /// @dev Fetch details of proposal when giving proposal id
    function getProposalDetailsById1(uint _proposalId) public constant returns(uint id, address owner, uint date_upd, uint8 versionNum, uint8 propStatus) {
        return (_proposalId, allProposal[_proposalId].owner, allProposal[_proposalId].date_upd, allProposalData[_proposalId].versionNumber, allProposalData[_proposalId].propStatus);
    }

    /// @dev Fetch details of proposal when giving proposal id
    function getProposalDetailsById2(uint _proposalId) public constant returns(uint id, uint8 category, uint8 currentVotingId, uint8 intermediateVerdict, uint8 finalVerdict, address votingTypeAddress, uint totalSolutions) {
        return (_proposalId, allProposalData[_proposalId].category, allProposalData[_proposalId].currVotingStatus, allProposalData[_proposalId].currentVerdict, allProposalData[_proposalId].finalVerdict, allProposal[_proposalId].votingTypeAddress, allProposalSolutions[_proposalId].length);
    }

    /// @dev Fetch details of proposal when giving proposal id
    function getProposalDetailsById3(uint _proposalId) constant returns(uint proposalIndex, uint propStatus, uint8 propCategory, uint8 propStatusId, uint8 finalVerdict) {
        return (_proposalId, getProposalStatus(_proposalId), allProposalData[_proposalId].category, allProposalData[_proposalId].propStatus, allProposalData[_proposalId].finalVerdict);
    }

    /// @dev Fetch details of proposal when giving proposal id
    function getProposalDetailsById4(uint _proposalId) constant returns(uint totalTokenToDistribute, uint totalVoteValue) {
        return (allProposalData[_proposalId].totalreward, allProposalData[_proposalId].totalVoteValue);
    }

    /// @dev Gets proposal details of given proposal id
    /// @param totalVotes Total number of votes that has been casted so far against proposal
    /// @param totalSolutions Total number of solutions proposed till now against proposal
    /// @param commonIncentive Incentive that needs to be distributed once the proposal is closed.
    /// @param finalVerdict Final solution index that has won by maximum votes.
    function getProposalDetailsById6(uint _proposalId) public constant returns(uint proposalId, uint status, uint totalVotes, uint totalSolutions, uint commonIncentive, uint finalVerdict) {
        proposalId = _proposalId;
        status = getProposalStatus(_proposalId);
        totalVotes = getProposalTotalVoteValue(_proposalId);
        totalSolutions = getTotalSolutions(_proposalId);
        commonIncentive = getProposalIncentive(_proposalId);
        finalVerdict = allProposalData[_proposalId].finalVerdict;
    }

    /// @dev Gets date when proposal is last updated
    function getProposalDateUpd(uint _proposalId) constant returns(uint) {
        return allProposal[_proposalId].date_upd;
    }

    /// @dev Gets member address who created the proposal i.e. proposal owner
    function getProposalOwner(uint _proposalId) public constant returns(address) {
        return allProposal[_proposalId].owner;
    }

    /// @dev Gets proposal incentive that will get distributed once the proposal is closed
    function getProposalIncentive(uint _proposalId) constant returns(uint commonIncentive) {
        return allProposalData[_proposalId].commonIncentive;
    }

    /// @dev Gets the total incentive amount given by dApp to different proposals
    function getTotalProposalIncentive() constant returns(uint allIncentive) {
        for (uint i = 0; i < allProposal.length; i++) {
            allIncentive = allIncentive + allProposalData[i].commonIncentive;
        }
    }

    /// @dev Gets proposal current voting status i.e. Who is next in voting sequence
    function getProposalCurrentVotingId(uint _proposalId) constant returns(uint8 _currVotingStatus) {
        return (allProposalData[_proposalId].currVotingStatus);
    }

    /// @dev Get Total Amount that has been collected at the end of voting to distribute further i.e. Total token to distribute
    function getProposalTotalReward(uint _proposalId) constant returns(uint) {
        return allProposalData[_proposalId].totalreward;
    }

    /// @dev Get Total number of Solutions being proposed against proposal.
    function getTotalSolutions(uint _proposalId) constant returns(uint) {
        return allProposalSolutions[_proposalId].length;
    }

    /// @dev Get Current Status of proposal when given proposal Id
    function getProposalStatus(uint _proposalId) constant returns(uint propStatus) {
        return allProposalData[_proposalId].propStatus;
    }

    /// @dev Gets proposal voting type when given proposal id
    function getProposalVotingType(uint _proposalId) constant returns(address) {
        return (allProposal[_proposalId].votingTypeAddress);
    }

    /// @dev Gets proposal category when given proposal id
    function getProposalCategory(uint _proposalId) constant returns(uint8 categoryId) {
        return allProposalData[_proposalId].category;
    }

    /// @dev Get member's reputation points and it's likely to be updated with time.
    function getMemberReputation(address _memberAddress) constant returns(uint32 memberPoints) {
        if (allMemberReputationByAddress[_memberAddress] == 0)
            memberPoints = 1;
        else
            memberPoints = allMemberReputationByAddress[_memberAddress];
    }

    /// @dev Gets Total vote value from all the votes that has been casted against of winning solution
    function getProposalTotalVoteValue(uint _proposalId) constant returns(uint voteValue) {
        voteValue = allProposalData[_proposalId].totalVoteValue;
    }

    /// @dev Gets Total number of proposal created till now in dApp
    function getProposalLength() constant returns(uint) {
        return (allProposal.length);
    }

    /// @dev Get Latest updated version of proposal.
    function getProposalVersion(uint _proposalId, uint8 _versionNum) constant returns(uint) {
        return allProposalData[_proposalId].versionNumber;
    }

    /// @dev Sets Total calculated vote value from all the votes that has been casted against of winning solution
    function setProposalTotalVoteValue(uint _proposalId, uint _voteValue) onlyInternal {
        allProposalData[_proposalId].totalVoteValue = _voteValue;
    }

    /// @dev Get Total Amount that has been collected at the end of voting to distribute further i.e. Total token to distribute
    function setProposalTotalReward(uint _proposalId, uint _totalreward) onlyInternal {
        allProposalData[_proposalId].totalreward = _totalreward;
    }

    /// @dev Changes status from pending proposal to start proposal
    function changePendingProposalStart(uint _value) onlyInternal {
        pendingProposalStart = _value;
    }

    /// @dev Adds new proposal
    function addNewProposal(uint _proposalId, address _memberAddress, uint8 _categoryId, address _votingTypeAddress, uint _dateAdd) onlyInternal {
        allProposal.push(proposal(_memberAddress, _dateAdd, _votingTypeAddress));
        allProposalData[_proposalId].category = _categoryId;
    }

    /// @dev Creates new proposal
    function createProposal1(uint _proposalId, address _memberAddress, address _votingTypeAddress, uint _dateAdd) onlyInternal {
        allProposal.push(proposal(_memberAddress, _dateAdd, _votingTypeAddress));
    }

    /// @dev Gets final solution index won after majority voting.
    function getProposalFinalVerdict(uint _proposalId) constant returns(uint finalSolutionIndex) {
        finalSolutionIndex = allProposalData[_proposalId].finalVerdict;
    }

    /// @dev Gets Intermidiate solution is while voting is still in progress by other voting layers
    function getProposalIntermediateVerdict(uint _proposalId) constant returns(uint8) {
        return allProposalData[_proposalId].currentVerdict;
    }

    /// @dev Change token holding time i.e. When user submits stake, Few tokens gets deposited and rest is locked for a period of time.
    function changeTokenHoldingTime(uint _time) onlyOwner {
        tokenHoldingTime = _time;
    }

    /// @dev Get total deposit tokens against member and proposal Id with type of (proposal/solution/vote); 
    function getDepositTokens_byAddressProposal(address _memberAddress, uint _proposalId) constant returns(uint, uint depositFor_creatingProposal, uint depositFor_proposingSolution, uint depositFor_castingVote) {
        return (_proposalId, getDepositedTokens(_memberAddress, _proposalId, "P"), getDepositedTokens(_memberAddress, _proposalId, "S"), getDepositedTokens(_memberAddress, _proposalId, "V"));
    }

    /// @dev Gets statuses of proposals
    /// @param _proposalLength Total proposals created till now.
    /// @param _draftProposals Proposal that are currently in draft or still getting updated.
    /// @param _pendingProposals Those proposals still open for voting
    /// @param _acceptedProposals Proposal those are submitted or accepted by majority voting
    /// @param _rejectedProposals Proposal those are rejected by majority voting.
    function getStatusOfProposals() constant returns(uint _proposalLength, uint _draftProposals, uint _pendingProposals, uint _acceptedProposals, uint _rejectedProposals) {
        uint proposalStatus;
        _proposalLength = getProposalLength();

        for (uint i = 0; i < _proposalLength; i++) {
            proposalStatus = getProposalStatus(i);
            if (proposalStatus < 2)
                _draftProposals++;
            else if (proposalStatus == 2)
                _pendingProposals++;
            else if (proposalStatus == 3)
                _acceptedProposals++;
            else if (proposalStatus >= 4)
                _rejectedProposals++;
        }
    }

    /// @dev Gets statuses of all the proposal that are created by specific member
    /// @param _proposalsIds All proposal Ids array is passed
    /// @return proposalLength Total number of proposals
    /// @return draftProposals Proposals in draft or still getting updated
    /// @return pendingProposals Proposals still open for voting are pending ones
    /// @return acceptedProposals If a decision has been made then the proposal is in accep state
    /// @return rejectedProposals All the proposals rejected by majority voting
    function getStatusOfProposalsForMember(uint[] _proposalsIds) constant returns(uint proposalLength, uint draftProposals, uint pendingProposals, uint acceptedProposals, uint rejectedProposals) {
        uint proposalStatus;
        proposalLength = getProposalLength();

        for (uint i = 0; i < _proposalsIds.length; i++) {
            proposalStatus = getProposalStatus(_proposalsIds[i]);
            if (proposalStatus < 2)
                draftProposals++;
            else if (proposalStatus == 2)
                pendingProposals++;
            else if (proposalStatus == 3)
                acceptedProposals++;
            else if (proposalStatus >= 4)
                rejectedProposals++;
        }
    }

    /// @dev Gets Total number of solutions provided by a specific member
    function getAllSolutionIdsLength_byAddress(address _memberAddress) constant returns(uint totalSolutionProposalCount) {
        for (uint i = 0; i < allProposal.length; i++) {
            for (uint j = 0; j < getTotalSolutions(i); j++) {
                if (_memberAddress == getSolutionAddedByProposalId(i, j))
                    totalSolutionProposalCount++;
            }
        }
    }

    /// @dev Get Total tokens deposited by member till date against all proposal.
    /// @return depositFor_creatingProposal tokens deposited for crating proposals so far
    /// @return depositFor_proposingSolution Total amount that has been deposited for proposing solutions
    /// @return depositFor_castingVote Total amount that has been deposited when casting vote against proposals
    function getAllDepositTokens_byAddress(address _memberAddress) constant returns(uint depositFor_creatingProposal, uint depositFor_proposingSolution, uint depositFor_castingVote) {
        for (uint i = 0; i < allProposal.length; i++) {
            depositFor_creatingProposal = depositFor_creatingProposal + getDepositedTokens(_memberAddress, i, "P");
            depositFor_proposingSolution = depositFor_proposingSolution + getDepositedTokens(_memberAddress, i, "S");
            depositFor_castingVote = depositFor_castingVote + getDepositedTokens(_memberAddress, i, "V");
        }
    }

    /// @dev Gets All the solution ids provided by a member so far
    /// @param _memberAddress Address of member whose address we need to fetch
    /// @return proposalIds All the proposal ids array to which the solution being provided
    /// @return solutionIds This array containg all solution ids as all proposals might have many solutions.
    /// @return totalSolution Count of total solutions provided by member till now
    function getAllSolutionIds_byAddress(address _memberAddress) constant returns(uint[] proposalIds, uint[] solutionProposalIds, uint totalSolution) {
        uint8 m;
        uint solutionProposalLength = getAllSolutionIdsLength_byAddress(_memberAddress);
        proposalIds = new uint[](solutionProposalLength);
        solutionProposalIds = new uint[](solutionProposalLength);
        for (uint i = 0; i < allProposal.length; i++) {
            for (uint j = 0; j < allProposalSolutions[i].length; j++) {
                if (_memberAddress == getSolutionAddedByProposalId(i, j)) {
                    proposalIds[m] = i;
                    solutionProposalIds[m] = j;
                    m++;
                }
            }
        }
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
