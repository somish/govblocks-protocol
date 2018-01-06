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
    address masterAddress;
    MemberRoles MR;
    ProposalCategory PC;
    GovernanceData GD;
    MintableToken MT;
    mapping(uint=>uint[]) allProposalFeatures;

    function FeatureWeighted()
    {
        uint[] option;
        allVotes.push(proposalVote(0x00,0,option,now,0,0,0));
        votingTypeName = "FeatureWeighted";
    }

    /// @dev Change master's contract address
    function changeMasterAddress(address _masterContractAddress)
    {
        masterAddress = _masterContractAddress;
    }

    /// @dev Some amount to be paid while using GovBlocks contract service - Approve the contract to spend money on behalf of msg.sender
    function payableGNTTokensFeatureWeighted(uint _TokenAmount) public
    {
        MT=MintableToken(GNTAddress);
        require(_TokenAmount >= GD.GNTStakeValue());
        MT.transferFrom(msg.sender,GNTAddress,_TokenAmount);
    }

    function changeAllContractsAddress(address _GDcontractAddress, address _MRcontractAddress, address _PCcontractAddress) public
    {
        GDAddress = _GDcontractAddress;
        MRAddress = _MRcontractAddress;
        PCAddress = _PCcontractAddress;
    }

    /// @dev Changes GNT contract Address. //NEW
    function changeGNTtokenAddress(address _GNTcontractAddress)
    {
        GNTAddress = _GNTcontractAddress;
    }

    function getTotalVotes()  constant returns (uint votesTotal)
    {
        return(allVotes.length);
    }

    function increaseTotalVotes() returns (uint _totalVotes)
    {
        _totalVotes = SafeMath.add(allVotesTotal,1);  
        allVotesTotal=_totalVotes;
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
            _index = SafeMath.add(_index,1);
            sum = SafeMath.add(sum,_verdictChosen[_index]);
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
        uint8 verdictOptions;
        (,,,verdictOptions) = GD.getProposalCategoryParams(_proposalId);

        require(currentVotingId == 0 && GD.getBalanceOfMember(msg.sender) != 0 && GD.getProposalStatus(_proposalId) == 2);
        require(MR.getMemberRoleIdByAddress(msg.sender) == PC.getRoleSequencAtIndex(_categoryId,currentVotingId) && AddressProposalVote[msg.sender][_proposalId] == 0 );
        payableGNTTokensFeatureWeighted(_GNTPayableTokenAmount);
        
        uint8 paramInt; uint8 paramBytes32; uint8 paramAddress;
        (,,,paramInt,paramBytes32,paramAddress,,) = PC.getCategoryDetails(_categoryId);

        if(paramInt == _paramInt.length && paramBytes32 == _paramBytes32.length && paramAddress == _paramAddress.length)
        {
            uint optionValue = setOptionValue_givenByMember(_proposalId,_GNTPayableTokenAmount);
            GD.setProposalVerdictAddressAndStakeValue(_proposalId,msg.sender,_GNTPayableTokenAmount,optionValue);
            verdictOptions = verdictOptions+1;
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
                    sum = SafeMath.add(sum,verdictChosen[j]);
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
            for(uint i=0; i<_verdictChosen.length; i=i+_featureLength+1)
            {
                uint sum =0;
                require(msg.sender != GD.getVerdictAddressByProposalId(_proposalId,i));

                for(uint j=i+1; j<=_featureLength+i; j++)
                {
                    sum = SafeMath.add(sum,_verdictChosen[j]);
                }
                uint voteValue = SafeMath.div(SafeMath.mul(sum,100),_featureLength);
                allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][_verdictChosen[i]] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][_verdictChosen[i]],voteValue);
            }
        }  
        else
        {
            allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][_verdictChosen[0]] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][_verdictChosen[0]],1);
        }
    }

    function setOptionValue_givenByMember(uint _proposalId,uint _memberStake) public returns (uint finalOptionValue)
    {
        GD=GovernanceData(GDAddress);
        uint memberLevel = Math.max256(GD.getMemberReputation(msg.sender),1);
        uint tokensHeld = SafeMath.div((SafeMath.mul(SafeMath.mul(GD.getBalanceOfMember(msg.sender),100),100)),GD.getTotalTokenInSupply());
        uint maxValue= Math.max256(tokensHeld,GD.membershipScalingFactor());

        finalOptionValue = SafeMath.mul(SafeMath.mul(GD.globalRiskFactor(),memberLevel),SafeMath.mul(_memberStake,maxValue));
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
    
        uint8 currentVotingId; uint8 category;
        (category,currentVotingId,,,) = GD.getProposalDetailsById2(_proposalId);
        uint8 verdictOptions;
        (,,,verdictOptions) = GD.getProposalCategoryParams(_proposalId);
    
        require(GD.checkProposalVoteClosing(_proposalId)==1);
        uint8 max; uint totalVotes; uint verdictVal; uint majorityVote;
        uint roleId = MR.getMemberRoleIdByAddress(msg.sender);

        max=0;  
        for(uint8 i = 0; i < verdictOptions; i++)
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
            currentVotingId = currentVotingId+1;
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
        uint finalVerdict;  
        uint _featureLength = allProposalFeatures[_proposalId].length;

        (,,,finalVerdict,) = GD.getProposalDetailsById2(_proposalId);

        for(uint i=0; i<GD.getTotalVoteLengthAgainstProposal(_proposalId); i++)
        {
            uint voteid = GD.getVoteIdByProposalId(_proposalId,i);
            if(allVotes[voteid].verdictChosen[0] == finalVerdict)
            {
                voteValueFavour = SafeMath.add(voteValueFavour,allVotes[voteid].voteValue);
            }
            else
            {
                voterStake = SafeMath.add(voterStake,SafeMath.mul(allVotes[voteid].voteStakeGNT,(SafeMath.div(SafeMath.mul(1,100),GD.globalRiskFactor()))));
                returnTokens = SafeMath.mul(allVotes[voteid].voteStakeGNT,(SafeMath.sub(1,(SafeMath.div(SafeMath.mul(1,100),GD.globalRiskFactor())))));
                GD.transferBackGNTtoken(allVotes[voteid].voter,returnTokens);
            }

            // uint voteid = GD.getVoteIdByProposalId(_proposalId,i);
            // for(uint j=0; j<allVotes[voteid].verdictChosen.length; j=i+_featureLength+1)
            // {
            //     if(allVotes[voteid].verdictChosen[j] == finalVerdict)
            //     {
            //         voteValueFavour = SafeMath.add(voteValueFavour,allVotes[voteid].voteValue)+getOptionValue1(voteid,_proposalId,j);
            //     }
            //     else
            //     {
            //         voterStake = SafeMath.add(voterStake,SafeMath.mul(allVotes[voteid].voteStakeGNT,(SafeMath.div(SafeMath.mul(1,100),GD.globalRiskFactor())))) + getOptionValue1(voteid,_proposalId,j);
            //         returnTokens = SafeMath.mul(allVotes[voteid].voteStakeGNT,(SafeMath.sub(1,(SafeMath.div(SafeMath.mul(1,100),GD.globalRiskFactor())))));
            //         GD.transferBackGNTtoken(allVotes[voteid].voter,returnTokens);
            //     }
            // }
        }

        for(i=0; i<GD.getVerdictAddedAddressLength(_proposalId); i++)
        {
            if(i!= finalVerdict)  
                wrongOptionStake = SafeMath.add(wrongOptionStake,GD.getVerdictStakeByProposalId(_proposalId,i));
        }

        totalVoteValue = SafeMath.add(GD.getVerdictValueByProposalId(_proposalId,finalVerdict),voteValueFavour);
        totalTokenToDistribute = SafeMath.add(wrongOptionStake,voterStake);

        if(finalVerdict>0)
            totalVoteValue = SafeMath.add(totalVoteValue,GD.getProposalValue(_proposalId));
        else
            totalTokenToDistribute = SafeMath.add(totalTokenToDistribute,GD.getProposalStake(_proposalId));

        distributeReward(_proposalId,totalTokenToDistribute,totalVoteValue);
    }

    function distributeReward(uint _proposalId,uint _totalTokenToDistribute,uint _totalVoteValue)
    {
        uint reward;uint transferToken;
        uint finalVerdict;
        (,,,finalVerdict,) = GD.getProposalDetailsById2(_proposalId);
         uint addMemberPoints; uint subMemberPoints;
        (,,addMemberPoints,,,subMemberPoints)=GD.getMemberReputationPoints();

        if(finalVerdict > 0)
        {
            reward = SafeMath.div(SafeMath.mul(GD.getProposalStake(_proposalId),_totalTokenToDistribute),_totalVoteValue);
            transferToken = SafeMath.add(GD.getProposalStake(_proposalId),reward);
            GD.transferBackGNTtoken(GD.getProposalOwner(_proposalId),transferToken);

            address verdictOwner = GD.getVerdictAddressByProposalId(_proposalId,finalVerdict);
            uint verdictStake = GD.getVerdictStakeByProposalId(_proposalId,finalVerdict);
            reward = SafeMath.div(SafeMath.mul(verdictStake,_totalTokenToDistribute),_totalVoteValue);
            transferToken = SafeMath.add(verdictStake,reward);
            GD.transferBackGNTtoken(verdictOwner,transferToken);
        }

        for(uint i=0; i<GD.getTotalVoteLengthAgainstProposal(_proposalId); i++)
        {
            uint voteid = GD.getVoteIdByProposalId(_proposalId,i);
            if(getOptionValue(voteid,_proposalId,finalVerdict) != 0)
            {
                reward = SafeMath.div(SafeMath.mul(allVotes[voteid].voteValue,_totalTokenToDistribute),_totalVoteValue);
                transferToken = SafeMath.add(allVotes[voteid].voteStakeGNT,reward);
                GD.transferBackGNTtoken(allVotes[voteid].voter,transferToken);
                GD.setMemberReputation1(allVotes[voteid].voter,SafeMath.add(GD.getMemberReputation(allVotes[voteid].voter),addMemberPoints));
            }
            else
            {
                GD.setMemberReputation1(allVotes[voteid].voter,SafeMath.sub(GD.getMemberReputation(allVotes[voteid].voter),subMemberPoints));
            }  
        }
        updateMemberReputation(_proposalId,finalVerdict);
    }

    function getOptionValue(uint _voteid,uint _proposalId,uint _finalVerdict) returns (uint optionValue)
    {
        uint[] _verdictChosen = allVotes[_voteid].verdictChosen;
        uint _featureLength = allProposalFeatures[_proposalId].length;

        for(uint i=0; i<_verdictChosen.length; i=i+_featureLength+1)
        {
            uint sum=0;
            require(_verdictChosen[i] == _finalVerdict);
                for(uint j=i+1; j<=_featureLength+i; j++)
                {
                    sum = SafeMath.add(sum,_verdictChosen[j]);
                }
                optionValue = SafeMath.div(SafeMath.mul(sum,100),_featureLength);
        }
    }

    function getOptionValue1(uint _voteid,uint _proposalId,uint _optionIndex) returns (uint optionValue)
    {   
        uint[] _verdictChosen = allVotes[_voteid].verdictChosen;
        uint _featureLength = allProposalFeatures[_proposalId].length; uint sum;

        for(uint j=_optionIndex+1; j<=_featureLength+_optionIndex; j++)
        {
            sum = SafeMath.add(sum,_verdictChosen[j]);
        }
        optionValue = SafeMath.div(SafeMath.mul(sum,100),_featureLength);
    }

    function updateMemberReputation(uint _proposalId,uint finalVerdict)
    {
        address _proposalOwner =  GD.getProposalOwner(_proposalId);
        address _finalOptionOwner = GD.getVerdictAddressByProposalId(_proposalId,finalVerdict);
        uint addProposalOwnerPoints; uint addOptionOwnerPoints; uint subProposalOwnerPoints; uint subOptionOwnerPoints;
        (addProposalOwnerPoints,addOptionOwnerPoints,,subProposalOwnerPoints,subOptionOwnerPoints,)=GD.getMemberReputationPoints();
        uint memberPoints1; uint memberPoints2;

        if(finalVerdict>0)
        {
            memberPoints1 = SafeMath.add(addProposalOwnerPoints,GD.getMemberReputation(_proposalOwner));
            memberPoints2 = SafeMath.add(addOptionOwnerPoints,GD.getMemberReputation(_finalOptionOwner));
            GD.setMemberReputation(_proposalOwner,_finalOptionOwner,memberPoints1,memberPoints2);  
        }
        else
        {
            memberPoints1 = SafeMath.sub(GD.getMemberReputation(_proposalOwner),subProposalOwnerPoints);
            GD.setMemberReputation1(_proposalOwner,memberPoints1);
            for(uint i=0; i<GD.getVerdictAddedAddressLength(_proposalId); i++)
            {
                address memberAddress = GD.getVerdictAddressByProposalId(_proposalId,i);
                memberPoints2 = SafeMath.sub(GD.getMemberReputation(memberAddress),subOptionOwnerPoints);
                GD.setMemberReputation1(memberAddress,memberPoints2);  
            }
        }
    }   
}
