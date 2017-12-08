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
import "./GovernanceData.sol";

contract SimpleVoting is VotingType
{

    using SafeMath for uint;
    using Math for uint;
    address GDAddress;
    address MRAddress;
    address PCAddress;
    address GNTAddress;
    MemberRoles MR;
    ProposalCategory PC;
    GovernanceData GD;
    MintableToken MT;

    function SimpleVoting()
    {
        uint[] verdictOption;
        allVotes.push(proposalVote(0x00,0,verdictOption,now,0,0,0));
    }
    
    /// @dev Some amount to be paid while using GovBlocks contract service - Approve the contract to spend money on behalf of msg.sender
    function payableGNTTokensSimpleVoting(uint _TokenAmount) public
    {
        MT=MintableToken(GNTAddress);
        GD=GovernanceData(GDAddress);
        require(_TokenAmount >= GD.GNTStakeValue());
        MT.transferFrom(msg.sender,GNTAddress,_TokenAmount);
    }

    function changeAllContractsAddress(address _GNTcontractAddress,address _GDcontractAddress, address _MRcontractAddress, address _PCcontractAddress) public
    {
        GNTAddress = _GNTcontractAddress;
        GDAddress = _GDcontractAddress;
        MRAddress = _MRcontractAddress;
        PCAddress = _PCcontractAddress;
    }

    function getTotalVotes() constant returns (uint votesTotal)
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

    function setVerdictValue_givenByMember(uint _proposalId,uint _memberStake) public returns (uint finalVerdictValue)
    {
        GD=GovernanceData(GDAddress);
        uint memberLevel = Math.max256(GD.getMemberReputation(msg.sender),1);
        uint tokensHeld = SafeMath.div((SafeMath.mul(SafeMath.mul(GD.getBalanceOfMember(msg.sender),100),100)),GD.getTotalTokenInSupply());
        uint maxValue= Math.max256(tokensHeld,GD.membershipScalingFactor());

        finalVerdictValue = SafeMath.mul(SafeMath.mul(GD.globalRiskFactor(),memberLevel),SafeMath.mul(_memberStake,maxValue));
    }

    function setVoteValue_givenByMember(uint _proposalId,uint _memberStake) public returns (uint finalVoteValue)
    {
        GD=GovernanceData(GDAddress);
        MT=MintableToken(GNTAddress);
        uint _voterTokens = GD.getBalanceOfMember(msg.sender);
        if(_memberStake != 0)
            MT.transferFrom(msg.sender,GNTAddress,_memberStake);

        uint tokensHeld = SafeMath.div((SafeMath.mul(SafeMath.mul(GD.getBalanceOfMember(msg.sender),100),100)),GD.getTotalTokenInSupply());
        uint value= SafeMath.mul(Math.max256(_memberStake,GD.scalingWeight()),Math.max256(tokensHeld,GD.membershipScalingFactor()));
        finalVoteValue = SafeMath.mul(GD.getMemberReputation(msg.sender),value);
    }

    function addVerdictOption(uint _proposalId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress,uint _GNTPayableTokenAmount)
    {
        GD=GovernanceData(GDAddress);
        MR=MemberRoles(MRAddress);
        PC=ProposalCategory(PCAddress);
        
        uint propStatus;
        (,,,,,,propStatus) = GD.getProposalDetailsById1(_proposalId);
        uint currentVotingId; uint category;
        (category,currentVotingId,,,) = GD.getProposalDetailsById2(_proposalId);
        uint verdictOptions;
        (,,,verdictOptions) = GD.getProposalCategoryParams(_proposalId);

        require(AddressProposalVote[msg.sender][_proposalId] == 0 );
        require(GD.getBalanceOfMember(msg.sender) != 0 && propStatus == 2 && currentVotingId == 0);
        require(MR.getMemberRoleIdByAddress(msg.sender) == PC.getRoleSequencAtIndex(category,currentVotingId));
        payableGNTTokensSimpleVoting(_GNTPayableTokenAmount);
        
        uint8 paramInt; uint8 paramBytes32; uint8 paramAddress;
        (,,,paramInt,paramBytes32,paramAddress,,) = PC.getCategoryDetails(category);

        if(paramInt == _paramInt.length && paramBytes32 == _paramBytes32.length && paramAddress == _paramAddress.length)
        {
            uint stakeValue = setVerdictValue_givenByMember(_proposalId,_GNTPayableTokenAmount);
            GD.setProposalVerdictAddressAndStakeValue(_proposalId,msg.sender,stakeValue);
            verdictOptions = SafeMath.add(verdictOptions,1); 
            GD.setProposalCategoryParams(_proposalId,_paramInt,_paramBytes32,_paramAddress,verdictOptions);   
        } 
    }

    function proposalVoting(uint _proposalId,uint[] _verdictChosen,uint _GNTPayableTokenAmount)
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
        require(GD.getBalanceOfMember(msg.sender) != 0 && propStatus == 2 && _verdictChosen.length == 1);

        if(currentVotingId == 0)
            require(_verdictChosen[0] <= verdictOptions);
        else
            require(_verdictChosen[0]==intermediateVerdict || _verdictChosen[0]==0);
        uint roleId = MR.getMemberRoleIdByAddress(msg.sender);
        require(roleId == PC.getRoleSequencAtIndex(category,currentVotingId));

        if(AddressProposalVote[msg.sender][_proposalId] == 0)
        {
            uint votelength = getTotalVotes();
            increaseTotalVotes();
            allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_verdictChosen[0]] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_verdictChosen[0]],1);
            allProposalVoteAndTokenCount[_proposalId].totalTokenCount[roleId] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalTokenCount[roleId],GD.getBalanceOfMember(msg.sender));
            AddressProposalVote[msg.sender][_proposalId] = votelength;
            ProposalRoleVote[_proposalId][roleId].push(votelength);
            uint finalVoteValue = setVoteValue_givenByMember(_proposalId,_GNTPayableTokenAmount);
            allVotes.push(proposalVote(msg.sender,_proposalId,_verdictChosen,now,GD.getBalanceOfMember(msg.sender),_GNTPayableTokenAmount,finalVoteValue));
        }
        else 
            changeMemberVote(_proposalId,_verdictChosen,_GNTPayableTokenAmount);
    }

    function changeMemberVote(uint _proposalId,uint[] _verdictChosen,uint _GNTPayableTokenAmount) 
    {
        MR=MemberRoles(MRAddress); 
        uint roleId = MR.getMemberRoleIdByAddress(msg.sender);
        uint voteId = AddressProposalVote[msg.sender][_proposalId];
        uint[] verdictChosen = allVotes[voteId].verdictChosen;
        uint verdict = verdictChosen[0];
        
        allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][verdict] = SafeMath.sub(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][verdict],1);
        allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_verdictChosen[0]] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_verdictChosen[0]],1);
        allVotes[voteId].verdictChosen[0] = _verdictChosen[0];
        uint finalVoteValue = setVoteValue_givenByMember(_proposalId,_GNTPayableTokenAmount);
        allVotes[voteId].voteStakeGNT = _GNTPayableTokenAmount;
        allVotes[voteId].voteValue = finalVoteValue;

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
        address voter; uint[] verdictChosen;uint category; uint roleId; uint reward;uint voteid;
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
                verdictChosen = allVotes[voteid].verdictChosen;
                uint verdict = verdictChosen[0];
                require(verdict == finalVerdict);
                GD.transferTokenAfterFinalReward(voter,reward);  
            }
        }    
    }

}
