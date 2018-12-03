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
import "./GovernanceData.sol";
import "./ProposalCategory.sol";
import "./MemberRoles.sol";
import "./Upgradeable.sol";
import "./Master.sol";
import "./imports/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./imports/openzeppelin-solidity/contracts/math/Math.sol";
import "./GBTStandardToken.sol";
import "./EventCaller.sol";

import "./interfaces/IGovernance.sol";



contract Governance is IGovernance, Upgradeable {

    using SafeMath for uint;

    enum ProposalStatus { 
        Draft,
        AwaitingSolution,
        VotingStarted,
        Accepted,
        Rejected,
        Majority_Not_Reached_But_Accepted,
        Denied,
        Threshold_Not_Reached_But_Accepted_By_PrevVoting 
    }

    address public poolAddress;
    MemberRoles public memberRole;
    ProposalCategory public proposalCategory;
    GovernanceData public governanceDat;
    EventCaller public eventCaller;
    address public dAppLocker;

    modifier onlyProposalOwner(uint _proposalId) {
        require(msg.sender == governanceDat.getProposalOwner(_proposalId));
        _;
    }

    modifier checkProposalValidity(uint _proposalId) {
        require(governanceDat.getProposalStatus(_proposalId) < uint(ProposalStatus.VotingStarted));
        _;
    }

    modifier isAllowed(uint _categoryId){
        require(allowedToCreateProposal(_categoryId), "User not authorized to create proposal under this category");
        require(validateStake(_categoryId, msg.sender), "Lock more tokens");
        _;
    }

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

    /// @dev updates all dependency addresses to latest ones from Master
    function updateDependencyAddresses() public {
        dAppLocker = master.dAppLocker();
        governanceDat = GovernanceData(master.getLatestAddress("GD"));
        memberRole = MemberRoles(master.getLatestAddress("MR"));
        proposalCategory = ProposalCategory(master.getLatestAddress("PC"));
        poolAddress = master.getLatestAddress("PL");
        eventCaller = EventCaller(master.getEventCallerAddress());
    }

    /// @dev Creates a new proposal
    /// @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
    /// @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
    function createProposal(
        string _proposalTitle, 
        string _proposalSD, 
        string _proposalDescHash, 
        uint _categoryId
    ) 
        external isAllowed(_categoryId)
    {
        _createProposal(_proposalTitle, _proposalSD, _proposalDescHash, _categoryId);
    }

    /// @dev Edits the details of an existing proposal and creates new version
    /// @param _proposalId Proposal id that details needs to be updated
    /// @param _proposalDescHash Proposal description hash having long and short description of proposal.
    // function updateProposal(
    //     uint _proposalId, 
    //     string _proposalTitle, 
    //     string _proposalSD, 
    //     string _proposalDescHash
    // ) 
    //     external onlyProposalOwner(_proposalId)
    // {
    //     require(
    //         governanceDat.getTotalSolutions(_proposalId) < 2,
    //         "Cannot update proposal, since solutions had already been submitted"
    //     );
    //     governanceDat.storeProposalVersion(_proposalId, _proposalDescHash);
    //     governanceDat.setProposalDateUpd(_proposalId);
    //     governanceDat.changeProposalStatus(_proposalId, 0);
    //     governanceDat.setProposalCategory_Incentive(_proposalId, 0, 0);
    //     emit Proposal(
    //         governanceDat.getProposalOwner(_proposalId), 
    //         _proposalId, 
    //         now, 
    //         _proposalTitle, 
    //         _proposalSD, 
    //         _proposalDescHash
    //     );
    // }

    /// @dev Categorizes proposal to proceed further. Categories shows the proposal objective.
    function categorizeProposal(
        uint _proposalId,
        uint _categoryId
    )
        external
        checkProposalValidity(_proposalId) isAllowed(_categoryId)
    {

        require(
            governanceDat.getTotalSolutions(_proposalId) < 2,
            "Categorization not possible, since solutions had already been submitted"
        );

        _categorizeProposal(_proposalId, _categoryId);
    }

    /// @dev Initiates add solution
    /// @param _solutionHash Solution hash having required data against adding solution
    function addSolution(
        uint32 _proposalId, 
        string _solutionHash, 
        bytes _action
    ) 
        external 
    {
        require(
            governanceDat.getProposalStatus(_proposalId) >= uint(Governance.ProposalStatus.AwaitingSolution),
            "Proposal should be open for solution submission"
        );
        require(validateStake(governanceDat.getProposalCategory(_proposalId), msg.sender), "Lock more tokens");

        _addSolution( _proposalId, _action, _solutionHash);
    }

    /// @dev Opens proposal for voting
    function openProposalForVoting(uint _proposalId)
        public onlyProposalOwner(_proposalId) checkProposalValidity(_proposalId)
    {
        uint category = governanceDat.getProposalCategory(_proposalId);

        require(category != 0, "Proposal should be categorized first");

        require(
            governanceDat.getTotalSolutions(_proposalId) > 1,
            "Proposal should contain atleast two solutions before it is open for voting"
        );
        governanceDat.changeProposalStatus(_proposalId, uint8(ProposalStatus.VotingStarted));
        uint closingTime;
        (, , , , , closingTime, ) = proposalCategory.category(category);
        closingTime = SafeMath.add(closingTime, now); // solhint-disable-line
        eventCaller.callCloseProposalOnTimeAtAddress(_proposalId, address(this), closingTime);
    }

    /// @dev Submit proposal with solution
    /// @param _proposalId Proposal id
    /// @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
    function submitProposalWithSolution(
        uint _proposalId, 
        string _solutionHash, 
        bytes _action
    ) 
        external
        onlyProposalOwner(_proposalId) 
    {
        _proposalSubmission(_proposalId, _solutionHash, _action);
    }


    /// @dev Creates a new proposal with solution and votes for the solution
    /// @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
    /// @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
    /// @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
    function createProposalwithSolution(
        string _proposalTitle, 
        string _proposalSD, 
        string _proposalDescHash,
        uint _categoryId, 
        string _solutionHash, 
        bytes _action
    ) 
        external
    {

        uint proposalId = governanceDat.getProposalLength();

        _createProposal(_proposalTitle, _proposalSD, _proposalDescHash, _categoryId);

        _categorizeProposal(proposalId, _categoryId);

        _proposalSubmission(
            proposalId,
            _solutionHash,
            _action
        );

        submitVote(uint32(proposalId), 1, msg.sender);
    }


    function submitVote(uint32 _proposalId, uint64 _solution, address _voter) public {
        //Variables are reused to save gas. We know that this reduces code readability but proposalVoting is
        //where gas usage should be optimized as much as possible. voters should not feel burdened while voting.
        require(governanceDat.getMemberVoteAgainstProposal(_voter, _proposalId) == 0);

        require(governanceDat.getProposalStatus(_proposalId) == uint(Governance.ProposalStatus.VotingStarted));

        uint categoryThenMRSequence;
        uint voteValue;

        (categoryThenMRSequence) 
            = governanceDat.getProposalCategory(_proposalId);

        require(validateStake(categoryThenMRSequence, _voter));

        (, categoryThenMRSequence, , , , , ) = proposalCategory.category(categoryThenMRSequence);
        //categoryThenMRSequence is now MemberRoleSequence

        require(memberRole.checkRole(_voter, categoryThenMRSequence));
        require(_solution <= governanceDat.getTotalSolutions(_proposalId));

        voteValue = calculateVoteValue(_proposalId, _voter);

        governanceDat.setProposalVote(_proposalId, _voter, _solution, voteValue);
        emit Vote(msg.sender, _proposalId, now, governanceDat.getProposalVoteLength(_proposalId) - 1);
        if (governanceDat.getProposalVoteLength(_proposalId) == memberRole.numberOfMembers(categoryThenMRSequence) &&
            categoryThenMRSequence != 2 &&
            categoryThenMRSequence != 0
        ) {
            eventCaller.callVoteCast(_proposalId);
        }
    }    

    /// @dev Checks If the proposal voting time is up and it's ready to close 
    ///      i.e. Closevalue is 1 if proposal is ready to be closed, 2 if already closed, 0 otherwise!
    /// @param _proposalId Proposal id to which closing value is being checked
    function canCloseProposal(uint _proposalId) 
        public 
        view 
        returns(uint8 closeValue)
    {
        uint dateUpdate;
        uint pStatus;
        uint _closingTime;
        uint _roleId;
        uint _category;
        require(!governanceDat.proposalPaused(_proposalId));
        
        (, _category, , dateUpdate, , pStatus) = governanceDat.getProposalDetailsById(_proposalId);
        (, _roleId, , , , _closingTime, ) = proposalCategory.category(_category);
        if (
            pStatus == uint(ProposalStatus.VotingStarted) &&
            _roleId != uint(MemberRoles.Role.TokenHolder) &&
            _roleId != uint(MemberRoles.Role.UnAssigned)
        ) {
            if (SafeMath.add(dateUpdate, _closingTime) <= now ||  //solhint-disable-line
                governanceDat.getProposalVoteLength(_proposalId) == memberRole.numberOfMembers(_roleId)
            )
                closeValue = 1;
        } else if (pStatus == uint(ProposalStatus.VotingStarted)) {
            if (SafeMath.add(dateUpdate, _closingTime) <= now) //solhint-disable-line
                closeValue = 1;
        } else if (pStatus > uint(ProposalStatus.VotingStarted)) {
            closeValue = 2;
        } else {
            closeValue = 0;
        }
    }

    function closeProposal(uint _proposalId) external {
        uint category = governanceDat.getProposalCategory(_proposalId);
        uint64 max;
        uint totalVoteValue;
        uint i;
        uint solutionId;
        uint voteValue;

        require(canCloseProposal(_proposalId) == 1);
        uint[] memory voteIds = governanceDat.getProposalVotes(_proposalId);
        uint[] memory finalVoteValues = new uint[](governanceDat.getTotalSolutions(_proposalId));
        for (i = 0; i < voteIds.length; i++) {
            (, solutionId, , voteValue) = governanceDat.getVoteData(voteIds[i]);
            totalVoteValue = SafeMath.add(totalVoteValue, voteValue);
            finalVoteValues[solutionId] = finalVoteValues[solutionId].add(voteValue);
            if (finalVoteValues[max] < finalVoteValues[solutionId]) {
                max = uint64(solutionId);
            }
        }
        (voteValue,) = governanceDat.getProposalVoteValue(_proposalId);
        totalVoteValue = SafeMath.add(totalVoteValue, voteValue);

        governanceDat.setProposalVoteValue(_proposalId, totalVoteValue, finalVoteValues[max]);

        if (checkForThreshold(_proposalId, category)) {
            closeProposalVoteThReached(finalVoteValues[max], totalVoteValue, category, _proposalId, max);
        } else {
            governanceDat.updateProposalDetails(_proposalId, max);
            governanceDat.changeProposalStatus(_proposalId, uint8(Governance.ProposalStatus.Denied));
        }
    }

    function getPendingReward(address _memberAddress, uint _lastRewardVoteId)
        public view returns(uint pendingDAppReward)
    {
        uint i;
        uint[] memory totalVotesByMember = governanceDat.getAllVotesByMember(_memberAddress);
        uint voteId;
        uint proposalId;
        for (i = _lastRewardVoteId; i < totalVotesByMember.length; i++) {
            voteId = totalVotesByMember[i];
            if (!governanceDat.rewardClaimed(voteId)) {
                (, , proposalId, ) = governanceDat.getVoteData(voteId);
                pendingDAppReward = SafeMath.add(pendingDAppReward, calculatePendingVoteReward(voteId, proposalId));
            }
        }
    }

    function claimReward(address _memberAddress, uint[] _proposals) 
        public onlyInternal returns(uint pendingDAppReward) 
    {
        uint voteIdThenVoteValue;
        uint finalVerdict;
        uint totalReward;
        uint solutionId;
        uint calcReward;
        uint totalVoteValue;
        uint finalVoteValue;
        for (uint i = 0; i < _proposals.length; i++) {
            voteIdThenVoteValue = governanceDat.getMemberVoteAgainstProposal(_memberAddress, _proposals[i]);
            (, , totalVoteValue, finalVoteValue, , totalReward, finalVerdict) = governanceDat.getProposalDetails(_proposals[i]);
            require(!governanceDat.rewardClaimed(voteIdThenVoteValue), "Reward already claimed for one of the given proposals");

            governanceDat.setRewardClaimed(voteIdThenVoteValue);

            (, solutionId, , voteIdThenVoteValue) = governanceDat.getVoteData(voteIdThenVoteValue);
            //voteIdThenVoteValue holds voteValue
            require(
                governanceDat.getProposalStatus(_proposals[i]) > uint(ProposalStatus.VotingStarted),
                "Reward can be claimed only after the proposal is closed"
            );

            if (governanceDat.punishVoters()) {
                if ((finalVerdict > 0 && solutionId == finalVerdict)) {
                    calcReward = SafeMath.div(SafeMath.mul(voteIdThenVoteValue, totalReward), finalVoteValue);
                }
            } else if (finalVerdict > 0) {
                calcReward = SafeMath.div(SafeMath.mul(voteIdThenVoteValue, totalReward), totalVoteValue);
            }
            
            pendingDAppReward = pendingDAppReward.add(calcReward);
        }

    }

    /// @dev pause a proposal
    function pauseProposal(uint _proposalId) public onlyInternal {
        governanceDat.togglePauseProposal(_proposalId, true);
    }

    /// @dev resume a proposal
    function resumeProposal(uint _proposalId) public onlyInternal {
        require(!governanceDat.proposalPaused(_proposalId));
        governanceDat.togglePauseProposal(_proposalId, false);
    }


    function proposal(uint _proposalId) external returns(uint proposalId, uint category, uint status, uint version, uint finalVerdict, uint totalReward)
    {
        status = governanceDat.getProposalStatus(_proposalId);
        (proposalId, category, finalVerdict, totalReward, ) = governanceDat.getProposalVotingDetails(_proposalId);
        (, , , , version, ) = governanceDat.getProposalDetailsById(_proposalId) ;
    }

    /// @dev Checks if the solution is already added by a member against specific proposal
    /// @param _proposalId Proposal id
    /// @param _memberAddress Member address
    function alreadyAdded(uint _proposalId, address _memberAddress) public view returns(bool) {
        for (uint i = 1; i < governanceDat.getTotalSolutions(_proposalId); i++) {
            if (governanceDat.getSolutionOwnerByProposalIdAndIndex(_proposalId, i) == _memberAddress)
                return true;
        }
    }


    /// @dev checks if the msg.sender has enough tokens locked for creating a proposal or solution
    function validateStake(uint _categoryId, address _memberAddress) public view returns(bool) {
        uint minStake;
        uint tokenHoldingTime;
        (, , , , , , minStake) = proposalCategory.category(_categoryId);
        tokenHoldingTime = governanceDat.tokenHoldingTime();

        if (minStake == 0)
            return true;

        uint lockedTokens = _getLockedBalance(_memberAddress, tokenHoldingTime);
        if (lockedTokens >= minStake)
            return true;
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


    function _createProposal(
        string _proposalTitle,
        string _proposalSD,
        string _proposalDescHash,
        uint _categoryId
    )
        internal
    {
        uint _proposalId = governanceDat.getProposalLength();

        governanceDat.addNewProposal(msg.sender);


        emit Proposal(
            msg.sender,
            _proposalId,
            now,
            _proposalTitle,
            _proposalSD,
            _proposalDescHash
        );
        eventCaller.callProposalCreated(
            _proposalId,
            _categoryId,
            master.dAppName(),
            _proposalDescHash
        );
    }


    function _categorizeProposal(
        uint _proposalId,
        uint _categoryId
    ) 
        internal
    {
        uint defaultIncentive;
        (, , , defaultIncentive) = proposalCategory.categoryAction(_categoryId);

        require(
            defaultIncentive <= GBTStandardToken(dAppLocker).balanceOf(poolAddress),
            "Less token balance in pool for incentive distribution"
        );

        governanceDat.setProposalCategory_Incentive(_proposalId, _categoryId, defaultIncentive);
        governanceDat.changeProposalStatus(_proposalId, uint8(ProposalStatus.AwaitingSolution));
    }


    function _addSolution(uint _proposalId, bytes _action, string _solutionHash)
        internal
    {
        require(!alreadyAdded(_proposalId, msg.sender), "User already added a solution for this proposal");
        governanceDat.setSolutionAdded(_proposalId, msg.sender, _action, _solutionHash);
        emit Solution(_proposalId, msg.sender, governanceDat.getTotalSolutions(_proposalId) - 1, _solutionHash, now);
    }


    /// @dev When creating or submitting proposal with solution, This function open the proposal for voting
    function _proposalSubmission(
        uint _proposalId,
        string _solutionHash,
        bytes _action
    ) 
        internal
    {

        governanceDat.changeProposalStatus(_proposalId, uint8(ProposalStatus.AwaitingSolution));

        _addSolution(
            _proposalId,
            _action,
            _solutionHash
        );

        openProposalForVoting(
            _proposalId
        );
    }

    /// @dev Checks if the vote count against any solution passes the threshold value or not.
    function checkForThreshold(uint _proposalId, uint _category) internal view returns(bool) {
        uint thresHoldValue;
        uint categoryQuorumPerc;
        uint _mrSequenceId;
        (, _mrSequenceId, , categoryQuorumPerc, , , ) = proposalCategory.category(_category);
        if (_mrSequenceId == uint(MemberRoles.Role.TokenHolder)) {
            uint totalTokens;
            GBTStandardToken tokenInstance = GBTStandardToken(dAppLocker);
            uint[] memory voteIds = governanceDat.getProposalVotes(_proposalId);
            for (uint i = 0; i < voteIds.length; i++) {
                address voterAddress;
                (voterAddress, , , ) = governanceDat.getVoteData(voteIds[i]);
                totalTokens = totalTokens.add(tokenInstance.balanceOf(voterAddress));
            }

            thresHoldValue = SafeMath.div(totalTokens.mul(100), tokenInstance.totalSupply());
            if (thresHoldValue > categoryQuorumPerc)
                return true;
        } else if (_mrSequenceId == uint(MemberRoles.Role.UnAssigned)) {
            return true;
        } else {
            thresHoldValue =
                SafeMath.div(
                    SafeMath.mul(
                        governanceDat.getProposalVoteLength(_proposalId),
                        100
                    ),
                    memberRole.numberOfMembers(_mrSequenceId)
                );
            if (thresHoldValue > categoryQuorumPerc)
                return true;
        }
    }

    /// @dev This does the remaining functionality of closing proposal vote
    function closeProposalVoteThReached(uint maxVoteValue, uint totalVoteValue, uint category, uint _proposalId, uint64 max)  //solhint-disable-line
        internal 
    {
        uint _majorityVote;
        bytes2 contractName;
        address actionAddress;
        (, , _majorityVote, , , , ) = proposalCategory.category(category);
        (, actionAddress, contractName, ) = proposalCategory.categoryAction(category);
        if (SafeMath.div(SafeMath.mul(maxVoteValue, 100), totalVoteValue) >= _majorityVote) {
            if (max > 0) {
                governanceDat.updateProposalDetails(_proposalId, max);
                governanceDat.changeProposalStatus(_proposalId, uint8(ProposalStatus.Accepted));
                /*solhint-disable*/
                if (contractName == "MS")
                    actionAddress = address(master);
                else if(contractName !="EX")
                    actionAddress = master.getLatestAddress(contractName);
                /*solhint-enable*/
                if (actionAddress.call(governanceDat.getSolutionActionByProposalId(_proposalId, uint64(max)))) { //solhint-disable-line
                    eventCaller.callActionSuccess(_proposalId);
                }
                eventCaller.callProposalAccepted(_proposalId);
            } else {
                governanceDat.updateProposalDetails(_proposalId, max);
                governanceDat.changeProposalStatus(_proposalId, uint8(ProposalStatus.Rejected));
            }
        } else {
            governanceDat.updateProposalDetails(
                _proposalId, 
                max
            );
            governanceDat.changeProposalStatus(_proposalId, uint8(ProposalStatus.Majority_Not_Reached_But_Accepted)); //solhint-disable-line
        }
    }


    /// @dev validates that the voter has enough tokens locked for voting and returns vote value
    ///     Seperate function from validateStake to save gas.
    function calculateVoteValue(uint32 _proposalId, address _of) 
        internal view returns(uint voteValue) 
    {
        uint tokenHoldingTime;

        tokenHoldingTime = governanceDat.tokenHoldingTime();

        voteValue = _getLockedBalance(_of, tokenHoldingTime);

        voteValue = 
            Math.max(
                SafeMath.div(
                    voteValue, uint256(10) ** GBTStandardToken(dAppLocker).decimals()
                ),
                governanceDat.getMinVoteWeight()
            );
    }

    function _getLockedBalance(address _of, uint _time)
        internal view returns(uint lockedTokens)
    {
        GBTStandardToken tokenInstance = GBTStandardToken(dAppLocker);
        _time += now; //solhint-disable-line
        lockedTokens = tokenInstance.tokensLockedAtTime(_of, "GOV", _time);
    }

    function calculatePendingVoteReward(uint _voteId, uint _proposalId)
        internal
        view
        returns (uint pendingDAppReward)
    {
        uint solutionChosen;
        uint finalVerdict;
        uint voteValue;
        uint totalReward;
        uint calcReward;
        uint finalVoteValue;
        uint totalVoteValue;
        (, solutionChosen, , voteValue) = governanceDat.getVoteData(_voteId);
        (, , finalVerdict, totalReward, ) = 
            governanceDat.getProposalVotingDetails(_voteId);
        (totalVoteValue, finalVoteValue) = governanceDat.getProposalVoteValue(_proposalId);
        if (governanceDat.punishVoters()) {
            if ((finalVerdict > 0 && solutionChosen == finalVerdict)) {
                calcReward = SafeMath.div(SafeMath.mul(voteValue, totalReward), finalVoteValue);
            }
        } else if (finalVerdict > 0) {
            calcReward = SafeMath.div(SafeMath.mul(voteValue, totalReward), totalVoteValue);
        }

        pendingDAppReward = calcReward;
    }

}