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
    address G1Address;
    address SVTAddress;
    address GBTSAddress;
    GBTStandardToken GBTS;
    memberRoles MR;
    Governance G1;
    ProposalCategory PC;
    governanceData GD;
    StandardVotingType SVT;
    Master MS;
    uint public constructorCheck;
    address public masterAddress;

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
    
    function changeAllContractsAddress(address _StandardVotingAddress,address _GDcontractAddress, address _MRcontractAddress, address _PCcontractAddress,address _G1ContractAddress) onlyInternal
    {
        SVTAddress = _StandardVotingAddress;
        GDAddress = _GDcontractAddress;
        MRAddress = _MRcontractAddress;
        PCAddress = _PCcontractAddress;
        G1Address = _G1ContractAddress;
    }

    function changeGBTSAddress(address _GBTSAddress) onlyMaster
    {
        GBTSAddress = _GBTSAddress;    
    }
    
    function initiateAddSolution(uint _proposalId,address _memberAddress,uint _solutionStake,string _solutionHash,uint _dateAdd) public
    {
        SVT=StandardVotingType(SVTAddress);
        MS=Master(masterAddress);
        require(MS.isInternal(msg.sender) == 1 || msg.sender == _memberAddress);
        if(_solutionStake!=0)
            receiveStakeInGbtSV(_proposalId,_solutionStake,_solutionHash,_dateAdd)
        SVT.addSolutionSVT(_proposalId,_memberAddress,_solutionHash,_dateAdd);
    }
     
    function addSolution(uint _proposalId,uint _solutionStake,string _solutionHash) 
    {
        initiateAddSolution(_proposalId,msg.sender,_solutionStake, _solutionHash,now); 
    }

    function receiveSolutionStakeSV(uint _proposalId,uint _solutionStake,string _solutionHash,uint _dateAdd) internal
    {
        uint depositAmount = ((_solutionStake*GD.depositPercOption())/100);
        uint finalAmount = depositAmount + GD.getDepositTokensByAddress(msg.sender,_proposalId);
        GD.setDepositTokens(msg.sender,_proposalId,finalAmount,'S');
        GBTS.lockMemberToken(_gbUserName,_proposalId,SafeMath.sub(_solutionStake,finalAmount));  
        GD.callSolutionEvent(_proposalId,msg.sender,_solutionHash,_dateAdd,_solutionStake);    
    }

    function proposalVoting(uint _proposalId,uint[] _optionChosen,uint _voteStake) public
    {
        GD=governanceData(GDAddress);
        MR=memberRoles(MRAddress);
        GBTS=GBTStandardToken(GBTSAddress);
        uint8 _mrSequence;uint _majorityVote;uint24 _closingTime; uint currentVotingId;uint intermediateVerdict;uint category;
        (,category,currentVotingId,intermediateVerdict,,) = GD.getProposalDetailsById2(_proposalId);
        (_mrSequence,_majorityVote,_closingTime) = PC.getCategpryData2(category,currentVotingId)
        uint _proposalDateUpd = GD.getProposalDateUpd(_proposalId);
        uint roleId = MR.getMemberRoleIdByAddress(msg.sender);

        require(SafeMath.add(_proposalDateUpd,_closingTime) >= now && msg.sender != GD.getOptionAddressByProposalId(_proposalId,_optionChosen[0]));
        require(roleId == _mrSequence && GBTS.balanceOf(msg.sender) != 0 && GD.getProposalStatus(_proposalId) == 2 && _optionChosen.length == 1);

        if(currentVotingId == 0)
            require(_optionChosen[0] <= GD.getTotalVerdictOptions(_proposalId););
        else
            require(_optionChosen[0]==intermediateVerdict || _optionChosen[0]==0);
            
        castVote(_proposalId,_optionChosen,msg.sender,_voteStake,roleId,_closingTime,_majorityVote);
        
    }

    function castVote(uint _proposalId,uint[] _optionChosen,address _memberAddress,uint _voteStake,uint _roleId,uint _closingTime,uint _majorityVote) internal
    {
        GD=governanceData(GDAddress);
        SVT=StandardVotingType(SVTAddress);
        G1=Governance(G1Address);
        if(GD.getVoteId_againstMember(_memberAddress,_proposalId) == 0)
        {
            uint voteId = GD.allVotesTotal();
            uint finalVoteValue = SVT.setVoteValue_givenByMember(_memberAddress,_proposalId,_voteStake);
            GD.setVoteId_againstMember(_memberAddress,_proposalId,voteId);
            GD.setVoteIdAgainstProposalRole(_proposalId,_roleId,voteId);
            G1.checkRoleVoteClosing(_proposalId,_roleId,_closingTime,_majorityVote);
            GD.addInVote(_memberAddress,_proposalId,_optionChosen,_voteStake,finalVoteValue);
            receiveVoteStakeSV(_voteStake,_proposalId);
        }
        // else 
            // changeMemberVote(_proposalId,_optionChosen,_memberAddress,_GBTPayableTokenAmount);
    }

    function receiveVoteStakeSV(uint _memberStake,uint _proposalId) internal
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

        for(i=0; i<GD.getTotalVerdictOptions(_proposalId); i++)
        {
            if(i!= finalVerdict)         
                totalReward = SafeMath.add(totalReward,GD.getDepositedTokens(GD.getOptionAddressByProposalId(_proposalId,i),_proposalId,'S'));
        }

        uint mrLength = MR.getAllMemberLength();
        for(uint i=0; i<mrLength; i++) 
        {
            uint mrVoteLength = GD.getVoteLength(_proposalId,i);
            for(uint j =0; j<mrVoteLength; j++)
            {
                if(GD.getOptionById(GD.getVoteIdAgainstRole(_proposalId,j,0),0) != finalVerdict)
                {
                    totalReward = SafeMath.add(totalReward,GD.getDepositedTokens(GD.getVoterAddress(voteid),_proposalId,'V');
                    totalVoteValue = SafeMath.add(totalVoteValue,GD.getVoteValue(voteid));
                } 
            }
        }

        totalReward = totalReward + GD.getProposalIncentive(_proposalId); 
        G1.setProposalDetails(_proposalId,totalReward,block.number,totalVoteValue);         
    } 

    // function changeMemberVote(uint _proposalId,uint[] _optionChosen,address _memberAddress,uint _GBTPayableTokenAmount) internal
    // {
    //     MR=memberRoles(MRAddress);
    //     G1=Governance(G1Address);
    //     GD=governanceData(GDAddress);
    //     SVT=StandardVotingType(SVTAddress);

    //     uint roleId = MR.getMemberRoleIdByAddress(_memberAddress);
    //     uint voteId = GD.getVoteId_againstMember(_memberAddress,_proposalId);
    //     uint voteVal = GD.getVoteValue(voteId);
        
    //     GD.editProposalVoteCount(_proposalId,roleId,GD.getOptionById(voteId,0),voteVal);
    //     GD.setProposalVoteCount(_proposalId,roleId,_optionChosen[0],voteVal);
    //     GD.setOptionChosen(voteId,_optionChosen[0]);

           // receiveGBT(gbtTransfer,"Payable GBT Stake to submit proposal for voting");
           // receiveGBT(amount,"Payable GBT Stake for adding solution against proposal");
           // receiveGBT(_Incentive,"Dapp incentive to be distributed in GBT")
    // }
}

