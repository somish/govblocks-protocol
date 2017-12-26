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

/**
 * @title votingType interface for All Types of voting.
 */

pragma solidity ^0.4.8;

contract VotingType
{
    struct proposalVote {
        address voter;
        uint proposalId;
        uint[] verdictChosen;
        uint dateSubmit;
        uint voterTokens;
        uint voteStakeGNT;
        uint voteValue;
    }

    struct proposalVoteAndTokenCount 
    {
        mapping(uint=>mapping(uint=>uint)) totalVoteCount; 
        mapping(uint=>uint) totalTokenCount; 
    }
    
    mapping(uint => proposalVoteAndTokenCount) allProposalVoteAndTokenCount;
    mapping(uint=>mapping(uint=>uint[])) ProposalRoleVote;
    mapping(address=>mapping(uint=>uint)) AddressProposalVote; 
    proposalVote[] allVotes;
    uint public allVotesTotal;
    string public votingTypeName;

    function addVerdictOption(uint _proposalId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress,uint _GNTPayableTokenAmount);
    function proposalVoting(uint _proposalId,uint[] _verdictChosen,uint _GNTPayableTokenAmount);
    function setVerdictValue_givenByMember(uint _proposalId,uint _memberStake) public returns (uint finalVerdictValue);
    function setVoteValue_givenByMember(uint _proposalId,uint _memberStake) public returns (uint finalVoteValue);
    function closeProposalVote(uint _proposalId);

    function getTotalVotes() constant returns (uint votesTotal);
    function getVoteDetailByid(uint _voteid) constant returns(address voter,uint proposalId,uint[] verdictChosen,uint dateSubmit,uint voterTokens,uint voteStakeGNT,uint voteValue);

    function getProposalVoteAndTokenCountByRoleId(uint _proposalId,uint _roleId,uint _optionIndex) constant returns(uint totalVotes,uint totalToken);
    function giveReward_afterFinalDecision(uint _proposalId);
}
