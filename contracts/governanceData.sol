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

contract testData {

    struct proposal{
        address owner;
        string shortDesc;
        string longDesc;
        uint date_add;
        uint date_upd;
        uint versionNum;
        uint status;  
        uint category;
    }
    struct proposalCategory{
        address categorizedBy;
        uint[] paramInt;
        bytes32[] paramBytes32;
        address[] paramAddress;
    }
    struct proposalVersionData{
        uint versionNum;
        string shortDesc;
        string longDesc;
        uint date_add;
    }
    struct Status{
        uint movedTo;
        uint date;
    }
    struct category
    {
        string categoryName;
        uint8 memberVoteRequired;
        uint8 majorityVote;
        string functionName;
        address contractAt;
        uint8 paramInt;
        uint8 paramBytes32;
        uint8 paramAddress;      
    }

    mapping(uint=>proposalCategory) allProposalCategory;
    category[] public allCategory;
    string[] public status;
    proposal[] allProposal;
    mapping(uint=>proposalVersionData[]) proposalVersions;
    mapping (uint=>Status[]) proposalStatus;
    mapping (address=>uint8) public advisoryBoardMembers;

    /// @dev Proposal.. and version..
    /// @dev Creates a new proposal 
    function addNewProposal(string _shortDesc,string _longDesc) public
    {
        allProposal.push(proposal(msg.sender,_shortDesc,_longDesc,now,now,0,0,0));

    }

    /// @dev Fetch details of proposal by giving proposal Id
    function getProposalDetailsById(uint _id) public constant returns (address owner,string shortDesc,string longDesc,uint date_add,uint date_upd,uint versionNum,uint status)
    {
        return (allProposal[_id].owner,allProposal[_id].shortDesc,allProposal[_id].longDesc,allProposal[_id].date_add,allProposal[_id].date_upd,allProposal[_id].versionNum,allProposal[_id].status);
    }
      
    /// @dev Edits a proposal and Only owner of a proposal can edit it.
    function editProposal(uint _id , string _shortDesc, string _longDesc) public
    {
        require(msg.sender == allProposal[_id].owner);
        {
            storeProposalVersion(_id);
            updateProposal(_id,_shortDesc,_longDesc);
        }
    }

    /// @dev Stores the information of a given version number of a given proposal. Maintains the record of all the versions of a proposal.
    function storeProposalVersion(uint _id) private 
    {
       
        proposalVersions[_id].push(proposalVersionData(allProposal[_id].versionNum,allProposal[_id].shortDesc,allProposal[_id].longDesc,allProposal[_id].date_add));            
    }

    /// @dev Edits the details of an existing proposal and creates new version.
    function updateProposal(uint _id,string _shortDesc,string _longDesc) private
    {
        allProposal[_id].shortDesc = _shortDesc;
        allProposal[_id].longDesc = _longDesc;
        allProposal[_id].date_upd = now;
        allProposal[_id].date_add = now;
        allProposal[_id].versionNum += 1;
    }

    /// @dev Gets version details of a given proposal id.
    function getProposalDetailsByIdAndVersion(uint _id,uint _versionNum) public constant returns( uint versionNum,string shortDesc,string longDesc,uint date_add)
    {
       return (proposalVersions[_id][_versionNum].versionNum,proposalVersions[_id][_versionNum].shortDesc,proposalVersions[_id][_versionNum].longDesc,proposalVersions[_id][_versionNum].date_add);
    }
    /// @dev Status..
    /// @dev Changes the status of a given proposal.
    function changeProposalStatus(uint _id,uint _status) internal
    {
        
        pushInProposalStatus(_id,_status);
        updateProposalStatus(_id,_status);
        

    }

    /// @dev Adds status names in array - Not generic right now
    function addStatus() public
    {   
        status.push("Draft for discussion, multiple versions.");
        status.push("Pending-Advisory Board Vote");
        status.push("Pending-Advisory Board Vote Accepted, pending Member Vote");
        status.push("Final-Advisory Board Vote Declined");
        status.push("Final-Advisory Board Vote Accepted, Member Vote not required");
        status.push("Final-Advisory Board Vote Accepted, Member Vote Accepted");
        status.push("Final-Advisory Board Vote Accepted, Member Vote Declined");
        status.push("Final-Advisory Board Vote Accepted, Member Vote Quorum not Achieved");
        status.push("Proposal Accepted, Insufficient Funds");
    }
   

    /// @dev Updates  status of an existing proposal.
    function updateProposalStatus(uint _id ,uint _status) public
    {
        allProposal[_id].status = _status;
         allProposal[_id].date_upd =now;
    }

    /// @dev Stores the status information of a given proposal.
    function pushInProposalStatus(uint _id , uint _status) public
    {
        proposalStatus[_id].push(Status(_status,now));
    }
    /// @dev category..
    /// @dev Adds a new category.
    function addNewCategory(string _categoryName,uint8 _memberVoteRequired,uint8 _majorityVote,string _functionName,address _contractAt,uint8 _paramInt,uint8 _paramBytes32,uint8 _paramAddress) public
    {
        allCategory.push(category(_categoryName,_memberVoteRequired,_majorityVote,_functionName,_contractAt,_paramInt,_paramBytes32,_paramAddress));
    }

    /// @dev Gets category details by category id.
    function getCategoryDetails(uint _categoryId) public constant returns (string categoryName,uint64 memberVoteRequired,uint16 majorityVote,string functionName,address contractAt,uint16 paramInt,uint16 paramBytes32,uint16 paramAddress)
    {    
        categoryName = allCategory[_categoryId].categoryName;
        memberVoteRequired = allCategory[_categoryId].memberVoteRequired;
        majorityVote = allCategory[_categoryId].majorityVote;
        functionName = allCategory[_categoryId].functionName;
        contractAt = allCategory[_categoryId].contractAt;
        paramInt = allCategory[_categoryId].paramInt;
        paramBytes32 = allCategory[_categoryId].paramBytes32;
        paramAddress = allCategory[_categoryId].paramAddress;
    } 

    function updateCategory(uint _categoryId,string _categoryName,uint64 _memberVoteRequired,uint16 _majorityVote,string _functionName,address _contractAt,uint8 _paramInt,uint8 _paramBytes32,uint8 _paramAddress)
    {
        allCategory[_categoryId].categoryName = _categoryName;
        allCategory[_categoryId].functionName = _functionName;
        allCategory[_categoryId].contractAt = _contractAt;
        allCategory[_categoryId].paramInt = _paramInt;
        allCategory[_categoryId].paramBytes32 = _paramBytes32; 
        allCategory[_categoryId].paramAddress = _paramAddress; 
    }

    function categorizeProposal(uint _id , uint _categoryId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress)
    {
         require(advisoryBoardMembers[msg.sender]==1);
        
                uint16 paramInt; uint16 paramBytes32; uint16 paramAddress;
                (,,,,,paramInt,paramBytes32,paramAddress) = getCategoryDetails(_categoryId);
                if(paramInt == _paramInt.length && paramBytes32 == _paramBytes32.length && paramAddress == _paramAddress.length)
                {
                    allProposal[_id].category = _categoryId;
                    allProposalCategory[_id]=proposalCategory(msg.sender,_paramInt,_paramBytes32,_paramAddress);
                }
      
    }


    function isProposalCategorised(uint _id) public constant returns(uint check)
    {   
        check=allProposal[_id].category;
    }

 

}  


