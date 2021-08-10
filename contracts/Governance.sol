// SPDX-License-Identifier: GNU

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

pragma solidity 0.8.0;

import "./Upgradeable.sol";
import "./Master.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./external/lockable-token/LockableToken.sol";
import "./MemberRoles.sol";
import "./interfaces/IGovernance.sol";
import "./interfaces/IProposalCategory.sol";


contract Governance is IGovernance, Upgradeable {

    enum ProposalStatus { 
        Draft,
        AwaitingSolution,
        VotingStarted,
        Accepted,
        Rejected,
        Majority_Not_Reached_But_Accepted,
        Denied,
        Majority_Not_Reached_But_Rejected
    }

    struct ProposalStruct {
        address owner;
        uint dateUpd;
    }

    struct ProposalData {
        uint propStatus;
        uint finalVerdict;
        uint category;
        uint totalVoteValue;
        uint majVoteValue;
        uint commonIncentive;
    }

    struct SolutionStruct {
        address owner;
        bytes action;
    }

    struct ProposalVote {
        address voter;
        uint solutionChosen;
        uint proposalId;
        uint voteValue;
        uint dateAdd;
    }

    mapping(uint => ProposalData) internal allProposalData;
    mapping(uint => SolutionStruct[]) internal allProposalSolutions;
    mapping(address => mapping(uint => uint)) public addressProposalVote;
    mapping(uint => uint[]) internal proposalVote;
    mapping(address => uint[]) internal allVotesByMember;
    mapping(uint => bool) public proposalPaused;
    mapping(uint => bool) public rewardClaimed; //can read from event
    mapping (address => uint) public lastRewardClaimed;

    ProposalStruct[] internal allProposal;
    ProposalVote[] internal allVotes;

    bool internal constructorCheck;
    bool internal punishVoters;
    uint internal minVoteWeight;
    uint public tokenHoldingTime;
    uint public override allowedToCatgorize;
    bool internal locked;

    MemberRoles internal memberRole;
    IProposalCategory internal proposalCategory;
    LockableToken internal tokenInstance;

    receive() external payable{}

    modifier noReentrancy() {
        require(!locked, "Reentrant call.");
        locked = true;
        _;
        locked = false;
    }

    modifier onlySelf() {
        require(msg.sender == address(this));
        _;
    }

    modifier onlyProposalOwner(uint _proposalId) {
        require(msg.sender == allProposal[_proposalId].owner, "Not authorized");
        _;
    }

    modifier voteNotStarted(uint _proposalId) {
        require(allProposalData[_proposalId].propStatus < uint(ProposalStatus.VotingStarted));
        _;
    }

    modifier isAllowed(uint _categoryId) {
        require(allowedToCreateProposal(_categoryId), "Not authorized");
        require(validateStake(_categoryId), "Lock more tokens");
        _;
    }

    modifier isAllowedToCategorize() {
        require(memberRole.checkRole(msg.sender, allowedToCatgorize), "Not authorized");
        _;
    }

    modifier isStakeValidated(uint _proposalId) {
        require(validateStake(allProposalData[_proposalId].category), "Lock more tokens");
        _;
    }

    /// @dev Creates a new proposal
    /// @param _proposalTitle Title of the proposal
    /// @param _proposalSD Proposal short description
    /// @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
    /// @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
    function createProposal(
        string calldata _proposalTitle,
        string calldata _proposalSD, 
        string calldata _proposalDescHash, 
        uint _categoryId
    ) 
        external override isAllowed(_categoryId)
    {
        _createProposal(_proposalTitle, _proposalSD, _proposalDescHash, _categoryId);
    }

    /// @dev Edits the details of an existing proposal
    /// @param _proposalId Proposal id that details needs to be updated
    /// @param _proposalTitle Title of the proposal
    /// @param _proposalSD Proposal short description    
    /// @param _proposalDescHash Proposal description hash having long and short description of proposal.
    function updateProposal(
        uint _proposalId, 
        string calldata _proposalTitle, 
        string calldata _proposalSD, 
        string calldata _proposalDescHash
    ) 
        external override onlyProposalOwner(_proposalId)
    {
        require(
            allProposalSolutions[_proposalId].length < 2,
            "Solution submitted"
        );
        _updateProposalStatus(_proposalId, uint(ProposalStatus.Draft));
        allProposalData[_proposalId].category = 0;
        allProposalData[_proposalId].commonIncentive = 0;
        emit Proposal(
            allProposal[_proposalId].owner,
            _proposalId,
            block.timestamp,
            _proposalTitle, 
            _proposalSD, 
            _proposalDescHash
        );
    }

    /// @dev Categorizes proposal to proceed further. Categories shows the proposal objective.
    /// @param _proposalId Proposal id
    /// @param _categoryId Category id
    /// @param _incentive Number of tokens to be distributed, if proposal is passed
    function categorizeProposal(
        uint _proposalId,
        uint _categoryId,
        uint _incentive
    )
        external override
        voteNotStarted(_proposalId) isAllowedToCategorize
    {

        require(
            allProposalSolutions[_proposalId].length < 2,
            "Solutions had already been submitted"
        );

        _categorizeProposal(_proposalId, _categoryId, _incentive);
    }

    /// @dev Initiates add solution
    /// @param _proposalId Proposal id
    /// @param _solutionHash Solution hash having required data against adding solution
    /// @param _action encoded hash of the action to call, if solution is choosen
    function addSolution(
        uint _proposalId,
        string calldata _solutionHash, 
        bytes calldata _action
    ) 
        external override isStakeValidated(_proposalId)
    {
        require(
            allProposalData[_proposalId].propStatus == uint(Governance.ProposalStatus.AwaitingSolution),
            "Not in solutioning phase"
        );

        _addSolution(_proposalId, _action, _solutionHash);
    }

    /// @dev Opens proposal for voting
    /// @param _proposalId Proposal id
    function openProposalForVoting(uint _proposalId)
        external override onlyProposalOwner(_proposalId) voteNotStarted(_proposalId) isStakeValidated(_proposalId)
    {
        require(
            allProposalSolutions[_proposalId].length > 1,
            "Add more solutions"
        );

        _openProposalForVoting(_proposalId);
    }

    /// @dev Submit proposal with solution
    /// @param _proposalId Proposal id
    /// @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
    /// @param _action encoded hash of the action to call, if solution is choosen
    function submitProposalWithSolution(
        uint _proposalId, 
        string calldata _solutionHash, 
        bytes calldata _action
    ) 
        external override
        onlyProposalOwner(_proposalId) isStakeValidated(_proposalId)
    {
        _proposalSubmission(_proposalId, _solutionHash, _action);
    }

    /// @dev Creates a new proposal with solution and votes for the solution
    /// @param _proposalTitle Title of the proposal
    /// @param _proposalSD Proposal short description    
    /// @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
    /// @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
    /// @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
    /// @param _action encoded hash of the action to call, if solution is choosen
    function createProposalwithSolution(
        string calldata _proposalTitle, 
        string calldata _proposalSD, 
        string calldata _proposalDescHash,
        uint _categoryId, 
        string calldata _solutionHash, 
        bytes calldata _action
    ) 
        external override isAllowed(_categoryId)
    {

        uint proposalId = allProposal.length;

        _createProposal(_proposalTitle, _proposalSD, _proposalDescHash, _categoryId);

        _proposalSubmission(
            proposalId,
            _solutionHash,
            _action
        );

        _submitVote(proposalId, 1);
    }

    /// @dev Submits a vote to solution of a proposal
    /// @param _proposalId Proposal id
    /// @param _solution Solution id
    function submitVote(uint _proposalId, uint _solution) external override isStakeValidated(_proposalId) {
        require(addressProposalVote[msg.sender][_proposalId] == 0, "Already voted");

        require(allProposalData[_proposalId].propStatus == uint(Governance.ProposalStatus.VotingStarted), "Not allowed");

        require(_solution < allProposalSolutions[_proposalId].length, "Solution doesn't exist");

        _submitVote(_proposalId, _solution);
    }

    /// @dev Close proposal for voting, calculate the result and perform defined action
    function closeProposal(uint _proposalId) external override {
        uint category = allProposalData[_proposalId].category;
        uint max;
        uint totalVoteValue;
        uint i;
        uint solutionId;
        uint voteValue;
        uint totalTokens;
        require(canCloseProposal(_proposalId) == 1, "Cannot close");

        uint[] memory finalVoteValues = new uint[](allProposalSolutions[_proposalId].length);
        for (i = 0; i < proposalVote[_proposalId].length; i++) {
            solutionId = allVotes[proposalVote[_proposalId][i]].solutionChosen;
            voteValue = allVotes[proposalVote[_proposalId][i]].voteValue;
            totalVoteValue = totalVoteValue + voteValue;
            finalVoteValues[solutionId] = finalVoteValues[solutionId] + voteValue;
            totalTokens = totalTokens + tokenInstance.totalBalanceOf(allVotes[proposalVote[_proposalId][i]].voter);
            if (finalVoteValues[max] < finalVoteValues[solutionId]) {
                max = solutionId;
            }
        }

        allProposalData[_proposalId].totalVoteValue = totalVoteValue;
        allProposalData[_proposalId].majVoteValue = finalVoteValues[max];

        if (checkForThreshold(_proposalId, category, totalTokens)) {
            closeProposalVoteThReached(finalVoteValues[max], totalVoteValue, category, _proposalId, max);
        } else {
            allProposalData[_proposalId].finalVerdict = max;
            _updateProposalStatus(_proposalId, uint(ProposalStatus.Denied));
        }
    }

    /// @dev user can calim the tokens rewarded them till now
    /// Index 0 of _ownerProposals, _voterProposals is not parsed. 
    /// proposal arrays of 1 length are treated as empty.
    function claimReward(address _claimer, uint _maxRecords) external override noReentrancy returns(uint pendingDAppReward) {
        
        pendingDAppReward = _claimReward(_claimer, _maxRecords);

        if (pendingDAppReward != 0) {
            tokenInstance.transfer(_claimer, pendingDAppReward);
            emit RewardClaimed(
                _claimer,
                pendingDAppReward
            );
        }

    }

    /// @dev Get proposal details
    function proposal(uint _proposalId)
        external override
        view
        returns(
            uint _id,
            uint _categoryId,
            uint _status,
            uint _finalVerdict,
            uint _incentive
        )
    {
        return(
            _proposalId,
            allProposalData[_proposalId].category,
            allProposalData[_proposalId].propStatus,
            allProposalData[_proposalId].finalVerdict,
            allProposalData[_proposalId].commonIncentive
        );
    }

    /// @dev Get proposal details
    function proposalDetails(uint _proposalId) external view returns(uint _id, uint _totalSolutions, uint _totalVotes) {
        return(
            _proposalId,
            allProposalSolutions[_proposalId].length,
            proposalVote[_proposalId].length
        );
    }

    /// @dev Get encoded action hash of solution
    function getSolutionAction(uint _proposalId, uint _solution) external view returns(uint, bytes memory) {
        return (
            _solution,
            allProposalSolutions[_proposalId][_solution].action
        );
    }

    /// @dev Gets statuses of proposals
    /// @param _proposalLength Total proposals created till now.
    /// @param _draftProposals Proposal that are currently in draft or still getting updated.
    /// @param _awaitingSolution Proposals waiting for solutions to be submitted
    /// @param _pendingProposals Those proposals still open for voting
    /// @param _acceptedProposals Proposal those are submitted or accepted by majority voting
    /// @param _rejectedProposals Proposal those are rejected by majority voting.
    function getStatusOfProposals() 
        external 
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
        _proposalLength = allProposal.length;

        for (uint i = 0; i < _proposalLength; i++) {
            proposalStatus = allProposalData[i].propStatus;
            if (proposalStatus == uint(ProposalStatus.Draft)) {
                _draftProposals = _draftProposals + 1;
            } else if (proposalStatus == uint(ProposalStatus.AwaitingSolution)) {
                _awaitingSolution = _awaitingSolution + 1;
            } else if (proposalStatus == uint(ProposalStatus.VotingStarted)) {
                _pendingProposals = _pendingProposals + 1;
            } else if (proposalStatus == uint(ProposalStatus.Accepted) || proposalStatus == uint(ProposalStatus.Majority_Not_Reached_But_Accepted)) {
                _acceptedProposals = _acceptedProposals + 1;
            } else {
                _rejectedProposals = _rejectedProposals + 1;
            }
        }
    }

    /// @dev Get total number of proposal created
    function getProposalLength() external view returns(uint) {
        return (allProposal.length);
    }

    function initiateGovernance(bool _punishVoters) external {
        require(!constructorCheck);
        allowedToCatgorize = uint(MemberRoles.Role.AdvisoryBoard);
        allVotes.push(ProposalVote(address(0), 0, 0, 1, 0));
        allProposal.push(ProposalStruct(address(0), block.timestamp));
        tokenHoldingTime = 7 days;
        punishVoters = _punishVoters;
        minVoteWeight = 1;
        constructorCheck = true;
    }

    /// @dev updates all dependency addresses to latest ones from Master
    function updateDependencyAddresses() public override{
        tokenInstance = LockableToken(ms.dAppLocker());
        memberRole = MemberRoles(ms.getLatestAddress("MR"));
        proposalCategory = IProposalCategory(ms.getLatestAddress("PC"));
    }

    /// @dev Checks If the proposal voting time is up and it's ready to close 
    ///      i.e. Closevalue is 1 if proposal is ready to be closed, 2 if already closed, 0 otherwise!
    /// @param _proposalId Proposal id to which closing value is being checked
    function canCloseProposal(uint _proposalId) 
        public 
        override
        view 
        returns(uint closeValue)
    {
        uint dateUpdate;
        uint pStatus;
        uint _closingTime;
        uint _roleId;
        require(!proposalPaused[_proposalId]);
        pStatus = allProposalData[_proposalId].propStatus;
        dateUpdate = allProposal[_proposalId].dateUpd;
        (, _roleId, , , , _closingTime, ) = proposalCategory.category(allProposalData[_proposalId].category);
        if (
            pStatus == uint(ProposalStatus.VotingStarted) &&
            _roleId != uint(MemberRoles.Role.TokenHolder) &&
            _roleId != uint(MemberRoles.Role.UnAssigned)
        ) {
            if (dateUpdate + _closingTime <= block.timestamp || 
                proposalVote[_proposalId].length == memberRole.numberOfMembers(_roleId)
            )
                closeValue = 1;
        } else if (pStatus == uint(ProposalStatus.VotingStarted)) {
            if (dateUpdate + _closingTime <= block.timestamp)
                closeValue = 1;
        } else if (pStatus > uint(ProposalStatus.VotingStarted)) {
            closeValue = 2;
        } else {
            closeValue = 0;
        }
    }

    /// @dev pause a proposal
    function pauseProposal(uint _proposalId) public override onlySelf {
        proposalPaused[_proposalId] = true;
        allProposal[_proposalId].dateUpd = block.timestamp;
    }

    /// @dev resume a proposal
    function resumeProposal(uint _proposalId) public override onlySelf {
        proposalPaused[_proposalId] = false;
        allProposal[_proposalId].dateUpd = block.timestamp;
    }

    /// @dev Get number of token incentives to be claimed by a member
    /// @param _memberAddress address  of member to calculate pending reward 
    function getPendingReward(address _memberAddress)
        public view returns(uint pendingDAppReward)
    {
        uint i;
        uint totalVotes = allVotesByMember[_memberAddress].length;
        uint proposalId;
        uint voteId;
        uint finalVerdict;
        uint proposalVoteValue;
        for (i = lastRewardClaimed[_memberAddress]; i < totalVotes; i++) {
            voteId = allVotesByMember[_memberAddress][i];
            proposalId = allVotes[voteId].proposalId;
            finalVerdict = allProposalData[proposalId].finalVerdict;
            if (punishVoters) {
                if (allVotes[voteId].solutionChosen != finalVerdict) {
                    continue;
                }
                proposalVoteValue = allProposalData[proposalId].majVoteValue;
            } else {
                proposalVoteValue = allProposalData[proposalId].totalVoteValue;
            }
            if (finalVerdict > 0) {
                if (!rewardClaimed[voteId]) {
                    pendingDAppReward += (allVotes[voteId].voteValue *
                                        allProposalData[proposalId].commonIncentive) / 
                                        proposalVoteValue;
                }
            }
        }
    }

    /// @dev checks if the msg.sender is allowed to create a proposal under certain category
    function allowedToCreateProposal(uint category) public view returns(bool check) {
        if (category == 0)
            return true;
        uint[] memory mrAllowed;
        (, , , , mrAllowed, , ) = proposalCategory.category(category);

        for (uint i = 0; i < mrAllowed.length; i++) {
            if (mrAllowed[i] == 0 || memberRole.checkRole(msg.sender, mrAllowed[i]))
                return true;
        }
    }

    /// @dev transfers its assets to latest addresses
    function transferAssets() public {
        address newPool = ms.getLatestAddress("GV");
        if (address(this) != newPool) {
            uint tokenBal = tokenInstance.balanceOf(address(this));
            uint ethBal = address(this).balance;
            if (tokenBal > 0)
                tokenInstance.transfer(newPool, tokenBal);
            if (ethBal > 0)
                payable(newPool).transfer(ethBal);
        }
    }

    /// @dev Transfer Ether to someone
    /// @param _amount Amount to be transferred back
    /// @param _receiverAddress address where ether has to be sent
    function transferEther(address _receiverAddress, uint256 _amount) public onlySelf {
        payable(_receiverAddress).transfer(_amount);
    }

    /// @dev Transfer token to someone    
    /// @param _amount Amount to be transferred back
    /// @param _receiverAddress address where tokens have to be sent
    /// @param _token address of token to transfer
    function transferToken(address _token, address _receiverAddress, uint256 _amount) public onlySelf {
        LockableToken token = LockableToken(_token);
        token.transfer(_receiverAddress, _amount);
    }

    /// @dev Internal call for creating proposal
    function _createProposal(
        string memory _proposalTitle,
        string memory _proposalSD,
        string memory _proposalDescHash,
        uint _categoryId
    )
        internal
    {
        uint _proposalId = allProposal.length;

        allProposalSolutions[allProposal.length].push(SolutionStruct(address(0), ""));
        allProposal.push(ProposalStruct(msg.sender, block.timestamp));

        if (_categoryId > 0) {
            uint defaultIncentive;
            (, , , defaultIncentive) = proposalCategory.categoryAction(_categoryId);
            _categorizeProposal(_proposalId, _categoryId, defaultIncentive);
        }

        emit Proposal(
            msg.sender,
            _proposalId,
            block.timestamp,
            _proposalTitle,
            _proposalSD,
            _proposalDescHash
        );
    }

    /// @dev Internal call for categorizing proposal
    function _categorizeProposal(
        uint _proposalId,
        uint _categoryId,
        uint _incentive
    ) 
        internal
    {
        require(
            _categoryId > 0 && _categoryId < proposalCategory.totalCategories(),
            "Invalid category"
        );

        require(
            _incentive <= tokenInstance.balanceOf(address(this)),
            "Less token balance in pool for incentive distribution"
        );

        allProposalData[_proposalId].category = _categoryId;
        allProposalData[_proposalId].commonIncentive = _incentive;
        _updateProposalStatus(_proposalId, uint(ProposalStatus.AwaitingSolution));
    }

    /// @dev Internal call for opening propsoal for voting
    function _openProposalForVoting(uint _proposalId) internal {

        require(allProposalData[_proposalId].category != 0, "Categorize the proposal");
        
        _updateProposalStatus(_proposalId, uint(ProposalStatus.VotingStarted));
        uint closingTime;
        (, , , , , closingTime, ) = proposalCategory.category(allProposalData[_proposalId].category);
        emit CloseProposalOnTime(_proposalId, closingTime + block.timestamp);
    }

    /// @dev Internal call for addig a solution to proposal
    function _addSolution(uint _proposalId, bytes memory _action, string memory _solutionHash)
        internal
    {
        require(!alreadyAdded(_proposalId, msg.sender), "User already added a solution for this proposal");
        // governanceDat.setSolutionAdded(_proposalId, msg.sender, _action, _solutionHash);
        allProposalSolutions[_proposalId].push(SolutionStruct(msg.sender, _action));
        emit Solution(_proposalId, msg.sender, allProposalSolutions[_proposalId].length - 1, _solutionHash, block.timestamp);
    }

    /// @dev When creating or submitting proposal with solution, This function open the proposal for voting
    function _proposalSubmission(
        uint _proposalId,
        string memory _solutionHash,
        bytes memory _action
    )
        internal
    {

        _addSolution(
            _proposalId,
            _action,
            _solutionHash
        );

        _openProposalForVoting(
            _proposalId
        );
    }

    /// @dev Internal call for addig a vote to solution
    function _submitVote(uint _proposalId, uint _solution) internal {

        uint mrSequence;
        uint totalVotes = allVotes.length;
        (, mrSequence, , , , , ) = proposalCategory.category(allProposalData[_proposalId].category);

        require(memberRole.checkRole(msg.sender, mrSequence));

        proposalVote[_proposalId].push(totalVotes);
        allVotesByMember[msg.sender].push(totalVotes);
        addressProposalVote[msg.sender][_proposalId] = totalVotes;
        allVotes.push(ProposalVote(msg.sender, _solution, _proposalId, calculateVoteValue(msg.sender), block.timestamp));

        emit Vote(msg.sender, _proposalId, totalVotes, block.timestamp, _solution);

        if (proposalVote[_proposalId].length == memberRole.numberOfMembers(mrSequence) &&
            mrSequence != uint(MemberRoles.Role.TokenHolder) &&
            mrSequence != uint(MemberRoles.Role.UnAssigned)
        ) {
            emit VoteCast(_proposalId);
        }
    }

    /// @dev Checks if the vote count against any solution passes the threshold value or not.
    function checkForThreshold(uint _proposalId, uint _category, uint _totalTokens) internal view returns(bool) {
        uint thresHoldValue;
        uint categoryQuorumPerc;
        uint _mrSequenceId;
        (, _mrSequenceId, , categoryQuorumPerc, , , ) = proposalCategory.category(_category);
        if (_mrSequenceId == uint(MemberRoles.Role.TokenHolder)) {
            thresHoldValue = (_totalTokens * 100) / tokenInstance.totalSupply();
            if (thresHoldValue > categoryQuorumPerc)
                return true;
        } else if (_mrSequenceId == uint(MemberRoles.Role.UnAssigned)) {
            return true;
        } else {
            thresHoldValue = (proposalVote[_proposalId].length *
                        100) / 
                    memberRole.numberOfMembers(_mrSequenceId);
            if (thresHoldValue > categoryQuorumPerc)
                return true;
        }
    }

    /// @dev This does the remaining functionality of closing proposal vote
    function closeProposalVoteThReached(uint maxVoteValue, uint totalVoteValue, uint category, uint _proposalId, uint max) 
        internal
    {
        uint _majorityVote;
        bytes2 contractName;
        address actionAddress;
        allProposalData[_proposalId].finalVerdict = max;
        (, , _majorityVote, , , , ) = proposalCategory.category(category);
        (, actionAddress, contractName, ) = proposalCategory.categoryAction(category);
        if ((maxVoteValue * 100) / totalVoteValue >= _majorityVote) {
            if (max > 0) {
                _updateProposalStatus(_proposalId, uint(ProposalStatus.Accepted));
                /*solhint-disable*/
                if (contractName == "MS")
                    actionAddress = address(ms);
                else if(contractName !="EX")
                    actionAddress = ms.getLatestAddress(contractName);
                /*solhint-enable*/
                (bool success, ) = actionAddress.call(allProposalSolutions[_proposalId][max].action);
                if (success) {
                    emit ActionSuccess(_proposalId);
                }
                emit ProposalAccepted(_proposalId);
            } else {
                _updateProposalStatus(_proposalId, uint(ProposalStatus.Rejected));
            }
        } else {
            if (max > 0) {
                _updateProposalStatus(_proposalId, uint(ProposalStatus.Majority_Not_Reached_But_Accepted));
            } else {
                _updateProposalStatus(_proposalId, uint(ProposalStatus.Majority_Not_Reached_But_Rejected));
            }
        }
    }

    /// @dev validates that the voter has enough tokens locked for voting and returns vote value
    ///     Seperate function from validateStake to save gas.
    function calculateVoteValue(address _of) 
        internal view returns(uint voteValue) 
    {

        voteValue = _getLockedBalance(_of, tokenHoldingTime);

        voteValue = 
            Math.max(
                voteValue / uint256(10) ** tokenInstance.decimals(),
                minVoteWeight
            );
    }

    /// @dev Checks if the solution is already added by a member against specific proposal
    /// @param _proposalId Proposal id
    /// @param _memberAddress Member address
    function alreadyAdded(uint _proposalId, address _memberAddress) internal view returns(bool) {
        SolutionStruct[] memory solutions = allProposalSolutions[_proposalId];
        for (uint i = 1; i < solutions.length; i++) {
            if (solutions[i].owner == _memberAddress)
                return true;
        }
    }

    /// @dev checks if the msg.sender has enough tokens locked for creating a proposal or solution
    function validateStake(uint _categoryId) internal view returns(bool) {
        uint minStake;
        (, , , , , , minStake) = proposalCategory.category(_categoryId);

        if (minStake == 0)
            return true;

        uint lockedTokens = _getLockedBalance(msg.sender, tokenHoldingTime);
        if (lockedTokens >= minStake)
            return true;
    }

    /// @dev Get amount of tokens locked by the member upto givien time
    function _getLockedBalance(address _of, uint _time)
        internal view returns(uint lockedTokens)
    {
        _time += block.timestamp;
        lockedTokens = tokenInstance.tokensLockedAtTime(_of, "GOV", _time);
    }

    // /// @dev calculate amount of reward applicable for given vote vote id 
    // function calculatePendingVoteReward(uint _voteId, uint _proposalId)
    //     internal
    //     view
    //     returns (uint pendingDAppReward)
    // {
    //     uint solutionChosen;
    //     uint finalVerdict;
    //     uint voteValue;
    //     uint totalReward;
    //     uint calcReward;
    //     uint finalVoteValue;
    //     uint totalVoteValue;
    //     solutionChosen = allVotes[_voteId].solutionChosen;
    //     voteValue = allVotes[_voteId].voteValue;
    //     // (, solutionChosen, , voteValue) = governanceDat.getVoteData(_voteId);
    //     finalVerdict = allProposalData[_proposalId].finalVerdict;
    //     totalReward = allProposalData[_proposalId].commonIncentive;
    //     totalVoteValue = allProposalData[_proposalId].totalVoteValue;
    //     finalVoteValue = allProposalData[_proposalId].majVoteValue;
    //     // (, , finalVerdict, totalReward, ) = 
    //     //     governanceDat.getProposalVotingDetails(_proposalId);
    //     // (totalVoteValue, finalVoteValue) = governanceDat.getProposalVoteValue(_proposalId);
    //     if (punishVoters) {
    //         if ((finalVerdict > 0 && solutionChosen == finalVerdict)) {
    //             calcReward = (voteValue * totalReward) / finalVoteValue;
    //         }
    //     } else if (finalVerdict > 0) {
    //         calcReward = (voteValue * totalReward) / totalVoteValue;
    //     }

    //     pendingDAppReward = calcReward;
    // }

    /// @dev Update proposal status
    function _updateProposalStatus(uint _proposalId, uint _status) internal {
        allProposal[_proposalId].dateUpd = block.timestamp;
        allProposalData[_proposalId].propStatus = _status;
    }

    /// @dev Internal call from claimReward
    function _claimReward(address _memberAddress, uint _maxRecords) 
        internal returns(uint pendingDAppReward) 
    {
        uint proposalId;
        uint voteId;
        uint finalVerdict;
        uint totalVotes = allVotesByMember[_memberAddress].length;
        uint lastClaimed = totalVotes;
        uint j;
        uint i;
        uint proposalVoteValue;
        uint proposalStatus = allProposalData[proposalId].propStatus;
        for (i = lastRewardClaimed[_memberAddress]; i < totalVotes && j < _maxRecords; i++) {
            voteId = allVotesByMember[_memberAddress][i];
            proposalId = allVotes[voteId].proposalId;
            finalVerdict = allProposalData[proposalId].finalVerdict;
            if (punishVoters) {
                if (allVotes[voteId].solutionChosen != finalVerdict) {
                    continue;
                }
                proposalVoteValue = allProposalData[proposalId].majVoteValue;
            } else {
                proposalVoteValue = allProposalData[proposalId].totalVoteValue;
            }
            if (finalVerdict > 0) {
                if (!rewardClaimed[voteId]) {
                    pendingDAppReward += (
                                        allVotes[voteId].voteValue *
                                        allProposalData[proposalId].commonIncentive
                                    ) /
                                    proposalVoteValue;
                    rewardClaimed[voteId] = true;
                }
            } else {
                if (proposalStatus <= uint(ProposalStatus.VotingStarted) && 
                    lastClaimed == totalVotes
                ) {
                    lastClaimed = i;
                }
            }
        }

        if (lastClaimed == totalVotes) {
            lastRewardClaimed[_memberAddress] = i;
        } else {
            lastRewardClaimed[_memberAddress] = lastClaimed;
        }
    }

}