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

contract RankBasedVoting is VotingType
{
    using SafeMath for uint;
    address GDAddress;
    address MRAddress;
    address PCAddress;
    address GNTAddress;
    MemberRoles MR;
    ProposalCategory PC;
    MintableToken MT;
    GovernanceData  GD;
    mapping (uint=>uint) verdictOptionsByVoteId;
     
    function RankBasedVoting()
    {
        uint[] option;
        allVotes.push(proposalVote(0x00,0,option,now,0,0,0));
    }

    /// @dev Some amount to be paid while using GovBlocks contract service - Approve the contract to spend money on behalf of msg.sender
    function payableGNTTokensRankBasedVoting(uint _TokenAmount) public
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

    function addInTotalVotes(uint _proposalId,uint[] _verdictChosen,uint _GNTPayableTokenAmount,uint _finalVoteValue)
    {
        increaseTotalVotes();
        allVotes.push(proposalVote(msg.sender,_proposalId,_verdictChosen,now,GD.getBalanceOfMember(msg.sender),_GNTPayableTokenAmount,_finalVoteValue));
    }

    function addVerdictOption(uint _proposalId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress,uint _GNTPayableTokenAmount)
    {
        GD=GovernanceData(GDAddress);
        MR=MemberRoles(MRAddress);
        PC=ProposalCategory(PCAddress);

        uint verdictOptions;
        (,,,verdictOptions) = GD.getProposalCategoryParams(_proposalId);
        uint _categoryId;uint currentVotingId;
        (_categoryId,currentVotingId,,,) = GD.getProposalDetailsById2(_proposalId);

        require(currentVotingId == 0 && GD.getProposalStatus(_proposalId) == 2 && GD.getBalanceOfMember(msg.sender) != 0);
        require(MR.getMemberRoleIdByAddress(msg.sender) == PC.getRoleSequencAtIndex(_categoryId,currentVotingId) && AddressProposalVote[msg.sender][_proposalId] == 0 );
        payableGNTTokensRankBasedVoting(_GNTPayableTokenAmount);
        
        uint8 paramInt; uint8 paramBytes32; uint8 paramAddress;
        (,,,paramInt,paramBytes32,paramAddress,,) = PC.getCategoryDetails(_categoryId);

        if(paramInt == _paramInt.length && paramBytes32 == _paramBytes32.length && paramAddress == _paramAddress.length)
        {
            uint verdictValue = setVerdictValue_givenByMember(_proposalId,_GNTPayableTokenAmount);
            GD.setProposalVerdictAddressAndStakeValue(_proposalId,msg.sender,_GNTPayableTokenAmount,verdictValue);
            verdictOptions = SafeMath.add(verdictOptions,1);
            GD.setProposalCategoryParams(_proposalId,_paramInt,_paramBytes32,_paramAddress,verdictOptions);
        } 
    }

    function proposalVoting(uint _proposalId,uint[] _verdictChosen,uint _GNTPayableTokenAmount)
    {    
        GD=GovernanceData(GDAddress);
        MR=MemberRoles(MRAddress);
        PC=ProposalCategory(PCAddress);
        uint currentVotingId; uint category; uint intermediateVerdict;
        uint verdictOptions;
        (category,currentVotingId,intermediateVerdict,,) = GD.getProposalDetailsById2(_proposalId);
        (,,,verdictOptions) = GD.getProposalCategoryParams(_proposalId);

        require(GD.getBalanceOfMember(msg.sender) != 0 && GD.getProposalStatus(_proposalId) == 2);
        require(MR.getMemberRoleIdByAddress(msg.sender) == PC.getRoleSequencAtIndex(category,currentVotingId) && _verdictChosen.length <= verdictOptions);

        if(currentVotingId == 0)
        {   
            for(uint i=0; i<_verdictChosen.length; i++)
            {
                require(_verdictChosen[i] < verdictOptions);
            }
        }   
        else
            require(_verdictChosen[0]==intermediateVerdict || _verdictChosen[0]==0);


        if(AddressProposalVote[msg.sender][_proposalId] == 0)
        {
            uint votelength = getTotalVotes();
            submitAndUpdateNewMemberVote(_proposalId,currentVotingId,_verdictChosen,verdictOptions);
            allProposalVoteAndTokenCount[_proposalId].totalTokenCount[MR.getMemberRoleIdByAddress(msg.sender)] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalTokenCount[MR.getMemberRoleIdByAddress(msg.sender)],GD.getBalanceOfMember(msg.sender));
            AddressProposalVote[msg.sender][_proposalId] = votelength;
            ProposalRoleVote[_proposalId][MR.getMemberRoleIdByAddress(msg.sender)].push(votelength);
            verdictOptionsByVoteId[votelength] = verdictOptions;
            uint finalVoteValue = setVoteValue_givenByMember(_proposalId,_GNTPayableTokenAmount);
            addInTotalVotes(_proposalId,_verdictChosen,_GNTPayableTokenAmount,finalVoteValue);
        }
        else 
            changeMemberVote(_proposalId,_verdictChosen,_GNTPayableTokenAmount);
    }

    function changeMemberVote(uint _proposalId,uint[] _verdictChosen,uint _GNTPayableTokenAmount)  
    {
        MR=MemberRoles(MRAddress);
        GD=GovernanceData(GDAddress);
        uint voteId = AddressProposalVote[msg.sender][_proposalId];
        uint[] verdictChosen = allVotes[voteId].verdictChosen;

        uint verdictOptions; 
        (,,,verdictOptions) = GD.getProposalCategoryParams(_proposalId);
        uint currentVotingId;
        (,currentVotingId,,,) = GD.getProposalDetailsById2(_proposalId);

        allVotes[voteId].verdictChosen = _verdictChosen;
        verdictOptionsByVoteId[voteId] = verdictOptions;
        revertChangesInMemberVote(_proposalId,currentVotingId,verdictChosen,voteId);
        submitAndUpdateNewMemberVote(_proposalId,currentVotingId,_verdictChosen,verdictOptions);

        uint finalVoteValue = setVoteValue_givenByMember(_proposalId,_GNTPayableTokenAmount);
        allVotes[voteId].voteStakeGNT = _GNTPayableTokenAmount;
        allVotes[voteId].voteValue = finalVoteValue;
    }

    function revertChangesInMemberVote(uint _proposalId,uint _currentVotingId,uint[] _verdictChosen,uint _voteId)
    {
        if(_currentVotingId == 0)
        {
            uint previousVerdictOptions = verdictOptionsByVoteId[_voteId];
            for(uint i=0; i<_verdictChosen.length; i++)
            {
                uint sum = SafeMath.add(sum,(SafeMath.sub(previousVerdictOptions,i)));
            }

            for(i=0; i<_verdictChosen.length; i++)
            {
                uint voteValue = SafeMath.div(SafeMath.mul(SafeMath.sub(previousVerdictOptions,i),100),sum);
                allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][_verdictChosen[i]] = SafeMath.sub(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][_verdictChosen[i]],voteValue);
            }
        }
        else
        {
            allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][_verdictChosen[0]] = SafeMath.sub(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][_verdictChosen[0]],1);
        }
       
    }

    function submitAndUpdateNewMemberVote(uint _proposalId,uint _currentVotingId,uint[] _verdictChosen,uint _verdictOptions)
    {
        uint roleId = MR.getMemberRoleIdByAddress(msg.sender);

        if(_currentVotingId == 0)
        {
            for(uint i=0; i<_verdictChosen.length; i++)
            {
                uint sum = SafeMath.add(sum,(SafeMath.sub(_verdictOptions ,i)));
            }

            for(i=0; i<_verdictChosen.length; i++)
            {
                uint voteValue = SafeMath.div(SafeMath.mul(SafeMath.sub(_verdictOptions,i),100),sum);
                allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_verdictChosen[i]] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_verdictChosen[i]],voteValue);
            }
        } 
        else
        {   
            allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_verdictChosen[0]] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_verdictChosen[0]],1);
        }
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
        if(_memberStake != 0)
            MT.transferFrom(msg.sender,GNTAddress,_memberStake);

        uint tokensHeld = SafeMath.div((SafeMath.mul(SafeMath.mul(GD.getBalanceOfMember(msg.sender),100),100)),GD.getTotalTokenInSupply());
        uint value= SafeMath.mul(Math.max256(_memberStake,GD.scalingWeight()),Math.max256(tokensHeld,GD.membershipScalingFactor()));
        finalVoteValue = SafeMath.mul(GD.getMemberReputation(msg.sender),value);
    }  

    function closeProposalVote(uint _proposalId)
    {
        GD=GovernanceData(GDAddress);
        MR=MemberRoles(MRAddress);
        PC=ProposalCategory(PCAddress);
    
        uint currentVotingId; uint category;
        (category,currentVotingId,,,) = GD.getProposalDetailsById2(_proposalId);
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

    function giveReward_afterFinalDecision(uint _proposalId)
    {
        GD=GovernanceData(GDAddress); uint totalVoteValue;uint TotalTokensToDistribute;
        uint proposalValue; uint proposalStake;
        (proposalValue,proposalStake) = GD.getProposalValueAndStake(_proposalId);
        uint finalVerdict;
        (,,,finalVerdict,) = GD.getProposalDetailsById2(_proposalId);

        for(uint i=0; i<allVotes.length; i++)
        {
            for(uint j=0; j<GD.getVerdictAddedAddressLength(_proposalId); i++)
            {
                require(allVotes[i].voter == GD.getVerdictAddedAddressByProposalId(_proposalId,j));
                if(finalVerdict > 0)
                    totalVoteValue = GD.getVerdictValueByProposalId(_proposalId,finalVerdict) + proposalValue + allVotes[i].voteValue;
                else
                    TotalTokensToDistribute = GD.getVerdictStakeByProposalId(_proposalId,j) + proposalStake + SafeMath.div(SafeMath.mul(allVotes[i].voteStakeGNT,100),GD.globalRiskFactor());
            }

        }
        distributeReward(_proposalId,TotalTokensToDistribute,totalVoteValue,proposalStake);
    }

     function distributeReward(uint _proposalId,uint _TotalTokensToDistribute,uint _totalVoteValue,uint _proposalStake)
    {
        address proposalOwner;
        (proposalOwner,,,,,) = GD.getProposalDetailsById1(_proposalId);
        uint roleId;uint category;uint finalVerdict;
        (category,,,finalVerdict,) = GD.getProposalDetailsById2(_proposalId);
        address verdictOwner = GD.getVerdictAddedAddressByProposalId(_proposalId,finalVerdict);
        
        uint reward = (_proposalStake*_TotalTokensToDistribute)/_totalVoteValue;
        GD.transferTokenAfterFinalReward(proposalOwner,reward);
        
        uint verdictStake =GD.getVerdictStakeByProposalId(_proposalId,finalVerdict);
        reward = (verdictStake*_TotalTokensToDistribute)/_totalVoteValue;
        GD.transferTokenAfterFinalReward(verdictOwner,reward);

        for(uint j=0; j<PC.getRoleSequencLength(category); j++)
        {
            roleId = PC.getRoleSequencAtIndex(category,j);
            for(uint i=0; i<getProposalRoleVoteLength(_proposalId,roleId); i++)
            {
                uint voteid = getProposalRoleVote(_proposalId,roleId,i);
                require(allVotes[voteid].verdictChosen[0] == finalVerdict);
                reward = (allVotes[voteid].voteValue*_TotalTokensToDistribute)/_totalVoteValue;
                _TotalTokensToDistribute = _TotalTokensToDistribute - reward;
                GD.transferTokenAfterFinalReward(allVotes[voteid].voter,reward);
            }
        }
    }

}
