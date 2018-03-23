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
import "./governanceData.sol";
import "./GBTController.sol";
import "./Governance.sol";
import "./memberRoles.sol";

contract simpleVoting is VotingType
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
    memberRoles MR;
    Governance G1;
    BasicToken BT;
    ProposalCategory PC;
    governanceData GD;
    StandardVotingType SVT;
    Master MS;
    uint public constructorCheck;

    modifier onlyInternal {
        MS=Master(masterAddress);
        require(MS.isInternal(msg.sender) == 1);
        _; 
    }

    function SimpleVotingInitiate()
    {
        require(constructorCheck == 0);
        votingTypeName = "Simple Voting";
        constructorCheck=1;
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
    function payableGBTTokensSimpleVoting(address _member,uint _TokenAmount,string _description) internal
    {
        GBTC=GBTController(GBTCAddress);
        GD=governanceData(GDAddress);
        require(_TokenAmount >= GD.GBTStakeValue());
        GBTC.receiveGBT(_member,_TokenAmount,_description);
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

    function transferVoteStakeSV(uint _memberStake)
    {
        GBTC=GBTController(GBTCAddress);
        if(_memberStake != 0)
            GBTC.receiveGBT(msg.sender,_memberStake,"Payable GBT Stake for voting against proposal");
    }

    function addVerdictOption(uint _proposalId,address _member,uint _GBTPayableTokenAmount,string _optionHash,uint _dateAdd)
    {
        SVT=StandardVotingType(SVTAddress);

        SVT.addVerdictOptionSVT(_proposalId,_member,_GBTPayableTokenAmount,_optionHash,_dateAdd);
        payableGBTTokensSimpleVoting(_member,_GBTPayableTokenAmount,"Payable GBT Stake for adding solution against proposal");
    }
     
    function initiateVerdictOption(uint _proposalId,uint _GBTPayableTokenAmount,string _optionHash,uint _dateAdd) 
    {
        addVerdictOption(_proposalId,msg.sender, _GBTPayableTokenAmount, _optionHash,_dateAdd);
    }

    function proposalVoting(uint _proposalId,uint[] _optionChosen,uint _GBTPayableTokenAmount,uint _authRole,uint24 _closingTime) 
    {
        GD=governanceData(GDAddress);
        MR=memberRoles(MRAddress);
        SVT=StandardVotingType(SVTAddress);
        G1=Governance(G1Address);

        uint currentVotingId;uint intermediateVerdict;
        (,,currentVotingId,intermediateVerdict,,) = GD.getProposalDetailsById2(_proposalId); //0,0
        uint8 verdictOptions = GD.getTotalVerdictOptions(_proposalId); //2
        uint _proposalDateUpd = GD.getProposalDateUpd(_proposalId); //1521782597
        require(SafeMath.add(_proposalDateUpd,_closingTime) >= now && msg.sender != GD.getOptionAddressByProposalId(_proposalId,_optionChosen[0]));
        require(GD.getBalanceOfMember(msg.sender) != 0 && GD.getProposalStatus(_proposalId) == 2 && _optionChosen.length == 1);

        if(currentVotingId == 0)
            require(_optionChosen[0] <= verdictOptions);
        else
            require(_optionChosen[0]==intermediateVerdict || _optionChosen[0]==0);
            
        uint roleId = MR.getMemberRoleIdByAddress(msg.sender); //2
        // require(roleId == PC.getRoleSequencAtIndex(category,currentVotingId));

        require(roleId == _authRole);
        castVote(_proposalId,_optionChosen,_GBTPayableTokenAmount,_authRole,roleId);
        
    }

    function castVote(uint _proposalId,uint[] _optionChosen,uint _GBTPayableTokenAmount,uint _authRole,uint roleId) internal
    {
         GD=governanceData(GDAddress);
         SVT=StandardVotingType(SVTAddress);

        if(GD.getVoteId_againstMember(msg.sender,_proposalId) == 0)
        {
            uint votelength = GD.allVotesTotal(); //1
            uint finalVoteValue = SVT.setVoteValue_givenByMember(msg.sender,_proposalId,_GBTPayableTokenAmount);
            
            GD.setProposalVoteCount(_proposalId,roleId,_optionChosen[0],finalVoteValue);
            GD.setProposalTokenCount(_proposalId,roleId,msg.sender);
            
            GD.setVoteId_againstMember(msg.sender,_proposalId,votelength);
            GD.setVoteIdAgainstProposalRole(_proposalId,roleId,votelength);
            GD.setVoteIdAgainstProposal(_proposalId,votelength);
            GD.addInTotalVotes(msg.sender,votelength);
            
            uint _voteLength = GD.getVoteLength(_proposalId,roleId);
            address _voteAddress = GD.getProposalVotingType(_proposalId);
            G1.checkRoleVoteClosing(_proposalId,_voteLength,_authRole);
            GD.addInVote(msg.sender,_proposalId,_optionChosen,_GBTPayableTokenAmount,finalVoteValue);
            GD.callVoteEvent(msg.sender,_voteAddress,votelength);
            transferVoteStakeSV(_GBTPayableTokenAmount);
        }
        else 
            changeMemberVote(_proposalId,_optionChosen,_GBTPayableTokenAmount);
    }
    function changeMemberVote(uint _proposalId,uint[] _optionChosen,uint _GBTPayableTokenAmount) internal
    {
        MR=memberRoles(MRAddress);
        G1=Governance(G1Address);
        GD=governanceData(GDAddress);
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

    // function closeProposalVote(uint _proposalId)
    // {
    //     SVT=StandardVotingType(SVTAddress);
    //     SVT.closeProposalVoteSVT(_proposalId);
    // }

    function closeProposalVote(uint _proposalId,uint _roleId,uint24 _closingTime,uint _majorityVote,uint _roleSequenceLength)
    {
        SVT=StandardVotingType(SVTAddress);
        SVT.closeProposalVoteSVT(_proposalId,_roleId,_closingTime,_majorityVote,_roleSequenceLength);
    }

    uint public voteValueFavour; uint public voterStake; uint public wrongOptionStake; uint public returnTokens;
    uint public totalVoteValue; uint public totalTokenToDistribute; 
    uint reward; uint public reward1; uint public reward2; uint public reward3;

    function giveReward_afterFinalDecision(uint _proposalId) 
    {
        GD=governanceData(GDAddress);
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
                
                G1.transferBackGBTtoken(GD.getVoterAddress(voteid),returnTokens,"Transfer Back GBT after penalty for voting other than final option -  Token Returned");
                GD.callPenaltyEvent(GD.getVoterAddress(voteid),_proposalId,"Penalty for voting other than final option -  Token burned",burnedTokens);
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
        distributeReward(_proposalId,totalTokenToDistribute,totalVoteValue);
    }
    
    function distributeReward(uint _proposalId,uint _totalTokenToDistribute,uint _totalVoteValue) 
    {
        GD=governanceData(GDAddress);
        G1=Governance(G1Address);
        
         reward=0;
        uint addMemberPoints; uint subMemberPoints; uint finalVerdict; 
        (,,,,finalVerdict,) = GD.getProposalDetailsById2(_proposalId);
        (,,addMemberPoints,,,subMemberPoints)=GD.getMemberReputationPoints();
 
        if(finalVerdict > 0) 
        {
            reward1 = SafeMath.div(SafeMath.mul(GD.getProposalValue(_proposalId),_totalTokenToDistribute),_totalVoteValue);
            G1.transferBackGBTtoken(GD.getProposalOwner(_proposalId),SafeMath.add(GD.getProposalStake(_proposalId),reward1),"GBT Stake Returned for being Proposal owner - Accepted");
            G1.setProposalDetails(_proposalId,_totalTokenToDistribute,block.number,reward1);
            GD.callRewardEvent(GD.getProposalOwner(_proposalId),_proposalId,"Reward for proposal owner - Accepted ",reward1);

            reward3 = SafeMath.div(SafeMath.mul(GD.getOptionValueByProposalId(_proposalId,finalVerdict),_totalTokenToDistribute),_totalVoteValue);
            G1.transferBackGBTtoken(GD.getOptionAddressByProposalId(_proposalId,finalVerdict),SafeMath.add(GD.getOptionStakeById(_proposalId,finalVerdict),reward3),"GBT Stake Returned for being Final Solution owner - Accepted");
            GD.setOptionReward(_proposalId,reward3,finalVerdict);
            GD.callRewardEvent(GD.getOptionAddressByProposalId(_proposalId,finalVerdict),_proposalId,"Reward for option owner - Final option by majority voting",reward3);
        }

        for(uint i=0; i<GD.getVoteLengthById(_proposalId); i++)
        {
            uint voteid = GD.getVoteIdById(_proposalId,i); 
            if(GD.getOptionById(voteid,0) == finalVerdict)
            {
                reward = SafeMath.div(SafeMath.mul(GD.getVoteValue(voteid),_totalTokenToDistribute),_totalVoteValue);
                uint repPoints = GD.getMemberReputation(GD.getVoterAddress(voteid))+addMemberPoints;
                
                G1.transferBackGBTtoken(GD.getVoterAddress(voteid),SafeMath.add(GD.getVoteStake(voteid),reward),"Voting stake and reward earned after voted in favour of final option");
                G1.updateMemberReputation1("Reputation credit after voted in favour of final option",_proposalId,GD.getVoterAddress(voteid),repPoints,addMemberPoints,"C");
                GD.setVoteReward(voteid,reward);
                GD.callRewardEvent(GD.getVoterAddress(voteid),_proposalId,"Reward for voting in favour of final option",reward);
            }
            else
            {
                G1.updateMemberReputation1("Reputation debit after voted other than final option",_proposalId,GD.getVoterAddress(voteid),(GD.getMemberReputation(GD.getVoterAddress(voteid))-subMemberPoints),subMemberPoints,"D");
            }     
        } 
        G1.updateMemberReputation(_proposalId,finalVerdict);
    }
}

