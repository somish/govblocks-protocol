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
import "./MemberRoles.sol";
import "./ProposalCategory.sol";
import "./GovernanceData.sol";
import "./zeppelin-solidity/contracts/math/SafeMath.sol";
// import "./SafeMath.sol";

contract RankBasedVoting is VotingType
{
    using SafeMath for uint;
    address GDAddress;
    address MRAddress;
    address PCAddress;
    MemberRoles MR;
    ProposalCategory PC;
    GovernanceData GD;
    mapping(uint=>uint[]) allVoteValueAgainstOption;
        
    function RankBasedVoting()
    {
        uint[] option;
        allVotes.push(proposalVote(0x00,0,option,now,0));
    }

    function changeAllContractsAddress(address _GDcontractAddress, address _MRcontractAddress, address _PCcontractAddress) public
    {
        GDAddress = _GDcontractAddress;
        MRAddress = _MRcontractAddress;
        PCAddress = _PCcontractAddress;
    }

    function getTotalVotes()  constant returns (uint votesTotal)
    {
        return(allVotes.length);
    }

    function increaseTotalVotes() returns (uint _totalVotes)
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

    function addVerdictOption(uint _proposalId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress)
    {
        GD=GovernanceData(GDAddress);
        MR=MemberRoles(MRAddress);
        PC=ProposalCategory(PCAddress);
        
        uint propStatus;
        (,,,,,,propStatus) = GD.getProposalDetailsById1(_proposalId);
        uint currentVotingId; uint category; uint intermediateVerdict;
        (category,currentVotingId,intermediateVerdict,,) = GD.getProposalDetailsById2(_proposalId);
        uint verdictOptions;
        (,,,verdictOptions) = GD.getProposalCategoryParams(_proposalId);
        
        require(GD.getBalanceOfMember(msg.sender) != 0 && propStatus == 2 && currentVotingId == 0);
        uint _categoryId;
        (_categoryId,,,,) = GD.getProposalDetailsById2(_proposalId); 
        uint roleId = MR.getMemberRoleIdByAddress(msg.sender);
        require(roleId == PC.getRoleSequencAtIndex(_categoryId,currentVotingId) && AddressProposalVote[msg.sender][_proposalId] == 0 );
        
        uint8 paramInt; uint8 paramBytes32; uint8 paramAddress;
        (,,,paramInt,paramBytes32,paramAddress,,) = PC.getCategoryDetails(_categoryId);

        if(paramInt == _paramInt.length && paramBytes32 == _paramBytes32.length && paramAddress == _paramAddress.length)
        {
            verdictOptions = SafeMath.add(verdictOptions,1);
            GD.setProposalCategoryParams(_proposalId,_paramInt,_paramBytes32,_paramAddress,verdictOptions);  
        } 
    }

    function proposalVoting(uint _proposalId,uint[] _verdictChosen)
    {    
        GD=GovernanceData(GDAddress);
        MR=MemberRoles(MRAddress);
        PC=ProposalCategory(PCAddress);
        uint propStatus; uint voteValue;
        (,,,,,,propStatus) = GD.getProposalDetailsById1(_proposalId);
        uint currentVotingId; uint category; uint intermediateVerdict;
        (category,currentVotingId,intermediateVerdict,,) = GD.getProposalDetailsById2(_proposalId);
        uint verdictOptions;
        (,,,verdictOptions) = GD.getProposalCategoryParams(_proposalId);

        require(GD.getBalanceOfMember(msg.sender) != 0 && propStatus == 2 && _verdictChosen.length <= verdictOptions);

        if(currentVotingId == 0)
        {
            for(uint i=0; i<_verdictChosen.length; i++)
            {
                require(_verdictChosen[i] < verdictOptions);
                uint sum = SafeMath.add(sum,(SafeMath.sub(verdictOptions ,i)));
            }
        }   
        else
            require(_verdictChosen[0]==intermediateVerdict || _verdictChosen[0]==0);

        uint roleId = MR.getMemberRoleIdByAddress(msg.sender);
        require(roleId == PC.getRoleSequencAtIndex(category,currentVotingId));

        if(AddressProposalVote[msg.sender][_proposalId] == 0)
        {
            uint votelength = getTotalVotes();
            addInTotalVotes(_proposalId,_verdictChosen);
            if(currentVotingId == 0)
            {
                for(i=0; i<_verdictChosen.length; i++)
                {
                    voteValue = SafeMath.div(SafeMath.mul(SafeMath.sub(verdictOptions,i),100),sum);
                    allVoteValueAgainstOption[votelength].push(voteValue);
                    allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_verdictChosen[i]] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_verdictChosen[i]],voteValue);
                }

            } 
            else
            {
                allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_verdictChosen[0]] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_verdictChosen[0]],1);
            }
            
            allProposalVoteAndTokenCount[_proposalId].totalTokenCount[roleId] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalTokenCount[roleId],GD.getBalanceOfMember(msg.sender));
            AddressProposalVote[msg.sender][_proposalId] = votelength;
            ProposalRoleVote[_proposalId][roleId].push(votelength);
        }
        else 
            changeMemberVote(_proposalId,_verdictChosen,sum);
    }

    function addInTotalVotes(uint _proposalId,uint[] _verdictChosen)
    {
        increaseTotalVotes();
        allVotes.push(proposalVote(msg.sender,_proposalId,_verdictChosen,now,GD.getBalanceOfMember(msg.sender)));
    }
    
    function getAllVoteValueAgainstOption(uint _voteid) public constant returns(uint[] val)
    {
        return allVoteValueAgainstOption[_voteid];
    }


    function changeMemberVote(uint _proposalId,uint[] _verdictChosen,uint _sum)  
    {
        MR=MemberRoles(MRAddress);
        GD=GovernanceData(GDAddress);
        uint roleId = MR.getMemberRoleIdByAddress(msg.sender);
        uint voteId = AddressProposalVote[msg.sender][_proposalId];
        uint[] verdictChosen = allVotes[voteId].verdictChosen;
        uint verdictOptions; uint verdict;
        (,,,verdictOptions) = GD.getProposalCategoryParams(_proposalId);
        uint currentVotingId;
        (,currentVotingId,,,) = GD.getProposalDetailsById2(_proposalId);

        if(currentVotingId == 0)
        {
            for(uint i=0; i<allVoteValueAgainstOption[voteId].length; i++)
            {
                verdict = verdictChosen[i];
                uint voteValue = allVoteValueAgainstOption[voteId][i];
                allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][verdict] = SafeMath.sub(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][verdict],voteValue);
            }

            for(i=0; i<_verdictChosen.length; i++)
            {
                verdict = _verdictChosen[i];
                voteValue = SafeMath.div(SafeMath.mul((SafeMath.sub(verdictOptions,i)),100),_sum); 
                allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][verdict] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][verdict],voteValue);
            }
        }
        else
        {
            allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][verdictChosen[0]] = SafeMath.sub(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][verdictChosen[0]],1);
            allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_verdictChosen[0]] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_verdictChosen[0]],1);
        }
        allVotes[voteId].verdictChosen = _verdictChosen;
    }

    function closeProposalVote(uint _proposalId)
    {
        GD=GovernanceData(GDAddress);
        MR=MemberRoles(MRAddress);
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
        address voter; uint[] verdict;uint category;uint roleId; uint reward;uint voteid;
        PC=ProposalCategory(PCAddress); 
        GD=GovernanceData(GDAddress);
        uint currentVotingId;uint intermediateVerdict;uint finalVerdict;
        (category,currentVotingId,intermediateVerdict,finalVerdict,) = GD.getProposalDetailsById2(_proposalId);

        for(uint index=0; index<PC.getRoleSequencLength(category); index++)
        {
            roleId = PC.getRoleSequencAtIndex(category,index);
            reward = GD.getProposalRewardAndComplexity(_proposalId,index);
            for(uint i=0; i<getProposalRoleVoteLength(_proposalId,roleId); i++)
            {
                voteid = getProposalRoleVote(_proposalId,roleId,i);
                verdict = allVotes[voteid].verdictChosen;
                require(verdict[0] == finalVerdict);
                GD.transferTokenAfterFinalReward(voter,reward);  
            }
        }    
    }
}
