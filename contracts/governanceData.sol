/* Copyright (C) 2017 NexusMutual.io

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


pragma solidity ^0.4.8;

contract governanceData {

    struct proposal{
        address owner;
        string shortDesc;
        string longDesc;
        uint date_add;
    }
    proposal[] allProposal;

    /// @dev Creates a new proposal 
    function addNewProposal(string _shortDesc,string _longDesc) public
    {
        allProposal.push(proposal(msg.sender,_shortDesc,_longDesc,now));
    }

    /// @dev Fetch details of proposal
    function getProposalDetails(uint _id) public constant returns (address owner,string shortDesc,string longDesc,uint date_add)
    {
        return (allProposal[_id].owner,allProposal[_id].shortDesc,allProposal[_id].longDesc,allProposal[_id].date_add);
    }
      
}



        



        

