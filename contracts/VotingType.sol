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
    string public votingTypeName;
    function initiateAddSolution(uint _proposalId,address _memberAddress,uint _solutionStake,string _solutionHash,uint _dateAdd) public;
    function addSolution(uint _proposalId,uint _solutionStake,string _solutionHash) public;
    function proposalVoting(uint _proposalId,uint[] _optionChosen,uint _voteStake) public;
    function closeProposalVote(uint _proposalId) public;
    function giveReward_afterFinalDecision(uint _proposalId) public;   
}