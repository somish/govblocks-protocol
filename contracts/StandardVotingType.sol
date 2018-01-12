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

/**
 * @title Standard votingType interface for All Types of voting That contains All Common functions required for voting type.
 */

pragma solidity ^0.4.8;
import "./SimpleVoting.sol";
import "./RankBasedVoting.sol";
import "./FeatureWeighted.sol";
import "./GovernanceData.sol";
import "./VotingType.sol";

contract StandardVotingType
{
    address SVAddress;
    address RBAddress;
    address FWAddress;
    address GDAddress;
    address MRAddress;
    address PCAddress;
    address VTAddress;
    MemberRoles MR;
    ProposalCategory PC;
    GovernanceData  GD;
    MintableToken MT;
    StandardVotingType SVT;
    SimpleVoting SV;
    RankBasedVoting RB;
    FeatureWeighted FW;
    VotingType VT;

    function changeOtherContractAddress(address _SVaddress,address _RBaddress,address _FWaddress)
    {
        SVAddress = _SVaddress;
        RBAddress = _RBaddress;
        FWAddress = _FWaddress;
    }
    
    function changeAllContractsAddress(address _GDcontractAddress, address _MRcontractAddress, address _PCcontractAddress) public
    {
        GDAddress = _GDcontractAddress;
        MRAddress = _MRcontractAddress;
        PCAddress = _PCcontractAddress;
    }
    
    function setOptionValue_givenByMemberSVT(address GDAddress,uint _proposalId,uint _memberStake) internal returns (uint finalOptionValue)
    {
        GD=GovernanceData(GDAddress);
        uint memberLevel = Math.max256(GD.getMemberReputation(msg.sender),1);
        uint tokensHeld = SafeMath.div((SafeMath.mul(SafeMath.mul(GD.getBalanceOfMember(msg.sender),100),100)),GD.getTotalTokenInSupply());
        uint maxValue= Math.max256(tokensHeld,GD.membershipScalingFactor());

        finalOptionValue = SafeMath.mul(SafeMath.mul(GD.globalRiskFactor(),memberLevel),SafeMath.mul(_memberStake,maxValue));
    }

    function setVoteValue_givenByMember(address GBTAddress,uint _proposalId,uint _memberStake) public returns (uint finalVoteValue)
    {
        GD=GovernanceData(GDAddress);
        MT=MintableToken(GBTAddress);
        
        if(_memberStake != 0)
            MT.transferFrom(msg.sender,GBTAddress,_memberStake);

        uint tokensHeld = SafeMath.div((SafeMath.mul(SafeMath.mul(GD.getBalanceOfMember(msg.sender),100),100)),GD.getTotalTokenInSupply());
        uint value= SafeMath.mul(Math.max256(_memberStake,GD.scalingWeight()),Math.max256(tokensHeld,GD.membershipScalingFactor()));
        finalVoteValue = SafeMath.mul(GD.getMemberReputation(msg.sender),value);
    }  

    function addVerdictOptionSVT(address _VTaddress,uint _proposalId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress,uint _GBTPayableTokenAmount)
    {
        VT=VotingType(_VTaddress);
        GD=GovernanceData(GDAddress);
        MR=MemberRoles(MRAddress);
        PC=ProposalCategory(PCAddress);
        
        uint8 verdictOptions;
        (,,,verdictOptions) = GD.getProposalCategoryParams(_proposalId);
        uint _categoryId;uint currentVotingId;
        (_categoryId,currentVotingId,,,) = GD.getProposalDetailsById2(_proposalId);

        require(currentVotingId == 0 && GD.getProposalStatus(_proposalId) == 2 && GD.getBalanceOfMember(msg.sender) != 0);
        require(MR.getMemberRoleIdByAddress(msg.sender) == PC.getRoleSequencAtIndex(_categoryId,currentVotingId) && VT.getVoteId_againstMember(msg.sender,_proposalId) == 0 );
        
        uint8 paramInt; uint8 paramBytes32; uint8 paramAddress;
        (,,,paramInt,paramBytes32,paramAddress,,) = PC.getCategoryDetails(_categoryId);

        if(paramInt == _paramInt.length && paramBytes32 == _paramBytes32.length && paramAddress == _paramAddress.length)
        {
            uint optionValue = setOptionValue_givenByMemberSVT(GD,_proposalId,_GBTPayableTokenAmount);
            GD.setProposalVerdictAddressAndStakeValue(_proposalId,msg.sender,_GBTPayableTokenAmount,optionValue);
            verdictOptions = verdictOptions+1;
            GD.setProposalCategoryParams(_categoryId,_proposalId,_paramInt,_paramBytes32,_paramAddress,verdictOptions);
        } 
    }

    function closeProposalVoteSVT(address _VTaddress,uint _votingType,uint _proposalId)
    {
        GD=GovernanceData(GDAddress);
        MR=MemberRoles(MRAddress);
        PC=ProposalCategory(PCAddress);
        SV=SimpleVoting(SVAddress);
        RB=RankBasedVoting(RBAddress);
        FW=FeatureWeighted(FWAddress);
        VT=VotingType(_VTaddress);
        
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
            totalVotes = SafeMath.add(totalVotes,VT.getVotesbyOption_againstProposal(_proposalId,roleId,i)); 
            if(VT.getVotesbyOption_againstProposal(_proposalId,roleId,max) < VT.getVotesbyOption_againstProposal(_proposalId,roleId,i))
            {  
                max = i; 
            }
        }
        verdictVal = VT.getVotesbyOption_againstProposal(_proposalId,roleId,max);
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
                    if(_votingType == 0)
                    {
                        SV.giveReward_afterFinalDecision(_proposalId);
                    }
                    else if(_votingType == 1)
                    {
                        RB.giveReward_afterFinalDecision(_proposalId);
                    } 
                    else
                    {
                        FW.giveReward_afterFinalDecision(_proposalId);
                    }
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
}






