                if(sum*100/totalMember < getQuorumPerc()) 
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
// import "./oraclizeAPI.sol";

contract governanceData{
    struct proposal{
        address owner;
        string shortDesc;
        string longDesc;
        uint date_add;
        uint date_upd;
        uint versionNum;
        uint status;  
        uint category;
        uint finalVerdict; // depends on options
    }
    struct proposalCategory{
        address categorizedBy;
        uint[] paramInt;
        bytes32[] paramBytes32;
        address[] paramAddress;
        uint8 verdictOptions;
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

    struct category{
        string categoryName;
        uint8 memberVoteRequired;
        uint majorityVote;
        string functionName;
        address contractAt;
        uint8 paramInt;
        uint8 paramBytes32;
        uint8 paramAddress;
    }
     struct proposalVote {
        address voter;
        uint proposalId;
        int verdictChoosen;
        uint dateSubmit;
    }

    address public owner;
    function governanceData () 
    {
        owner = msg.sender;
        proposalVoteClosingTime = 60;
        pendingProposalStart=0;
        quorumPercentage=25;
        addStatusAndCategory();
    }

    mapping (uint=>mapping(uint=>uint)) proposalABvoteCount; 
    mapping (uint=>mapping(uint=>uint)) proposalMemberVoteCount;

    uint public proposalVoteClosingTime;
    uint public quorumPercentage;
    uint public pendingProposalStart;
    uint public memberCounter;
    mapping(uint=>proposalCategory) allProposalCategory;
    category[] public allCategory;
    string[] public status;
    proposal[] allProposal;
    mapping(uint=>proposalVersionData[]) proposalVersions;
    mapping (uint=>Status[]) proposalStatus;
    mapping (address=>uint8) public advisoryBoardMembers;
    mapping (address=>uint[])  userAdvisoryBoardVote; /// Maps the given vote Id against the given Advisory board member's address
    mapping (address=>uint[])  userMemberVote; /// Maps the given vote Id against the given member's address.
    mapping (uint=>uint[])  proposalAdvisoryBoardVote;  /// Adds the given voter Id(AB) against the given Proposal's Id
    mapping (uint=>uint[])  proposalMemberVote; /// Adds the given voter Id(Member) against the given Proposal's Id
    mapping (address=>mapping(uint=>int))  userProposalAdvisoryBoardVote; /// Records a members vote on a given proposal id as an AB member.
    mapping (address=>mapping(uint=>int))  userProposalMemberVote; /// Records a members vote on a given proposal id.
    // mapping (uint=>VoteCount)  proposalVoteCount;
    mapping (address=>Status[])  memberAsABmember;
    proposalVote[] allVotes;
    uint public totalVotes;

    /// @dev Get the vote count(voting done by AB) for options of proposal when giving Proposal id and Option index.
    function getproposalABVoteCount(uint _proposalId,uint index) constant returns(uint result)
    {
        result = proposalABvoteCount[_proposalId][index]; 
    }
    
    /// @dev Get the vote count(voting done by Member) for options of proposal when giving Proposal id and Option index.
    function getproposalMemberVoteCount(uint _proposalId,uint index) constant returns(uint result)
    {
        result = proposalMemberVoteCount[_proposalId][index]; 
    }  

    /// @dev Stores the AB joining date against a AB member's address.
    function memberAsABmemberStatus(address _memberAddress ,uint status) internal
    {
        memberAsABmember[_memberAddress].push(Status(status,now));
    }

    /// @dev add status and category.
    function addStatusAndCategory () 
    {
        addCategory();
        addStatus();
    }
    
    /// @dev Increases the count of NXM Members by 1 (called whenever a new Member is added).
    function incMemberCounter() internal
    {
        memberCounter++;
    }

    /// @dev Decreases the count of NXM Members by 1 (called when a member is removed i.e. NXM tokens of a member is 0).
    function decMemberCounter() internal
    {
        memberCounter--;
    }

    /// @dev Gets the Quorum Percentage.
    function getQuorumPerc() public constant returns(uint percentage) 
    {
        percentage = quorumPercentage;
    }

    /// @dev Changes the Quorum Percentage.
    function changeQuorumPercentage(uint _percentage) public  
    {
        quorumPercentage = _percentage;
    }

    /// @dev Changes the status of a given proposal to open it for voting. // wil get called when we submit the proposal
    function openProposalForVoting(uint _proposalId) public
    {
        require(allProposal[_proposalId].owner == msg.sender || allProposal[_proposalId].status ==0);
        pushInProposalStatus(_id,1);
        updateProposalStatus(_id,1);
    }

    /// @dev Changes the time(in seconds) after which proposal voting is closed.
    function changeProposalVoteClosingTime(uint _closingTime) public
    {
        proposalVoteClosingTime = _closingTime;   
    }

    /// @dev Checks if voting time of a given proposal should be closed or not. 
    function checkProposalVoteClosing(uint _proposalId) constant returns(uint8 closeValue)
    {
        require((allProposal[_proposalId].date_upd + proposalVoteClosingTime <= now && allProposal[_proposalId].status == 1)|| allProposal[_proposalId].status == 2);
        closeValue=1;
    }

    /// @dev fetch the parameter details for the final verdict (Option having maximum votes)
    function getProposalFinalVerdictDetails(uint _proposalId) public constant returns(uint paramint, bytes32 parambytes32,address paramaddress)
    {
        require(allProposal[_proposalId].finalVerdict != -1);
        uint category = allProposal[_proposalId].category;
        uint verdictChoosen = allProposal[_proposalId].finalVerdict;
        paramint = allProposalCategory[_proposalId].paramInt[verdictChoosen];
        parambytes32 = allProposalCategory[_proposalId].paramBytes32[verdictChoosen];
        paramaddress = allProposalCategory[_proposalId].paramAddress[verdictChoosen];
    }

    /// @dev proposal should gets closed.
    function closeProposalVote(uint _proposalId)
    {
        if(checkProposalVoteClosing(_proposalId)==1) /// either status == 1 or status == 2 thats why Closing ==1
        {
            uint majorityVote;
            uint8 memberVoteRequired;
            uint category = allProposal[_proposalId].category;
            uint8 verdictOptions = allProposalCategory[_proposalId].verdictOptions;
            uint totalMember = memberCounter; 
            sum;
            max;
            uint i;
            verdictVal;
            (,memberVoteRequired,majorityVote,,,,,) = getCategoryDetails(category);
            if(allProposal[_proposalId].status==1)  // // pending advisory board vote
            {
                max=0;  
                sum=0;
                for(i = 0; i < verdictOptions; i++)
                {
                    sum = sum + allProposalCategory[_proposalId].paramInt[i];
                    if(proposalABvoteCount[_proposalId][max] < proposalABvoteCount[_proposalId][i])
                    {  
                        max = i;
                    }
                }
                verdictVal = allProposalCategory[_proposalId].paramInt[max];
                if(verdictVal*100/sum>=majorityVote)
                {   
                    if(memberVoteRequired==1) /// Member vote required 
                    {
                        changeProposalStatus(_proposalId,2);
                        // p1.closeProposalOraclise(id,gd1.getClosingTime());
                    }
                    else /// Member vote not required
                    {
                        pushInProposalStatus(_proposalId,4);
                        updateProposalStatus(_proposalId,4);
                        allProposal[_proposalId].finalVerdict = max;
                        actionAfterProposalPass(_proposalId ,category); //neww
                    }
                } // when AB votes are not enough . /// if proposal is denied
                else
                {
                    changeProposalStatus(_proposalId,3);
                    allProposal[_proposalId].finalVerdict = max;
                } 
            }
            else if(allProposal[_proposalId].status==2) /// pending member vote
            {
                // when Member Vote Quorum not Achieved
                max=0;  
                sum=0;
                for(i = 0; i < verdictOptions; i++)
                {
                    sum = sum + allProposalCategory[_proposalId].paramInt[i];
                    if(proposalMemberVoteCount[_proposalId][max] < proposalMemberVoteCount[_proposalId][i])
                    {  
                        max = i;
                    }
                }
                verdictVal = allProposalCategory[_proposalId].paramInt[max];
                if(sum*100/totalMember < getQuorumPerc()) 
                {
                    pushInProposalStatus(_proposalId,7);
                    updateProposalStatus(_proposalId,7);
                    allProposal[_proposalId].finalVerdict = -1;
                    actionAfterProposalPass(_proposalId , category);
                }
                /// if proposal accepted% >=majority % (by Members)
                else if(verdictVal*100/sum>=majorityVote)
                {
                    pushInProposalStatus(_proposalId,5);
                    updateProposalStatus(_proposalId,5);
                    allProposal[_proposalId].finalVerdict = max;
                    actionAfterProposalPass(_proposalId , category);
                }
                /// if proposal is denied
                else
                {
                    pushInProposalStatus(_proposalId,5);
                    updateProposalStatus(_proposalId,5);
                    allProposal[_proposalId].finalVerdict = -1;    
                }
            }
        } 
        uint pendingPS = pendingProposalStart;
        uint proposalLength = allProposal.length;
        for(uint j=pendingPS; j<proposalLength; j++)
        {
            if(allProposal[j].status > 2)
                pendingPS += 1;
            else
                break;
        }
        if(j!=pendingPS)
        {
            changePendingProposalStart(j);
        }
        
    }

    /// @dev Change pending proposal start variable
    function changePendingProposalStart(uint _pendingPS) internal
    {
        pendingProposalStart = _pendingPS;
    }

    function actionAfterProposalPass(uint256 _proposalId,uint _categoryId) public //NEWW
    {
        address contractAt = allCategory[_categoryId].contractAt; // then function name:
        contractAt.call(bytes4(sha3(allCategory[_categoryId].functionName)),_proposalId);
    }

    function updateCategoryMVR(uint _categoryId) 
    {
        allCategory[_categoryId].memberVoteRequired = 1;
    }

    /// @dev Check if the member who wants to change in contracts, is owner.
    function isOwner(address _memberAddress) constant returns(uint checkOwner)
    {
        checkOwner=0;
        if(owner == _memberAddress)
            checkOwner=1;
    }

    /// @dev Change current owner
    function changeOwner(address _memberAddress) public
    {
        if(owner == msg.sender)
            owner = _memberAddress;
    }

    /// @dev Gets the total number of categories.
    function getCategoriesLength() constant returns (uint length){
        length = allCategory.length;
    }

    /// @dev Gets category details by category id.
    function getCategoryDetails(uint _categoryId) public constant returns (string categoryName,uint8 memberVoteRequired,uint majorityVote,string functionName,address contractAt,uint8 paramInt,uint8 paramBytes32,uint8 paramAddress)
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


    /// @dev Increases the number of votes by 1.
    function increaseTotalVotes() internal
    {
        totalVotes++;
    }

    /// @dev Registers an Advisroy Board Member's vote for Proposal. _id is proposal id..
    function proposalVoteByABmember(uint _proposalId , uint8 _verdictChoosen) public
    {
        require(_verdictChoosen <= allProposalCategory[_proposalId].verdictOptions);
        require(advisoryBoardMembers[msg.sender]==1 && allProposal[_proposalId].status == 1 && userProposalAdvisoryBoardVote[msg.sender][_proposalId]==0);
        uint votelength = totalVotes;
        increaseTotalVotes();
        allVotes.push(proposalVote(msg.sender,_proposalId,_verdictChoosen,now)); 
        userAdvisoryBoardVote[msg.sender].push(votelength); 
        proposalAdvisoryBoardVote[_proposalId].push(votelength);
        userProposalAdvisoryBoardVote[msg.sender][_proposalId]=_verdictChoosen;
        proposalABvoteCount[_proposalId][_verdictChoosen] +=1;
       
    }

    /// @dev Registers an User Member's vote for Proposal. _id is proposal id...
    function proposalVoteByMember(uint _proposalId , uint8 _verdictChoosen) public
    {
        require(_verdictChoosen <= allProposalCategory[_proposalId].verdictOptions);
        require(advisoryBoardMembers[msg.sender]==0 && allProposal[_proposalId].status == 1 && userProposalMemberVote[msg.sender][_proposalId]==0);
        uint votelength = totalVotes;
        increaseTotalVotes();
        allVotes.push(proposalVote(msg.sender,_proposalId,_verdictChoosen,now)); 
        userMemberVote[msg.sender].push(votelength); 
        proposalMemberVote[_proposalId].push(votelength);
        userProposalMemberVote[msg.sender][_proposalId]=_verdictChoosen;
        proposalMemberVoteCount[_proposalId][_verdictChoosen] +=1;

    }

    /// @dev Provides Vote details of a given vote id. 
    function getVoteDetailByid(uint _voteid) public constant returns( address voter,uint proposalId,int verdictChoosen,uint dateSubmit)
    {
        return(allVotes[_voteid].voter,allVotes[_voteid].proposalId,allVotes[_voteid].verdictChoosen,allVotes[_voteid].dateSubmit);
    }

    /// @dev Creates a new proposal 
    function addNewProposal(string _shortDesc,string _longDesc) public
    {
        allProposal.push(proposal(msg.sender,_shortDesc,_longDesc,now,now,0,0,0,-1));
    }

    /// @dev Fetch details of proposal by giving proposal Id
    function getProposalDetailsById(uint _id) public constant returns (address owner,string shortDesc,string longDesc,uint date_add,uint date_upd,uint versionNum,uint status)
    {
        return (allProposal[_id].owner,allProposal[_id].shortDesc,allProposal[_id].longDesc,allProposal[_id].date_add,allProposal[_id].date_upd,allProposal[_id].versionNum,allProposal[_id].status);
    }
     
    function getProposalCategory (uint _proposalid) public constant returns(uint category) 
    {
        category = allProposal[_proposalid].category; 
    }
        
    /// @dev Edits a proposal and Only owner of a proposal can edit it.
    function editProposal(uint _id , string _shortDesc, string _longDesc) public
    {
        require(msg.sender == allProposal[_id].owner);
        {
            storeProposalVersion(_id);
            updateProposal(_id,_shortDesc,_longDesc);
            allProposal[_id].category = 0;
            allProposalCategory[_id].paramInt.push(0);
            allProposalCategory[_id].paramBytes32.push("");
            allProposalCategory[_id].paramAddress.push(0);
        }
    }

    /// @dev Stores the information of a given version number of a given proposal. Maintains the record of all the versions of a proposal.
    function storeProposalVersion(uint _id) internal 
    {
        proposalVersions[_id].push(proposalVersionData(allProposal[_id].versionNum,allProposal[_id].shortDesc,allProposal[_id].longDesc,allProposal[_id].date_add));            
    }

    /// @dev Edits the details of an existing proposal and creates new version.
    function updateProposal(uint _id,string _shortDesc,string _longDesc) internal
    {
        allProposal[_id].shortDesc = _shortDesc;
        allProposal[_id].longDesc = _longDesc;
        allProposal[_id].date_upd = now;
        allProposal[_id].versionNum += 1;
    }

    /// @dev Gets version details of a given proposal id.
    function getProposalDetailsByIdAndVersion(uint _id,uint _versionNum) public constant returns( uint versionNum,string shortDesc,string longDesc,uint date_add)
    {
        return (proposalVersions[_id][_versionNum].versionNum,proposalVersions[_id][_versionNum].shortDesc,proposalVersions[_id][_versionNum].longDesc,proposalVersions[_id][_versionNum].date_add);
    }

    /// @dev Changes the status of a given proposal.
    function changeProposalStatus(uint _id,uint _status) 
    {
        require(allProposal[_id].category != 0);
        pushInProposalStatus(_id,_status);
        updateProposalStatus(_id,_status);
    }

    /// @dev Adds status names in array - Not generic right now
    function addStatus() internal
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

    /// @dev Adds category names -
    function addCategory() internal
    {   
        allCategory.push(category("Uncategorised",0,0,"",0,0,0,0));
        allCategory.push(category("Filter member proposals as necessary(which are put to a member vote)",0,60,"",0,0,0,0));
    }

    /// @dev Updates  status of an existing proposal.
    function updateProposalStatus(uint _id ,uint _status) 
    {
        allProposal[_id].status = _status;
        allProposal[_id].date_upd =now;
    }

    /// @dev Stores the status information of a given proposal.
    function pushInProposalStatus(uint _id , uint _status) 
    {
        proposalStatus[_id].push(Status(_status,now));
    }

    /// @dev Adds a new category.
    function addNewCategory(string _categoryName,uint8 _memberVoteRequired,uint8 _majorityVote,string _functionName,address _contractAt,uint8 _paramInt,uint8 _paramBytes32,uint8 _paramAddress) public
    {
        allCategory.push(category(_categoryName,_memberVoteRequired,_majorityVote,_functionName,_contractAt,_paramInt,_paramBytes32,_paramAddress));
    }


    function updateCategory(uint _categoryId,string _categoryName,uint8 _memberVoteRequired,uint8 _majorityVote,string _functionName,address _contractAt,uint8 _paramInt,uint8 _paramBytes32,uint8 _paramAddress) public
    {
        allCategory[_categoryId].categoryName = _categoryName;
        allCategory[_categoryId].functionName = _functionName;
        allCategory[_categoryId].contractAt = _contractAt;
        allCategory[_categoryId].paramInt = _paramInt;
        allCategory[_categoryId].paramBytes32 = _paramBytes32; 
        allCategory[_categoryId].paramAddress = _paramAddress;
        allCategory[_categoryId].memberVoteRequired = _memberVoteRequired;
        allCategory[_categoryId].majorityVote = _majorityVote;
    }

    function categorizeProposal(uint _id , uint _categoryId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress,uint8 _verdictOptions) public
    {
        require(advisoryBoardMembers[msg.sender]==1 && allProposal[_id].status == 0);
        uint8 paramInt; uint8 paramBytes32; uint8 paramAddress;
        (,,,,,paramInt,paramBytes32,paramAddress) = getCategoryDetails(_categoryId);

        if(paramInt*_verdictOptions == _paramInt.length && paramBytes32*_verdictOptions == _paramBytes32.length && paramAddress*_verdictOptions == _paramAddress.length)
        {
            allProposal[_id].category = _categoryId;
            allProposalCategory[_id]=proposalCategory(msg.sender,_paramInt,_paramBytes32,_paramAddress,_verdictOptions);
        } 
    }

    /// @dev Adds a given address as an advisory board member.
    function joinAdvisoryBoard(address _memberAddress) public
    {
        require(advisoryBoardMembers[_memberAddress]==0 && isOwner(msg.sender) == 1);
        advisoryBoardMembers[_memberAddress] = 1;
        memberAsABmemberStatus(_memberAddress,1);
    }

    /// @dev Removes a given address from the advisory board.
    function removeAdvisoryBoard(address _memberAddress) public
    {
        require(advisoryBoardMembers[_memberAddress]==1 && isOwner(msg.sender) == 1);
        advisoryBoardMembers[_memberAddress] = 0;
        memberAsABmemberStatus(_memberAddress,0);
    }


}  

contract governance 
{
   address governanceDataAddress;
    governanceData gd1;
    function changeGovernanceDataAddress(address _contractAddress) public
    {
        governanceDataAddress = _contractAddress;
        gd1=governanceData(governanceDataAddress);
    }
    
    function updateCategory_memberVote(uint256 _proposalId) 
    {
        gd1=governanceData(governanceDataAddress);
        uint _categoryId = gd1.getProposalCategory(_proposalId);
        gd1.updateCategoryMVR(_categoryId);
    }
    
}


