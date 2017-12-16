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

contract FeatureWeighted is VotingType
{
    using SafeMath for uint;
    address GDAddress;
    address MRAddress;
    address PCAddress;
    address GNTAddress;
    MemberRoles MR;
    ProposalCategory PC;
    GovernanceData GD;
    MintableToken MT;
    mapping(uint=>uint[]) allProposalFeatures;
    mapping(uint=>uint) allMemberFinalVerdictByVoteId;

    function FeatureWeighted()
    {
        uint[] option;
        allVotes.push(proposalVote(0x00,0,option,now,0,0,0));
    }

    /// @dev Some amount to be paid while using GovBlocks contract service - Approve the contract to spend money on behalf of msg.sender
    function payableGNTTokensFeatureWeighted(uint _TokenAmount) public
    {
        MT=MintableToken(GNTAddress);
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

    function getVoteDetailByid(uint _voteid) public constant returns(address voter,uint proposalId,uint[] verdictChosen,uint dateSubmit,uint voterTokens,uint voteStakeGNT,uint voteValue)
    {
        return(allVotes[_voteid].voter,allVotes[_voteid].proposalId,allVotes[_voteid].verdictChosen,allVotes[_voteid].dateSubmit,allVotes[_voteid].voterTokens,allVotes[_voteid].voteStakeGNT,allVotes[_voteid].voteValue);
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

    function addProposalFeature(uint _proposalId,uint[] _featureArray) 
    {
        require(allProposalFeatures[_proposalId].length == 0);
        for(uint i=0; i<_featureArray.length; i++)
        {
            allProposalFeatures[_proposalId].push(_featureArray[i]);
        }    
    }

    function getMaxLength(uint _verdictOptions,uint _featureLength) returns (uint maxLength)
    {
        if(_verdictOptions < _featureLength)
            maxLength = _featureLength;
        else
            maxLength = _verdictOptions;
    }

    function getFeatureRankTotal(uint _featureLength,uint[] _verdictChosen,uint _index) returns (uint sum)
    {
        for(uint j=0; j<_featureLength; j++)
        {
            _index+=1;
            sum = sum + _verdictChosen[_index];
        }
    }
    
    function addInTotalVotes(uint _proposalId,uint[] _verdictChosen,uint _GNTPayableTokenAmount,uint _finalVoteValue)
    {
        increaseTotalVotes();
        allVotes.push(proposalVote(msg.sender,_proposalId,_verdictChosen,now,GD.getBalanceOfMember(msg.sender),_GNTPayableTokenAmount,_finalVoteValue));
    }

    function getAddressProposalVote(uint _proposalId) constant returns (uint check)
    {
        check = AddressProposalVote[msg.sender][_proposalId];
    }

    function addVerdictOption(uint _proposalId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress,uint _GNTPayableTokenAmount)
    {
        GD=GovernanceData(GDAddress);
        MR=MemberRoles(MRAddress);
        PC=ProposalCategory(PCAddress);

        uint currentVotingId;uint _categoryId;
        (_categoryId,currentVotingId,,,) = GD.getProposalDetailsById2(_proposalId);
        uint verdictOptions;
        (,,,verdictOptions) = GD.getProposalCategoryParams(_proposalId);

        require(currentVotingId == 0 && GD.getBalanceOfMember(msg.sender) != 0 && GD.getProposalStatus(_proposalId) == 2);
        require(MR.getMemberRoleIdByAddress(msg.sender) == PC.getRoleSequencAtIndex(_categoryId,currentVotingId) && AddressProposalVote[msg.sender][_proposalId] == 0 );
        payableGNTTokensFeatureWeighted(_GNTPayableTokenAmount);
        
        uint8 paramInt; uint8 paramBytes32; uint8 paramAddress;
        (,,,paramInt,paramBytes32,paramAddress,,) = PC.getCategoryDetails(_categoryId);

        if(paramInt == _paramInt.length && paramBytes32 == _paramBytes32.length && paramAddress == _paramAddress.length)
        {
            uint verdictValue = setVerdictValue_givenByMember(_proposalId,_GNTPayableTokenAmount);
            GD.setProposalVerdictAddressAndStakeValue(_proposalId,msg.sender,_GNTPayableTokenAmount,verdictValue);
            verdictOptions = SafeMath.add(verdictOptions,1);
            GD.setProposalCategoryParams(_categoryId,_proposalId,_paramInt,_paramBytes32,_paramAddress,verdictOptions); 
        } 
    }

    function proposalVoting(uint _proposalId,uint[] _verdictChosen,uint _GNTPayableTokenAmount)
    {    
        GD=GovernanceData(GDAddress);
        MR=MemberRoles(MRAddress);
        PC=ProposalCategory(PCAddress);

        uint voteValue; uint voteLength;
        uint currentVotingId; uint category; uint intermediateVerdict;
        uint featureLength = allProposalFeatures[_proposalId].length;
        (category,currentVotingId,intermediateVerdict,,) = GD.getProposalDetailsById2(_proposalId);

        require(GD.getBalanceOfMember(msg.sender) != 0 && GD.getProposalStatus(_proposalId) == 2 && _verdictChosen.length <=  SafeMath.mul(featureLength+1,GD.getTotalVerdictOptions(_proposalId)));
        require(MR.getMemberRoleIdByAddress(msg.sender) == PC.getRoleSequencAtIndex(category,currentVotingId));

        if(currentVotingId == 0)
        {
            for(uint i=0; i<_verdictChosen.length; i++)
            {
                require(_verdictChosen[i] <= getMaxLength(GD.getTotalVerdictOptions(_proposalId),featureLength));
            }
        }   
        else
            require(_verdictChosen[0]==intermediateVerdict || _verdictChosen[0]==0);

        if(AddressProposalVote[msg.sender][_proposalId] == 0)
        {
            voteLength = getTotalVotes();
            submitAndUpdateNewMemberVote(_proposalId,currentVotingId,_verdictChosen,featureLength,voteLength);
            uint finalVoteValue = setVoteValue_givenByMember(_proposalId,_GNTPayableTokenAmount);
            allProposalVoteAndTokenCount[_proposalId].totalTokenCount[MR.getMemberRoleIdByAddress(msg.sender)] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalTokenCount[MR.getMemberRoleIdByAddress(msg.sender)],GD.getBalanceOfMember(msg.sender));
            AddressProposalVote[msg.sender][_proposalId] = voteLength;
            ProposalRoleVote[_proposalId][MR.getMemberRoleIdByAddress(msg.sender)].push(voteLength);
            GD.setVoteidAgainstProposal(_proposalId,voteLength);
            addInTotalVotes(_proposalId,_verdictChosen,_GNTPayableTokenAmount,finalVoteValue);

        }
        else 
            changeMemberVote(_proposalId,_verdictChosen,featureLength,_GNTPayableTokenAmount);
    }

    function changeMemberVote(uint _proposalId,uint[] _verdictChosen,uint featureLength,uint _GNTPayableTokenAmount)  
    {
        MR=MemberRoles(MRAddress);
        GD=GovernanceData(GDAddress);
        uint voteId = AddressProposalVote[msg.sender][_proposalId];
        uint[] verdictChosen = allVotes[voteId].verdictChosen;
        uint currentVotingId;
        (,currentVotingId,,,) = GD.getProposalDetailsById2(_proposalId);

        revertChangesInMemberVote(_proposalId,currentVotingId,verdictChosen,voteId,featureLength);
        submitAndUpdateNewMemberVote(_proposalId,currentVotingId,_verdictChosen,featureLength,voteId);
        allVotes[voteId].verdictChosen = _verdictChosen;
        
        uint finalVoteValue = setVoteValue_givenByMember(_proposalId,_GNTPayableTokenAmount);
        allVotes[voteId].voteStakeGNT = _GNTPayableTokenAmount;
        allVotes[voteId].voteValue = finalVoteValue;

    }

    function revertChangesInMemberVote(uint _proposalId,uint currentVotingId,uint[] verdictChosen,uint voteId,uint featureLength)
    {
        if(currentVotingId == 0)
        {
            for(uint i=0; i<verdictChosen.length; i=i+featureLength+1)
            {
                uint sum =0;      
                for(uint j=i+1; j<=featureLength+i; j++)
                {
                    sum = sum + verdictChosen[j];
                }
                uint voteValue = SafeMath.div(SafeMath.mul(sum,100),featureLength);
                allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][verdictChosen[i]] = SafeMath.sub(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][verdictChosen[i]],voteValue);  
            }
        }
        else
        {
            allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][verdictChosen[0]] = SafeMath.sub(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][verdictChosen[0]],1);
        }
    }

    function submitAndUpdateNewMemberVote(uint _proposalId,uint currentVotingId,uint[] _verdictChosen,uint _featureLength,uint _voteId)
    {
        if(currentVotingId == 0)
        {
            uint max=0;uint maxValue;
            for(uint i=0; i<_verdictChosen.length; i=i+_featureLength+1)
            {
                uint sum =0;      
                for(uint j=i+1; j<=_featureLength+i; j++)
                {
                    sum = sum + _verdictChosen[j];
                }
                uint voteValue = SafeMath.div(SafeMath.mul(sum,100),_featureLength);
               
                if(maxValue < voteValue)
                {    
                    max = i;
                    maxValue = voteValue;
                }
                allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][_verdictChosen[i]] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][_verdictChosen[i]],voteValue);
            }
            allMemberFinalVerdictByVoteId[_voteId] = max;
        }  
        else
        {
            allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][_verdictChosen[0]] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][_verdictChosen[0]],1);
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
        GD=GovernanceData(GDAddress);
        uint voteValueFavour; uint voterStake; uint wrongOptionStake;
        uint totalVoteValue; uint totalTokenToDistribute;uint returnTokens;
        uint finalVerdict; uint proposalValue; uint proposalStake; 

        (proposalValue,proposalStake) = GD.getProposalValueAndStake(_proposalId);
        (,,,finalVerdict,) = GD.getProposalDetailsById2(_proposalId);

        for(uint i=0; i<GD.getTotalVoteLengthAgainstProposal(_proposalId); i++)
        {
            uint voteid = GD.getVoteIdByProposalId(_proposalId,i);
            if(allVotes[voteid].verdictChosen[0] == finalVerdict)
            {
                voteValueFavour = voteValueFavour + allVotes[voteid].voteValue;
            }
            else
            {
                voterStake = voterStake + allVotes[voteid].voteStakeGNT*(1/GD.globalRiskFactor());
                returnTokens = allVotes[voteid].voteStakeGNT*(1-(1/GD.globalRiskFactor()));
                GD.transferBackGNTtoken(allVotes[voteid].voter,returnTokens);
            }
        }

        for(i=0; i<GD.getVerdictAddedAddressLength(_proposalId); i++)
        {
            if(i!= finalVerdict)         
                 wrongOptionStake = wrongOptionStake + GD.getVerdictStakeByProposalId(_proposalId,i);
        }

        totalVoteValue = GD.getVerdictValueByProposalId(_proposalId,finalVerdict) + voteValueFavour; 
        totalTokenToDistribute = wrongOptionStake + voterStake;

        if(finalVerdict>0)
            totalVoteValue = totalVoteValue + proposalValue;
        else
            totalTokenToDistribute = totalTokenToDistribute + proposalStake;

        distributeReward(_proposalId,totalTokenToDistribute,totalVoteValue,proposalStake);
    }

    function distributeReward(uint _proposalId,uint _totalTokenToDistribute,uint _totalVoteValue,uint _proposalStake)
    {
        address proposalOwner;uint reward;uint transferToken;
        (proposalOwner,,,,,) = GD.getProposalDetailsById1(_proposalId);
        uint roleId;uint category;uint finalVerdict;
        (category,,,finalVerdict,) = GD.getProposalDetailsById2(_proposalId);
 
        if(finalVerdict > 0)
        {
            reward = (_proposalStake*_totalTokenToDistribute)/_totalVoteValue;
            transferToken = _proposalStake + reward;
            GD.transferBackGNTtoken(proposalOwner,transferToken);

            address verdictOwner = GD.getVerdictAddressByProposalId(_proposalId,finalVerdict);
            uint verdictStake =GD.getVerdictStakeByProposalId(_proposalId,finalVerdict);
            transferToken = verdictStake + reward;
            GD.transferBackGNTtoken(verdictOwner,transferToken);
        }

        for(uint i=0; i<GD.getTotalVoteLengthAgainstProposal(_proposalId); i++)
        {
            uint voteid = GD.getVoteIdByProposalId(_proposalId,i);
            require(allMemberFinalVerdictByVoteId[voteid] == finalVerdict);
                reward = (allVotes[voteid].voteValue*_totalTokenToDistribute)/_totalVoteValue;
                transferToken = allVotes[voteid].voteStakeGNT + reward;
                GD.transferBackGNTtoken(allVotes[voteid].voter,transferToken);
        }
    }
}
