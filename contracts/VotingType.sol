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
    }

    struct proposalVoteAndTokenCount 
    {
        mapping(uint=>mapping(uint=>uint)) totalVoteCount; 
        mapping(uint=>uint) totalTokenCount; 
    }

    mapping(uint => proposalVoteAndTokenCount) allProposalVoteAndTokenCount;
    mapping(uint=>mapping(uint=>uint[])) ProposalRoleVote;
    mapping(address=>mapping(uint=>uint)) AddressProposalVote; 
    proposalVote[] public allVotes;
    uint public totalVotes;

    function addVerdictOption(uint _proposalId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress);
    function proposalVoting(uint _proposalId,uint[] _verdictChosen);
    function changeMemberVote(uint _proposalId,uint[] _verdictChosen);
    function closeProposalVote(uint _proposalId);

    function increaseTotalVotes() internal returns (uint _totalVotes);
    function getTotalVotes() internal constant returns (uint votesTotal);
    function getVoteDetailByid(uint _voteid) constant returns(address voter,uint proposalId,uint[] verdictChosen,uint dateSubmit,uint voterTokens);

    function getProposalVoteAndTokenCountByRoleId(uint _proposalId,uint _roleId,uint _optionIndex) constant returns(uint totalVotes,uint totalToken);
    function getProposalRoleVoteArray(uint _proposalId,uint _roleId) constant returns(uint[] voteId);
    function finalReward(uint _proposalId);
}
