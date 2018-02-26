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
        GD=GovernanceData(GDAddress);
        require(constructorCheck == 0);
        uint[] optionChosen;
        GD.addInVote(msg.sender,0,optionChosen,0,0);
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
    
    function changeAllContractsAddress(address _StandardVotingAddress,address _GDcontractAddress, address _MRcontractAddress, address _PCcontractAddress,address _G1ContractAddress) onlyInternal
    {
        SVTAddress = _StandardVotingAddress;
        GDAddress = _GDcontractAddress;
        MRAddress = _MRcontractAddress;
        PCAddress = _PCcontractAddress;
        G1Address = _G1ContractAddress;
    }

    function changeGBTControllerAddress(address _GBTCAddress) onlyInternal
    {
        GBTCAddress = _GBTCAddress;
    }

    function transferVoteStakeSV(uint _memberStake) onlyInternal
    {
        GBTC=GBTController(GBTCAddress);
        if(_memberStake != 0)
            GBTC.receiveGBT(msg.sender,_memberStake);
    }

    function addVerdictOption(uint _proposalId,address _member,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress,uint _GBTPayableTokenAmount,string _optionHash) onlyInternal
    {
        SVT=StandardVotingType(SVTAddress);
        SVT.addVerdictOptionSVT(_proposalId,_member,_paramInt,_paramBytes32,_paramAddress,_GBTPayableTokenAmount,_optionHash);
        payableGBTTokensSimpleVoting(_member,_GBTPayableTokenAmount);
    }
     
    function initiateVerdictOption(uint _proposalId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress,uint _GBTPayableTokenAmount,string _optionHash) 
    {
        addVerdictOption(_proposalId,msg.sender,_paramInt,_paramBytes32,_paramAddress, _GBTPayableTokenAmount, _optionHash);
    }

    function proposalVoting(uint _proposalId,uint[] _optionChosen,uint _GBTPayableTokenAmount) 
    {
        GD=GovernanceData(GDAddress);
        MR=MemberRoles(MRAddress);
        PC=ProposalCategory(PCAddress);
        SVT=StandardVotingType(SVTAddress);
        G1=Governance(G1Address);

        uint currentVotingId; uint category; uint intermediateVerdict;
        (,category,currentVotingId,intermediateVerdict,,) = GD.getProposalDetailsById2(_proposalId); //1,0,0
        uint verdictOptions;
        (,,,verdictOptions) = GD.getProposalOptionAll(_proposalId); //3
        
        require(msg.sender != GD.getOptionAddressByProposalId(_proposalId,_optionChosen[0]));
        require(GD.getBalanceOfMember(msg.sender) != 0 && GD.getProposalStatus(_proposalId) == 2 && _optionChosen.length == 1);

        if(currentVotingId == 0)
            require(_optionChosen[0] <= verdictOptions);
        else
            require(_optionChosen[0]==intermediateVerdict || _optionChosen[0]==0);
            
        uint roleId = MR.getMemberRoleIdByAddress(msg.sender);
        require(roleId == PC.getRoleSequencAtIndex(category,currentVotingId));

        if(GD.getVoteId_againstMember(msg.sender,_proposalId) == 0)
        {
            uint votelength = GD.allVotesTotal();
            uint finalVoteValue = SVT.setVoteValue_givenByMember(msg.sender,_proposalId,_GBTPayableTokenAmount);
            
            GD.setProposalVoteCount(_proposalId,roleId,_optionChosen[0],finalVoteValue);
            GD.setProposalTokenCount(_proposalId,roleId,msg.sender);
            
            GD.setVoteId_againstMember(msg.sender,_proposalId,votelength);
            GD.setVoteIdAgainstProposalRole(_proposalId,roleId,votelength);
            GD.setVoteIdAgainstProposal(_proposalId,votelength);
            GD.addInTotalVotes(msg.sender,votelength);
            
            G1.checkRoleVoteClosing(_proposalId,GD.getVoteLength(_proposalId,roleId));
            GD.addInVote(msg.sender,_proposalId,_optionChosen,_GBTPayableTokenAmount,finalVoteValue);
            GD.callVoteEvent(msg.sender,GD.getProposalVotingType(_proposalId),votelength);
            transferVoteStakeSV(_GBTPayableTokenAmount);
        }
        else 
            changeMemberVote(_proposalId,_optionChosen,_GBTPayableTokenAmount);
    }

    function changeMemberVote(uint _proposalId,uint[] _optionChosen,uint _GBTPayableTokenAmount) internal
    {
        MR=MemberRoles(MRAddress);
        G1=Governance(G1Address);
        GD=GovernanceData(GDAddress);
        SVT=StandardVotingType(SVTAddress);

        uint roleId = MR.getMemberRoleIdByAddress(msg.sender);
        uint voteId = GD.getVoteId_againstMember(msg.sender,_proposalId);
        uint voteVal = GD.getVoteValue(voteId);
        
        GD.editProposalVoteCount(_proposalId,roleId,GD.getOptionById(voteId,0),voteVal);
        GD.setProposalVoteCount(_proposalId,roleId,_optionChosen[0],voteVal);
        GD.setOptionChosen(voteId,_optionChosen[0]);

        // uint finalVoteValue = SVT.setVoteValue_givenByMember(msg.sender,_proposalId,_GBTPayableTokenAmount);
        // allVotes[voteId].voteStakeGBT = _GBTPayableTokenAmount;
        // allVotes[voteId].voteValue = finalVoteValue;
    }

    function closeProposalVote(uint _proposalId)
    {
        SVT=StandardVotingType(SVTAddress);
        SVT.closeProposalVoteSVT(_proposalId,msg.sender);
    }

    uint public voteValueFavour; uint public voterStake; uint public wrongOptionStake; uint public returnTokens;
    uint public totalVoteValue; uint public totalTokenToDistribute; 
    uint reward; uint public reward1; uint public reward2; uint public reward3;
    function giveReward_afterFinalDecision(uint _proposalId,address _memberAddress) 
    {
        GD=GovernanceData(GDAddress);
        G1=Governance(G1Address);
        
         voteValueFavour=0;  voterStake=0;  wrongOptionStake=0;  returnTokens=0;
         totalVoteValue=0;  totalTokenToDistribute=0; 
        uint finalVerdict;
        (,,,,finalVerdict,) = GD.getProposalDetailsById2(_proposalId);
        
        for(uint i=0; i<GD.getVoteLengthById(_proposalId); i++) 
        {
            uint voteid = GD.getVoteIdById(_proposalId,i);
            
            if(GD.getOptionById(voteid,0) == finalVerdict)
            {   
                voteValueFavour = GD.getVoteValue(voteid) + voteValueFavour;
            }
            else 
            {
                uint burnedTokens = SafeMath.div(GD.getVoteStake(voteid),GD.globalRiskFactor());
                voterStake = SafeMath.add(voterStake,burnedTokens);
                returnTokens = SafeMath.sub(GD.getVoteStake(voteid),SafeMath.div(GD.getVoteStake(voteid),GD.globalRiskFactor()));
                
                G1.transferBackGBTtoken(GD.getVoterAddress(voteid),returnTokens);
                GD.callRewardEvent(_memberAddress,_proposalId,"VoteOwner Burned",returnTokens);
                GD.setVoteReward(voteid,returnTokens);
            }
        }

        for(i=0; i<GD.getOptionAddedAddressLength(_proposalId); i++)
        {
            if(i!= finalVerdict)         
                wrongOptionStake = SafeMath.add(wrongOptionStake,GD.getOptionStakeById(_proposalId,i));
                GD.setOptionReward(_proposalId,0,i);
        }

        totalVoteValue = SafeMath.add(GD.getOptionValueByProposalId(_proposalId,finalVerdict),voteValueFavour);
        totalTokenToDistribute = SafeMath.add(wrongOptionStake,voterStake);
 
        if(finalVerdict>0)
            totalVoteValue = SafeMath.add(totalVoteValue,GD.getProposalValue(_proposalId)); // accpted
        else
            totalTokenToDistribute = SafeMath.add(totalTokenToDistribute,GD.getProposalStake(_proposalId)); // denied

        totalTokenToDistribute = totalTokenToDistribute + GD.getProposalIncentive(_proposalId);
        distributeReward(_proposalId,totalTokenToDistribute,totalVoteValue,_memberAddress);
    }
    
    function distributeReward(uint _proposalId,uint _totalTokenToDistribute,uint _totalVoteValue,address _memberAddress) 
    {
        GD=GovernanceData(GDAddress);
        G1=Governance(G1Address);
         reward=0;
        uint addMemberPoints; uint subMemberPoints; uint finalVerdict; 
        (,,,,finalVerdict,) = GD.getProposalDetailsById2(_proposalId);
        (,,addMemberPoints,,,subMemberPoints)=GD.getMemberReputationPoints();
 
        if(finalVerdict > 0) 
        {
            reward1 = SafeMath.div(SafeMath.mul(GD.getProposalValue(_proposalId),_totalTokenToDistribute),_totalVoteValue);
            G1.transferBackGBTtoken(GD.getProposalOwner(_proposalId),SafeMath.add(GD.getProposalStake(_proposalId),reward1));
            G1.setProposalDetails(_proposalId,_totalTokenToDistribute,block.number,reward1);
            GD.callRewardEvent(_memberAddress,_proposalId,"ProposalOwner Reward",reward1);

            reward3 = SafeMath.div(SafeMath.mul(GD.getOptionValueByProposalId(_proposalId,finalVerdict),_totalTokenToDistribute),_totalVoteValue);
            G1.transferBackGBTtoken(GD.getOptionAddressByProposalId(_proposalId,finalVerdict),SafeMath.add(GD.getOptionStakeById(_proposalId,finalVerdict),reward3));
            GD.setOptionReward(_proposalId,reward3,finalVerdict);
            GD.callRewardEvent(_memberAddress,_proposalId,"OptionOwner Reward",reward3);
        }

        for(uint i=0; i<GD.getVoteLengthById(_proposalId); i++)
        {
            uint voteid = GD.getVoteIdById(_proposalId,i); 
            if(GD.getOptionById(voteid,0) == finalVerdict)
            {
                reward = SafeMath.div(SafeMath.mul(GD.getVoteValue(voteid),_totalTokenToDistribute),_totalVoteValue);
                uint repPoints = GD.getMemberReputation(GD.getVoterAddress(voteid))+addMemberPoints;
                
                G1.transferBackGBTtoken(GD.getVoterAddress(voteid),SafeMath.add(GD.getVoteStake(voteid),reward));
                G1.updateMemberReputation1("VoteOwner Favour",_proposalId,GD.getVoterAddress(voteid),repPoints);
                GD.setVoteReward(voteid,reward);
                GD.callRewardEvent(_memberAddress,_proposalId,"VoteOwner Reward",reward);
            }
            else
            {
                G1.updateMemberReputation1("VoteOwner Against",_proposalId,GD.getVoterAddress(voteid),(GD.getMemberReputation(GD.getVoterAddress(voteid))-subMemberPoints));
            }     
        } 
        G1.updateMemberReputation(_proposalId,finalVerdict);
    }
}

