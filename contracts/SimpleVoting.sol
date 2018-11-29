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
import "./Governance.sol";
import "./MemberRoles.sol";
import "./Upgradeable.sol";
import "./GBTStandardToken.sol";
import "./ProposalCategory.sol";
import "./Pool.sol";
import "./imports/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./imports/openzeppelin-solidity/contracts/math/Math.sol";
import "./EventCaller.sol";
import "./imports/govern/Governed.sol";


contract SimpleVoting is Upgradeable {
    using SafeMath for uint;
    GovernanceData public governanceDat;
    MemberRoles public memberRole;
    Governance public governance;
    ProposalCategory public proposalCategory;
    bool public constructorCheck;
    Pool public pool;
    EventCaller public eventCaller;
    GovernChecker public governChecker;
    bytes32 public votingTypeName;

    struct ProposalVote {
        address voter;
        uint64 solutionChosen;
        uint32 proposalId;
        uint voteValue;
    }

    mapping(address => mapping(uint => uint)) internal addressProposalVote;
    mapping(uint => uint[]) internal proposalRoleVote;
    mapping(address => uint[]) internal allVotesByMember;
    mapping(uint => bool) public rewardClaimed;


    ProposalVote[] internal allVotes;

    modifier onlySelf {
        require(msg.sender == address(this));
        _;
    }

    /// @dev Initiates add solution 
    /// @param _memberAddress Address of member who is adding the solution
    /// @param _solutionHash Solution hash having required data against adding solution
    function addSolution(
        uint32 _proposalId,
        address _memberAddress, 
        string _solutionHash, 
        bytes _action
    ) 
        external 
    {   
        require(governanceDat.getProposalStatus(_proposalId) >= uint(Governance.ProposalStatus.AwaitingSolution) , "Proposal should be open for solution submission");
        if (msg.sender == _memberAddress) {
            require(validateStake(_proposalId, _memberAddress),"Lock more tokens");
        } else
            require(master.isInternal(msg.sender),"Not authorized");
        require(!alreadyAdded(_proposalId, _memberAddress),"User already added a solution for this proposal");
        governanceDat.setSolutionAdded(_proposalId, _memberAddress, _action);
        uint solutionId = governanceDat.getTotalSolutions(_proposalId);
        governanceDat.callSolutionEvent(_proposalId, _memberAddress, solutionId - 1, _solutionHash, now); //solhint-disable-line

    }

    /// @dev Casts vote
    /// @param _proposalId Proposal id
    /// @param _solutionChosen solution chosen while voting. _solutionChosen[0] is the chosen solution
    function proposalVoting(uint32 _proposalId, uint64[] _solutionChosen) external {
        _addVote(_proposalId, _solutionChosen[0], msg.sender);
    } 

    function initialVote(uint32 _proposalId, address _voter) external onlyInternal {
        _addVote(_proposalId, 1, _voter);
    }

    /// @dev Initiates simple voting contract
    function simpleVotingInitiate() public {
        require(!constructorCheck);
        votingTypeName = "Simple Voting";
        allVotes.push(ProposalVote(address(0), 0, 0, 1));
        rewardClaimed[0] = true;
        constructorCheck = true;
    }

    /// @dev updates dependancies
    function updateDependencyAddresses() public {
        if (!constructorCheck)
            simpleVotingInitiate();
        governanceDat = GovernanceData(master.getLatestAddress("GD"));
        memberRole = MemberRoles(master.getLatestAddress("MR"));
        proposalCategory = ProposalCategory(master.getLatestAddress("PC"));
        governance = Governance(master.getLatestAddress("GV"));
        pool = Pool(master.getLatestAddress("PL"));
        eventCaller = EventCaller(master.getEventCallerAddress());
        governChecker = GovernChecker(master.getGovernCheckerAddress());
    }

    function claimVoteReward(address _memberAddress, uint[] _proposals) 
        public onlyInternal returns(uint pendingGBTReward, uint pendingDAppReward) 
    {
        uint voteId;
        uint finalVerdict;
        uint totalReward;
        uint category;
        uint calcReward;
        uint totalVoteValue;
        uint finalVoteValue;
        for (uint i = 0; i < _proposals.length; i++) {
            voteId = addressProposalVote[_memberAddress][_proposals[i]];
            (totalVoteValue, finalVoteValue) = governanceDat.getProposalVoteValue(_proposals[i]);
            require(!rewardClaimed[voteId], "Reward already claimed for one of the given proposals");

            rewardClaimed[voteId] = true;
            (finalVerdict, totalReward, category) = 
                getVoteDetailsForReward(_proposals[i]);

            require(governanceDat.getProposalStatus(_proposals[i]) > uint(Governance.ProposalStatus.VotingStarted), "Reward can be claimed only after the proposal is closed");

            if(governanceDat.punishVoters()){
                if((finalVerdict > 0 && allVotes[voteId].solutionChosen == finalVerdict)){
                    calcReward = SafeMath.div(SafeMath.mul(allVotes[voteId].voteValue, totalReward),finalVoteValue);
                }
            }
            else if(finalVerdict > 0){
                calcReward = SafeMath.div(SafeMath.mul(allVotes[voteId].voteValue, totalReward),totalVoteValue);
            }
            if (proposalCategory.isCategoryExternal(category))
                pendingGBTReward = pendingGBTReward.add(calcReward);
            else
                pendingDAppReward = pendingDAppReward.add(calcReward);
        }

    }

    function getPendingReward(address _memberAddress, uint _lastRewardVoteId) 
        public view returns(uint pendingGBTReward, uint pendingDAppReward) 
    {
        uint i;
        uint totalVotes = allVotesByMember[_memberAddress].length;
        uint voteId;
        uint proposalId;
        uint tempGBTReward;
        uint tempDAppReward;
        for (i = _lastRewardVoteId; i < totalVotes; i++) {
            voteId = allVotesByMember[_memberAddress][i];
            if (!rewardClaimed[voteId]) {
                proposalId = allVotes[voteId].proposalId;
                (tempGBTReward, tempDAppReward) = calculatePendingVoteReward(voteId, proposalId);
                pendingGBTReward = SafeMath.add(pendingGBTReward, tempGBTReward);
                pendingDAppReward = SafeMath.add(pendingDAppReward, tempDAppReward);
            }
        }
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

    /// @dev gets dApp name 
    function dAppName() public view returns (bytes32) {
        return master.dAppName();
    }

    function getAllVoteIdsByAddress(address _memberAddress) public view returns(uint[]) {
        return allVotesByMember[_memberAddress];
    }

    function getTotalNumberOfVotesByAddress(address _memberAddress) public view returns(uint) {
        return allVotesByMember[_memberAddress].length;
    }

    /// @dev Gets vote details by id such as Vote value, Address of the voter and Solution id for which he has voted.
    function getVoteDetailById(uint _voteId) 
        public 
        view 
        returns(
            address, 
            uint64[], 
            uint,
            uint32
        ) 
    {
        uint64[] memory solutionChosen = new uint64[](1);
        solutionChosen[0] = allVotes[_voteId].solutionChosen;
        return (
            allVotes[_voteId].voter, 
            solutionChosen, 
            allVotes[_voteId].voteValue, 
            allVotes[_voteId].proposalId
        );
    }

    /// @dev Returns the solution index that was being voted
    function getSolutionByVoteId(uint _voteId) public view returns(uint64[]) {
        uint64[] memory solutionChosen = new uint64[](1);
        solutionChosen[0] = allVotes[_voteId].solutionChosen;
        return (solutionChosen);
    }

    /// @dev Gets Solution id against which vote had been casted
    /// @param _solutionChosenId To get solution id at particular index 
    ///     from solutionChosen array i.e. 0 is passed In case of Simple Voting Type.
    function getSolutionByVoteIdAndIndex(uint _voteId, uint _solutionChosenId) 
        public 
        view 
        returns(uint) 
    {
        require(_solutionChosenId == 0);
        
        return (allVotes[_voteId].solutionChosen);
    }

    /// @dev Gets Vote id Against proposal when passing proposal id and member address
    function getVoteIdAgainstMember(address _memberAddress, uint _proposalId) 
        public 
        view 
        returns(uint voteId) 
    {
        voteId = addressProposalVote[_memberAddress][_proposalId];
    }

    /// @dev Gets voter address
    function getVoterAddress(uint _voteId) public view returns(address _voterAddress) {
        return (allVotes[_voteId].voter);
    }

    /// @dev Gets All the Role specific vote ids against proposal 
    /// @return totalVotes Total votes casted by this particular role id.
    function getAllVoteIdsByProposal(uint _proposalId) public view returns(uint[] totalVotes) {
        return proposalRoleVote[_proposalId];
    }

    /// @dev Gets Total number of votes of specific role against proposal
    function getAllVoteIdsLengthByProposal(uint _proposalId) public view returns(uint length) {
        return proposalRoleVote[_proposalId].length;
    }

    /// @dev Gets vote value against Vote id
    function getVoteValue(uint _voteId) public view returns(uint) {
        return (allVotes[_voteId].voteValue);
    }

    /// @dev Gets total number of votes 
    function allVotesTotal() public view returns(uint) {
        return allVotes.length;
    }

    /// @dev Closes Proposal Voting after All voting layers done with voting or Time out happens.
    function closeProposalVote(uint _proposalId) public {
        uint category = governanceDat.getProposalCategory(_proposalId);
        uint64 max;
        uint totalVoteValue;
        uint i;
        uint voteId;
        uint voteValue;
        uint majoritySolutionVoteValue;

        require(checkForClosing(_proposalId, category) == 1);
        uint voteLen = proposalRoleVote[_proposalId].length;
        uint[] memory finalVoteValues = new uint[](governanceDat.getTotalSolutions(_proposalId));
        for (i = 0; i < voteLen; i++) {
            voteId = proposalRoleVote[_proposalId][i];
            voteValue = allVotes[voteId].voteValue;
            totalVoteValue = SafeMath.add(totalVoteValue, voteValue);
            finalVoteValues[allVotes[voteId].solutionChosen] = 
                finalVoteValues[allVotes[voteId].solutionChosen].add(voteValue);
        }
        (voteValue,) = governanceDat.getProposalVoteValue(_proposalId);
        totalVoteValue = SafeMath.add(totalVoteValue, voteValue);

        for (i = 0; i < finalVoteValues.length; i++) {
            if (finalVoteValues[max] < finalVoteValues[i]) {
                max = uint64(i);
            }
        }

        for (i = 0; i < voteLen; i++) {
            voteId = proposalRoleVote[_proposalId][i];
            if(allVotes[voteId].solutionChosen == uint(max)){
                majoritySolutionVoteValue = SafeMath.add(majoritySolutionVoteValue, allVotes[voteId].voteValue);
            }
        }
        governanceDat.setProposalVoteValue(_proposalId, totalVoteValue, majoritySolutionVoteValue);

        if (checkForThreshold(_proposalId, category)) {
            closeProposalVoteThReached(finalVoteValues[max], totalVoteValue, category, _proposalId, max);
        } else {
            governanceDat.updateProposalDetails(_proposalId, max);
            governanceDat.changeProposalStatus(_proposalId, uint8(Governance.ProposalStatus.Denied));
        }
    }

    /// @dev transfers authority and funds to new addresses
    function upgrade() public onlySelf {
        address newSV = master.getLatestAddress("SV");
        if (newSV != address(this)) {
            governChecker.updateAuthorized(master.dAppName(), newSV);
        }
        pool.transferAssets();
    } 

    /// @dev Checks If the proposal voting time is up and it's ready to close 
    ///      i.e. Closevalue is 1 in case of closing, 0 otherwise!
    /// @param _proposalId Proposal id to which closing value is being checked
    function checkForClosing(uint _proposalId, uint _category) 
        public 
        view 
        returns(uint8 closeValue) 
    {
        uint dateUpdate;
        uint pStatus;
        uint _closingTime;
        uint _majorityVote;
        uint _roleId;
        require(!governanceDat.proposalPaused(_proposalId));
        
        (, , dateUpdate, , pStatus) = governanceDat.getProposalDetailsById(_proposalId);
        (,_roleId,_majorityVote,, _closingTime,,) = proposalCategory.getCategoryDetails(_category);
        if (pStatus == uint(Governance.ProposalStatus.VotingStarted) && _roleId != uint(MemberRoles.Role.TokenHolder) && _roleId != uint(MemberRoles.Role.UnAssigned)) {
            if (SafeMath.add(dateUpdate, _closingTime) <= now ||  //solhint-disable-line
                proposalRoleVote[_proposalId].length == memberRole.numberOfMembers(_roleId)
            )
                closeValue = 1;
        } else if (pStatus == uint(Governance.ProposalStatus.VotingStarted)) {
            if (SafeMath.add(dateUpdate, _closingTime) <= now) //solhint-disable-line
                closeValue = 1;
        } else if (pStatus > uint(Governance.ProposalStatus.VotingStarted)) {
            closeValue = 2;
        } else {
            closeValue = 0;
        }
    }

    /// @dev This does the remaining functionality of closing proposal vote
    function closeProposalVoteThReached(uint maxVoteValue, uint totalVoteValue, uint category, uint _proposalId, uint64 max) 
        internal 
    {
        uint _closingTime;
        uint _majorityVote;
        bytes2 contractName;
        address actionAddress;
        (,,_majorityVote,, _closingTime,,) = proposalCategory.getCategoryDetails(category);
        (,actionAddress, contractName,) = proposalCategory.getCategoryActionDetails(category);
        if (SafeMath.div(SafeMath.mul(maxVoteValue, 100), totalVoteValue) >= _majorityVote) {
            if (max > 0) {
                governanceDat.updateProposalDetails(_proposalId, max);
                governanceDat.changeProposalStatus(_proposalId, uint8(Governance.ProposalStatus.Accepted));
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
                governanceDat.changeProposalStatus(_proposalId, uint8(Governance.ProposalStatus.Rejected));
            }
        } else {
            governanceDat.updateProposalDetails(
                _proposalId, 
                max
            );
            governanceDat.changeProposalStatus(_proposalId, uint8(Governance.ProposalStatus.Majority_Not_Reached_But_Accepted));
        }
    }

    /// @dev Checks if the vote count against any solution passes the threshold value or not.
    function checkForThreshold(uint _proposalId, uint _category) internal view returns(bool) {
        uint thresHoldValue;
        uint categoryQuorumPerc;
        uint _mrSequenceId;
        (,_mrSequenceId,,,,,) = proposalCategory.getCategoryDetails(_category);
        (, categoryQuorumPerc) = proposalCategory.getCategoryQuorumPercent(_category);
        if (_mrSequenceId == uint(MemberRoles.Role.TokenHolder)) {
            uint totalTokens;
            address token = governanceDat.getStakeToken(_proposalId);
            GBTStandardToken tokenInstance = GBTStandardToken(token);
            for (uint i = 0; i < proposalRoleVote[_proposalId].length; i++) {
                uint voteId = proposalRoleVote[_proposalId][i];
                address voterAddress = allVotes[voteId].voter;
                totalTokens = totalTokens.add(tokenInstance.balanceOf(voterAddress));
            }

            thresHoldValue = SafeMath.div(totalTokens.mul(100), tokenInstance.totalSupply());
            if (thresHoldValue > categoryQuorumPerc)
                return true;
        } else if (_mrSequenceId == uint(MemberRoles.Role.UnAssigned)) {
            return true;
        } else {
            thresHoldValue = SafeMath.div(SafeMath.mul(getAllVoteIdsLengthByProposal(_proposalId), 100), memberRole.numberOfMembers(_mrSequenceId));
            if (thresHoldValue > categoryQuorumPerc)
                return true;
        }
    }

    function calculatePendingVoteReward(uint _voteId, uint _proposalId) 
        internal
        view
        returns (uint pendingGBTReward, uint pendingDAppReward) 
    {
        uint solutionChosen;
        uint finalVerdict;
        uint voteValue;
        uint totalReward;
        uint category;
        uint calcReward;
        uint finalVoteValue;
        uint totalVoteValue;
        (solutionChosen,, finalVerdict, voteValue, totalReward, category) = 
            getVoteDetailsToCalculateReward(_voteId);
        (totalVoteValue,finalVoteValue) = governanceDat.getProposalVoteValue(_proposalId);
        if(governanceDat.punishVoters()){
            if((finalVerdict > 0 && allVotes[_voteId].solutionChosen == finalVerdict)){
                calcReward = SafeMath.div(SafeMath.mul(allVotes[_voteId].voteValue, totalReward),finalVoteValue);
            }   
        }
        else if(finalVerdict > 0){
            calcReward = SafeMath.div(SafeMath.mul(allVotes[_voteId].voteValue, totalReward),totalVoteValue);
        }
        if (proposalCategory.isCategoryExternal(category))    
            pendingGBTReward = calcReward;
        else
            pendingDAppReward = calcReward;
    }

    /// @dev Gets vote id details when giving member address and proposal id
    function getVoteDetailsToCalculateReward(
        uint _voteId
    ) 
        internal 
        view 
        returns(
            uint solutionChosen, 
            uint proposalStatus, 
            uint finalVerdict, 
            uint voteValue, 
            uint totalReward, 
            uint category
        ) 
    {
        uint proposalId = allVotes[_voteId].proposalId;
        voteValue = allVotes[_voteId].voteValue;
        solutionChosen = allVotes[_voteId].solutionChosen;
        proposalStatus = governanceDat.getProposalStatus(proposalId);
        finalVerdict = governanceDat.getProposalFinalVerdict(proposalId);
        totalReward = governanceDat.getProposalIncentive(proposalId);
        category = governanceDat.getProposalCategory(proposalId);
    }

    /// @dev Gets vote id details for reward
    function getVoteDetailsForReward(uint _proposalId) 
        internal 
        view 
        returns(
            uint finalVerdict, 
            uint totalReward, 
            uint category
        ) 
    {
        finalVerdict = governanceDat.getProposalFinalVerdict(_proposalId);
        totalReward = governanceDat.getProposalIncentive(_proposalId);
        category = governanceDat.getProposalCategory(_proposalId);
    }

    function _getLockedBalance(address _token, address _of, uint _time) 
        internal view returns(uint lockedTokens) 
    {
        GBTStandardToken tokenInstance = GBTStandardToken(_token);
        _time += now; //solhint-disable-line
        lockedTokens = tokenInstance.tokensLockedAtTime(_of, "GOV", _time);
    }

    function _addVote(uint32 _proposalId, uint64 _solution, address _voter) internal {
        //Variables are reused to save gas. We know that this reduces code readability but proposalVoting is
        //where gas usage should be optimized as much as possible. voters should not feel burdened while voting.
        require(addressProposalVote[_voter][_proposalId] == 0);

        require (governanceDat.getProposalStatus(_proposalId) == uint(Governance.ProposalStatus.VotingStarted));

        require(validateStake(_proposalId, _voter));

        uint categoryThenMRSequence;
        uint voteValue;

        (categoryThenMRSequence) 
            = governanceDat.getProposalCategory(_proposalId);

        (,categoryThenMRSequence,,,,,) = proposalCategory.getCategoryDetails(categoryThenMRSequence);
        //categoryThenMRSequence is now MemberRoleSequence

        require(memberRole.checkRole(_voter, categoryThenMRSequence));
        require(_solution <= governanceDat.getTotalSolutions(_proposalId));

        voteValue = calculateVoteValue(_proposalId, _voter);

        proposalRoleVote[_proposalId].push(allVotes.length);
        allVotesByMember[_voter].push(allVotes.length);
        addressProposalVote[_voter][_proposalId] = allVotes.length;
        governanceDat.callVoteEvent(_voter, _proposalId, now, allVotes.length); //solhint-disable-line
        allVotes.push(ProposalVote(_voter, _solution, _proposalId, voteValue));

        if (proposalRoleVote[_proposalId].length
            == memberRole.numberOfMembers(categoryThenMRSequence) 
            && categoryThenMRSequence != 2
            && categoryThenMRSequence != 0
        ) {
            eventCaller.callVoteCast(_proposalId);
        }
    }

    /// @dev validates that the voter has enough tokens locked for voting
    function validateStake(uint32 _proposalId, address _of) internal view returns(bool) {
        address token;
        uint category;
        uint minStake;
        uint tokenHoldingTime;
        (token, category) = governanceDat.getTokenAndCategory(_proposalId);
        (,,,,, tokenHoldingTime, minStake) = proposalCategory.getCategoryDetails(category);

        if (minStake == 0)
            return true; 
        
        if (_getLockedBalance(token, _of, tokenHoldingTime) >= minStake)
            return true;
    }

    /// @dev validates that the voter has enough tokens locked for voting and returns vote value
    ///     Seperate function from validateStake to save gas.
    function calculateVoteValue(uint32 _proposalId, address _of) 
        internal view returns(uint voteValue) 
    {
        address token;
        uint category;
        uint tokenHoldingTime;

        (token, category) 
            = governanceDat.getTokenAndCategory(_proposalId);
        (,,,,,tokenHoldingTime,) = proposalCategory.getCategoryDetails(category);

        voteValue = _getLockedBalance(token, _of, tokenHoldingTime);

        voteValue = Math.max((SafeMath.div(voteValue, uint256(10) ** GBTStandardToken(token).decimals())),governanceDat.getMinVoteWeight());

    }
    
}
