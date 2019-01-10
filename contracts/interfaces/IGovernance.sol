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


contract IGovernance {

    /// @dev Creates a new proposal
    /// @param _proposalTitle Title of the proposal
    /// @param _proposalSD Proposal short description
    /// @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
    /// @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
    function createProposal(
        string _proposalTitle, 
        string _proposalSD, 
        string _proposalDescHash, 
        uint _categoryId
    ) external 
    {
    }

    /// @dev Edits the details of an existing proposal
    /// @param _proposalId Proposal id that details needs to be updated
    /// @param _proposalTitle Title of the proposal
    /// @param _proposalSD Proposal short description    
    /// @param _proposalDescHash Proposal description hash having long and short description of proposal.
    function updateProposal(
        uint _proposalId, 
        string _proposalTitle, 
        string _proposalSD, 
        string _proposalDescHash
    ) 
        external
    {
    }

    /// @dev Categorizes proposal to proceed further. Categories shows the proposal objective.
    /// @param _proposalId Proposal id
    /// @param _categoryId Category id
    /// @param _incentives Number of tokens to be distributed, if proposal is passed
    function categorizeProposal(
        uint _proposalId, 
        uint _categoryId,
        uint _incentives
    ) external
    {
    }

    /// @dev Initiates add solution
    /// @param _proposalId Proposal id
    /// @param _solutionHash Solution hash having required data against adding solution
    /// @param _action encoded hash of the action to call, if solution is choosen
    function addSolution(
        uint _proposalId,
        string _solutionHash, 
        bytes _action
    ) 
        external 
    {
    }

    /// @dev Opens proposal for voting
    /// @param _proposalId Proposal id
    function openProposalForVoting(uint _proposalId) 
        external
    {
    }

    /// @dev Submit proposal with solution
    /// @param _proposalId Proposal id
    /// @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
    /// @param _action encoded hash of the action to call, if solution is choosen
    function submitProposalWithSolution(
        uint _proposalId, 
        string _solutionHash, 
        bytes _action
    ) 
        external 
    {   
    }

    /// @dev Creates a new proposal with solution and votes for the solution
    /// @param _proposalTitle Title of the proposal
    /// @param _proposalSD Proposal short description    
    /// @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
    /// @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
    /// @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
    /// @param _action encoded hash of the action to call, if solution is choosen
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
    }    

    /// @dev Submits a vote to solution of a proposal
    /// @param _proposalId Proposal id
    /// @param _solutionChosen Solution id
    function submitVote(uint _proposalId, uint _solutionChosen) external {
    } 

    /// @dev Close proposal for voting, calculate the result and perform defined action
    function closeProposal(uint _proposalId) external {
    }

    /// @dev user can calim the tokens rewarded them till now
    /// Index 0 of _ownerProposals, _voterProposals is not parsed. 
    /// proposal arrays of 1 length are treated as empty.
    function claimReward(address _memberAddress, uint[] _proposals) 
        external 
    {
    }

    /// @dev Get proposal details
    function proposal(uint _proposalId) external view returns(uint proposalId, uint category, uint status, uint finalVerdict, uint totalReward)
    {
    }

    /// @dev Checks If the proposal voting time is up and it's ready to close 
    ///      i.e. Closevalue is 1 if proposal is ready to be closed, 2 if already closed, 0 otherwise!
    /// @param _proposalId Proposal id to which closing value is being checked
    function canCloseProposal(uint _proposalId) 
        public 
        view 
        returns(uint closeValue) 
    {
    }

    /// @dev Returns id of the role authorized to categorize proposals in dApp 
    function allowedToCatgorize() public returns(uint roleId) {
    }

    /// @dev pause a proposal
    function pauseProposal(uint _proposalId) public {
    }

    /// @dev resume a proposal
    function resumeProposal(uint _proposalId) public {
    }

    event Proposal(
        address indexed proposalOwner,
        uint256 indexed proposalId,
        uint256 dateAdd,
        string proposalTitle,
        string proposalSD,
        string proposalDescHash
    );

    event Solution(
        uint256 indexed proposalId,
        address indexed solutionOwner,
        uint256 indexed solutionId,
        string solutionDescHash,
        uint256 dateAdd
    );

    event Vote(
        address indexed from,
        uint256 indexed proposalId,
        uint256 indexed voteId,
        uint256 dateAdd,
        uint256 solutionChosen
    );

    event RewardClaimed(
        address indexed member,
        uint[] voterProposals,
        uint gbtReward
    );

}