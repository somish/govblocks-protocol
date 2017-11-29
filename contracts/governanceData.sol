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


pragma solidity ^0.4.8;
import "./zeppelin-solidity/contracts/token/BasicToken.sol";
import "./zeppelin-solidity/contracts/token/MintableToken.sol";
import "./memberRoles.sol";
import "./ProposalCategory.sol";
// import "./BasicToken.sol";
// import "./MintableToken.sol";

contract governanceData is Ownable{
    using SafeMath for uint;
    struct proposal{
        address owner;
        string shortDesc;
        string longDesc;
        uint date_add;
        uint date_upd;
        uint versionNum;
        uint currVotingStatus;
        uint propStatus;  
        uint category;
        uint finalVerdict;
        uint currentVerdict;
    }

    struct proposalCategory{
        address categorizedBy;
        uint[] paramInt;
        bytes32[] paramBytes32;
        address[] paramAddress;
        uint verdictOptions;
    }
    struct proposalVersionData{
        uint versionNum;
        string shortDesc;
        string longDesc;
        uint date_add;
    }
    struct Status{
        uint statusId;
        uint date;
    }
    
     struct proposalVote {
        address voter;
        uint proposalId;
        uint verdictChosen;
        uint dateSubmit;
        uint voterTokens;
    }

    struct proposalPriority 
    {
        uint8 complexityLevel;
        uint[] levelReward;
    }

    function governanceData () 
    {
        proposalVoteClosingTime = 20;
        pendingProposalStart=0;
        quorumPercentage=25;
        addStatus();
        allVotes.push(proposalVote(0x00,0,0,now,0));
    }

    struct proposalVoteAndTokenCount 
    {
        mapping(uint=>mapping(uint=>uint)) totalVoteCount; 
        mapping(uint=>uint) totalTokenCount; 
    }

    mapping(uint => proposalVoteAndTokenCount) allProposalVoteAndTokenCount;
    mapping(uint=>mapping(uint=>uint[])) ProposalRoleVote;
    mapping(address=>mapping(uint=>uint)) AddressProposalVote;   
    mapping(uint=>proposalCategory) allProposalCategory;
    mapping(uint=>proposalVersionData[]) proposalVersions;
    mapping(uint=>Status[]) proposalStatus;
    mapping(uint=>proposalPriority) allProposalPriority;

    uint public proposalVoteClosingTime;
    uint public quorumPercentage;
    uint public pendingProposalStart;
    uint public totalVotes;

    
    string[] public status;
    proposal[] allProposal;
    proposalVote[] allVotes;
    
    address BTAddress;
    BasicToken BT;
    address MRAddress;
    address PCAddress;
    memberRoles MR;
    ProposalCategory Pcategory;

    /// @dev change all contract's addresses.
    function changeAllContractsAddress(address _BTcontractAddress, address _MRcontractAddress, address _PCcontractAddress) public
    {
        BTAddress = _BTcontractAddress;
        MRAddress = _MRcontractAddress;
        PCAddress = _PCcontractAddress;
    }

    /// @dev Fetch user balance when giving member address.
    function getBalanceOfMember(address _memberAddress) public constant returns (uint totalBalance)
    {
        BT=BasicToken(BTAddress);
        totalBalance = BT.balanceOf(_memberAddress);
    }

    /// @dev Get the vote count(voting done by AB) for options of proposal when giving Proposal id and Option index.
    function getProposalVoteAndTokenCountByRoleId(uint _proposalId,uint _roleId,uint _optionIndex) constant returns(uint totalVotes,uint totalToken)
    {
        totalVotes = allProposalVoteAndTokenCount[_proposalId].totalVoteCount[_roleId][_optionIndex];
        totalToken = allProposalVoteAndTokenCount[_proposalId].totalTokenCount[_roleId];
    }

    /// @dev add status and category.
    function addStatus() 
    {
        status.push("Draft for discussion"); 
        status.push("Draft Ready for submission");
        status.push("Voting started"); 
        status.push("Proposal Decision - Accepted by Majority Voting"); 
        status.push("Proposal Decision - Rejected by Majority voting"); 
        status.push("Proposal Denied, Threshold not reached"); 
    }
    
    /// @dev Changes the status of a given proposal to open it for voting. // wil get called when we submit the proposal on submit button
    function openProposalForVoting(uint _proposalId) onlyOwner public
    {
        require(allProposal[_proposalId].category != 0);
        pushInProposalStatus(_proposalId,2);
        updateProposalStatus(_proposalId,2);
    }

    /// @dev Changes the time(in seconds) after which proposal voting is closed.
    function changeProposalVoteClosingTime(uint _closingTime) onlyOwner public
    {
        proposalVoteClosingTime = _closingTime;   
    }

    /// @dev Checks if voting time of a given proposal should be closed or not. 
    function checkProposalVoteClosing(uint _proposalId) constant returns(uint8 closeValue)
    {
        require(SafeMath.add(allProposal[_proposalId].date_upd,proposalVoteClosingTime) <= now);
        closeValue=1;
    }

    /// @dev fetch the parameter details for the final verdict (Option having maximum votes)
    function getProposalFinalVerdictDetails(uint _proposalId) public constant returns(uint paramint, bytes32 parambytes32,address paramaddress)
    {
        uint category = allProposal[_proposalId].category;
        uint verdictChosen = allProposal[_proposalId].finalVerdict;
        if(allProposalCategory[_proposalId].paramInt.length != 0)
        {
             paramint = allProposalCategory[_proposalId].paramInt[verdictChosen];
        }

        if(allProposalCategory[_proposalId].paramBytes32.length != 0)
        {
            parambytes32 = allProposalCategory[_proposalId].paramBytes32[verdictChosen];
        }

        if(allProposalCategory[_proposalId].paramAddress.length != 0)
        {
            paramaddress = allProposalCategory[_proposalId].paramAddress[verdictChosen];
        }  
    }
    
    /// @dev Get final verdict of proposal after CloseproposalVote function.
    function getProposalFinalVerdict(uint _proposalId) constant returns(uint verdict) 
    {
        verdict = allProposal[_proposalId].finalVerdict;
    }  

    /// @dev Closes the voting of a given proposal.Changes the status and verdict of the proposal by calculating the votes
    function closeProposalVote(uint _proposalId)
    {
        require(checkProposalVoteClosing(_proposalId)==1);
        MR = memberRoles(MRAddress);
        Pcategory=ProposalCategory(PCAddress);
        uint category = allProposal[_proposalId].category;
        uint max; uint totalVotes; uint verdictVal; uint majorityVote;
        uint verdictOptions = allProposalCategory[_proposalId].verdictOptions;
        uint index = allProposal[_proposalId].currVotingStatus;
        uint roleId = MR.getMemberRoleIdByAddress(msg.sender);

        max=0;  
        for(uint i = 0; i < verdictOptions; i++)
        {
            totalVotes = SafeMath.add(totalVotes,allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][i]); 
            if(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][max] < allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][i])
            {  
                max = i; 
            }
        }
        verdictVal = allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][max];
        majorityVote=Pcategory.getRoleMajorityVote(category,index);
       
        if(SafeMath.div(SafeMath.mul(verdictVal,100),totalVotes)>=majorityVote)
        {   
            index = SafeMath.add(index,1);
            if(max > 0 )
            {
                if(index < Pcategory.getRoleSequencLength(category))
                {
                    allProposal[_proposalId].currVotingStatus = index;
                    allProposal[_proposalId].currentVerdict = max;
                } 
                else
                {
                    allProposal[_proposalId].finalVerdict = max;
                    changeProposalStatus(_proposalId,3);
                    Pcategory.actionAfterProposalPass(_proposalId ,category);
                }
            }
            else
            {
                allProposal[_proposalId].finalVerdict = max;
                changeProposalStatus(_proposalId,4);
                changePendingProposalStart();
            }      
        } 
        else
        {
            allProposal[_proposalId].finalVerdict = max;
            changeProposalStatus(_proposalId,5);
            changePendingProposalStart();
        } 
    }
    /// @dev Final rewards to distribute to sender according to proposal decision.
    function finalRewardAfterProposalDecision(uint _proposalId) public returns(uint votingLength,uint roleId,uint category,uint reward)
    {
        address voter; uint verdictChosen; uint voterTokens;
        BT=BasicToken(BTAddress);
        Pcategory=ProposalCategory(PCAddress); 
        category = allProposal[_proposalId].category;
        votingLength = Pcategory.getRoleSequencLength(category);
        
        for(uint index=0; index<votingLength ; index++)
        {
            roleId = Pcategory.getRoleSequencAtIndex(category,index);
            uint length = getProposalRoleVoteLength(_proposalId,roleId);
            reward = allProposalPriority[_proposalId].levelReward[index];
            for(uint i=0; i<length; i++)
            {
                uint voteid = getProposalRoleVote(_proposalId,roleId,i);
                (voter,,verdictChosen,,) = getVoteDetailByid(voteid);
                require(verdictChosen == allProposal[_proposalId].finalVerdict);
                bool result = BT.transfer(voter,reward);  
            }
        }
        
    }
    
    /// @dev Get length of total votes against each role for given Proposal.
    function getProposalRoleVoteLength(uint _proposalId,uint _roleId) public constant returns(uint length)
    {
         length = ProposalRoleVote[_proposalId][_roleId].length;
    }
    
    /// @dev Get Vote id of a _roleId against given proposal.
    function getProposalRoleVote(uint _proposalId,uint _roleId,uint _index) public constant returns(uint voteId) 
    {
        voteId = ProposalRoleVote[_proposalId][_roleId][_index];
    }
    
    /// @dev Change pending proposal start variable
    function changePendingProposalStart() public
    {
        uint pendingPS = pendingProposalStart;
        uint proposalLength = allProposal.length;
        for(uint j=pendingPS; j<proposalLength; j++)
        {
            if(allProposal[j].propStatus > 3)
                pendingPS = SafeMath.add(pendingPS,1);
            else
                break;
        }
        if(j!=pendingPS)
        {
            pendingProposalStart = j;
        }
    }

    /// @dev Check if the member who wants to change in contracts, is owner.
    function isOwner(address _memberAddress) returns(uint checkOwner)
    {
        require(owner == _memberAddress);
            checkOwner=1;
    }

    /// @dev Change current owner
    function changeOwner(address _memberAddress) onlyOwner public
    {
        transferOwnership(_memberAddress);
    }

    /// @dev Register's vote of members - generic function (i.e. for different roles)
    function proposalVoting(uint _proposalId,uint _verdictChosen) public
    {

        require(getBalanceOfMember(msg.sender) != 0 && allProposal[_proposalId].propStatus == 2);
        uint index = allProposal[_proposalId].currVotingStatus;
        MR = memberRoles(MRAddress);
        if(index == 0)
            require(_verdictChosen <= allProposalCategory[_proposalId].verdictOptions);
        else
            require(_verdictChosen==allProposal[_proposalId].currentVerdict || _verdictChosen==0);

        uint category;
        Pcategory=ProposalCategory(PCAddress);
        (category,,) = getProposalDetailsById2(_proposalId); 
        uint roleId = MR.getMemberRoleIdByAddress(msg.sender);
        require(roleId == Pcategory.getRoleSequencAtIndex(category,index));
        if(AddressProposalVote[msg.sender][_proposalId] == 0)
        {
            uint votelength = getTotalVotes();
            increaseTotalVotes();
            uint _voterTokens = getBalanceOfMember(msg.sender);
            allVotes.push(proposalVote(msg.sender,_proposalId,_verdictChosen,now,_voterTokens));
            allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_verdictChosen] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_verdictChosen],1);
            allProposalVoteAndTokenCount[_proposalId].totalTokenCount[roleId] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalTokenCount[roleId],_voterTokens);
            AddressProposalVote[msg.sender][_proposalId] = votelength;
            ProposalRoleVote[_proposalId][roleId].push(votelength);
        }
        else 
            changeMemberVote(_proposalId,_verdictChosen);
    }

    /// @dev At the time of proposal voting, user can add own verdict option.
    function addVerdictOption(uint _proposalId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress,uint _memberVerdictOption) public
    {
        uint index = allProposal[_proposalId].currVotingStatus;
        require(getBalanceOfMember(msg.sender) != 0 && allProposal[_proposalId].propStatus == 2 && index == 0);
        MR = memberRoles(MRAddress);
        Pcategory=ProposalCategory(PCAddress);
        uint _categoryId;
        (_categoryId,,) = getProposalDetailsById2(_proposalId); 
        uint roleId = MR.getMemberRoleIdByAddress(msg.sender);
        require(roleId == Pcategory.getRoleSequencAtIndex(_categoryId,index) && AddressProposalVote[msg.sender][_proposalId] == 0 );
        
        uint8 paramInt; uint8 paramBytes32; uint8 paramAddress;
        (,,,paramInt,paramBytes32,paramAddress,,) = Pcategory.getCategoryDetails(_categoryId);

        if(paramInt*_memberVerdictOption == _paramInt.length && paramBytes32*_memberVerdictOption == _paramBytes32.length && paramAddress*_memberVerdictOption == _paramAddress.length)
        {
            allProposalCategory[_proposalId].verdictOptions = SafeMath.add(allProposalCategory[_proposalId].verdictOptions,_memberVerdictOption);
            allProposalCategory[_proposalId].categorizedBy = msg.sender;
            allProposal[_proposalId].category = _categoryId;
           
            for(uint i=0;i<_memberVerdictOption;i++)
            {
                if(_paramInt.length != 0  )
                {
                    allProposalCategory[_proposalId].paramInt.push(_paramInt[i]);
                }
        
                if(_paramBytes32.length != 0  )
                {
                    allProposalCategory[_proposalId].paramBytes32.push(_paramBytes32[i]);
                }
        
                if(_paramAddress.length != 0  )
                {
                    allProposalCategory[_proposalId].paramAddress.push(_paramAddress[i]);
                }
            }
            
        } 
    }

    /// @dev Change vote of a member
    function changeMemberVote(uint _proposalId,uint _verdictChosen) 
    {
        MR = memberRoles(MRAddress);
        uint roleId = MR.getMemberRoleIdByAddress(msg.sender);
        uint voteId = AddressProposalVote[msg.sender][_proposalId];
        uint verdictChosen; uint voterTokens;
        (,,verdictChosen,,voterTokens) = getVoteDetailByid(voteId);

        allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][verdictChosen] = SafeMath.sub(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][verdictChosen],1);
        allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_verdictChosen] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_verdictChosen],1);
        allVotes[voteId].verdictChosen = _verdictChosen;
    }
    
    /// @dev Get total number of votes.
    function getTotalVotes() internal constant returns (uint votesTotal)
    {
        return(allVotes.length);
    }
    
    /// @dev Increase total number of votes by 1.
    function increaseTotalVotes() internal returns (uint _totalVotes)
    {
        _totalVotes = SafeMath.add(totalVotes,1);  
        totalVotes=_totalVotes;
    }
        
    /// @dev Get Vote id of a _roleId against given proposal.
    function getProposalRoleVoteArr(uint _proposalId,uint _roleId) public constant returns(uint[] voteId) 
    {
        voteId = ProposalRoleVote[_proposalId][_roleId];
    }
    
    /// @dev Provides Vote details of a given vote id. 
    function getVoteDetailByid(uint _voteid) public constant returns(address voter,uint proposalId,uint verdictChosen,uint dateSubmit,uint voterTokens)
    {
        return(allVotes[_voteid].voter,allVotes[_voteid].proposalId,allVotes[_voteid].verdictChosen,allVotes[_voteid].dateSubmit,allVotes[_voteid].voterTokens);
    }

    /// @dev Creates a new proposal 
    function addNewProposal(string _shortDesc,string _longDesc) public
    {
        allProposal.push(proposal(msg.sender,_shortDesc,_longDesc,now,now,0,0,0,0,0,0));
        
    }

    /// @dev Fetch details of proposal by giving proposal Id
    function getProposalDetailsById1(uint _id) public constant returns (address owner,string shortDesc,string longDesc,uint date_add,uint date_upd,uint versionNum,uint propStatus)
    {
        return (allProposal[_id].owner,allProposal[_id].shortDesc,allProposal[_id].longDesc,allProposal[_id].date_add,allProposal[_id].date_upd,allProposal[_id].versionNum,allProposal[_id].propStatus);
    }
    
    /// @dev Get the category, of given proposal. 
    function getProposalDetailsById2(uint _proposalId) public constant returns(uint category,uint roleId,uint intermediateVerdict) 
    {
        category = allProposal[_proposalId].category;
        roleId = allProposal[_proposalId].currVotingStatus;
        intermediateVerdict = allProposal[_proposalId].currentVerdict;    
    }
    
    /// @dev Edits a proposal and Only owner of a proposal can edit it.
    function editProposal(uint _proposalId , string _shortDesc, string _longDesc) onlyOwner public
    {
        storeProposalVersion(_proposalId);
        updateProposal(_proposalId,_shortDesc,_longDesc);
        changeProposalStatus(_proposalId,1);
        
        (allProposal[_proposalId].category > 0);
            uint category;
            (category,,) = getProposalDetailsById2(_proposalId); 
            uint verdictOptions = allProposalCategory[_proposalId].verdictOptions;
            uint8 paramInt; uint8 paramBytes32; uint8 paramAddress;
            Pcategory=ProposalCategory(PCAddress);
            (,,,paramInt,paramBytes32,paramAddress,,) = Pcategory.getCategoryDetails(category);
            if(SafeMath.mul(verdictOptions,paramInt) != 0  )
            {
                allProposalCategory[_proposalId].paramInt=new uint[](verdictOptions);     
            }
    
            if(SafeMath.mul(verdictOptions,paramBytes32) != 0  )
            {
                allProposalCategory[_proposalId].paramBytes32=new bytes32[](verdictOptions);   
            }
    
            if(SafeMath.mul(verdictOptions,paramAddress) != 0  )
            {
                allProposalCategory[_proposalId].paramAddress=new address[](verdictOptions);        
            }

            allProposal[_proposalId].category = 0;
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
        allProposal[_id].versionNum = SafeMath.add(allProposal[_id].versionNum,1);
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
    /// @dev Updates  status of an existing proposal.
    function updateProposalStatus(uint _id ,uint _status) internal
    {
        allProposal[_id].propStatus = _status;
        allProposal[_id].date_upd = now;
    }
    /// @dev Stores the status information of a given proposal.
    function pushInProposalStatus(uint _proposalId , uint _status) internal
    {
        proposalStatus[_proposalId].push(Status(_status,now));
    }
    /// @dev Get the category paramets given against a proposal after categorizing the proposal.
    function getProposalCategoryParams(uint _proposalId) constant returns(uint[] paramsInt,bytes32[] paramsBytes,address[] paramsAddress,uint verdictOptions)
    {
        paramsInt = allProposalCategory[_proposalId].paramInt;
        paramsBytes = allProposalCategory[_proposalId].paramBytes32;
        paramsAddress = allProposalCategory[_proposalId].paramAddress;
        verdictOptions = allProposalCategory[_proposalId].verdictOptions;
    }
    /// @dev Proposal's complexity level and reward is added 
    function addComplexityLevelAndReward(uint _proposalId,uint _category,uint8 _proposalComplexityLevel,uint[] _levelReward) internal
    {
        Pcategory=ProposalCategory(PCAddress);
        uint votingLength = Pcategory.getRoleSequencLength(_category);
        require(votingLength == _levelReward.length);
        allProposalPriority[_proposalId].complexityLevel = _proposalComplexityLevel;
        for(uint i=0; i<_levelReward.length; i++)
        {
            allProposalPriority[_proposalId].levelReward.push(_levelReward[i]);
        }
           
    }

    /// @dev categorizing proposal to proceed further.
    function categorizeProposal(uint _proposalId , uint _categoryId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress,uint _verdictOptions,uint8 _proposalComplexityLevel,uint[] _levelReward) public
    {
        MR = memberRoles(MRAddress);
        Pcategory=ProposalCategory(PCAddress);
        require(MR.getMemberRoleIdByAddress(msg.sender) == MR.getAuthorizedMemberId());
        require(allProposal[_proposalId].propStatus == 1 || allProposal[_proposalId].propStatus == 0);
        addComplexityLevelAndReward(_proposalId,_categoryId,_proposalComplexityLevel,_levelReward);
        
        uint8 paramInt; uint8 paramBytes32; uint8 paramAddress;

        if(_paramInt.length != 0  )
        {
            allProposalCategory[_proposalId].paramInt=new uint[](_verdictOptions+1);
            allProposalCategory[_proposalId].paramInt[0]=0;
        }

        if(_paramBytes32.length != 0  )
        {
            allProposalCategory[_proposalId].paramBytes32=new bytes32[](_verdictOptions+1);   
            allProposalCategory[_proposalId].paramBytes32[0]="";
        }

        if(_paramAddress.length != 0  )
        {
            allProposalCategory[_proposalId].paramAddress=new address[](_verdictOptions+1);        
            allProposalCategory[_proposalId].paramAddress[0]=0x00;
        }
        (,,,paramInt,paramBytes32,paramAddress,,) = Pcategory.getCategoryDetails(_categoryId);

        if(paramInt*_verdictOptions == _paramInt.length && paramBytes32*_verdictOptions == _paramBytes32.length && paramAddress*_verdictOptions == _paramAddress.length)
        {
            allProposalCategory[_proposalId].verdictOptions = SafeMath.add(_verdictOptions,1);
            allProposalCategory[_proposalId].categorizedBy = msg.sender;
            allProposal[_proposalId].category = _categoryId;
           
            for(uint i=0;i<_verdictOptions;i++)
            {
                if(_paramInt.length != 0  )
                {
                    allProposalCategory[_proposalId].paramInt[i+1]=_paramInt[i];
                }
        
                if(_paramBytes32.length != 0  )
                {
                    allProposalCategory[_proposalId].paramBytes32[i+1]=_paramBytes32[i];
                }
        
                if(_paramAddress.length != 0  )
                {
                    allProposalCategory[_proposalId].paramAddress[i+1]=_paramAddress[i];
                }
            }
            
        } 
    }
    /// @dev function to get called after Proposal Pass
    function categoryFunction(uint256 _proposalId) public
    {
        uint _categoryId;
        (_categoryId,,)= getProposalDetailsById2(_proposalId);
        uint paramint;
        bytes32 parambytes32;
        address paramaddress;
        (paramint,parambytes32,paramaddress) = getProposalFinalVerdictDetails(_proposalId);
        // add your functionality here;
        // gd1.updateCategoryMVR(_categoryId);
    }  
}  




