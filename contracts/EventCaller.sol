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

contract EventCaller {

    /// @dev VoteCast event is called whenever a vote is cast that can potentially close the proposal. 
    ///      closeProposalAddress is used to call closeProposal(proposalId) if proposal is ready to be closed.
    event VoteCast (
        uint256 proposalId,
        address closeProposalAddress,
    )

    /// @dev ProposalAccepted event is called when a proposal is accepted so that a server can listen that can 
    ///      call any offchain actions. closeProposalAddress is used to verify that the proposal is actually closed.
    event ProposalAccepted (
        bytes32 indexed dAppName,
        uint256 proposalId,
        address closeProposalAddress,
    )

    /// @dev calls VoteCast event
    /// @param _proposalId Proposal ID for which the vote is cast
    function callVoteCast (uint256 _proposalId) public {
        emit VoteCast(_proposalId, msg.sender);
    }

    /// @dev calls ProposalAccepted event
    /// @param _dAppName Name of the dApp whose proposal is accepted
    /// @param _proposalId Proposal ID of the proposal that is accepted
    function callProposalAccepted (bytes32 _dAppName, uint256 _proposalId) public {
        emit ProposalAccepted(_dAppName, _proposalId, msg.sender);
    }
}