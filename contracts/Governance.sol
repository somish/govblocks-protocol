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
        Denied
    }

    struct ProposalStruct {
        address owner;
        uint dateUpd;
    }

    struct ProposalData {
        uint8 propStatus;
        uint64 finalVerdict;
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
        uint64 solutionChosen;
        uint32 proposalId;
        uint voteValue;
    }

    mapping(uint => ProposalData) internal allProposalData;
    mapping(uint => SolutionStruct[]) internal allProposalSolutions;
    mapping(uint => uint) internal proposalVersion;
    mapping(address => mapping(uint => uint)) internal addressProposalVote;
    mapping(uint => uint[]) internal proposalVote;
    mapping(address => uint[]) internal allVotesByMember;
    mapping(uint => bool) public proposalPaused;
    mapping(uint => bool) public rewardClaimed; //can read from event

    ProposalStruct[] internal allProposal;
    ProposalVote[] internal allVotes;

    bool internal punishVoters;
    uint internal minVoteWeight;
    uint internal tokenHoldingTime;


    address internal poolAddress;
    MemberRoles internal memberRole;
    ProposalCategory internal proposalCategory;
    EventCaller internal eventCaller;
    address internal dAppLocker;

    modifier onlyProposalOwner(uint _proposalId) {
        require(msg.sender == allProposal[_proposalId].owner, "Not authorized");
        _;
    }

    modifier checkProposalValidity(uint _proposalId) {
        require(allProposalData[_proposalId].propStatus < uint(ProposalStatus.VotingStarted));
        _;
    }

    modifier isAllowed(uint _categoryId){
        require(allowedToCreateProposal(_categoryId), "Not authorized");
        require(validateStake(_categoryId, msg.sender), "Lock more tokens");
        _;
    }

    /// @dev updates all dependency addresses to latest ones from Master
    function updateDependencyAddresses() public {
        dAppLocker = master.dAppLocker();
        memberRole = MemberRoles(master.getLatestAddress("MR"));
        proposalCategory = ProposalCategory(master.getLatestAddress("PC"));
        poolAddress = master.getLatestAddress("PL");
        eventCaller = EventCaller(master.getEventCallerAddress());
    }


    function callRewardClaimed(
        address _member,
        uint[] _voterProposals,
        uint _gbtReward,
        uint _reputation
    ) 
        external
        onlyInternal 
    {
        emit RewardClaimed(
            _member,
            _voterProposals, 
            _gbtReward,
            _reputation
        );
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
    function updateProposal(
        uint _proposalId, 
        string _proposalTitle, 
        string _proposalSD, 
        string _proposalDescHash
    ) 
        external onlyProposalOwner(_proposalId)
    {
        require(
            allProposalSolutions[_proposalId].length < 2,
            "Solutions had already been submitted"
        );
        proposalVersion[_proposalId] = SafeMath.add(proposalVersion[_proposalId], 1);
        updateProposalStatus(_proposalId, uint8(ProposalStatus.Draft));
        allProposalData[_proposalId].category = 0;
        allProposalData[_proposalId].commonIncentive = 0;
        emit Proposal(
            allProposal[_proposalId].owner,
            _proposalId,
            now,
            _proposalTitle, 
            _proposalSD, 
            _proposalDescHash
        );
    }

    /// @dev Categorizes proposal to proceed further. Categories shows the proposal objective.
    function categorizeProposal(
        uint _proposalId,
        uint _categoryId
    )
        external
        checkProposalValidity(_proposalId) isAllowed(_categoryId)
    {

        require(
            allProposalSolutions[_proposalId].length < 2,
            "Solutions had already been submitted"
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
            allProposalData[_proposalId].propStatus >= uint(Governance.ProposalStatus.AwaitingSolution),
            "Open proposal for solution submission"
        );
        require(validateStake(allProposalData[_proposalId].category, msg.sender), "Lock more tokens");

        _addSolution( _proposalId, _action, _solutionHash);
    }

    /// @dev Opens proposal for voting
    function openProposalForVoting(uint _proposalId)
        public onlyProposalOwner(_proposalId) checkProposalValidity(_proposalId)
    {
        uint category = allProposalData[_proposalId].category;

        require(category != 0, "Categorize the proposal");

        require(
            allProposalSolutions[_proposalId].length > 1,
            "Add more solutions"
        );
        updateProposalStatus(_proposalId, uint8(ProposalStatus.VotingStarted));
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

        uint proposalId = allProposal.length;

        _createProposal(_proposalTitle, _proposalSD, _proposalDescHash, _categoryId);

        _categorizeProposal(proposalId, _categoryId);

        _proposalSubmission(
            proposalId,
            _solutionHash,
            _action
        );

        submitVote(uint32(proposalId), 1);
    }


    function submitVote(uint32 _proposalId, uint64 _solution) public {
        //Variables are reused to save gas. We know that this reduces code readability but proposalVoting is
        //where gas usage should be optimized as much as possible. voters should not feel burdened while voting.
        require(addressProposalVote[msg.sender][_proposalId] == 0);

        require(allProposalData[_proposalId].propStatus == uint(Governance.ProposalStatus.VotingStarted));

        uint categoryThenMRSequence;
        uint voteValue;

        (categoryThenMRSequence) 
            = allProposalData[_proposalId].category;

        require(validateStake(categoryThenMRSequence, msg.sender));

        (, categoryThenMRSequence, , , , , ) = proposalCategory.category(categoryThenMRSequence);
        //categoryThenMRSequence is now MemberRoleSequence

        require(memberRole.checkRole(msg.sender, categoryThenMRSequence));
        require(_solution <= allProposalSolutions[_proposalId].length);

        voteValue = calculateVoteValue(msg.sender);

        // governanceDat.setProposalVote(_proposalId, msg.sender, _solution, voteValue);
        proposalVote[_proposalId].push(allVotes.length);
        allVotesByMember[msg.sender].push(allVotes.length);
        addressProposalVote[msg.sender][_proposalId] = allVotes.length;
        allVotes.push(ProposalVote(msg.sender, uint64(_solution), uint32(_proposalId), voteValue));
        emit Vote(msg.sender, _proposalId, now, proposalVote[_proposalId].length - 1, _solution);
        if (proposalVote[_proposalId].length == memberRole.numberOfMembers(categoryThenMRSequence) &&
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
        internal 
        view 
        returns(uint8 closeValue)
    {
        uint dateUpdate;
        uint pStatus;
        uint _closingTime;
        uint _roleId;
        uint _category;
        require(!proposalPaused[_proposalId]);
        _category = allProposalData[_proposalId].category;
        pStatus = allProposalData[_proposalId].propStatus;
        dateUpdate =  allProposal[_proposalId].dateUpd;
        // (, _category, , dateUpdate, , pStatus) = governanceDat.getProposalDetailsById(_proposalId);
        (, _roleId, , , , _closingTime, ) = proposalCategory.category(_category);
        if (
            pStatus == uint(ProposalStatus.VotingStarted) &&
            _roleId != uint(MemberRoles.Role.TokenHolder) &&
            _roleId != uint(MemberRoles.Role.UnAssigned)
        ) {
            if (SafeMath.add(dateUpdate, _closingTime) <= now ||  //solhint-disable-line
                proposalVote[_proposalId].length == memberRole.numberOfMembers(_roleId)
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
        uint category = allProposalData[_proposalId].category;
        uint64 max;
        uint totalVoteValue;
        uint i;
        uint solutionId;
        uint voteValue;

        require(canCloseProposal(_proposalId) == 1);
        uint[] memory voteIds = proposalVote[_proposalId];
        uint[] memory finalVoteValues = new uint[](allProposalSolutions[_proposalId].length);
        for (i = 0; i < voteIds.length; i++) {
            solutionId = allVotes[i].solutionChosen;
            voteValue = allVotes[i].voteValue;
            // (, solutionId, , voteValue) = governanceDat.getVoteData(voteIds[i]);
            totalVoteValue = SafeMath.add(totalVoteValue, voteValue);
            finalVoteValues[solutionId] = finalVoteValues[solutionId].add(voteValue);
            if (finalVoteValues[max] < finalVoteValues[solutionId]) {
                max = uint64(solutionId);
            }
        }
        voteValue = allProposalData[_proposalId].totalVoteValue;
        // (voteValue,) = governanceDat.getProposalVoteValue(_proposalId);
        totalVoteValue = SafeMath.add(totalVoteValue, voteValue);

        allProposalData[_proposalId].totalVoteValue = totalVoteValue;
        allProposalData[_proposalId].majVoteValue = finalVoteValues[max];
        // governanceDat.setProposalVoteValue(_proposalId, totalVoteValue, finalVoteValues[max]);

        if (checkForThreshold(_proposalId, category)) {
            closeProposalVoteThReached(finalVoteValues[max], totalVoteValue, category, _proposalId, max);
        } else {
            allProposalData[_proposalId].finalVerdict = max;
            updateProposalStatus(_proposalId, uint8(ProposalStatus.Denied));
            // governanceDat.updateProposalDetails(_proposalId, max);
            // governanceDat.changeProposalStatus(_proposalId, uint8(Governance.ProposalStatus.Denied));
        }
    }

    function getPendingReward(address _memberAddress, uint _lastRewardVoteId)
        public view returns(uint pendingDAppReward)
    {
        uint i;
        uint[] memory votesByMember = allVotesByMember[_memberAddress];
        uint proposalId;
        for (i = _lastRewardVoteId; i < votesByMember.length; i++) {
            if (!rewardClaimed[votesByMember[i]]) {
                proposalId = allVotes[votesByMember[i]].proposalId;
                pendingDAppReward = SafeMath.add(pendingDAppReward, calculatePendingVoteReward(votesByMember[i], proposalId));
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
            voteIdThenVoteValue = addressProposalVote[_memberAddress][_proposals[i]];
            totalVoteValue = allProposalData[_proposals[i]].totalVoteValue;
            finalVoteValue = allProposalData[_proposals[i]].majVoteValue;
            totalReward = allProposalData[_proposals[i]].commonIncentive;
            finalVerdict = allProposalData[_proposals[i]].finalVerdict;
            // (, , totalVoteValue, finalVoteValue, , totalReward, finalVerdict) = governanceDat.getProposalDetails(_proposals[i]);
            require(!rewardClaimed[voteIdThenVoteValue], "Reward already claimed");
            rewardClaimed[voteIdThenVoteValue] = true;
            // governanceDat.setRewardClaimed(voteIdThenVoteValue);

            solutionId = allVotes[voteIdThenVoteValue].solutionChosen;
            voteIdThenVoteValue = allVotes[voteIdThenVoteValue].voteValue;
            // (, solutionId, , voteIdThenVoteValue) = governanceDat.getVoteData(voteIdThenVoteValue);
            //voteIdThenVoteValue holds voteValue
            require(
                allProposalData[_proposals[i]].propStatus > uint(ProposalStatus.VotingStarted),
                "Reward can be claimed only after the proposal is closed"
            );

            if (punishVoters) {
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
        proposalPaused[_proposalId] = true;
        allProposal[_proposalId].dateUpd = now;
    }

    /// @dev resume a proposal
    function resumeProposal(uint _proposalId) public onlyInternal {
        require(!proposalPaused[_proposalId]);
        proposalPaused[_proposalId] = false;
        allProposal[_proposalId].dateUpd = now;
    }


    function proposal(uint _proposalId) external returns(uint, uint, uint, uint, uint, uint)
    {
        return(
            _proposalId,
            allProposalData[_proposalId].category,
            allProposalData[_proposalId].propStatus,
            proposalVersion[_proposalId],
            allProposalData[_proposalId].finalVerdict,
            allProposalData[_proposalId].commonIncentive
        );
    }

    /// @dev Checks if the solution is already added by a member against specific proposal
    /// @param _proposalId Proposal id
    /// @param _memberAddress Member address
    function alreadyAdded(uint _proposalId, address _memberAddress) public view returns(bool) {
        for (uint i = 1; i < allProposalSolutions[_proposalId].length; i++) {
            if (allProposalSolutions[_proposalId][i].owner == _memberAddress)
                return true;
        }
    }


    /// @dev checks if the msg.sender has enough tokens locked for creating a proposal or solution
    function validateStake(uint _categoryId, address _memberAddress) internal view returns(bool) {
        uint minStake;
        (, , , , , , minStake) = proposalCategory.category(_categoryId);

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
        uint _proposalId = allProposal.length;

        allProposalSolutions[allProposal.length].push(SolutionStruct(address(0), ""));
        allProposal.push(ProposalStruct(msg.sender, now));


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

        allProposalData[_proposalId].category = _categoryId;
        allProposalData[_proposalId].commonIncentive = defaultIncentive;
        updateProposalStatus(_proposalId, uint8(ProposalStatus.AwaitingSolution));
        // governanceDat.setProposalCategory_Incentive(_proposalId, _categoryId, defaultIncentive);
        // governanceDat.changeProposalStatus(_proposalId, uint8(ProposalStatus.AwaitingSolution));
    }


    function _addSolution(uint _proposalId, bytes _action, string _solutionHash)
        internal
    {
        require(!alreadyAdded(_proposalId, msg.sender), "User already added a solution for this proposal");
        // governanceDat.setSolutionAdded(_proposalId, msg.sender, _action, _solutionHash);
        allProposalSolutions[_proposalId].push(SolutionStruct(msg.sender, _action));
        emit Solution(_proposalId, msg.sender, allProposalSolutions[_proposalId].length - 1, _solutionHash, now);
    }


    /// @dev When creating or submitting proposal with solution, This function open the proposal for voting
    function _proposalSubmission(
        uint _proposalId,
        string _solutionHash,
        bytes _action
    ) 
        internal
    {

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
            for (uint i = 0; i < proposalVote[_proposalId].length; i++) {
                totalTokens = totalTokens.add(tokenInstance.balanceOf(allVotes[proposalVote[_proposalId][i]].voter));
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
                        proposalVote[_proposalId].length,
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
        allProposalData[_proposalId].finalVerdict = max;
        (, , _majorityVote, , , , ) = proposalCategory.category(category);
        (, actionAddress, contractName, ) = proposalCategory.categoryAction(category);
        if (SafeMath.div(SafeMath.mul(maxVoteValue, 100), totalVoteValue) >= _majorityVote) {
            if (max > 0) {
                // allProposalData[_proposalId].propStatus = uint8(ProposalStatus.Accepted);
                updateProposalStatus(_proposalId, uint8(ProposalStatus.Accepted));
                // governanceDat.updateProposalDetails(_proposalId, max);
                // governanceDat.changeProposalStatus(_proposalId, uint8(ProposalStatus.Accepted));
                /*solhint-disable*/
                if (contractName == "MS")
                    actionAddress = address(master);
                else if(contractName !="EX")
                    actionAddress = master.getLatestAddress(contractName);
                /*solhint-enable*/
                if (actionAddress.call(allProposalSolutions[_proposalId][uint64(max)].action)) { //solhint-disable-line
                    eventCaller.callActionSuccess(_proposalId);
                }
                eventCaller.callProposalAccepted(_proposalId);
            } else {
                // allProposalData[_proposalId].propStatus = uint8(ProposalStatus.Rejected);
                updateProposalStatus(_proposalId, uint8(ProposalStatus.Rejected));
                // governanceDat.updateProposalDetails(_proposalId, max);
                // governanceDat.changeProposalStatus(_proposalId, uint8(ProposalStatus.Rejected));
            }
        } else {
            // allProposalData[_proposalId].propStatus = uint8(ProposalStatus.Majority_Not_Reached_But_Accepted);
            updateProposalStatus(_proposalId, uint8(ProposalStatus.Majority_Not_Reached_But_Accepted));
            // governanceDat.updateProposalDetails(
            //     _proposalId, 
            //     max
            // );
            // governanceDat.changeProposalStatus(_proposalId, uint8(ProposalStatus.Majority_Not_Reached_But_Accepted)); //solhint-disable-line
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
                SafeMath.div(
                    voteValue, uint256(10) ** GBTStandardToken(dAppLocker).decimals()
                ),
                minVoteWeight
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
        solutionChosen = allVotes[_voteId].solutionChosen;
        voteValue = allVotes[_voteId].voteValue;
        // (, solutionChosen, , voteValue) = governanceDat.getVoteData(_voteId);
        finalVerdict = allProposalData[_proposalId].finalVerdict;
        totalReward = allProposalData[_proposalId].commonIncentive;
        totalVoteValue = allProposalData[_proposalId].totalVoteValue;
        finalVoteValue = allProposalData[_proposalId].majVoteValue;
        // (, , finalVerdict, totalReward, ) = 
        //     governanceDat.getProposalVotingDetails(_proposalId);
        // (totalVoteValue, finalVoteValue) = governanceDat.getProposalVoteValue(_proposalId);
        if (punishVoters) {
            if ((finalVerdict > 0 && solutionChosen == finalVerdict)) {
                calcReward = SafeMath.div(SafeMath.mul(voteValue, totalReward), finalVoteValue);
            }
        } else if (finalVerdict > 0) {
            calcReward = SafeMath.div(SafeMath.mul(voteValue, totalReward), totalVoteValue);
        }

        pendingDAppReward = calcReward;
    }

    function updateProposalStatus(uint _proposalId,uint8 _status) internal{
        allProposal[_proposalId].dateUpd = now;
        allProposalData[_proposalId].propStatus = _status;
    }

    function configureGlobalParameters(bytes8 _typeOf, uint _value) internal {
        if(_typeOf == "MV"){
            minVoteWeight = _value;
        }
        else if(_typeOf == "TH"){
            tokenHoldingTime = _value;
        }
    }

    function setPunishVoters(bool _punish) internal {
        punishVoters = _punish;
    }

    function getGlobalParameters() view external returns(uint, uint, bool) {
        return(
            minVoteWeight,
            tokenHoldingTime,
            punishVoters
        );
    }

    function getSolutionAction(uint _proposalId, uint _solution) view external returns(uint, bytes){
        return (
            _solution,
            allProposalSolutions[_proposalId][_solution].action
            );
    }

    /// @dev Gets statuses of proposals
    /// @param _proposalLength Total proposals created till now.
    /// @param _draftProposals Proposal that are currently in draft or still getting updated.
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
                _draftProposals = SafeMath.add(_draftProposals, 1);
            } else if (proposalStatus == uint(ProposalStatus.AwaitingSolution)) {
                _awaitingSolution = SafeMath.add(_awaitingSolution, 1);
            } else if (proposalStatus == uint(ProposalStatus.VotingStarted)) {
                _pendingProposals = SafeMath.add(_pendingProposals, 1);
            } else if (proposalStatus == uint(ProposalStatus.Accepted) || proposalStatus == uint(ProposalStatus.Majority_Not_Reached_But_Accepted)) { //solhint-disable-line
                _acceptedProposals = SafeMath.add(_acceptedProposals, 1);
            } else {
                _rejectedProposals = SafeMath.add(_rejectedProposals, 1);
            }
        }
    }

    function getProposalLength() external view returns(uint){
        allProposal.length;
    }


}