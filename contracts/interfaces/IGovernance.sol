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
contract IGovernance{




    /// @dev Creates a new proposal
    /// @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
    /// @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
    function createProposal(
        string _proposalTitle, 
        string _proposalSD, 
        string _proposalDescHash, 
        uint _categoryId
    ) public 
    {
    }

    /// @dev Categorizes proposal to proceed further. Categories shows the proposal objective.
    function categorizeProposal(
        uint _proposalId, 
        uint _categoryId
    ) public checkProposalValidity(_proposalId)
    {
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
    }

    /// @dev Opens proposal for voting
    function openProposalForVoting(uint _proposalId) 
        public onlyProposalOwner(_proposalId) checkProposalValidity(_proposalId) 
    {
    }

    /// @dev Submit proposal with solution
    /// @param _proposalId Proposal id
    /// @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
    function submitProposalWithSolution(
        uint _proposalId, 
        string _solutionHash, 
        bytes _action
    ) 
        public 
        onlyProposalOwner(_proposalId) 
    {   
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
    }    

    /// @dev Casts vote
    /// @param _proposalId Proposal id
    /// @param _solutionChosen solution chosen while voting. _solutionChosen[0] is the chosen solution
    function submitVote(uint32 _proposalId, uint64[] _solutionChosen) external {
        _addVote(_proposalId, _solutionChosen[0], msg.sender);
    } 

    function canCloseProposal(uint _proposalId) 
        public 
        view 
        returns(uint8 closeValue) 
    {
    }

    function closeProposal(uint _proposalId) public {
    }

    function claimReward(address _memberAddress, uint[] _proposals) 
        public onlyInternal returns(uint pendingGBTReward, uint pendingDAppReward) 
    {
    }

    function pauseProposal(uint _proposalId)
    {
    }

    function resumeProposal(uint _proposalId)
    {
    }

    function proposal(uint _propoosalId) returns()
    {
    }
         
}