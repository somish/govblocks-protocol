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
import "./GBTStandardToken.sol";

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
    address GBTSAddress;
    GBTStandardToken GBTS;
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

    modifier onlyMaster {    
        require(msg.sender == masterAddress);
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
        // GBTC=GBTController(GBTCAddress);
        // GD=governanceData(GDAddress);
        // require(_TokenAmount >= GD.GBTStakeValue());
        // GBTC.receiveGBT(_member,_TokenAmount,_description);
    }
    
    function changeAllContractsAddress(address _StandardVotingAddress,address _GDcontractAddress, address _MRcontractAddress, address _PCcontractAddress,address _G1ContractAddress) onlyInternal
    {
        SVTAddress = _StandardVotingAddress;
        GDAddress = _GDcontractAddress;
        MRAddress = _MRcontractAddress;
        PCAddress = _PCcontractAddress;
        G1Address = _G1ContractAddress;
    }

    function changeGBTControllerAddress(address _GBTCAddress) onlyMaster
    {
        GBTCAddress = _GBTCAddress;
    }

    function changeGBTSAddress(address _GBTSAddress) onlyMaster
    {
        GBTSAddress = _GBTSAddress;    
    }
    
    function receiveStake(uint _memberStake) internal
    {
        GBTS=GBTStandardToken(GBTSAddress);
        GD=governanceData(GDAddress);
        if(_memberStake != 0)
        {
            uint depositAmount = ((gbtTransfer*GD.depositPercVote())/100);
            uint finalAmount = depositAmount + GD.getDepositTokensByAddress(msg.sender,_proposalId);
            GD.setDepositTokens(msg.sender,_proposalId,finalAmount,'V');
            GBTS.lockMemberToken(_gbUserName,_proposalId,SafeMath.sub(_TokenAmount,finalAmount);
        }  
    }

    function addVerdictOption(uint _proposalId,address _member,string _optionHash,uint _dateAdd) 
    {
        SVT=StandardVotingType(SVTAddress);
        MS=Master(masterAddress);
            require(MS.isInternal(msg.sender) == 1 || msg.sender == _member);
       
        SVT.addVerdictOptionSVT(_proposalId,_member,_GBTPayableTokenAmount,_optionHash,_dateAdd);
        //     payableGBTTokensSimpleVoting(_member,_GBTPayableTokenAmount,"Payable GBT Stake for adding solution against proposal");
    }
     
    function initiateVerdictOption(uint _proposalId,,uint _GBTPayableTokenAmount,string _optionHash,uint _dateAdd) 
    {
        addVerdictOption(_proposalId,msg.sender,_GBTPayableTokenAmount, _optionHash,_dateAdd);
        if(_GBTPayableTokenAmount!=0)
        {
            uint depositAmount = ((optionGBT*GD.depositPercOption())/100);
            uint finalAmount = depositAmount + GD.getDepositTokensByAddress(msg.sender,_proposalId);
            GD.setDepositTokens(msg.sender,_proposalId,finalAmount,'S');
            GBTS.lockMemberToken(_proposalId,SafeMath.sub(_GBTPayableTokenAmount,finalAmount));
        }
    }

    function proposalVoting(uint _proposalId,uint[] _optionChosen,address _memberAddress,uint _GBTPayableTokenAmount) 
    {
        GD=governanceData(GDAddress);
        MR=memberRoles(MRAddress);
        SVT=StandardVotingType(SVTAddress);
        G1=Governance(G1Address);
        GBTS=GBTStandardToken(GBTSAddress);

        uint currentVotingId;uint intermediateVerdict;
        (,,currentVotingId,intermediateVerdict,,) = GD.getProposalDetailsById2(_proposalId);
        uint8 verdictOptions = GD.getTotalVerdictOptions(_proposalId); 
        uint _proposalDateUpd = GD.getProposalDateUpd(_proposalId);
        uint _closingTime = PC.getClosingTimeAtIndex(GD.getProposalCategory(_proposalId),currentVotingId);
        uint _majorityVote = PC.getRoleMajorityVoteAtIndex(GD.getProposalCategory(_proposalId),currentVotingId);

        require(SafeMath.add(_proposalDateUpd,_closingTime) >= now && _memberAddress != GD.getOptionAddressByProposalId(_proposalId,_optionChosen[0]));
        require(GBTS.balanceOf(_memberAddress) != 0 && GD.getProposalStatus(_proposalId) == 2 && _optionChosen.length == 1);

        if(currentVotingId == 0)
            require(_optionChosen[0] <= verdictOptions);
        else
            require(_optionChosen[0]==intermediateVerdict || _optionChosen[0]==0);
            
        uint roleId = MR.getMemberRoleIdByAddress(_memberAddress);
        require(roleId == PC.getRoleSequencAtIndex(GD.getProposalCategory(_proposalId),currentVotingId));

        castVote(_proposalId,_optionChosen,_memberAddress,_GBTPayableTokenAmount,roleId,_closingTime,_majorityVote);
        
    }

    function castVote(uint _proposalId,uint[] _optionChosen,address _memberAddress,uint _GBTPayableTokenAmount,uint _roleId,uint _closingTime,uint _majorityVote) internal
    {
         GD=governanceData(GDAddress);
         SVT=StandardVotingType(SVTAddress);
         G1=Governance(G1Address);

        if(GD.getVoteId_againstMember(_memberAddress,_proposalId) == 0)
        {
            uint votelength = GD.allVotesTotal(); //1
            uint finalVoteValue = SVT.setVoteValue_givenByMember(_memberAddress,_proposalId,_GBTPayableTokenAmount);
            
            GD.setProposalVoteCount(_proposalId,_roleId,_optionChosen[0],finalVoteValue);
            GD.setProposalTokenCount(_proposalId,_roleId,_memberAddress);
            
            GD.setVoteId_againstMember(_memberAddress,_proposalId,votelength);
            GD.setVoteIdAgainstProposalRole(_proposalId,_roleId,votelength);
            GD.setVoteIdAgainstProposal(_proposalId,votelength);
            GD.addInTotalVotes(_memberAddress,votelength);
            
            uint _voteLength = GD.getVoteLength(_proposalId,_roleId);
            address _voteAddress = GD.getProposalVotingType(_proposalId);
            G1.checkRoleVoteClosing(_proposalId,_roleId,_closingTime,_majorityVote);
            GD.addInVote(_memberAddress,_proposalId,_optionChosen,_GBTPayableTokenAmount,finalVoteValue);
            GD.callVoteEvent(_memberAddress,_voteAddress,votelength);
            receiveStake(_GBTPayableTokenAmount);
        }
        else 
            changeMemberVote(_proposalId,_optionChosen,_memberAddress,_GBTPayableTokenAmount);
    }
    
    function changeMemberVote(uint _proposalId,uint[] _optionChosen,address _memberAddress,uint _GBTPayableTokenAmount) internal
    {
        MR=memberRoles(MRAddress);
        G1=Governance(G1Address);
        GD=governanceData(GDAddress);
        SVT=StandardVotingType(SVTAddress);

        uint roleId = MR.getMemberRoleIdByAddress(_memberAddress);
        uint voteId = GD.getVoteId_againstMember(_memberAddress,_proposalId);
        uint voteVal = GD.getVoteValue(voteId);
        
        GD.editProposalVoteCount(_proposalId,roleId,GD.getOptionById(voteId,0),voteVal);
        GD.setProposalVoteCount(_proposalId,roleId,_optionChosen[0],voteVal);
        GD.setOptionChosen(voteId,_optionChosen[0]);
    }

    function closeProposalVote(uint _proposalId) onlyInternal
    {
        SVT=StandardVotingType(SVTAddress);
        SVT.closeProposalVoteSVT(_proposalId);
    }

    function giveReward_afterFinalDecision(uint _proposalId) onlyInternal
    {   
        GD=governanceData(GDAddress); uint totalTokenToDistribute; uint voteValueFavour;
        G1=Governance(G1Address); 

        if(GD.getProposalFinalOption(_proposalId) < 0)
            totalReward = SafeMath.add(totalReward,GD.getDepositedTokens(GD.getProposalOwner(_proposalId),_proposalId,'P'));

        for(i=0; i<GD.getOptionAddedAddressLength(_proposalId); i++)
        {
            if(i!= finalVerdict)         
                totalReward = SafeMath.add(totalReward,GD.getDepositedTokens(GD.getOptionAddressByProposalId(_proposalId,i),_proposalId,'S'));
        }

        for(uint i=0; i<GD.getVoteLengthById(_proposalId); i++) 
        {
            uint voteid = GD.getVoteIdById(_proposalId,i);
            if(GD.getOptionById(voteid,0) != finalVerdict)
            {   
                totalReward = SafeMath.add(totalReward,GD.getDepositedTokens(GD.getVoterAddress(voteid),_proposalId,'V');
                totalVoteValue = SafeMath.add(totalVoteValue,GD.getVoteValue(voteid));
            }
        }

        totalReward = totalReward + GD.getProposalIncentive(_proposalId); 
        G1.setProposalDetails(_proposalId,totalReward,block.number,totalVoteValue);         
    }

    // function giveReward_afterFinalDecision(uint _proposalId) onlyInternal
    // {
    //     GD=governanceData(GDAddress);
    //     G1=Governance(G1Address);        
        
    //     voteValueFavour=0;  voterStake=0;  wrongOptionStake=0;  returnTokens=0;
    //     totalVoteValue=0;  totalTokenToDistribute=0; 
    //     uint finalVerdict;
    //     (,,,,finalVerdict,) = GD.getProposalDetailsById2(_proposalId);
        
    //     for(uint i=0; i<GD.getVoteLengthById(_proposalId); i++) 
    //     {
    //         uint voteid = GD.getVoteIdById(_proposalId,i);
            
    //         if(GD.getOptionById(voteid,0) == finalVerdict)
    //         {   
    //             voteValueFavour = GD.getVoteValue(voteid) + voteValueFavour;
    //         }
    //         else 
    //         {
    //             uint burnedTokens = SafeMath.div(GD.getVoteStake(voteid),GD.globalRiskFactor());
    //             voterStake = SafeMath.add(voterStake,burnedTokens);
    //             returnTokens = SafeMath.sub(GD.getVoteStake(voteid),SafeMath.div(GD.getVoteStake(voteid),GD.globalRiskFactor()));
                
    //             G1.transferBackGBTtoken(GD.getVoterAddress(voteid),returnTokens,"Transfer Back GBT after penalty for voting other than final option -  Token Returned");
    //             GD.callPenaltyEvent(GD.getVoterAddress(voteid),_proposalId,"Penalty in GBT for voting other than final option -  Token burned", burnedTokens);
    //             GD.setVoteReward(voteid,returnTokens);
    //         }
    //     }

    //     for(i=0; i<GD.getOptionAddedAddressLength(_proposalId); i++)
    //     {
    //         if(i!= finalVerdict)         
    //             wrongOptionStake = SafeMath.add(wrongOptionStake,GD.getOptionStakeById(_proposalId,i));
    //             GD.setOptionReward(_proposalId,0,i);
    //     }

    //     totalVoteValue = SafeMath.add(GD.getOptionValueByProposalId(_proposalId,finalVerdict),voteValueFavour);
    //     totalTokenToDistribute = SafeMath.add(wrongOptionStake,voterStake);
 
    //     if(finalVerdict>0)
    //         totalVoteValue = SafeMath.add(totalVoteValue,GD.getProposalValue(_proposalId)); // accpted
    //     else
    //         totalTokenToDistribute = SafeMath.add(totalTokenToDistribute,GD.getProposalStake(_proposalId)); // denied

    //     totalTokenToDistribute = totalTokenToDistribute + GD.getProposalIncentive(_proposalId);
    //     // distributeReward(_proposalId,totalTokenToDistribute,totalVoteValue);
    // }
    
    // function distributeReward(uint _proposalId,uint _totalTokenToDistribute,uint _totalVoteValue) internal
    // {
    //     GD=governanceData(GDAddress);
    //     G1=Governance(G1Address);
        
    //     reward=0;reward1=0;reward3=0;
    //     uint addMemberPoints; uint subMemberPoints; uint finalVerdict; 
    //     (,,,,finalVerdict,) = GD.getProposalDetailsById2(_proposalId);
    //     (,,addMemberPoints,,,subMemberPoints)=GD.getMemberReputationPoints();
 
    //     if(finalVerdict > 0) 
    //     {
    //         reward1 = SafeMath.div(SafeMath.mul(GD.getProposalValue(_proposalId),_totalTokenToDistribute),_totalVoteValue);
    //         G1.transferBackGBTtoken(GD.getProposalOwner(_proposalId),SafeMath.add(GD.getProposalStake(_proposalId),reward1),"GBT Stake Returned for being Proposal owner - Accepted");
    //         GD.callRewardEvent(GD.getProposalOwner(_proposalId),_proposalId,"GBT Reward for being Proposal owner - Accepted ",reward1);

    //         reward3 = SafeMath.div(SafeMath.mul(GD.getOptionValueByProposalId(_proposalId,finalVerdict),_totalTokenToDistribute),_totalVoteValue);
    //         G1.transferBackGBTtoken(GD.getOptionAddressByProposalId(_proposalId,finalVerdict),SafeMath.add(GD.getOptionStakeById(_proposalId,finalVerdict),reward3),"GBT Stake Returned for being Final Solution owner - Accepted");
    //         GD.setOptionReward(_proposalId,reward3,finalVerdict);
    //         GD.callRewardEvent(GD.getOptionAddressByProposalId(_proposalId,finalVerdict),_proposalId,"GBT Reward earned for being Solution owner - Final Solution by majority voting",reward3);
    //     }
        
    //     G1.setProposalDetails(_proposalId,_totalTokenToDistribute,block.number,reward1);
        
    //     for(uint i=0; i<GD.getVoteLengthById(_proposalId); i++)
    //     {
    //         uint voteid = GD.getVoteIdById(_proposalId,i); 
    //         if(GD.getOptionById(voteid,0) == finaelVrdict)
    //         {
    //             reward = SafeMath.div(SafeMath.mul(GD.getVoteValue(voteid),_totalTokenToDistribute),_totalVoteValue);
    //             uint repPoints = GD.getMemberReputation(GD.getVoterAddress(voteid))+addMemberPoints;
                
    //             G1.transferBackGBTtoken(GD.getVoterAddress(voteid),SafeMath.add(GD.getVoteStake(voteid),reward),"GBT Stake Returned for voting in favour of final solution");
    //             G1.updateMemberReputation1("Reputation credit after voted in favour of final option",_proposalId,GD.getVoterAddress(voteid),repPoints,addMemberPoints,"C");
    //             GD.setVoteReward(voteid,reward);
    //             GD.callRewardEvent(GD.getVoterAddress(voteid),_proposalId,"GBT Reward earned for voting in favour of final option",reward);
    //         }
    //         else
    //         {
    //             G1.updateMemberReputation1("Reputation debit after voted other than final option",_proposalId,GD.getVoterAddress(voteid),(GD.getMemberReputation(GD.getVoterAddress(voteid))-subMemberPoints),subMemberPoints,"D");
    //         }     
    //     } 
    //     G1.updateMemberReputation(_proposalId,finalVerdict);
    // }
}

