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
import "./Governance.sol";
import "./VotingType.sol";
import "./imports/govern/Governed.sol";


contract GovernanceData is Upgradeable, Governed { //solhint-disable-line

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
    
    event ProposalVersion(
        uint256 indexed proposalId, 
        uint256 indexed versionNumber, 
        string proposalDescHash, 
        uint256 dateAdd
    );

    event RewardClaimed(
        address indexed member,
        uint[] voterProposals,
        uint gbtReward, 
        uint dAppReward, 
        uint reputation
    );

    function callRewardClaimed(
        address _member,
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
            _voterProposals, 
            _gbtReward, 
            _dAppReward, 
            _reputation
        );
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
    }

    struct ProposalData {
        uint8 propStatus;
        uint64 finalVerdict;
        // uint64 currentVerdict;
        uint category;
        uint totalVoteValue;
        uint finalVoteValue;
        uint commonIncentive;
        address stakeToken;
    }

    struct SolutionStruct {
        address owner;
        bytes action;
    }

    mapping(uint => ProposalData) internal allProposalData;
    mapping(uint => SolutionStruct[]) internal allProposalSolutions;
    mapping(uint => bool) public proposalPaused;
    mapping(address => mapping(uint => bool)) internal rewardClaimed;
    mapping (uint => uint) internal proposalVersion;
    
    
    bool public constructorCheck;
    bool public punishVoters;
    uint internal minVoteWeight;

    ProposalStruct[] internal allProposal;

    Governance public gov;
    
    /// @dev updates all dependency addresses to latest ones from Master
    function updateDependencyAddresses() public {
        if (!constructorCheck)
            governanceDataInitiate();
        gov = Governance(master.getLatestAddress("GV"));
    }

    /// @dev Initiates governance data
    function governanceDataInitiate() public {
        require(!constructorCheck);
        allProposal.push(ProposalStruct(address(0), now)); //solhint-disable-line
        dappName = master.dAppName();
        constructorCheck = true;
        minVoteWeight = 1;
    }

    function getMinVoteWeight() public view returns (uint ){
        return minVoteWeight;
    }

    function setMinVoteWeight(uint _minVoteWeight) public onlyAuthorizedToGovern {
        minVoteWeight = _minVoteWeight;
    }

    function setPunishVoters(bool _punish) public onlyAuthorizedToGovern {
        punishVoters = _punish;
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

    /// @dev Sets the address of member as solution owner whosoever provided the solution
    function setSolutionAdded(uint _proposalId, address _memberAddress, bytes _action) public onlyInternal {
        allProposalSolutions[_proposalId].push(SolutionStruct(_memberAddress, _action));
    }

    /// @dev Gets The Address of Solution owner By solution sequence index 
    ///     As a proposal might have n number of solutions.
    function getSolutionOwnerByProposalIdAndIndex(uint _proposalId, uint _index) 
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
        updateProposalStatus(_id, _status);
    }

    /// @dev Sets proposal's final verdict once the final voting layer is crossed 
    ///     and voting is final closed for proposal
    function setProposalFinalVerdict(uint _proposalId, uint64 _finalVerdict) public onlyInternal {
        allProposalData[_proposalId].finalVerdict = _finalVerdict;
    }

    /// @dev Stores the information of version number of a given proposal. 
    ///     Maintains the record of all the versions of a proposal.
    function storeProposalVersion(uint _proposalId, string _proposalDescHash) public onlyInternal {
        proposalVersion[_proposalId] = SafeMath.add(proposalVersion[_proposalId], 1);
        emit ProposalVersion(_proposalId, proposalVersion[_proposalId], _proposalDescHash, now); //solhint-disable-line
    }

    /// @dev Sets proposal's date when the proposal last modified
    function setProposalDateUpd(uint _proposalId) public onlyInternal {
        allProposal[_proposalId].dateUpd = now; //solhint-disable-line
    }

    /// @dev Fetch details of proposal when giving proposal id
    function getProposalDetailsById(uint _proposalId) 
        public 
        view 
        returns(uint id, address owner, uint dateUpd, uint versionNum, uint8 propStatus) 
    {
        return (
            _proposalId, 
            allProposal[_proposalId].owner, 
            allProposal[_proposalId].dateUpd, 
            proposalVersion[_proposalId], 
            allProposalData[_proposalId].propStatus
        );
    }

    /// @dev Fetch details of proposal when giving proposal id
    function getProposalVotingDetails(uint _proposalId) 
        public 
        view 
        returns(
            uint id,
            uint category,
            uint64 finalVerdict, 
            address votingTypeAddress, 
            uint totalSolutions
        ) 
    {
            id = _proposalId;
            category = allProposalData[_proposalId].category;
            finalVerdict = allProposalData[_proposalId].finalVerdict;
            votingTypeAddress = getLatestVotingAddress();
            totalSolutions = allProposalSolutions[_proposalId].length;
    }

    /// @dev Fetch details of proposal when giving proposal id
    function getProposalStatusAndVerdict(uint _proposalId, address _memberAddress) 
        public 
        view 
        returns(bool, uint, uint8, uint64) 
    {
        return (
            rewardClaimed[_memberAddress][_proposalId], 
            allProposalData[_proposalId].category, 
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
            allProposalData[_proposalId].category, 
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
    function getProposalDetails(uint _proposalId) 
        public 
        view 
        returns(
            uint proposalId,
            uint status, 
            uint totalVoteValue, 
            uint totalSolutions, 
            uint commonIncentive, 
            uint finalVerdict,
            uint finalVoteValue
        ) 
    {
        proposalId = _proposalId;
        status = getProposalStatus(_proposalId);
        (totalVoteValue, finalVoteValue) = getProposalVoteValue(_proposalId);
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
                totalProposalCount = SafeMath.add(totalProposalCount, 1);
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

    /// @dev Gets the total incentive amount given by dApp for different proposals
    function getTotalProposalIncentive() public view returns(uint allIncentive) {
        for (uint i = 0; i < allProposal.length; i++) {
            allIncentive = SafeMath.add(allIncentive, allProposalData[i].commonIncentive);
        }
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
    function getProposalCategory(uint _proposalId) public view returns(uint) {
        return allProposalData[_proposalId].category;
    }

    function setRewardClaimed(uint _proposalId, address _memberAddress) public onlyInternal {
        rewardClaimed[_memberAddress][_proposalId] = true;
    }

    function getRewardClaimed(uint _proposalId, address _memberAddress) public view returns(bool) {
        return (rewardClaimed[_memberAddress][_proposalId]);
    }

    /// @dev gets total number of votes by a voter
    function getTotalNumberOfVotesByAddress(address _voter) public view returns(uint totalVotes) {
            VotingType vt = VotingType(master.getLatestAddress("SV"));
            totalVotes = SafeMath.add(vt.getTotalNumberOfVotesByAddress(_voter), 1);
    }

    /// @dev Gets Total vote value from all the votes that has been casted against of winning solution
    function getProposalVoteValue(uint _proposalId) public view returns(uint voteValue, uint finalVoteValue) {
        voteValue = allProposalData[_proposalId].totalVoteValue;
        finalVoteValue = allProposalData[_proposalId].finalVoteValue;
    }

    /// @dev Gets stakeToken proposal
    function getStakeToken(uint _proposalId) public view returns(address) {
        return allProposalData[_proposalId].stakeToken;
    }

    /// @dev Gets stakeToken and sub cat proposal
    function getTokenAndCategory(uint _proposalId) public view returns(address, uint) {
        return (allProposalData[_proposalId].stakeToken, allProposalData[_proposalId].category);
    }

    /// @dev Gets Total number of proposal created till now in dApp
    function getProposalLength() public view returns(uint) {
        return (allProposal.length);
    }

    function getLatestVotingAddress() public view returns(address) {
        return master.getLatestAddress("SV");
    }    

    /// @dev Sets Total calculated vote value from all the votes that has been casted against of winning solution
    function setProposalVoteValue(uint _proposalId, uint _voteValue,uint _finalVoteValue) public onlyInternal {
        allProposalData[_proposalId].totalVoteValue = _voteValue;
        allProposalData[_proposalId].finalVoteValue = _finalVoteValue;
    }

    /// @dev Adds new proposal
    function addNewProposal( 
        address _memberAddress, 
        uint _categoryId, 
        address _stakeToken
    ) 
        public 
        onlyInternal 
    {
        allProposalData[allProposal.length].category = _categoryId;
        allProposalData[allProposal.length].stakeToken = _stakeToken;
        _createProposal(_memberAddress);
    }

    /// @dev Updates proposal's major details (Called from close proposal vote)
    /// @param _proposalId Proposal id
    /// @param _finalVerdict Final verdict is set after final layer of voting
    function updateProposalDetails(
        uint _proposalId,
        uint64 _finalVerdict
    ) 
    public
    onlyInternal 
    {
        setProposalFinalVerdict(_proposalId, _finalVerdict);
        setProposalDateUpd(_proposalId);
    }

    /// @dev Creates a proposal
    function createProposal(address _memberAddress) 
        public 
        onlyInternal 
    {
        _createProposal(_memberAddress);
    }

    /// @dev Gets final solution index won after majority voting.
    function getProposalFinalVerdict(uint _proposalId) public view returns(uint finalSolutionIndex) {
        finalSolutionIndex = allProposalData[_proposalId].finalVerdict;
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
            uint _awaitingSolution, 
            uint _pendingProposals, 
            uint _acceptedProposals, 
            uint _rejectedProposals
        ) 
    {
        uint proposalStatus;
        _proposalLength = getProposalLength();

        for (uint i = 0; i < _proposalLength; i++) {
            proposalStatus = getProposalStatus(i);
            if (proposalStatus == uint(Governance.ProposalStatus.Draft)) {
                _draftProposals = SafeMath.add(_draftProposals, 1);
            } else if (proposalStatus == uint(Governance.ProposalStatus.AwaitingSolution)) {
                _awaitingSolution = SafeMath.add(_awaitingSolution, 1);
            } else if (proposalStatus == uint(Governance.ProposalStatus.VotingStarted)) {
                _pendingProposals = SafeMath.add(_pendingProposals, 1);
            } else if (proposalStatus == uint(Governance.ProposalStatus.Accepted) || proposalStatus == uint(Governance.ProposalStatus.Majority_Not_Reached_But_Accepted) || proposalStatus == uint(Governance.ProposalStatus.Threshold_Not_Reached_But_Accepted_By_PrevVoting)) {
                _acceptedProposals = SafeMath.add(_acceptedProposals, 1);
            } else {
                _rejectedProposals = SafeMath.add(_rejectedProposals, 1);
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
                if (_memberAddress == getSolutionOwnerByProposalIdAndIndex(i, j))
                    totalSolutionProposalCount = SafeMath.add(totalSolutionProposalCount, 1);
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
                if (_memberAddress == getSolutionOwnerByProposalIdAndIndex(i, j)) {
                    proposalIds[totalSolution] = i;
                    solutionProposalIds[totalSolution] = j;
                    totalSolution = SafeMath.add(totalSolution, 1);
                }
            }
        }
    }

    /// @dev Updates status of an existing proposal
    function updateProposalStatus(uint _id, uint8 _status) internal {
        allProposalData[_id].propStatus = _status;
        allProposal[_id].dateUpd = now; //solhint-disable-line
    }

    /// @dev Creates new proposal
    function _createProposal(address _memberAddress) 
        internal
    {
        allProposalSolutions[allProposal.length].push(SolutionStruct(address(0), ""));
        allProposal.push(ProposalStruct(_memberAddress, now)); //solhint-disable-line
    }

}