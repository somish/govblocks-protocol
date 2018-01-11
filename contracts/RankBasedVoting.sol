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
import "./StandardVotingType.sol";

contract RankBasedVoting is VotingType
{
    using SafeMath for uint;
    address GDAddress;
    address MRAddress;
    address PCAddress;
    address GNTAddress;
    address masterAddress;
    address SVTAddress;
    MemberRoles MR;
    ProposalCategory PC;
    MintableToken MT;
    GovernanceData  GD;
    StandardVotingType SVT;
    uint8 constructorCheck;
    mapping (uint=>uint8) verdictOptionsByVoteId;
     
    function RankBasedVotingInitiate()
    {
        require(constructorCheck == 0 );
        uint[] option;
        allVotes.push(proposalVote(0x00,0,option,now,0,0,0));
        votingTypeName = "RankBasedVoting";
        constructorCheck = 1;
    }

    /// @dev Change master's contract address
    function changeMasterAddress(address _masterContractAddress)
    {
        masterAddress = _masterContractAddress;
    }

    /// @dev Some amount to be paid while using GovBlocks contract service - Approve the contract to spend money on behalf of msg.sender
    function payableGNTTokensRankBasedVoting(uint _TokenAmount) public
    {
        MT=MintableToken(GNTAddress);
        GD=GovernanceData(GDAddress);
        require(_TokenAmount >= GD.GNTStakeValue());
        MT.transferFrom(msg.sender,GNTAddress,_TokenAmount);
    }

    function changeAllContractsAddress(address _StandardVotingAddress,address _GDcontractAddress, address _MRcontractAddress, address _PCcontractAddress) public
    {
        SVTAddress = _StandardVotingAddress;
        GDAddress = _GDcontractAddress;
        MRAddress = _MRcontractAddress;
        PCAddress = _PCcontractAddress;
    }

    /// @dev Changes GNT contract Address. //NEW
    function changeGNTtokenAddress(address _GNTcontractAddress)
    {
        GNTAddress = _GNTcontractAddress;
    }

    function getTotalVotes() constant returns (uint votesTotal)
    {
        return(allVotes.length);
    }

    function increaseTotalVotes() internal returns (uint _totalVotes)
    {
        _totalVotes = SafeMath.add(allVotesTotal,1);  
        allVotesTotal=_totalVotes;
    }

    function getVoteDetailByid(uint _voteid) public constant returns(address voter,uint proposalId,uint[] optionChosen,uint dateSubmit,uint voterTokens,uint voteStakeGNT,uint voteValue)
    {
        return(allVotes[_voteid].voter,allVotes[_voteid].proposalId,allVotes[_voteid].optionChosen,allVotes[_voteid].dateSubmit,allVotes[_voteid].voterTokens,allVotes[_voteid].voteStakeGNT,allVotes[_voteid].voteValue);
    }

    /// @dev Get the vote count for options of proposal when giving Proposal id and Option index.
    function getProposalVoteAndTokenCountByRoleId(uint _proposalId,uint _roleId,uint _optionIndex) constant returns(uint totalVotes,uint totalToken)
    {
        totalVotes = allProposalVoteAndTokenCount[_proposalId].totalVoteCount[_roleId][_optionIndex];
        totalToken = allProposalVoteAndTokenCount[_proposalId].totalTokenCount[_roleId];
    }

    function addInTotalVotes(uint _proposalId,uint[] _optionChosen,uint _GNTPayableTokenAmount,uint _finalVoteValue) internal
    {
        increaseTotalVotes();
        allVotes.push(proposalVote(msg.sender,_proposalId,_optionChosen,now,GD.getBalanceOfMember(msg.sender),_GNTPayableTokenAmount,_finalVoteValue));
    }

    function addVerdictOption(uint _proposalId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress,uint _GNTPayableTokenAmount)
    {
        SVT.addVerdictOptionSVT(msg.sender,_proposalId,_paramInt,_paramBytes32,_paramAddress,_GNTPayableTokenAmount);
        payableGNTTokensRankBasedVoting(_GNTPayableTokenAmount);
    }

    function proposalVoting(uint _proposalId,uint[] _optionChosen,uint _GNTPayableTokenAmount)
    {    
        GD=GovernanceData(GDAddress);
        MR=MemberRoles(MRAddress);
        PC=ProposalCategory(PCAddress);
        SVT=StandardVotingType(SVTAddress);

        uint8 currentVotingId; uint8 category; uint8 intermediateVerdict;
        uint8 verdictOptions;
        (category,currentVotingId,intermediateVerdict,,) = GD.getProposalDetailsById2(_proposalId);
        (,,,verdictOptions) = GD.getProposalCategoryParams(_proposalId);

        require(GD.getBalanceOfMember(msg.sender) != 0 && GD.getProposalStatus(_proposalId) == 2);
        require(MR.getMemberRoleIdByAddress(msg.sender) == PC.getRoleSequencAtIndex(category,currentVotingId) && _optionChosen.length <= verdictOptions);

        if(currentVotingId == 0)
        {   
            for(uint i=0; i<_optionChosen.length; i++)
            {
                require(_optionChosen[i] < verdictOptions && msg.sender != GD.getOptionAddressByProposalId(_proposalId,i));
            }
        }   
        else
            require(_optionChosen[0]==intermediateVerdict || _optionChosen[0]==0);

        if(getVoteId_againstMember(msg.sender,_proposalId) == 0)
        {
            uint votelength = getTotalVotes();
            submitAndUpdateNewMemberVote(_proposalId,currentVotingId,_optionChosen,verdictOptions);
            uint finalVoteValue = SVT.setVoteValue_givenByMember(GNTAddress,_proposalId,_GNTPayableTokenAmount);
            allProposalVoteAndTokenCount[_proposalId].totalTokenCount[MR.getMemberRoleIdByAddress(msg.sender)] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalTokenCount[MR.getMemberRoleIdByAddress(msg.sender)],GD.getBalanceOfMember(msg.sender));
            setVoteId_againstMember(msg.sender,_proposalId,votelength);
            ProposalRoleVote[_proposalId][MR.getMemberRoleIdByAddress(msg.sender)].push(votelength);
            verdictOptionsByVoteId[votelength] = verdictOptions;
            GD.setVoteIdAgainstProposal(_proposalId,votelength);
            addInTotalVotes(_proposalId,_optionChosen,_GNTPayableTokenAmount,finalVoteValue);
        }
        else 
            changeMemberVote(_proposalId,_optionChosen,_GNTPayableTokenAmount);
    }

    function changeMemberVote(uint _proposalId,uint[] _optionChosen,uint _GNTPayableTokenAmount) internal
    {
        MR=MemberRoles(MRAddress);
        GD=GovernanceData(GDAddress);
        SVT=StandardVotingType(SVTAddress);

        uint voteId = getVoteId_againstMember(msg.sender,_proposalId);
        uint[] optionChosen = allVotes[voteId].optionChosen;

        uint8 verdictOptions; 
        (,,,verdictOptions) = GD.getProposalCategoryParams(_proposalId);
        uint8 currentVotingId;
        (,currentVotingId,,,) = GD.getProposalDetailsById2(_proposalId);

        allVotes[voteId].optionChosen = _optionChosen;
        verdictOptionsByVoteId[voteId] = verdictOptions;
        revertChangesInMemberVote(_proposalId,currentVotingId,optionChosen,voteId);
        submitAndUpdateNewMemberVote(_proposalId,currentVotingId,_optionChosen,verdictOptions);

        uint finalVoteValue = SVT.setVoteValue_givenByMember(GNTAddress,_proposalId,_GNTPayableTokenAmount);
        allVotes[voteId].voteStakeGNT = _GNTPayableTokenAmount;
        allVotes[voteId].voteValue = finalVoteValue;
    }

    function revertChangesInMemberVote(uint _proposalId,uint _currentVotingId,uint[] _optionChosen,uint _voteId) internal
    {
        if(_currentVotingId == 0)
        {
            uint previousVerdictOptions = verdictOptionsByVoteId[_voteId];
            for(uint i=0; i<_optionChosen.length; i++)
            {
                uint sum = SafeMath.add(sum,(SafeMath.sub(previousVerdictOptions,i)));
            }

            for(i=0; i<_optionChosen.length; i++)
            {
                uint voteValue = SafeMath.div(SafeMath.mul(SafeMath.sub(previousVerdictOptions,i),100),sum);
                allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][_optionChosen[i]] = SafeMath.sub(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][_optionChosen[i]],voteValue);
            }
        }
        else
        {
            allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][_optionChosen[0]] = SafeMath.sub(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][_optionChosen[0]],1);
        }
       
    }

    function submitAndUpdateNewMemberVote(uint _proposalId,uint _currentVotingId,uint[] _optionChosen,uint _verdictOptions) internal
    {
        uint roleId = MR.getMemberRoleIdByAddress(msg.sender);

        if(_currentVotingId == 0)
        {
            for(uint i=0; i<_optionChosen.length; i++)
            {
                uint sum = SafeMath.add(sum,(SafeMath.sub(_verdictOptions ,i)));
            }

            for(i=0; i<_optionChosen.length; i++)
            {
                uint voteValue = SafeMath.div(SafeMath.mul(SafeMath.sub(_verdictOptions,i),100),sum);
                allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_optionChosen[i]] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_optionChosen[i]],voteValue);
            }
        } 
        else
        {   
            allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_optionChosen[0]] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_optionChosen[0]],1);
        }
    }  

    function closeProposalVote(uint _proposalId)
    {
        SVT.closeProposalVoteSVT(msg.sender,1,_proposalId);
    }

    function giveReward_afterFinalDecision(uint _proposalId) public
    {
        GD=GovernanceData(GDAddress);
        uint voteValueFavour; uint voterStake; uint wrongOptionStake; uint returnTokens;
        uint totalVoteValue; uint totalTokenToDistribute;
        uint8 finalVerdict; 
        (,,,finalVerdict,) = GD.getProposalDetailsById2(_proposalId);


        for(uint i=0; i<GD.getTotalVoteLengthAgainstProposal(_proposalId); i++)
        {
            uint voteid = GD.getVoteIdByProposalId(_proposalId,i);
            if(allVotes[voteid].optionChosen[0] == finalVerdict)
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
            // for(uint j=0; j<allVotes[voteid].verdictChosen.length; j++)
            // {
            //     if(allVotes[voteid].verdictChosen[j] == finalVerdict)
            //     {
            //         voteValueFavour = SafeMath.add(voteValueFavour,allVotes[voteid].voteValue)+getOptionValue(voteid,_proposalId,j);
            //     }
            //     else
            //     {
            //         voterStake = SafeMath.add(voterStake,SafeMath.mul(allVotes[voteid].voteStakeGNT,(SafeMath.div(SafeMath.mul(1,100),GD.globalRiskFactor())))) + getOptionValue(voteid,_proposalId,j);
            //         returnTokens = SafeMath.mul(allVotes[voteid].voteStakeGNT,(SafeMath.sub(1,(SafeMath.div(SafeMath.mul(1,100),GD.globalRiskFactor())))));
            //         GD.transferBackGNTtoken(allVotes[voteid].voter,returnTokens);
            //     }
            // }
        }

        for(i=0; i<GD.getOptionAddedAddressLength(_proposalId); i++)
        {
            if(i!= finalVerdict)         
                wrongOptionStake = SafeMath.add(wrongOptionStake,GD.getOptionStakeByProposalId(_proposalId,i));
        }

        totalVoteValue = SafeMath.add(GD.getOptionValueByProposalId(_proposalId,finalVerdict),voteValueFavour);
        totalTokenToDistribute = SafeMath.add(wrongOptionStake,voterStake);

        if(finalVerdict>0)
            totalVoteValue = SafeMath.add(totalVoteValue,GD.getProposalValue(_proposalId));
        else
            totalTokenToDistribute = SafeMath.add(totalTokenToDistribute,GD.getProposalStake(_proposalId));

        distributeReward(_proposalId,totalTokenToDistribute,totalVoteValue);
    }

    function distributeReward(uint _proposalId,uint _totalTokenToDistribute,uint _totalVoteValue) internal
    {
        uint reward;uint transferToken;
        uint8 finalVerdict;
        (,,,finalVerdict,) = GD.getProposalDetailsById2(_proposalId);
        uint addMemberPoints; uint subMemberPoints;
        (,,addMemberPoints,,,subMemberPoints)=GD.getMemberReputationPoints();

        if(finalVerdict > 0)
        {
            reward = SafeMath.div(SafeMath.mul(GD.getProposalStake(_proposalId),_totalTokenToDistribute),_totalVoteValue);
            transferToken = SafeMath.add(GD.getProposalStake(_proposalId),reward);
            GD.transferBackGNTtoken(GD.getProposalOwner(_proposalId),transferToken);

            reward = SafeMath.div(SafeMath.mul(GD.getOptionStakeByProposalId(_proposalId,finalVerdict),_totalTokenToDistribute),_totalVoteValue);
            transferToken = SafeMath.add(GD.getOptionStakeByProposalId(_proposalId,finalVerdict),reward);
            GD.transferBackGNTtoken(GD.getOptionAddressByProposalId(_proposalId,finalVerdict),transferToken);
        }

        for(uint i=0; i<GD.getTotalVoteLengthAgainstProposal(_proposalId); i++)
        {
            uint voteid = GD.getVoteIdByProposalId(_proposalId,i);
            for(uint j=0; j<allVotes[voteid].optionChosen.length; j++)
            {
                if(allVotes[voteid].optionChosen[j] == finalVerdict)
                {
                    uint optionValue = getOptionValue(voteid,_proposalId,j);
                    reward = SafeMath.div(SafeMath.mul(allVotes[voteid].voteValue,_totalTokenToDistribute),_totalVoteValue);
                    transferToken = SafeMath.add(allVotes[voteid].voteStakeGNT,reward);
                    GD.transferBackGNTtoken(allVotes[voteid].voter,transferToken);
                    GD.updateMemberReputation1(allVotes[voteid].voter,SafeMath.add(addMemberPoints,GD.getMemberReputation(allVotes[voteid].voter)));
                }
                else
                {
                    GD.updateMemberReputation1(allVotes[voteid].voter,SafeMath.sub(GD.getMemberReputation(allVotes[voteid].voter),subMemberPoints));
                }
                    
            }        
        }
        GD.updateMemberReputation(_proposalId,finalVerdict);
    }

    function getOptionValue(uint voteid,uint _proposalId,uint _optionIndex) internal returns (uint optionValue)
    {
        uint[] _optionChosen = allVotes[voteid].optionChosen;
        uint8 _verdictOptions; 
        (,,,_verdictOptions) = GD.getProposalCategoryParams(_proposalId);

        for(uint i=0; i<_optionChosen.length; i++)
        {
            uint sum = SafeMath.add(sum,(SafeMath.sub(_verdictOptions ,i)));
        }
        optionValue = SafeMath.div(SafeMath.mul(SafeMath.sub(_verdictOptions,_optionIndex),100),sum);
    }

}
