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
        uint date_upd;
        uint versionNum;
    }
    struct proposalVersionData{
        uint versionNum;
        string shortDesc;
        string longDesc;
        uint date_add;
    }
    proposal[] allProposal;
    mapping(uint=>proposalVersionData[]) proposalVersions;

    /// @dev Creates a new proposal 
    function addNewProposal(string _shortDesc,string _longDesc) public
    {
        allProposal.push(proposal(msg.sender,_shortDesc,_longDesc,now,now,0));
    }

    /// @dev Fetch details of proposal by giving proposal Id
    function getProposalDetailsById(uint _id) public constant returns (address owner,string shortDesc,string longDesc,uint date_add,uint date_upd,uint versionNum)
    {
        return (allProposal[_id].owner,allProposal[_id].shortDesc,allProposal[_id].longDesc,allProposal[_id].date_add,allProposal[_id].date_upd,allProposal[_id].versionNum);
    }
      
    /// @dev Edits a proposal and Only owner of a proposal can edit it.
    function editProposal(uint _id , string _shortDesc, string _longDesc) public
    {
        if(msg.sender == allProposal[_id].owner)
        {
            storeProposalVersion(_id);
            updateProposal(_id,_shortDesc,_longDesc);
        }
        else
            throw;
    }

    /// @dev Stores the information of a given version number of a given proposal. Maintains the record of all the versions of a proposal.
    function storeProposalVersion(uint _id) public 
    {
        uint versionNum = allProposal[_id].versionNum;
        proposalVersions[_id].push(proposalVersionData(versionNum,allProposal[_id].shortDesc,allProposal[_id].longDesc,allProposal[_id].date_upd));            
    }

    /// @dev Edits the details of an existing proposal and creates new version.
    function updateProposal(uint _id,string _shortDesc,string _longDesc) public
    {
        allProposal[_id].shortDesc = _shortDesc;
        allProposal[_id].longDesc = _longDesc;
        allProposal[_id].date_upd = now;
        allProposal[_id].versionNum += 1;
    }

    /// @dev Gets version details of a given proposal id.
    function getProposalDetailsByIdAndVersion(uint _proposalId,uint _versionNum) public constant returns( uint versionNum,string shortDesc,string longDesc,uint date_add)
    {
       return (proposalVersions[_proposalId][_versionNum].versionNum,proposalVersions[_proposalId][_versionNum].shortDesc,proposalVersions[_proposalId][_versionNum].longDesc,proposalVersions[_proposalId][_versionNum].date_add);
    }

}

