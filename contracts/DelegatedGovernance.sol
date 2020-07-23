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
import "./Governance.sol";

contract DelegatedGovernance is Governance {

    struct DelegateVote {
        address follower;
        address leader;
        uint lastUpd;
    }

    mapping (address => uint) public lastRewardClaimed;
    mapping (address => uint) public followerDelegation;
    mapping (address => uint[]) internal leaderDelegation;
    mapping (address => bool) public isOpenForDelegation;
    mapping (address => uint) internal followerCount;

    DelegateVote[] public allDelegation;

    uint public maxFollowers;

    modifier checkPendingRewards {
        require(getPendingReward(msg.sender) == 0, "Claim pending rewards");
        _;
    }
    
    function remove_changeTokenHoldingTime(uint _time) public {
        tokenHoldingTime = _time;
    }

    /**
     * @dev get followers of an address
     * @return get followers of an address
     */
    function getFollowers(address _add) external view returns(uint[] memory) {
        return leaderDelegation[_add];
    }

    /**
     * @dev to know if an address is already delegated
     * @param _add in concern
     * @return bool value if the address is delegated or not
     */
    function alreadyDelegated(address _add) public view returns(bool delegated) {
        for (uint i=0; i < leaderDelegation[_add].length; i++) {
            if (allDelegation[leaderDelegation[_add][i]].leader == _add) {
                return true;
            }
        }
    }

    /**
     * @dev Used to set delegation acceptance status of individual user
     * @param _status delegation acceptance status
     */
    function setDelegationStatus(bool _status) external checkPendingRewards {
        isOpenForDelegation[msg.sender] = _status;
    }

    /**
     * @dev to delegate vote to an address.
     * @param _add is the address to delegate vote to.
     */
    function delegateVote(address _add) external checkPendingRewards {
        //Check if given address is not a follower
        require(allDelegation[followerDelegation[_add]].leader == address(0));

        if (followerDelegation[msg.sender] > 0) {
            require(SafeMath.add(allDelegation[followerDelegation[msg.sender]].lastUpd, tokenHoldingTime) < now);
        }

        require(!alreadyDelegated(msg.sender), "Already a leader");
        require(!memberRole.checkRole(msg.sender, uint(MemberRoles.Role.AdvisoryBoard)));


        require(followerCount[_add] < maxFollowers);
        
        if (allVotesByMember[msg.sender].length > 0) {
            uint memberLastVoteId = SafeMath.sub(allVotesByMember[msg.sender].length, 1);
            require(SafeMath.add(allVotes[allVotesByMember[msg.sender][memberLastVoteId]].dateAdd, tokenHoldingTime)
            < now);
        }

        // require(getPendingReward(msg.sender) == 0);

        
        require(memberRole.roles(_add).length > 0);
        require(memberRole.roles(msg.sender).length > 0);

        require(isOpenForDelegation[_add]);

        allDelegation.push(DelegateVote(msg.sender, _add, now));
        followerDelegation[msg.sender] = allDelegation.length - 1;
        leaderDelegation[_add].push(allDelegation.length - 1);
        followerCount[_add]++;
        lastRewardClaimed[msg.sender] = allVotesByMember[_add].length;
    }

    /**
     * @dev Undelegates the sender
     */
    function unDelegate() external checkPendingRewards {
        uint followerId = followerDelegation[msg.sender];
        if (followerId > 0) {

            followerCount[allDelegation[followerId].leader]--;
            allDelegation[followerId].leader = address(0);
            allDelegation[followerId].lastUpd = now;

            lastRewardClaimed[msg.sender] = allVotesByMember[msg.sender].length;
        }
    }

    function initiateGovernance(bool _punishVoters, uint _actionWaitingTime) public {
        super.initiateGovernance(_punishVoters, _actionWaitingTime);
        allDelegation.push(DelegateVote(address(0), address(0), now));
        maxFollowers = 40;
    }

    function updateUintParameters(bytes8 _code, uint _value) public {
        if(_code == "MAXFOL") {
            maxFollowers = _value;
        } else {
            super.updateUintParameters(_code, _value);
        }
    }

    function getUintParameters(bytes8 _code) public view returns(bytes8, uint) {
        if(_code == "MAXFOL") {
            return (_code, maxFollowers);
        } else {
            return super.getUintParameters(_code);
        }
    }

    /// @dev Get number of token incentives to be claimed by a member
    /// @param _memberAddress address  of member to calculate pending reward 
    // function getPendingReward(address _memberAddress)
    //     public view returns(uint pendingDAppReward)
    // {

    //     uint delegationId = followerDelegation[_memberAddress];
    //     address leader;
    //     uint lastUpd;
    //     if (delegationId > 0 && allDelegation[delegationId].leader != address(0)) {
    //         leader = allDelegation[delegationId].leader;
    //         lastUpd = allDelegation[delegationId].lastUpd;
    //     } else
    //         leader = _memberAddress;

    //     uint i;
    //     uint totalVotes = allVotesByMember[leader].length;
    //     uint proposalId;
    //     uint voteId;
    //     uint finalVerdict;
    //     uint proposalVoteValue;
    //     for (i = lastRewardClaimed[leader]; i < totalVotes; i++) {
    //         voteId = allVotesByMember[leader][i];
    //         proposalId = allVotes[voteId].proposalId;
    //         finalVerdict = allProposalData[proposalId].finalVerdict;
    //         if (punishVoters) {
    //             if (allVotes[voteId].solutionChosen != finalVerdict) {
    //                 continue;
    //             }
    //             proposalVoteValue = allProposalData[proposalId].majVoteValue;
    //         } else {
    //             proposalVoteValue = allProposalData[proposalId].totalVoteValue;
    //         }
    //         if (finalVerdict > 0 && (allVotes[allVotesByMember[leader][i]].dateAdd > (
    //             lastUpd + tokenHoldingTime) || leader == _memberAddress)) {
    //             if (!rewardClaimed[voteId]) {
    //                 pendingDAppReward += SafeMath.div(
    //                                 SafeMath.mul(
    //                                     allVotes[voteId].voteValue,
    //                                     allProposalData[proposalId].commonIncentive
    //                                 ),
    //                                 proposalVoteValue
    //                             );
    //             }
    //         }
    //     }
    // }

    /// @dev Internal call for addig a vote to solution
    function _submitVote(uint _proposalId, uint _solution) internal {

        uint delegationId = followerDelegation[msg.sender];

        uint mrSequence;
        uint totalVotes = allVotes.length;
        (, mrSequence, , , , , ) = proposalCategory.category(allProposalData[_proposalId].category);

        require((delegationId == 0) || (delegationId > 0 && allDelegation[delegationId].leader == address(0) && 
        _checkLastUpd(allDelegation[delegationId].lastUpd)));

        require(memberRole.checkRole(msg.sender, mrSequence));

        proposalVote[_proposalId].push(totalVotes);
        allVotesByMember[msg.sender].push(totalVotes);
        addressProposalVote[msg.sender][_proposalId] = totalVotes;
        allVotes.push(ProposalVote(msg.sender, _solution, _proposalId, calculateVoteValue(msg.sender), now));

        emit Vote(msg.sender, _proposalId, totalVotes, now, _solution);

         _countFollowerVotes(_proposalId,_solution, mrSequence);

        if (proposalVote[_proposalId].length == memberRole.numberOfMembers(mrSequence) &&
            mrSequence != uint(MemberRoles.Role.TokenHolder) &&
            mrSequence != uint(MemberRoles.Role.UnAssigned)
        ) {
            emit VoteCast(_proposalId);
        }
    }

    function _countFollowerVotes(uint _proposalId, uint _solution, uint mrSequence) internal {
        address _follower;
        uint totalVotes;
        uint delegationId;
        for (uint i = 0; i < leaderDelegation[msg.sender].length; i++) {
            delegationId = leaderDelegation[msg.sender][i];
            if (allDelegation[delegationId].leader == msg.sender && 
            _checkLastUpd(allDelegation[delegationId].lastUpd)) {
                _follower = allDelegation[delegationId].follower;
                if (memberRole.checkRole(_follower, mrSequence)) {
                    totalVotes = allVotes.length;
                    proposalVote[_proposalId].push(totalVotes);
                    allVotesByMember[_follower].push(totalVotes);
                    addressProposalVote[_follower][_proposalId] = totalVotes;
                    allVotes.push(ProposalVote(_follower, _solution, _proposalId, calculateVoteValue(_follower), now));
                    emit Vote(_follower, _proposalId, totalVotes, now, _solution);
                }
            }
        }
    }

    // function calculateVoteValue(address _of) 
    //     internal view returns(uint voteValue) 
    // {
    //     for(uint i = 0;i < leaderDelegation[msg.sender].length; i++) {

    //     }
    //     voteValue = _getLockedBalance(_of, tokenHoldingTime);

    //     voteValue = 
    //         Math.max(
    //             SafeMath.div(
    //                 voteValue, uint256(10) ** tokenInstance.decimals()
    //             ),
    //             minVoteWeight
    //         );
    // }

    function _checkLastUpd(uint _lastUpd) internal view returns(bool) {
        return (now - _lastUpd) > tokenHoldingTime;
    }

    /// @dev Internal call from claimReward
    // function _claimReward(address _memberAddress, uint _maxRecords) 
    //     internal returns(uint pendingDAppReward) 
    // {

    //     uint delegationId = followerDelegation[_memberAddress];
    //     uint lastUpd;
    //     address leader;
    //     if (delegationId > 0 && allDelegation[delegationId].leader != address(0)) {
    //         leader = allDelegation[delegationId].leader;
    //         lastUpd = allDelegation[delegationId].lastUpd;
    //     } else {
    //         leader = _memberAddress;
    //     }

    //     uint proposalId;
    //     uint voteId;
    //     uint finalVerdict;
    //     uint totalVotes = allVotesByMember[leader].length;
    //     uint lastClaimed = totalVotes;
    //     // uint j;
    //     uint i;
    //     uint proposalVoteValue;
    //     // uint proposalStatus = allProposalData[proposalId].propStatus;
    //     // for (i = lastRewardClaimed[leader]; i < totalVotes && j < _maxRecords; i++) {
    //     for (i = lastRewardClaimed[leader]; i < totalVotes && _maxRecords > 0; i++) {
    //         voteId = allVotesByMember[leader][i];
    //         proposalId = allVotes[voteId].proposalId;
    //         finalVerdict = allProposalData[proposalId].finalVerdict;
    //         if(allVotes[voteId].dateAdd > (lastUpd + tokenHoldingTime) || _memberAddress == leader) {
    //             if (punishVoters) {
    //                 if (allVotes[voteId].solutionChosen != finalVerdict) {
    //                     continue;
    //                 }
    //                 proposalVoteValue = allProposalData[proposalId].majVoteValue;
    //             } else {
    //                 proposalVoteValue = allProposalData[proposalId].totalVoteValue;
    //             }
    //             if (finalVerdict > 0) {
    //                 if (!rewardClaimed[voteId]) {
    //                     pendingDAppReward += SafeMath.div(
    //                                     SafeMath.mul(
    //                                         allVotes[voteId].voteValue,
    //                                         allProposalData[proposalId].commonIncentive
    //                                     ),
    //                                     proposalVoteValue
    //                                 );
    //                     rewardClaimed[voteId] = true;
    //                     // j++;
    //                     _maxRecords--;
    //                 }
    //             } else {
    //                 if (allProposalData[proposalId].propStatus <= uint(ProposalStatus.VotingStarted) && 
    //                     lastClaimed == totalVotes
    //                 ) {
    //                     lastClaimed = i;
    //                 }
    //             }
    //         }
    //     }

    //     if (lastClaimed == totalVotes) {
    //         lastRewardClaimed[_memberAddress] = i;
    //     } else {
    //         lastRewardClaimed[_memberAddress] = lastClaimed;
    //     }
    // }

}