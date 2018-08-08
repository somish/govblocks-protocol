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
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import "./Master.sol";
import "./Upgradeable.sol";
import "./GBTStandardToken.sol";
import "./Governance.sol";


contract GovernanceData is Upgradeable {

    event Proposal(
        address indexed proposalOwner, 
        uint256 indexed proposalId, 
        uint256 dateAdd, 
        string proposalTitle, 
        string proposalSD, 
        string proposalDescHash
    );

    event Solution(
        uint256 indexed proposalId, 
        address indexed solutionOwner, 
        uint256 indexed solutionId, 
        string solutionDescHash, 
        uint256 dateAdd
    );

    event Reputation(
        address indexed from, 
        uint256 indexed proposalId, 
        string description, 
        uint256 reputationPoints,
        bytes4 typeOf
    );

    event Vote(
        address indexed from, 
        uint256 indexed proposalId, 
        uint256 dateAdd, 
        uint256 voteId
    );

    event Reward(address indexed to, uint256 indexed proposalId, string description, uint256 amount);
    
    event Penalty(address indexed to, uint256 indexed proposalId, string description, uint256 amount);

    event ProposalStatus(uint256 indexed proposalId, uint256 proposalStatus, uint256 dateAdd);
    
    event ProposalVersion(
        uint256 indexed proposalId, 
        uint256 indexed versionNumber, 
        string proposalDescHash, 
        uint256 dateAdd
    );
        
    event ProposalWithSolution(
        address indexed proposalOwner, 
        uint256 indexed proposalId, 
        string proposalDescHash, 
        string solutionDescHash, 
        uint256 dateAdd
    );

    /// @dev Calls proposal with solution event 
    /// @param proposalOwner Address of member whosoever has created the proposal
    /// @param proposalId ID or proposal created
    /// @param proposalDescHash Description hash of proposal having short and long description for proposal
    /// @param solutionDescHash Description hash of Solution 
    /// @param dateAdd Date when proposal was created
    function callProposalWithSolutionEvent(
        address proposalOwner, 
        uint256 proposalId, 
        string proposalDescHash, 
        string solutionDescHash, 
        uint256 dateAdd
    )
        public
        onlyInternal 
    {
        emit ProposalWithSolution(proposalOwner, proposalId, proposalDescHash, solutionDescHash, dateAdd);
    }

    /// @dev Calls proposal version event
    /// @param proposalId Id of proposal
    /// @param vNumber Version number
    /// @param proposalHash Proposal description hash on IPFS
    /// @param dateAdd Date when proposal version was added
    function callProposalVersionEvent(uint256 proposalId, uint256 vNumber, string proposalHash, uint256 dateAdd) 
        public
        onlyInternal 
    {
        emit ProposalVersion(proposalId, vNumber, proposalHash, dateAdd);
    }

    /// @dev Calls solution event
    /// @param proposalId Proposal id
    /// @param solutionOwner Member Address who has provided a solution
    /// @param solutionDescHash Solution description hash
    /// @param dateAdd Date the solution was added
    function callSolutionEvent(
        uint256 proposalId, 
        address solutionOwner, 
        uint solutionId, 
        string solutionDescHash, 
        uint256 dateAdd
    ) 
        public
        onlyInternal 
    {
        emit Solution(proposalId, solutionOwner, solutionId, solutionDescHash, dateAdd);
    }

    /// @dev Calls proposal event
    /// @param _proposalOwner Proposal owner
    /// @param _proposalId Proposal id
    /// @param _dateAdd Date when proposal was added
    /// @param _proposalDescHash Proposal description hash
    function callProposalEvent(
        address _proposalOwner, 
        uint _proposalId, 
        uint _dateAdd, 
        string _proposalTitle, 
        string _proposalSD, 
        string _proposalDescHash
    ) 
        public
        onlyInternal 
    {
        emit Proposal(_proposalOwner, _proposalId, _dateAdd, _proposalTitle, _proposalSD, _proposalDescHash);
    }

    /// @dev Calls event to update the reputation of the member
    /// @param _from Whose reputation is getting updated
    /// @param _proposalId Proposal id
    /// @param _description Description
    /// @param _reputationPoints Reputation points
    /// @param _typeOf Type of credit/debit of reputation
    function callReputationEvent(
        address _from, 
        uint256 _proposalId, 
        string _description, 
        uint _reputationPoints, 
        bytes4 _typeOf
    )
        public
        onlyInternal 
    {
        emit Reputation(_from, _proposalId, _description, _reputationPoints, _typeOf);
    }

    /// @dev Calls vote event
    /// @param _from Address of the member who has casted a vote
    /// @param _voteId Id of vote
    /// @param _proposalId Id of proposal
    /// @param _dateAdd Date when the vote was casted
    function callVoteEvent(address _from, uint _proposalId, uint _dateAdd, uint256 _voteId) 
        public
        onlyInternal 
    {
        emit Vote(_from, _proposalId, _dateAdd, _voteId);
    }

    /// @dev Calls reward event
    /// @param _to Address of the receiver of the reward
    /// @param _proposalId Proposal id
    /// @param _description Description of the event
    /// @param _amount Reward amount
    function callRewardEvent(address _to, uint256 _proposalId, string _description, uint256 _amount) 
        public 
        onlyInternal 
    {
        emit Reward(_to, _proposalId, _description, _amount);
    }

    /// @dev Calls penalty event
    /// @param _to Address to whom penalty is charged
    /// @param _proposalId Proposal id
    /// @param _description Tells the cause of penalty against Proposal, Solution or Vote.
    /// @param _amount Penalty amount
    function callPenaltyEvent(address _to, uint256 _proposalId, string _description, uint256 _amount) 
        public 
        onlyInternal 
    {
        emit Penalty(_to, _proposalId, _description, _amount);
    }

    /// @dev Calls proposal status event
    /// @param _proposalId Proposal id
    /// @param _proposalStatus Proposal status
    /// @param _dateAdd Date when proposal was added
    function callProposalStatusEvent(uint256 _proposalId, uint _proposalStatus, uint _dateAdd) 
        public 
        onlyInternal 
    {
        emit ProposalStatus(_proposalId, _proposalStatus, _dateAdd);
    }

    using SafeMath for uint;

    struct ProposalStruct {
        address owner;
        uint dateUpd;
        address votingTypeAddress;
    }

    struct ProposalData {
        uint8 propStatus;
        uint64 finalVerdict;
        uint64 currentVerdict;
        uint currVotingStatus;
        uint category;
        uint versionNumber;
        uint totalVoteValue;
        uint totalreward;
        uint commonIncentive;
        address stakeToken;
    }

    struct VotingTypeDetails {
        bytes32 votingTypeName;
        address votingTypeAddress;
    }

    struct ProposalVote {
        address voter;
        uint64[] solutionChosen;
        uint208 voteValue;
        uint32 proposalId;
    }

    struct LastReward {
        uint lastRewardProposalId;
        uint lastRewardSolutionProposalId;
        uint lastRewardVoteId;
    }

    struct Deposit {
        uint amount;
        uint returned;
    }

    struct SolutionStruct {
        address owner;
        bytes action;
    }

    mapping(uint => ProposalData) internal allProposalData;
    mapping(uint => SolutionStruct[]) internal allProposalSolutions;
    mapping(address => uint) internal allMemberReputationByAddress;
    mapping(address => mapping(uint => uint)) internal addressProposalVote;
    mapping(uint => mapping(uint => uint[])) internal proposalRoleVote;
    //mapping(address => uint[]) internal allProposalByMember;
    mapping(address => uint[]) internal allVotesByMember;
    mapping(address => LastReward) internal lastRewardDetails;

    uint public quorumPercentage;
    uint public pendingProposalStart;
    bool public constructorCheck;
    bool public punishVoters;
    uint public depositPercProposal;
    uint public depositPercSolution;
    uint public depositPercVote;
    uint public stakeWeight;
    uint public bonusStake;
    uint public reputationWeight;
    uint public bonusReputation;
    uint public addProposalOwnerPoints;
    uint public addSolutionOwnerPoints;
    uint public addMemberPoints;
    uint public subProposalOwnerPoints;
    uint public subSolutionOwnerPoints;
    uint public subMemberPoints;

    ProposalStruct[] internal allProposal;
    ProposalVote[] internal allVotes;
    VotingTypeDetails[] internal allVotingTypeDetails;

    GBTStandardToken internal gbt;
    Governance internal gov;
    
    /// @dev updates all dependency addresses to latest ones from Master
    function updateDependencyAddresses() public {
        if (!constructorCheck)
            governanceDataInitiate();
        gov = Governance(master.getLatestAddress("GV"));
        gbt = GBTStandardToken(master.getLatestAddress("GS"));
        editVotingTypeDetails(0, master.getLatestAddress("SV"));
    }

    /// @dev Initiates governance data
    function governanceDataInitiate() public {
        require(!constructorCheck);
        setGlobalParameters();
        addMemberReputationPoints();
        setVotingTypeDetails("Simple Voting", address(0));
        //setVotingTypeDetails("Rank Based Voting", null_address);
        //setVotingTypeDetails("Feature Weighted Voting", null_address);
        allVotes.push(ProposalVote(address(0), new uint64[](0), 0, 0));
        constructorCheck = true;
    }

    /// @dev Changes points to add or subtract in member reputation when proposal/Solution/vote gets denied or accepted
    /// @param _addProposalOwnerPoints Points that needs to be added in Proposal owner reputation 
    ///     after proposal acceptance
    /// @param _addSolutionOwnerPoints Points that needs to be added in Solution Owner reputation 
    ///     for providing correct solution against proposal
    /// @param _addMemberPoints Points that needs to be added in Other members reputation 
    ///     for casting vote in favour of correct solution
    /// @param _subProposalOwnerPoints Points that needs to be subtracted 
    ///     from Proposal owner reputation in case proposal gets rejected
    /// @param _subSolutionOwnerPoints  Points that needs to be subtracted 
    ///     from Solution Owner reputation for providing wrong solution against proposal
    /// @param _subMemberPoints Points that needs to be subtracted 
    ///     from Other members reputation for casting vote against correct solution
    function changeMemberReputationPoints(
        uint _addProposalOwnerPoints, 
        uint _addSolutionOwnerPoints, 
        uint _addMemberPoints, 
        uint _subProposalOwnerPoints, 
        uint _subSolutionOwnerPoints, 
        uint _subMemberPoints
    ) 
        public 
        onlyInternal 
    {
        addProposalOwnerPoints = _addProposalOwnerPoints;
        addSolutionOwnerPoints = _addSolutionOwnerPoints;
        addMemberPoints = _addMemberPoints;
        subProposalOwnerPoints = _subProposalOwnerPoints;
        subSolutionOwnerPoints = _subSolutionOwnerPoints;
        subMemberPoints = _subMemberPoints;
    }

    /// @dev Sets the Last proposal id till which the reward has been distributed
    ///     for Proposal Owner (Proposal creation and acceptance Reward)
    function setLastRewardIdOfCreatedProposals(address _memberAddress, uint _proposalId) public onlyInternal {
        lastRewardDetails[_memberAddress].lastRewardProposalId = _proposalId;
    }

    /// @dev Sets the last proposal id till which the reward has been distributed for Solution Owner 
    ///     (For providing correct solution Reward)
    function setLastRewardIdOfSolutionProposals(address _memberAddress, uint _proposalId) public onlyInternal {
        lastRewardDetails[_memberAddress].lastRewardSolutionProposalId = _proposalId;
    }

    /// @dev Sets the last Vote id till which the reward has been distributed for Vote owners 
    ///     (For voting in favour of correct solution Reward)
    function setLastRewardIdOfVotes(address _memberAddress, uint _voteId) public onlyInternal {
        lastRewardDetails[_memberAddress].lastRewardVoteId = _voteId;
    }

    /// @dev Gets last Proposal id till the reward has been distributed (Proposal creation and acceptance)
    function getLastRewardIdOfCreatedProposals(address _memberAddress) public view returns(uint) {
        return lastRewardDetails[_memberAddress].lastRewardProposalId;
    }

    /// @dev Gets the last proposal id till the reward has been distributed for being Solution Owner
    function getLastRewardIdOfSolutionProposals(address _memberAddress) public view returns(uint) {
        return lastRewardDetails[_memberAddress].lastRewardSolutionProposalId;
    }

    /// @dev Gets the last vote id till which the reward has been distributed against member
    function getLastRewardIdOfVotes(address _memberAddress) public view returns(uint) {
        return lastRewardDetails[_memberAddress].lastRewardVoteId;
    }

    /// @dev Get all Last Id's till which the reward has been distributed against member
    function getAllidsOfLastReward(address _memberAddress) 
        public 
        view 
        returns(
            uint lastRewardIdOfCreatedProposal, 
            uint lastRewardidOfSolution, 
            uint lastRewardIdOfVote
        ) 
    {
        return (
            lastRewardDetails[_memberAddress].lastRewardProposalId, 
            lastRewardDetails[_memberAddress].lastRewardSolutionProposalId, 
            lastRewardDetails[_memberAddress].lastRewardVoteId
        );
    }

    /// @dev Add vote details such as Solution id to which he has voted and vote value
    function addVote(
        address _memberAddress, 
        uint64[] _solutionChosen, 
        uint _voteValue, 
        uint32 _proposalId, 
        uint _roleId
    ) 
        external 
        onlyInternal
    {
        proposalRoleVote[_proposalId][_roleId].push(allVotes.length);
        allVotesByMember[_memberAddress].push(allVotes.length);
        addressProposalVote[_memberAddress][_proposalId] = allVotes.length;
        emit Vote(_memberAddress, _proposalId, now, allVotes.length);
        allVotes.push(ProposalVote(_memberAddress, _solutionChosen, uint208(_voteValue), _proposalId));
    }

    function getAllVoteIdsByAddress(address _memberAddress) public view returns(uint[]) {
        return allVotesByMember[_memberAddress];
    }

    function getVoteIdOfNthVoteOfMember(address _memberAddress, uint _vote) public view returns(uint) {
        return allVotesByMember[_memberAddress][_vote];
    }

    function getTotalNumberOfVotesByAddress(address _memberAddress) public view returns(uint) {
        return allVotesByMember[_memberAddress].length;
    }

    // function setVoteValue(uint _voteId, uint _voteValue) onlyInternal {
    //     allVotes[_voteId].voteValue = _voteValue;
    // }
    /// @dev Gets vote details by id such as Vote value, Address of the voter and Solution id for which he has voted.
    function getVoteDetailById(uint _voteid) 
        public 
        view 
        returns(
            address voter, 
            uint64[] solutionChosen, 
            uint208 voteValue,
            uint32 proposalId
        ) 
    {
        return (
            allVotes[_voteid].voter, 
            allVotes[_voteid].solutionChosen, 
            allVotes[_voteid].voteValue, 
            allVotes[_voteid].proposalId
        );
    }

    /// @dev Gets Vote id Against proposal when passing proposal id and member addresse
    function getVoteIdAgainstMember(address _memberAddress, uint _proposalId) 
        public 
        view 
        returns(uint voteId) 
    {
        voteId = addressProposalVote[_memberAddress][_proposalId];
    }

    /// @dev Check if the member has voted against a proposal. Returns true if vote id exists
    function checkVoteIdAgainstMember(address _memberAddress, uint _proposalId) public view returns(bool result) {
        if (addressProposalVote[_memberAddress][_proposalId] != 0)
            result = true;
    }

    /// @dev Gets voter address
    function getVoterAddress(uint _voteId) public view returns(address _voterAddress) {
        return (allVotes[_voteId].voter);
    }

    /// @dev Gets All the Role specific vote ids against proposal 
    /// @param _roleId Role id which number of votes to be fetched.
    /// @return totalVotes Total votes casted by this particular role id.
    function getAllVoteIdsByProposalRole(uint _proposalId, uint _roleId) public view returns(uint[] totalVotes) {
        return proposalRoleVote[_proposalId][_roleId];
    }

    /// @dev Gets Total number of votes of specific role against proposal
    function getAllVoteIdsLengthByProposalRole(uint _proposalId, uint _roleId) external view returns(uint length) {
        return proposalRoleVote[_proposalId][_roleId].length;
    }

    /// @dev Gets Vote id from the array that contains all role specific votes against proposal
    /// @param _index To get vote id at particular index from array
    function getVoteIdAgainstProposalRole(uint _proposalId, uint _roleId, uint _index) public view returns(uint) {
        return (proposalRoleVote[_proposalId][_roleId][_index]);
    }

    /// @dev Gets vote value against Vote id
    function getVoteValue(uint _voteId) public view returns(uint) {
        return (allVotes[_voteId].voteValue);
    }

    /// @dev Gets total number of votes 
    function allVotesTotal() public view returns(uint) {
        return allVotes.length;
    }

    /// @dev Gets Total number of voting types has been added till now.
    function getVotingTypeLength() public view returns(uint) {
        return allVotingTypeDetails.length;
    }

    /// @dev Gets voting type details by passing voting id
    function getVotingTypeDetailsById(uint _votingTypeId) 
        public 
        view 
        returns(uint votingTypeId, bytes32 vtName, address vtAddress) 
    {
        return (
            _votingTypeId, 
            allVotingTypeDetails[_votingTypeId].votingTypeName, 
            allVotingTypeDetails[_votingTypeId].votingTypeAddress
        );
    }

    /// @dev Gets Voting type address when voting type id is passes by
    function getVotingTypeAddress(uint _votingTypeId) public view returns(address votingAddress) {
        return (allVotingTypeDetails[_votingTypeId].votingTypeAddress);
    }

    /// @dev Sets the address of member as solution owner whosoever provided the solution
    function setSolutionAdded(uint _proposalId, address _memberAddress, bytes _action) public onlyInternal {
        allProposalSolutions[_proposalId].push(SolutionStruct(_memberAddress, _action));
    }

    /// @dev Returns the solution index that was being voted
    function getSolutionByVoteId(uint _voteId) public view returns(uint64[] solutionChosen) {
        return (allVotes[_voteId].solutionChosen);
    }

    /// @dev Gets Solution id against which vote had been casted
    /// @param _solutionChosenId To get solution id at particular index 
    ///     from solutionChosen array i.e. 0 is passed In case of Simple Voting Type.
    function getSolutionByVoteIdAndIndex(uint _voteId, uint _solutionChosenId) 
        public 
        view 
        returns(uint solution) 
    {
        return (allVotes[_voteId].solutionChosen[_solutionChosenId]);
    }

    /// @dev Gets The Address of Solution owner By solution sequence index 
    ///     As a proposal might have n number of solutions.
    function getSolutionAddedByProposalId(uint _proposalId, uint _index) 
        public 
        view 
        returns(address memberAddress) 
    {
        return allProposalSolutions[_proposalId][_index].owner;
    }

    /// @dev Gets The Solution Action By solution sequence index As a proposal might have n number of solutions.
    function getSolutionActionByProposalId(uint _proposalId, uint _index) public view returns(bytes action) {
        return allProposalSolutions[_proposalId][_index].action;
    }

    /// @dev Changes stakeWeight that helps in calculation of reward distribution
    function changeStakeWeight(uint _stakeWeight) public onlyInternal {
        stakeWeight = _stakeWeight;
    }

    /// @dev Changes bonusStake that helps in calculation of reward distribution
    function changeBonusStake(uint _bonusStake) public onlyInternal {
        bonusStake = _bonusStake;
    }

    /// @dev Changes reputationWeight that helps in calculation of reward distribution
    function changeReputationWeight(uint _reputationWeight) public onlyInternal {
        reputationWeight = _reputationWeight;
    }

    /// @dev Changes bonusReputation that helps in calculation of reward distribution
    function changeBonusReputation(uint _bonusReputation) public onlyInternal {
        bonusReputation = _bonusReputation;
    }

    /// @dev Changes quoram percentage. Value required to pass proposal.
    function changeQuorumPercentage(uint _quorumPercentage) public onlyInternal {
        quorumPercentage = _quorumPercentage;
    }

    function setPunishVoters(bool _punish) public onlyInternal {
        punishVoters = _punish;
    }

    /// @dev Changes Proposal owner reputation points that needs to be added at proposal acceptance
    function changeProposalOwnerAdd(uint _repPoints) public onlyInternal {
        addProposalOwnerPoints = _repPoints;
    }

    /// @dev Changes Solution owner reputation points that needs to be added if solution has won. 
    ///     (Upvoted with many votes)
    function changeSolutionOwnerAdd(uint _repPoints) public onlyInternal {
        addSolutionOwnerPoints = _repPoints;
    }

    /// @dev Change proposal owner reputation points that needs to be subtracted if proposal gets rejected. 
    function changeProposalOwnerSub(uint _repPoints) public onlyInternal {
        subProposalOwnerPoints = _repPoints;
    }

    /// @dev Changes solution owner reputation points that needs to be subtracted 
    ///     if solution is downvoted with many votes   
    function changeSolutionOwnerSub(uint _repPoints) public onlyInternal {
        subSolutionOwnerPoints = _repPoints;
    }

    /// @dev Change member points that needs to be added when voting in favour of final solution
    function changeMemberAdd(uint _repPoints) public onlyInternal {
        addMemberPoints = _repPoints;
    }

    /// @dev Change member points that needs to be subtracted when voted against final solution
    function changeMemberSub(uint _repPoints) public onlyInternal {
        subMemberPoints = _repPoints;
    }

    /// @dev Sets proposal category
    function setProposalCategory(uint _proposalId, uint _categoryId, address _stakeToken) public onlyInternal {
        allProposalData[_proposalId].category = _categoryId;
        allProposalData[_proposalId].stakeToken = _stakeToken;
    }

    /// @dev Sets proposal incentive/reward that needs to be distributed at the end of proposal closing
    function setProposalIncentive(uint _proposalId, uint _reward) public onlyInternal {
        allProposalData[_proposalId].commonIncentive = _reward;
    }

    /// @dev Changes the status of a given proposal.
    function changeProposalStatus(uint _id, uint8 _status) public onlyInternal {
        require(allProposalData[_id].category != 0);
        emit ProposalStatus(_id, _status, now);
        updateProposalStatus(_id, _status);
    }

    /// @dev Sets proposal current voting id i.e. Which Role id is next in row to vote against proposal
    /// @param _currVotingStatus It is the index to fetch the role id from voting sequence array. 
    function setProposalCurrentVotingId(uint _proposalId, uint _currVotingStatus) public onlyInternal {
        allProposalData[_proposalId].currVotingStatus = _currVotingStatus;
    }

    /// @dev Updates proposal's intermediateVerdict after every voting layer is passed.
    function setProposalIntermediateVerdict(uint _proposalId, uint64 _intermediateVerdict) public onlyInternal {
        allProposalData[_proposalId].currentVerdict = _intermediateVerdict;
    }

    /// @dev Sets proposal's final verdict once the final voting layer is crossed 
    ///     and voting is final closed for proposal
    function setProposalFinalVerdict(uint _proposalId, uint64 _finalVerdict) public onlyInternal {
        allProposalData[_proposalId].finalVerdict = _finalVerdict;
    }

    /// @dev Update member reputation once the proposal reward is distributed.
    /// @param _description Cause of points being credited/debited from reputation
    /// @param _proposalId Id of proposal
    /// @param _memberAddress Address of member whose reputation is being updated
    /// @param _repPoints Updated reputation of member
    /// @param _repPointsEventLog Actual points being added/subtracted from member's reputation
    /// @param _typeOf typeOf is "C" in case the points is credited, "D" otherwise!
    function setMemberReputation(
        string _description, 
        uint _proposalId, 
        address _memberAddress, 
        uint _repPoints, 
        uint _repPointsEventLog,
        bytes4 _typeOf
    ) 
        public 
        onlyInternal 
    {
        allMemberReputationByAddress[_memberAddress] = _repPoints;
        emit Reputation(_memberAddress, _proposalId, _description, _repPointsEventLog, _typeOf);
    }

    /// @dev Stores the information of version number of a given proposal. 
    ///     Maintains the record of all the versions of a proposal.
    function storeProposalVersion(uint _proposalId, string _proposalDescHash) public onlyInternal {
        uint versionNo = allProposalData[_proposalId].versionNumber + 1;
        emit ProposalVersion(_proposalId, versionNo, _proposalDescHash, now);
        setProposalVersion(_proposalId, versionNo);
    }

    /// @dev Sets proposal's date when the proposal last modified
    function setProposalDateUpd(uint _proposalId) public onlyInternal {
        allProposal[_proposalId].dateUpd = now;
    }

    /// @dev Fetch details of proposal when giving proposal id
    function getProposalDetailsById1(uint _proposalId) 
        public 
        view 
        returns(uint id, address owner, uint dateUpd, uint versionNum, uint8 propStatus) 
    {
        return (
            _proposalId, 
            allProposal[_proposalId].owner, 
            allProposal[_proposalId].dateUpd, 
            allProposalData[_proposalId].versionNumber, 
            allProposalData[_proposalId].propStatus
        );
    }

    /// @dev Fetch details of proposal when giving proposal id
    function getProposalDetailsById2(uint _proposalId) 
        public 
        view 
        returns(
            uint id,
            uint category, 
            uint currentVotingId, 
            uint64 intermediateVerdict, 
            uint64 finalVerdict, 
            address votingTypeAddress, 
            uint totalSolutions
        ) 
    {
        return (
            _proposalId, 
            allProposalData[_proposalId].category, 
            allProposalData[_proposalId].currVotingStatus, 
            allProposalData[_proposalId].currentVerdict, 
            allProposalData[_proposalId].finalVerdict, 
            allProposal[_proposalId].votingTypeAddress, 
            allProposalSolutions[_proposalId].length
        );
    }

    /// @dev Fetch details of proposal when giving proposal id
    function getProposalDetailsById3(uint _proposalId) 
        public 
        view 
        returns(uint proposalIndex, uint propStatus, uint propCategory, uint8 propStatusId, uint64 finalVerdict) 
    {
        return (
            _proposalId, 
            getProposalStatus(_proposalId), 
            allProposalData[_proposalId].category, 
            allProposalData[_proposalId].propStatus, 
            allProposalData[_proposalId].finalVerdict
        );
    }

    /// @dev fetches details for simplevoting and also verifies that the voter has not casted a vote already
    function getProposalDetailsForSV(address _voter, uint _proposalId) 
        external
        view
        returns(uint, uint, uint64) 
    {
        require(addressProposalVote[_voter][_proposalId] == 0);
        require(allProposalData[_proposalId].propStatus == 2);
        return(
            allProposalData[_proposalId].category,
            allProposalData[_proposalId].currVotingStatus,
            allProposalData[_proposalId].currentVerdict
        );
    }

    /// @dev Fetch details of proposal when giving proposal id
    function getProposalDetailsById4(uint _proposalId) 
        public 
        view 
        returns(uint totalTokenToDistribute, uint totalVoteValue) 
    {
        return (allProposalData[_proposalId].totalreward, allProposalData[_proposalId].totalVoteValue);
    }

    /// @dev Gets proposal details of given proposal id
    /// @param totalVoteValue Total value of votes that has been casted so far against proposal
    /// @param totalSolutions Total number of solutions proposed till now against proposal
    /// @param commonIncentive Incentive that needs to be distributed once the proposal is closed.
    /// @param finalVerdict Final solution index that has won by maximum votes.
    function getProposalDetailsById6(uint _proposalId) 
        public 
        view 
        returns(
            uint proposalId,
            uint status, 
            uint totalVoteValue, 
            uint totalSolutions, 
            uint commonIncentive, 
            uint finalVerdict
        ) 
    {
        proposalId = _proposalId;
        status = getProposalStatus(_proposalId);
        totalVoteValue = getProposalTotalVoteValue(_proposalId);
        totalSolutions = getTotalSolutions(_proposalId);
        commonIncentive = getProposalIncentive(_proposalId);
        finalVerdict = allProposalData[_proposalId].finalVerdict;
    }

    /// @dev Gets length of all created proposals by member
    /// @param _memberAddress Member address
    /// @return totalProposalCount Total proposal count
    function getAllProposalIdsLengthByAddress(address _memberAddress) 
        public 
        view 
        returns(uint totalProposalCount) 
    {
        uint length = getProposalLength();
        for (uint i = 0; i < length; i++) {
            if (_memberAddress == getProposalOwner(i))
                totalProposalCount++;
        }
    }

    /// @dev Gets date when proposal is last updated
    function getProposalDateUpd(uint _proposalId) public view returns(uint) {
        return allProposal[_proposalId].dateUpd;
    }

    /// @dev Gets member address who created the proposal i.e. proposal owner
    function getProposalOwner(uint _proposalId) public view returns(address) {
        return allProposal[_proposalId].owner;
    }

    /// @dev Gets proposal incentive that will get distributed once the proposal is closed
    function getProposalIncentive(uint _proposalId) public view returns(uint commonIncentive) {
        return allProposalData[_proposalId].commonIncentive;
    }

    /// @dev Gets the total incentive amount given by dApp to different proposals
    function getTotalProposalIncentive() public view returns(uint allIncentive) {
        for (uint i = 0; i < allProposal.length; i++) {
            allIncentive = allIncentive + allProposalData[i].commonIncentive;
        }
    }

    /// @dev Gets proposal current voting status i.e. Who is next in voting sequence
    function getProposalCurrentVotingId(uint _proposalId) public view returns(uint _currVotingStatus) {
        return (allProposalData[_proposalId].currVotingStatus);
    }

    /// @dev Get Total Amount that has been collected at the end of voting to distribute further 
    ///     i.e. Total token to distribute
    function getProposalTotalReward(uint _proposalId) public view returns(uint) {
        return allProposalData[_proposalId].totalreward;
    }

    /// @dev Get Total number of Solutions being proposed against proposal.
    function getTotalSolutions(uint _proposalId) public view returns(uint) {
        return allProposalSolutions[_proposalId].length;
    }

    /// @dev Get Current Status of proposal when given proposal Id
    function getProposalStatus(uint _proposalId) public view returns(uint propStatus) {
        return allProposalData[_proposalId].propStatus;
    }

    /// @dev Gets proposal voting type when given proposal id
    function getProposalVotingType(uint _proposalId) public view returns(address) {
        return (allProposal[_proposalId].votingTypeAddress);
    }

    /// @dev Gets proposal category when given proposal id
    function getProposalCategory(uint _proposalId) public view returns(uint categoryId) {
        return allProposalData[_proposalId].category;
    }

    /// @dev Get member's reputation points and it's likely to be updated with time.
    function getMemberReputation(address _memberAddress) public view returns(uint memberPoints) {
        if (allMemberReputationByAddress[_memberAddress] == 0)
            memberPoints = 1;
        else
            memberPoints = allMemberReputationByAddress[_memberAddress];
    }

    /// @dev Get member's reputation points and scalind data for sv.
    function getMemberReputationSV(address _memberAddress, uint32 _proposalId) 
        public 
        view 
        returns (uint, uint, uint, uint, uint, address, uint) {
        return(
            stakeWeight, 
            bonusStake, 
            reputationWeight, 
            bonusReputation, 
            allMemberReputationByAddress[_memberAddress],
            allProposalData[_proposalId].stakeToken, 
            allProposalData[_proposalId].category
        );
    }

    /// @dev Gets Total vote value from all the votes that has been casted against of winning solution
    function getProposalTotalVoteValue(uint _proposalId) public view returns(uint voteValue) {
        voteValue = allProposalData[_proposalId].totalVoteValue;
    }

    /// @dev Gets stakeToken proposal
    function getStakeToken(uint _proposalId) public view returns(address) {
        return allProposalData[_proposalId].stakeToken;
    }

    /// @dev Gets stakeToken and sub cat proposal
    function getTokenAndSubCat(uint _proposalId) public view returns(address, uint) {
        return (allProposalData[_proposalId].stakeToken, allProposalData[_proposalId].category);
    }

    /// @dev Gets Total number of proposal created till now in dApp
    function getProposalLength() public view returns(uint) {
        return (allProposal.length);
    }

    /// @dev Get Latest updated version of proposal.
    function getProposalVersion(uint _proposalId) public view returns(uint) {
        return allProposalData[_proposalId].versionNumber;
    }

    /// @dev Sets Total calculated vote value from all the votes that has been casted against of winning solution
    function setProposalTotalVoteValue(uint _proposalId, uint _voteValue) public onlyInternal {
        allProposalData[_proposalId].totalVoteValue = _voteValue;
    }

    /// @dev Get Total Amount that has been collected at the end of voting to distribute further 
    ///     i.e. Total token to distribute
    function setProposalTotalReward(uint _proposalId, uint _totalreward) public onlyInternal {
        allProposalData[_proposalId].totalreward = _totalreward;
    }

    /// @dev Changes status from pending proposal to start proposal
    function changePendingProposalStart(uint _value) public onlyInternal {
        pendingProposalStart = _value;
    }

    /// @dev Adds new proposal
    function addNewProposal(
        uint _proposalId, 
        address _memberAddress, 
        uint _categoryId, 
        address _votingTypeAddress,
        address _stakeToken
    ) 
        public 
        onlyInternal 
    {
        allProposal.push(ProposalStruct(_memberAddress, now, _votingTypeAddress));
        allProposalData[_proposalId].category = _categoryId;
        allProposalData[_proposalId].stakeToken = _stakeToken;
    }

    /// @dev Creates new proposal
    function createProposal1(address _memberAddress, address _votingTypeAddress) 
        public 
        onlyInternal 
    {
        allProposal.push(ProposalStruct(_memberAddress, now, _votingTypeAddress));
    }

    /// @dev Gets final solution index won after majority voting.
    function getProposalFinalVerdict(uint _proposalId) public view returns(uint finalSolutionIndex) {
        finalSolutionIndex = allProposalData[_proposalId].finalVerdict;
    }

    /// @dev Gets Intermidiate solution is while voting is still in progress by other voting layers
    function getProposalIntermediateVerdict(uint _proposalId) public view returns(uint64) {
        return allProposalData[_proposalId].currentVerdict;
    }

    /// @dev Gets statuses of proposals
    /// @param _proposalLength Total proposals created till now.
    /// @param _draftProposals Proposal that are currently in draft or still getting updated.
    /// @param _pendingProposals Those proposals still open for voting
    /// @param _acceptedProposals Proposal those are submitted or accepted by majority voting
    /// @param _rejectedProposals Proposal those are rejected by majority voting.
    function getStatusOfProposals() 
        public 
        view 
        returns(
            uint _proposalLength, 
            uint _draftProposals, 
            uint _pendingProposals, 
            uint _acceptedProposals, 
            uint _rejectedProposals
        ) 
    {
        uint proposalStatus;
        _proposalLength = getProposalLength();

        for (uint i = 0; i < _proposalLength; i++) {
            proposalStatus = getProposalStatus(i);
            if (proposalStatus < 2) {
                _draftProposals++;
            } else if (proposalStatus == 2) {
                _pendingProposals++;
            } else if (proposalStatus == 3) {
                _acceptedProposals++;
            } else if (proposalStatus >= 4) {
                _rejectedProposals++;
            }
        }
    }

    /// @dev Gets statuses of all the proposal that are created by specific member
    /// @param _proposalsIds All proposal Ids array is passed
    /// @return proposalLength Total number of proposals
    /// @return draftProposals Proposals in draft or still getting updated
    /// @return pendingProposals Proposals still open for voting are pending ones
    /// @return acceptedProposals If a decision has been made then the proposal is in accep state
    /// @return rejectedProposals All the proposals rejected by majority voting
    function getStatusOfProposalsForMember(uint[] _proposalsIds) 
        public 
        view 
        returns(
            uint proposalLength, 
            uint draftProposals, 
            uint pendingProposals, 
            uint acceptedProposals, 
            uint rejectedProposals
        ) 
    {
        uint proposalStatus;
        proposalLength = getProposalLength();

        for (uint i = 0; i < _proposalsIds.length; i++) {
            proposalStatus = getProposalStatus(_proposalsIds[i]);
            if (proposalStatus < 2) {
                draftProposals++;
            } else if (proposalStatus == 2) {
                pendingProposals++;
            } else if (proposalStatus == 3) {
                acceptedProposals++;
            } else if (proposalStatus >= 4) {
                rejectedProposals++;
            }
        }
    }

    /// @dev Gets Total number of solutions provided by a specific member
    function getAllSolutionIdsLengthByAddress(address _memberAddress) 
        public 
        view 
        returns(uint totalSolutionProposalCount) 
    {
        for (uint i = 0; i < allProposal.length; i++) {
            for (uint j = 0; j < getTotalSolutions(i); j++) {
                if (_memberAddress == getSolutionAddedByProposalId(i, j))
                    totalSolutionProposalCount++;
            }
        }
    }

    /// @dev Gets All the solution ids provided by a member so far
    /// @param _memberAddress Address of member whose address we need to fetch
    /// @return proposalIds All the proposal ids array to which the solution being provided
    /// @return solutionIds This array containg all solution ids as all proposals might have many solutions.
    /// @return totalSolution Count of total solutions provided by member till now
    function getAllSolutionIdsByAddress(address _memberAddress) 
        public 
        view 
        returns(uint[] proposalIds, uint[] solutionProposalIds, uint totalSolution) 
    {
        uint solutionProposalLength = getAllSolutionIdsLengthByAddress(_memberAddress);
        proposalIds = new uint[](solutionProposalLength);
        solutionProposalIds = new uint[](solutionProposalLength);
        for (uint i = 0; i < allProposal.length; i++) {
            for (uint j = 0; j < allProposalSolutions[i].length; j++) {
                if (_memberAddress == getSolutionAddedByProposalId(i, j)) {
                    proposalIds[totalSolution] = i;
                    solutionProposalIds[totalSolution] = j;
                    totalSolution++;
                }
            }
        }
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

    /// @dev Sets global parameters that will help in distributing reward
    function setGlobalParameters() internal {
        quorumPercentage = 25;
        stakeWeight = 1;
        bonusStake = 2;
        reputationWeight = 1;
        bonusReputation = 2;
        depositPercProposal = 30;
        depositPercSolution = 30;
        depositPercVote = 40;
    }

    /// @dev Sets Voting type details such as Voting type name and address
    function setVotingTypeDetails(bytes32 _votingTypeName, address _votingTypeAddress) internal {
        allVotingTypeDetails.push(VotingTypeDetails(_votingTypeName, _votingTypeAddress));
    }

    /// @dev Edits Voting type address when given voting type name
    function editVotingTypeDetails(uint _votingTypeId, address _votingTypeAddress) internal {
        allVotingTypeDetails[_votingTypeId].votingTypeAddress = _votingTypeAddress;
    }

    /// @dev Updates status of an existing proposal
    function updateProposalStatus(uint _id, uint8 _status) internal {
        allProposalData[_id].propStatus = _status;
        allProposal[_id].dateUpd = now;
    }

    /// @dev Sets version number of proposal i.e. Version number increases everytime the proposal is modified
    function setProposalVersion(uint _proposalId, uint _versionNum) internal {
        allProposalData[_proposalId].versionNumber = _versionNum;
    }

}
