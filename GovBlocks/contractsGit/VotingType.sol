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
        uint[] optionChosen;
        uint dateSubmit;
        uint voterTokens;
        uint voteStakeGBT;
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

    function addVerdictOption(uint _proposalId,address _member,uint _votingTypeId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress,uint _GBTPayableTokenAmount,string _optionHash) ;

     function initiateVerdictOption(uint _proposalId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress,uint _GBTPayableTokenAmount,string _optionHash) ;

    function proposalVoting(uint _proposalId,uint[] _optionChosen,uint _GBTPayableTokenAmount) public;
    function closeProposalVote(uint _proposalId,address _memberAddress) public;
    function giveReward_afterFinalDecision(uint _proposalId) public;

    function getTotalVotes() constant returns (uint votesTotal);
    function getVoteDetailByid(uint _voteid) constant returns(address voter,uint proposalId,uint[] optionChosen,uint dateSubmit,uint voterTokens,uint voteStakeGBT,uint voteValue);
    function getProposalVoteAndTokenCountByRoleId(uint _proposalId,uint _roleId,uint _optionIndex) constant returns(uint totalVotes,uint totalToken);

    function setVoteId_againstMember(address _memberAddress,uint _proposalId,uint _voteLength)
    {
        AddressProposalVote[_memberAddress][_proposalId] = _voteLength;
    }

    function getVoteId_againstMember(address _memberAddress,uint _proposalId) constant returns(uint voteId)
    {
        voteId = AddressProposalVote[_memberAddress][_proposalId];
    }

    function getVotesbyOption_againstProposal(uint _proposalId,uint _roleId,uint _optionIndex) constant returns(uint totalVotes)
    {
        totalVotes = allProposalVoteAndTokenCount[_proposalId].totalVoteCount[_roleId][_optionIndex];
    }
}