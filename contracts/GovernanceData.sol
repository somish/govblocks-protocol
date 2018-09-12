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
import "./imports/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Master.sol";
import "./Upgradeable.sol";
import "./GBTStandardToken.sol";
import "./Governance.sol";
import "./VotingType.sol";
import "./Governed.sol";


contract GovernanceData is Upgradeable, Governed { //solhint-disable-line

    constructor (bool _dAppTokenSupportsLocking) public {
        dAppTokenSupportsLocking = _dAppTokenSupportsLocking;
    }

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

    event RewardClaimed(
        address indexed member, 
        uint[] ownerProposals, 
        uint[] voterProposals,
        uint gbtReward, 
        uint dAppReward, 
        uint reputation
    );

    function callRewardClaimed(
        address _member, 
        uint[] _ownerProposals, 
        uint[] _voterProposals,
        uint _gbtReward, 
        uint _dAppReward, 
        uint _reputation
    ) 
        public
        onlyInternal 
    {
        emit RewardClaimed(
            _member, 
            _ownerProposals, 
            _voterProposals, 
            _gbtReward, 
            _dAppReward, 
            _reputation
        );
    }

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
        uint subCategory;
        uint versionNumber;
        uint totalVoteValue;
        uint commonIncentive;
        address stakeToken;
    }

    struct VotingTypeDetails {
        bytes32 votingTypeName;
        address votingTypeAddress;
    }

    struct SolutionStruct {
        address owner;
        bytes action;
    }

    mapping(uint => ProposalData) internal allProposalData;
    mapping(uint => SolutionStruct[]) internal allProposalSolutions;
    mapping(address => uint) internal allMemberReputationByAddress;
    mapping(uint => bool) public proposalPaused;
    mapping(address => mapping(uint => bool)) internal rewardClaimed;

    uint public quorumPercentage;
    bool public constructorCheck;
    bool public punishVoters;
    bool public dAppTokenSupportsLocking;
    uint public stakeWeight;
    uint public bonusStake;
    uint public reputationWeight;
    uint public bonusReputation;
    uint public addProposalOwnerPoints;
    uint public addSolutionOwnerPoints;

    ProposalStruct[] internal allProposal;
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
        allProposal.push(ProposalStruct(address(0), now, master.getLatestAddress("SV"))); //solhint-disable-line
        dappName = master.dAppName();
        constructorCheck = true;
    }

    /// @dev Changes points to add or subtract in member reputation when proposal/Solution/vote gets denied or accepted
    /// @param _addProposalOwnerPoints Points that needs to be added in Proposal owner reputation 
    ///     after proposal acceptance
    /// @param _addSolutionOwnerPoints Points that needs to be added in Solution Owner reputation 
    ///     for providing correct solution against proposal
    function changeMemberReputationPoints(
        uint _addProposalOwnerPoints, 
        uint _addSolutionOwnerPoints
    ) 
        public 
        onlyInternal 
    {
        addProposalOwnerPoints = _addProposalOwnerPoints;
        addSolutionOwnerPoints = _addSolutionOwnerPoints;
    }

    function setDAppTokenSupportsLocking(bool _value) public onlyAuthorizedToGovern {
        dAppTokenSupportsLocking = _value;
    }

    /// @dev Configures global parameters i.e. Voting or Reputation parameters
    /// @param _typeOf Passing intials of the parameter name which value needs to be updated
    /// @param _value New value that needs to be updated    
    // solhint-disable-next-line
    function configureGlobalParameters(bytes4 _typeOf, uint32 _value) public onlyAuthorizedToGovern {                    
        if (_typeOf == "APO") {
            _changeProposalOwnerAdd(_value);
        } else if (_typeOf == "AOO") {
            _changeSolutionOwnerAdd(_value);
        } else if (_typeOf == "RW") {
            _changeReputationWeight(_value);
        } else if (_typeOf == "SW") {
            _changeStakeWeight(_value);
        } else if (_typeOf == "BR") {
            _changeBonusReputation(_value);
        } else if (_typeOf == "BS") {
            _changeBonusStake(_value);
        } else if (_typeOf == "QP") {
            _changeQuorumPercentage(_value);
        }
    }

    /// @dev resume a proposal
    function resumeProposal(uint _proposalId) public onlyAuthorizedToGovern {
        require(proposalPaused[_proposalId]);
        proposalPaused[_proposalId] = false;
        allProposal[_proposalId].dateUpd = now; //solhint-disable-line
    }

    /// @dev pause a proposal
    function pauseProposal(uint _proposalId) public onlyInternal {
        proposalPaused[_proposalId] = true;
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

    function setPunishVoters(bool _punish) public onlyAuthorizedToGovern {
        punishVoters = _punish;
    }

    /// @dev Sets proposal category
    function setProposalSubCategory(uint _proposalId, uint _subCategoryId, address _stakeToken) public onlyInternal {
        allProposalData[_proposalId].subCategory = _subCategoryId;
        allProposalData[_proposalId].stakeToken = _stakeToken;
    }

    /// @dev Sets proposal incentive/reward that needs to be distributed at the end of proposal closing
    function setProposalIncentive(uint _proposalId, uint _reward) public onlyInternal {
        allProposalData[_proposalId].commonIncentive = _reward;
    }

    /// @dev Changes the status of a given proposal.
    function changeProposalStatus(uint _id, uint8 _status) public onlyInternal {
        emit ProposalStatus(_id, _status, now); //solhint-disable-line
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

    /// @dev Stores the information of version number of a given proposal. 
    ///     Maintains the record of all the versions of a proposal.
    function storeProposalVersion(uint _proposalId, string _proposalDescHash) public onlyInternal {
        uint versionNo = allProposalData[_proposalId].versionNumber + 1;
        emit ProposalVersion(_proposalId, versionNo, _proposalDescHash, now); //solhint-disable-line
        setProposalVersion(_proposalId, versionNo);
    }

    /// @dev Sets proposal's date when the proposal last modified
    function increaseMemberReputation(address _memberAddress, uint _repPoints) public onlyInternal {
        allMemberReputationByAddress[_memberAddress] = 
            allMemberReputationByAddress[_memberAddress].add(_repPoints);
    }

    /// @dev Sets proposal's date when the proposal last modified
    function setProposalDateUpd(uint _proposalId) public onlyInternal {
        allProposal[_proposalId].dateUpd = now; //solhint-disable-line
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
            uint subCategory, 
            uint currentVotingId, 
            uint64 intermediateVerdict, 
            uint64 finalVerdict, 
            address votingTypeAddress, 
            uint totalSolutions
        ) 
    {
        return (
            _proposalId, 
            allProposalData[_proposalId].subCategory, 
            allProposalData[_proposalId].currVotingStatus, 
            allProposalData[_proposalId].currentVerdict, 
            allProposalData[_proposalId].finalVerdict, 
            allProposal[_proposalId].votingTypeAddress, 
            allProposalSolutions[_proposalId].length
        );
    }

    /// @dev Fetch details of proposal when giving proposal id
    function getProposalDetailsById3(uint _proposalId, address _memberAddress) 
        public 
        view 
        returns(bool, uint, uint8, uint64) 
    {
        return (
            rewardClaimed[_memberAddress][_proposalId], 
            allProposalData[_proposalId].subCategory, 
            allProposalData[_proposalId].propStatus, 
            allProposalData[_proposalId].finalVerdict
        );
    }

    function getProposalDetailsForReward(uint _proposalId, address _memberAddress) 
        public
        view
        returns(bool, uint, uint, uint, uint, uint)
    {
        uint solutionId = allProposalSolutions[_proposalId].length;
        for (solutionId--; solutionId > 0; solutionId--) {
            if (_memberAddress == allProposalSolutions[_proposalId][solutionId].owner)
                break;
        }
        return (
            rewardClaimed[_memberAddress][_proposalId], 
            allProposalData[_proposalId].subCategory, 
            allProposalData[_proposalId].propStatus, 
            allProposalData[_proposalId].finalVerdict,
            solutionId,
            allProposalData[_proposalId].commonIncentive
        );
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
    function getProposalCurrentVotingId(uint _proposalId) public view returns(uint) {
        return (allProposalData[_proposalId].currVotingStatus);
    }

    /// @dev Get Total number of Solutions being proposed against proposal.
    function getTotalSolutions(uint _proposalId) public view returns(uint) {
        return allProposalSolutions[_proposalId].length;
    }

    /// @dev Get Current Status of proposal when given proposal Id
    function getProposalStatus(uint _proposalId) public view returns(uint) {
        return allProposalData[_proposalId].propStatus;
    }

    /// @dev Gets proposal sub category when given proposal id
    function getProposalSubCategory(uint _proposalId) public view returns(uint) {
        return allProposalData[_proposalId].subCategory;
    }

    function setRewardClaimed(uint _proposalId, address _memberAddress) public onlyInternal {
        rewardClaimed[_memberAddress][_proposalId] = true;
    }

    function getRewardClaimed(uint _proposalId, address _memberAddress) public view returns(bool) {
        return (rewardClaimed[_memberAddress][_proposalId]);
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
        returns (uint, uint, uint, uint, uint, address, uint) 
    {
        return(
            stakeWeight, 
            bonusStake, 
            reputationWeight, 
            bonusReputation, 
            allMemberReputationByAddress[_memberAddress],
            allProposalData[_proposalId].stakeToken, 
            allProposalData[_proposalId].subCategory
        );
    }

    /// @dev fetches details for simplevoting and also verifies that proposal is open for voting
    function getProposalDetailsForSV(uint _proposalId) 
        public
        view
        returns(uint, uint, uint64) 
    {
        require(allProposalData[_proposalId].propStatus == 2);
        return(
            allProposalData[_proposalId].subCategory,
            allProposalData[_proposalId].currVotingStatus,
            allProposalData[_proposalId].currentVerdict
        );
    }

    /// @dev gets total number of votes by a voter
    function getTotalNumberOfVotesByAddress(address _voter) public view returns(uint totalVotes) {
        for (uint i = 0; i < allVotingTypeDetails.length; i++) {
            VotingType vt = VotingType(allVotingTypeDetails[i].votingTypeAddress);
            totalVotes += vt.getTotalNumberOfVotesByAddress(_voter);
        }
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
        return (allProposalData[_proposalId].stakeToken, allProposalData[_proposalId].subCategory);
    }

    /// @dev Gets Total number of proposal created till now in dApp
    function getProposalLength() public view returns(uint) {
        return (allProposal.length);
    }

    function getLatestVotingAddress() public view returns(address) {
        return allVotingTypeDetails[allVotingTypeDetails.length - 1].votingTypeAddress;
    }

    function getProposalVotingAddress(uint _proposalId) public view returns(address) {
        return allProposal[_proposalId].votingTypeAddress;
    }
    
    /// @dev Get Latest updated version of proposal.
    function getProposalVersion(uint _proposalId) public view returns(uint) {
        return allProposalData[_proposalId].versionNumber;
    }

    /// @dev Sets Total calculated vote value from all the votes that has been casted against of winning solution
    function setProposalTotalVoteValue(uint _proposalId, uint _voteValue) public onlyInternal {
        allProposalData[_proposalId].totalVoteValue = _voteValue;
    }

    /// @dev Adds new proposal
    function addNewProposal( 
        address _memberAddress, 
        uint _subCategoryId, 
        address _votingTypeAddress,
        address _stakeToken
    ) 
        public 
        onlyInternal 
    {
        allProposalData[allProposal.length].subCategory = _subCategoryId;
        allProposalData[allProposal.length].stakeToken = _stakeToken;
        _createProposal(_memberAddress, _votingTypeAddress);
    }

    /// @dev Updates proposal's major details (Called from close proposal vote)
    /// @param _proposalId Proposal id
    /// @param _currVotingStatus It is the index to fetch the role id from voting sequence array. 
    ///         i.e. Tells which role id members is going to vote
    /// @param _intermediateVerdict Intermediate verdict is set after every voting layer is passed.
    /// @param _finalVerdict Final verdict is set after final layer of voting
    function updateProposalDetails(
        uint _proposalId, 
        uint _currVotingStatus, 
        uint64 _intermediateVerdict, 
        uint64 _finalVerdict
    ) 
    public
    onlyInternal 
    {
        setProposalCurrentVotingId(_proposalId, _currVotingStatus);
        setProposalIntermediateVerdict(_proposalId, _intermediateVerdict);
        setProposalFinalVerdict(_proposalId, _finalVerdict);
        setProposalDateUpd(_proposalId);
    }

    /// @dev Creates new proposal
    function createProposal(address _memberAddress, address _votingTypeAddress) 
        public 
        onlyInternal 
    {
        _createProposal(_memberAddress, _votingTypeAddress);
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
            } else {
                _rejectedProposals++;
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

    /// @dev Sets Voting type details such as Voting type name and address
    function setVotingTypeDetails(bytes32 _votingTypeName, address _votingTypeAddress) public onlyInternal {
        allVotingTypeDetails.push(VotingTypeDetails(_votingTypeName, _votingTypeAddress));
    }

    /// @dev Edits Voting type address when given voting type name
    function editVotingTypeDetails(uint _votingTypeId, address _votingTypeAddress) public onlyInternal {
        allVotingTypeDetails[_votingTypeId].votingTypeAddress = _votingTypeAddress;
    }

    /// @dev Adds points to add or subtract in member reputation when proposal/Solution/vote gets denied or accepted
    function addMemberReputationPoints() internal {
        addProposalOwnerPoints = 5;
        addSolutionOwnerPoints = 5;
    }

    /// @dev Sets global parameters that will help in distributing reward
    function setGlobalParameters() internal {
        quorumPercentage = 25;
        stakeWeight = 1;
        bonusStake = 2;
        reputationWeight = 1;
        bonusReputation = 2;
    }

    /// @dev Updates status of an existing proposal
    function updateProposalStatus(uint _id, uint8 _status) internal {
        allProposalData[_id].propStatus = _status;
        allProposal[_id].dateUpd = now; //solhint-disable-line
    }

    /// @dev Sets version number of proposal i.e. Version number increases everytime the proposal is modified
    function setProposalVersion(uint _proposalId, uint _versionNum) internal {
        allProposalData[_proposalId].versionNumber = _versionNum;
    }

    /// @dev Creates new proposal
    function _createProposal(address _memberAddress, address _votingTypeAddress) 
        internal    
    {
        allProposalSolutions[allProposal.length].push(SolutionStruct(address(0), ""));
        allProposal.push(ProposalStruct(_memberAddress, now, _votingTypeAddress)); //solhint-disable-line
    }

    /// @dev Changes stakeWeight that helps in calculation of reward distribution
    function _changeStakeWeight(uint _stakeWeight) internal {
        stakeWeight = _stakeWeight;
    }

    /// @dev Changes bonusStake that helps in calculation of reward distribution
    function _changeBonusStake(uint _bonusStake) internal {
        bonusStake = _bonusStake;
    }

    /// @dev Changes reputationWeight that helps in calculation of reward distribution
    function _changeReputationWeight(uint _reputationWeight) internal {
        reputationWeight = _reputationWeight;
    }

    /// @dev Changes bonusReputation that helps in calculation of reward distribution
    function _changeBonusReputation(uint _bonusReputation) internal {
        bonusReputation = _bonusReputation;
    }

    /// @dev Changes quoram percentage. Value required to pass proposal.
    function _changeQuorumPercentage(uint _quorumPercentage) internal {
        quorumPercentage = _quorumPercentage;
    }

    /// @dev Changes Proposal owner reputation points that needs to be added at proposal acceptance
    function _changeProposalOwnerAdd(uint _repPoints) internal {
        addProposalOwnerPoints = _repPoints;
    }

    /// @dev Changes Solution owner reputation points that needs to be added if solution has won. 
    ///     (Upvoted with many votes)
    function _changeSolutionOwnerAdd(uint _repPoints) internal {
        addSolutionOwnerPoints = _repPoints;
    }

}
