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

import "./VotingType.sol";
import "./memberRoles.sol";
import "./ProposalCategory.sol";
import "./governanceData.sol";
import "./zeppelin-solidity/contracts/math/SafeMath.sol";
// import "./SafeMath.sol";

contract simpleVoting is VotingType
{
    using SafeMath for uint;
    address GDAddress;
    address MRAddress;
    address PCAddress;
    memberRoles MR;
    ProposalCategory PC;
    governanceData GD;

    function simpleVoting()
    {
        uint[] verdictOption;
        allVotes.push(proposalVote(0x00,0,verdictOption,now,0));
    }

    function changeAllContractsAddress(address _GDcontractAddress, address _MRcontractAddress, address _PCcontractAddress) public
    {
        GDAddress = _GDcontractAddress;
        MRAddress = _MRcontractAddress;
        PCAddress = _PCcontractAddress;
    }

    function getTotalVotes() internal constant returns (uint votesTotal)
    {
        return(allVotes.length);
    }

    function increaseTotalVotes() internal returns (uint _totalVotes)
    {
        _totalVotes = SafeMath.add(totalVotes,1);  
        totalVotes=_totalVotes;
    } 

    function getVoteDetailByid(uint _voteid) public constant returns(address voter,uint proposalId,uint[] verdictChosen,uint dateSubmit,uint voterTokens)
    {
        return(allVotes[_voteid].voter,allVotes[_voteid].proposalId,allVotes[_voteid].verdictChosen,allVotes[_voteid].dateSubmit,allVotes[_voteid].voterTokens);
    }

    function getProposalRoleVoteLength(uint _proposalId,uint _roleId) public constant returns(uint length)
    {
         length = ProposalRoleVote[_proposalId][_roleId].length;
    }

    /// @dev Get Vote id of a _roleId against given proposal.
    function getProposalRoleVote(uint _proposalId,uint _roleId,uint _voteArrayIndex) public constant returns(uint voteId) 
    {
        voteId = ProposalRoleVote[_proposalId][_roleId][_voteArrayIndex];
    }

    /// @dev Get the vote count for options of proposal when giving Proposal id and Option index.
    function getProposalVoteAndTokenCountByRoleId(uint _proposalId,uint _roleId,uint _optionIndex) constant returns(uint totalVotes,uint totalToken)
    {
        totalVotes = allProposalVoteAndTokenCount[_proposalId].totalVoteCount[_roleId][_optionIndex];
        totalToken = allProposalVoteAndTokenCount[_proposalId].totalTokenCount[_roleId];
    }

    /// @dev Get Vote id of a _roleId against given proposal.
    function getProposalRoleVoteArray(uint _proposalId,uint _roleId) public constant returns(uint[] voteId) 
    {
        return ProposalRoleVote[_proposalId][_roleId];
    }

    function proposalVoting(uint _proposalId,uint[] _verdictChosen)
    {
        GD=governanceData(GDAddress);
        MR=memberRoles(MRAddress);
        PC=ProposalCategory(PCAddress);
        uint propStatus;
        (,,,,,,propStatus) = GD.getProposalDetailsById1(_proposalId);
        uint currentVotingId; uint category; uint intermediateVerdict;
        (category,currentVotingId,intermediateVerdict,,) = GD.getProposalDetailsById2(_proposalId);
        uint verdictOptions;
        (,,,verdictOptions) = GD.getProposalCategoryParams(_proposalId);
        require(GD.getBalanceOfMember(msg.sender) != 0 && propStatus == 2 && _verdictChosen.length == 1);

        if(currentVotingId == 0)
            require(_verdictChosen[0] <= verdictOptions);
        else
            require(_verdictChosen[0]==intermediateVerdict || _verdictChosen[0]==0);
        uint roleId = MR.getMemberRoleIdByAddress(msg.sender);
        require(roleId == PC.getRoleSequencAtIndex(_proposalId,category));

        if(AddressProposalVote[msg.sender][_proposalId] == 0)
        {
            uint votelength = getTotalVotes();
            increaseTotalVotes();
            uint _voterTokens = GD.getBalanceOfMember(msg.sender);
            allVotes.push(proposalVote(msg.sender,_proposalId,_verdictChosen,now,_voterTokens));
            allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_verdictChosen[0]] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_verdictChosen[0]],1);
            allProposalVoteAndTokenCount[_proposalId].totalTokenCount[roleId] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalTokenCount[roleId],_voterTokens);
            AddressProposalVote[msg.sender][_proposalId] = votelength;
            ProposalRoleVote[_proposalId][roleId].push(votelength);
        }
        else 
            changeMemberVote(_proposalId,_verdictChosen[0]);
    }

    function changeMemberVote(uint _proposalId,uint _verdictChosen) 
    {
        MR=memberRoles(MRAddress); 
        uint roleId = MR.getMemberRoleIdByAddress(msg.sender);
        uint voteId = AddressProposalVote[msg.sender][_proposalId];
        uint[] verdictChosen = allVotes[voteId].verdictChosen;
        uint verdict = verdictChosen[0];
        
        allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][verdict] = SafeMath.sub(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][verdict],1);
        allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_verdictChosen] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_verdictChosen],1);
        allVotes[voteId].verdictChosen[0] = _verdictChosen;
    }

    function addVerdictOption(uint _proposalId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress)
    {
        GD=governanceData(GDAddress);
        MR=memberRoles(MRAddress);
        PC=ProposalCategory(PCAddress);
        
        uint propStatus;
        (,,,,,,propStatus) = GD.getProposalDetailsById1(_proposalId);
        uint currentVotingId; uint category; uint intermediateVerdict;
        (category,currentVotingId,intermediateVerdict,,) = GD.getProposalDetailsById2(_proposalId);
        uint verdictOptions;
        (,,,verdictOptions) = GD.getProposalCategoryParams(_proposalId);
        uint roleId = MR.getMemberRoleIdByAddress(msg.sender);
        
        require((msg.sender) != 0 && propStatus == 2 && currentVotingId == 0);
        require(roleId == PC.getRoleSequencAtIndex(category,currentVotingId) && AddressProposalVote[msg.sender][_proposalId] == 0 );
        
        uint8 paramInt; uint8 paramBytes32; uint8 paramAddress;
        (,,,paramInt,paramBytes32,paramAddress,,) = PC.getCategoryDetails(category);

        if(paramInt == _paramInt.length && paramBytes32 == _paramBytes32.length && paramAddress == _paramAddress.length)
        {
            verdictOptions = SafeMath.add(verdictOptions,1);
            GD.setProposalCategoryParams(_proposalId,_paramInt,_paramBytes32,_paramAddress,verdictOptions);   
        } 
    }

    function closeProposalVote(uint _proposalId)
    {
        GD=governanceData(GDAddress);
        MR=memberRoles(MRAddress);
        PC=ProposalCategory(PCAddress);
    
        uint propStatus;
        (,,,,,,propStatus) = GD.getProposalDetailsById1(_proposalId);
        uint currentVotingId; uint category; uint intermediateVerdict;
        (category,currentVotingId,intermediateVerdict,,) = GD.getProposalDetailsById2(_proposalId);
        uint verdictOptions;
        (,,,verdictOptions) = GD.getProposalCategoryParams(_proposalId);
    
        require(GD.checkProposalVoteClosing(_proposalId)==1);
        uint max; uint totalVotes; uint verdictVal; uint majorityVote;
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
        majorityVote= PC.getRoleMajorityVote(category,currentVotingId);
       
        if(SafeMath.div(SafeMath.mul(verdictVal,100),totalVotes)>=majorityVote)
        {   
            currentVotingId = SafeMath.add(currentVotingId,1);
            if(max > 0 )
            {
                if(currentVotingId < PC.getRoleSequencLength(category))
                {
                    GD.updateProposalDetails(_proposalId,currentVotingId,max,0);
                } 
                else
                {
                    GD.updateProposalDetails(_proposalId,currentVotingId,max,max);
                    GD.changeProposalStatus(_proposalId,3);
                    PC.actionAfterProposalPass(_proposalId ,category);
                    giveReward_afterFinalDecision(_proposalId);
                }
            }
            else
            {
                GD.updateProposalDetails(_proposalId,currentVotingId,max,max);
                GD.changeProposalStatus(_proposalId,4);
                GD.changePendingProposalStart();
            }      
        } 
        else
        {
            GD.updateProposalDetails(_proposalId,currentVotingId,max,max);
            GD.changeProposalStatus(_proposalId,5);
            GD.changePendingProposalStart();
        } 
    }
     
    function giveReward_afterFinalDecision(uint _proposalId) public 
    {
        address voter; uint[] verdictChosen;uint category;uint votingLength; uint roleId; uint reward;uint length;uint voteid;
        PC=ProposalCategory(PCAddress); 
        GD=governanceData(GDAddress);
        uint currentVotingId;uint intermediateVerdict;uint finalVerdict;
        (category,currentVotingId,intermediateVerdict,finalVerdict,) = GD.getProposalDetailsById2(_proposalId);

        votingLength = PC.getRoleSequencLength(category);
        for(uint index=0; index<votingLength; index++)
        {
            roleId = PC.getRoleSequencAtIndex(category,index);
            length = getProposalRoleVoteLength(_proposalId,roleId);
            reward = GD.getProposalRewardAndComplexity(_proposalId,index);
            for(uint i=0; i<length; i++)
            {
                voteid = getProposalRoleVote(_proposalId,roleId,i);
                verdictChosen = allVotes[voteid].verdictChosen;
                uint verdict = verdictChosen[0];
                require(verdict == finalVerdict);
                GD.transferTokenAfterFinalReward(voter,reward);  
            }
        }    
    }

}
