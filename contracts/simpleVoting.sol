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
import "./Master.sol";
import "./StandardVotingType.sol";
import "./GovernanceData.sol";
import "./GBTController.sol";
import "./Governance.sol";

contract SimpleVoting is VotingType
{
    using SafeMath for uint;
    using Math for uint;
    address GDAddress;
    address MRAddress;
    address PCAddress;
    address GBTAddress;
    address BTAddress;
    address G1Address;
    address public masterAddress;
    address SVTAddress;
    address GBTCAddress;
    GBTController GBTC;
    MemberRoles MR;
    Governance G1;
    BasicToken BT;
    ProposalCategory PC;
    GovernanceData GD;
    StandardVotingType SVT;
    Master MS;
    uint constructorCheck;

    modifier onlyInternal {
        MS=Master(masterAddress);
        require(MS.isInternal(msg.sender) == 1);
        _; 
    }

    function SimpleVotingInitiate()
    {
        require(constructorCheck == 0);
        uint[] optionChosen;
        allVotes.push(proposalVote(0x00,0,optionChosen,now,0,0,0));
        votingTypeName = "Simple Voting";
        constructorCheck =1;
    }
    
    /// @dev Change master's contract address
    function changeMasterAddress(address _masterContractAddress)
    {
        if(masterAddress == 0x000)
            masterAddress = _masterContractAddress;
        else
        {
            MS=Master(masterAddress);
            require(MS.isInternal(msg.sender) == 1);
                masterAddress = _masterContractAddress;
        }
    }
    
    /// @dev Some amount to be paid while using GovBlocks contract service - Approve the contract to spend money on behalf of msg.sender
    function payableGBTTokensSimpleVoting(address _member,uint _TokenAmount) internal
    {
        GBTC=GBTController(GBTCAddress);
        GD=GovernanceData(GDAddress);
        require(_TokenAmount >= GD.GBTStakeValue());
        GBTC.receiveGBT(_member,_TokenAmount);
    }
    
    function changeAllContractsAddress(address _StandardVotingAddress,address _GDcontractAddress, address _MRcontractAddress, address _PCcontractAddress) onlyInternal
    {
        SVTAddress = _StandardVotingAddress;
        GDAddress = _GDcontractAddress;
        MRAddress = _MRcontractAddress;
        PCAddress = _PCcontractAddress;
    }

    function changeGovernanceAddress(address _G1ContractAddress)
    {
        G1Address = _G1ContractAddress;
    }

    // /// @dev Changes GBT contract Address. //NEW
    // function changeGBTtokenAddress(address _GBTcontractAddress) onlyInternal
    // {
    //     GBTAddress = _GBTcontractAddress;
    // }

    function changeGBTControllerAddress(address _GBTCAddress)
    {
        GBTCAddress = _GBTCAddress;
    }

    function getTotalVotes() constant returns (uint _votesTotal)
    {
        return(allVotes.length);
    }

    function increaseTotalVotes() internal returns (uint _totalVotes)
    {
        _totalVotes = SafeMath.add(allVotesTotal,1);  
        allVotesTotal=_totalVotes;
    } 

    function getVoteDetailByid(uint _voteid) public constant returns(address voter,uint proposalId,uint[] optionChosen,uint dateSubmit,uint voterTokens,uint voteStakeGBT,uint voteValue)
    {
        return(allVotes[_voteid].voter,allVotes[_voteid].proposalId,allVotes[_voteid].optionChosen,allVotes[_voteid].dateSubmit,allVotes[_voteid].voterTokens,allVotes[_voteid].voteStakeGBT,allVotes[_voteid].voteValue);
    }

    /// @dev Get the vote count for options of proposal when giving Proposal id and Option index.
    function getProposalVoteAndTokenCountByRoleId(uint _proposalId,uint _roleId,uint _optionIndex) public constant returns(uint totalVotes,uint totalToken)
    {
        totalVotes = allProposalVoteAndTokenCount[_proposalId].totalVoteCount[_roleId][_optionIndex];
        totalToken = allProposalVoteAndTokenCount[_proposalId].totalTokenCount[_roleId];
    }

    function getVoteLengthAgainstRole(uint _proposalId,uint _roleId) constant returns(uint[] totalVotes)
    {
        return ProposalRoleVote[_proposalId][_roleId];
    }

    function getVoteIdByIndex(uint _proposalId,uint _roleId,uint _index)constant returns(uint voteId,uint index)
    {
        index= _index;
        return (ProposalRoleVote[_proposalId][_roleId][_index],index);
    }

    function transferVoteStakeSV(uint _memberStake) onlyInternal
    {
        GBTC=GBTController(GBTCAddress);
        if(_memberStake != 0)
            GBTC.receiveGBT(msg.sender,_memberStake);
    }

    function addVerdictOption(uint _proposalId,address _member,uint _votingTypeId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress,uint _GBTPayableTokenAmount,string _optionHash) onlyInternal
    {
        SVT=StandardVotingType(SVTAddress);
        SVT.addVerdictOptionSVT(_proposalId,_member,_votingTypeId,_paramInt,_paramBytes32,_paramAddress,_GBTPayableTokenAmount,_optionHash);
        payableGBTTokensSimpleVoting(_member,_GBTPayableTokenAmount);
    }
     function initiateVerdictOption(uint _proposalId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress,uint _GBTPayableTokenAmount,string _optionHash) 
    {
        addVerdictOption(_proposalId,msg.sender,0,_paramInt,_paramBytes32,_paramAddress, _GBTPayableTokenAmount, _optionHash);
     }

    function proposalVoting(uint _proposalId,uint[] _optionChosen,uint _GBTPayableTokenAmount) 
    {
        GD=GovernanceData(GDAddress);
        MR=MemberRoles(MRAddress);
        PC=ProposalCategory(PCAddress);
        SVT=StandardVotingType(SVTAddress);
        G1=Governance(G1Address);

        uint currentVotingId; uint category; uint intermediateVerdict;
        (category,currentVotingId,intermediateVerdict,,) = GD.getProposalDetailsById2(_proposalId); //1,0,0
        uint verdictOptions;
        (,,,verdictOptions) = GD.getProposalOptions(_proposalId); //7
        
        require(msg.sender != GD.getOptionAddressByProposalId(_proposalId,_optionChosen[0]));
        require(GD.getBalanceOfMember(msg.sender) != 0 && GD.getProposalStatus(_proposalId) == 2 && _optionChosen.length == 1);

        if(currentVotingId == 0)
            require(_optionChosen[0] <= verdictOptions);
        else
            require(_optionChosen[0]==intermediateVerdict || _optionChosen[0]==0);
            
        uint roleId = MR.getMemberRoleIdByAddress(msg.sender);
        require(roleId == PC.getRoleSequencAtIndex(category,currentVotingId));

        if(AddressProposalVote[msg.sender][_proposalId] == 0)
        {
            uint votelength = getTotalVotes();
            increaseTotalVotes();
            uint finalVoteValue = SVT.setVoteValue_givenByMember(msg.sender,_proposalId,_GBTPayableTokenAmount);
            allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_optionChosen[0]] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_optionChosen[0]],1);
            allProposalVoteAndTokenCount[_proposalId].totalTokenCount[roleId] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalTokenCount[roleId],GD.getBalanceOfMember(msg.sender));
            AddressProposalVote[msg.sender][_proposalId] = votelength;
            ProposalRoleVote[_proposalId][roleId].push(votelength);
            GD.setVoteIdAgainstProposal(_proposalId,votelength);
            GD.addInTotalVotes(msg.sender);
            allVotes.push(proposalVote(msg.sender,_proposalId,_optionChosen,now,GD.getBalanceOfMember(msg.sender),_GBTPayableTokenAmount,finalVoteValue));
            G1.checkRoleVoteClosing(_proposalId,getVoteLengthAgainstRole(_proposalId,roleId).length);
            transferVoteStakeSV(_GBTPayableTokenAmount);
        }
        else 
            changeMemberVote(_proposalId,_optionChosen,ProposalRoleVote[_proposalId][roleId].length);
    }

    function changeMemberVote(uint _proposalId,uint[] _optionChosen,uint _GBTPayableTokenAmount) internal
    {
        MR=MemberRoles(MRAddress);
        G1=Governance(G1Address);
        GD=GovernanceData(GDAddress);
        SVT=StandardVotingType(SVTAddress);

        uint roleId = MR.getMemberRoleIdByAddress(msg.sender);
        uint voteId = AddressProposalVote[msg.sender][_proposalId];
        uint[] optionChosen = allVotes[voteId].optionChosen;
        
        allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][optionChosen[0]] = SafeMath.sub(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][optionChosen[0]],1);
        allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_optionChosen[0]] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][_optionChosen[0]],1);
        allVotes[voteId].optionChosen[0] = _optionChosen[0];

        uint finalVoteValue = SVT.setVoteValue_givenByMember(msg.sender,_proposalId,_GBTPayableTokenAmount);
        allVotes[voteId].voteStakeGBT = _GBTPayableTokenAmount;
        allVotes[voteId].voteValue = finalVoteValue;
        G1.checkRoleVoteClosing(_proposalId,getVoteLengthAgainstRole(_proposalId,roleId).length);
    }

    function closeProposalVote(uint _proposalId,address _memberAddress)
    {
        SVT=StandardVotingType(SVTAddress);
        SVT.closeProposalVoteSVT(_memberAddress,0,_proposalId);
    }

    function giveReward_afterFinalDecision(uint _proposalId) public
    {
        GD=GovernanceData(GDAddress);
        uint voteValueFavour; uint voterStake; uint wrongOptionStake; uint returnTokens;
        uint totalVoteValue; uint totalTokenToDistribute; 
        uint finalVerdict; uint proposalValue; uint proposalStake; 

        (,proposalValue,proposalStake) = GD.getProposalValueAndStake(_proposalId);
        (,,,,finalVerdict,) = GD.getProposalDetailsById2(_proposalId);

        for(uint i=0; i<GD.getTotalVoteLengthAgainstProposal(_proposalId); i++)
        {
            uint voteid = GD.getVoteIdByProposalId(_proposalId,i);
            if(allVotes[voteid].optionChosen[0] == finalVerdict)
            {
                voteValueFavour = SafeMath.add(voteValueFavour,allVotes[voteid].voteValue);
            }
            else
            {
                voterStake = SafeMath.add(voterStake,SafeMath.mul(allVotes[voteid].voteStakeGBT,(SafeMath.div(SafeMath.mul(1,100),GD.globalRiskFactor()))));
                returnTokens = SafeMath.mul(allVotes[voteid].voteStakeGBT,(SafeMath.sub(1,(SafeMath.div(SafeMath.mul(1,100),GD.globalRiskFactor())))));
                G1.transferBackGBTtoken(allVotes[voteid].voter,returnTokens);
            }
        }

        for(i=0; i<GD.getOptionAddedAddressLength(_proposalId); i++)
        {
            if(i!= finalVerdict)         
                wrongOptionStake = SafeMath.add(wrongOptionStake,GD.getOptionStakeByProposalId(_proposalId,i));
        }

        totalVoteValue = SafeMath.add(GD.getOptionValueByProposalId(_proposalId,finalVerdict),voteValueFavour);
        totalTokenToDistribute = SafeMath.add(wrongOptionStake,voterStake);

        if(finalVerdict>0)
            totalVoteValue = SafeMath.add(totalVoteValue,proposalValue); // accpted
        else
            totalTokenToDistribute = SafeMath.add(totalTokenToDistribute,proposalStake); // denied

        distributeReward(_proposalId,totalTokenToDistribute,totalVoteValue,proposalStake);
    }

    function distributeReward(uint _proposalId,uint _totalTokenToDistribute,uint _totalVoteValue,uint _proposalStake) internal
    {
        GD=GovernanceData(GDAddress);
        G1=Governance(G1Address);

        uint reward;uint transferToken;
        uint finalVerdict;
        (,,,,finalVerdict,) = GD.getProposalDetailsById2(_proposalId);
        uint addMemberPoints; uint subMemberPoints;
        (,,addMemberPoints,,,subMemberPoints)=GD.getMemberReputationPoints();
 
        if(finalVerdict > 0)
        {
            reward = SafeMath.div(SafeMath.mul(_proposalStake,_totalTokenToDistribute),_totalVoteValue);
            transferToken = SafeMath.add(_proposalStake,reward);
            G1.transferBackGBTtoken(GD.getProposalOwner(_proposalId),transferToken);

            reward = SafeMath.div(SafeMath.mul(GD.getOptionStakeByProposalId(_proposalId,finalVerdict),_totalTokenToDistribute),_totalVoteValue);
            transferToken = SafeMath.add(GD.getOptionStakeByProposalId(_proposalId,finalVerdict),reward);
            G1.transferBackGBTtoken(GD.getOptionAddressByProposalId(_proposalId,finalVerdict),transferToken);
        }

        for(uint i=0; i<GD.getTotalVoteLengthAgainstProposal(_proposalId); i++)
        {
            uint voteid = GD.getVoteIdByProposalId(_proposalId,i);
            if(allVotes[voteid].optionChosen[0] == finalVerdict)
            {
                reward = SafeMath.div(SafeMath.mul(allVotes[voteid].voteValue,_totalTokenToDistribute),_totalVoteValue);
                transferToken = SafeMath.add(allVotes[voteid].voteStakeGBT,reward);
                G1.transferBackGBTtoken(allVotes[voteid].voter,transferToken);
                G1.updateMemberReputation1(allVotes[voteid].voter,(GD.getMemberReputation(allVotes[voteid].voter)+addMemberPoints));
            }
            else
            {
                G1.updateMemberReputation1(allVotes[voteid].voter,(GD.getMemberReputation(allVotes[voteid].voter)-subMemberPoints));
            }
               
        } 
        G1.updateMemberReputation(_proposalId,finalVerdict);
    }

}

