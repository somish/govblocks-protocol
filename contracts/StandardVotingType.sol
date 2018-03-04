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
 * @title votingType interface for All Types of voting.
 */

pragma solidity ^0.4.8;
import "./simpleVoting.sol";
import "./RankBasedVoting.sol";
import "./FeatureWeighted.sol";
import "./governanceData.sol";
import "./VotingType.sol";
import "./Pool.sol";
import "./Master.sol";
import "./Governance.sol";


contract StandardVotingType
{
    address SVAddress;
    address RBAddress;
    address FWAddress;
    address GDAddress;
    address MRAddress;
    address PCAddress;
    address VTAddress;
    address G1Address;
    address P1Address;
    address public masterAddress;
    Master MS;
    Pool P1;
    Governance G1;
    memberRoles MR;
    ProposalCategory PC;
    governanceData  GD;
    BasicToken BT;
    StandardVotingType SVT;
    simpleVoting SV;
    RankBasedVoting RB;
    FeatureWeighted FW;
    VotingType VT;

    modifier onlyInternal {
        MS=Master(masterAddress);
        require(MS.isInternal(msg.sender) == 1);
        _; 
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
    
    function changeOtherContractAddress(address _SVaddress,address _RBaddress,address _FWaddress) 
    {
        SVAddress = _SVaddress;
        RBAddress = _RBaddress;
        FWAddress = _FWaddress;
    }

    function changeAllContractsAddress(address _GDcontractAddress, address _MRcontractAddress, address _PCcontractAddress,address _governanceContractAddress,address _poolContractAddress) 
    {
        GDAddress = _GDcontractAddress;
        MRAddress = _MRcontractAddress;
        PCAddress = _PCcontractAddress;
        G1Address = _governanceContractAddress;
        P1Address = _poolContractAddress;
    }

    function setOptionValue_givenByMemberSVT(address _memberAddress,uint _proposalId,uint _memberStake) internal returns (uint finalOptionValue)
    {
        GD=governanceData(GDAddress);

        uint memberLevel = Math.max256(GD.getMemberReputation(_memberAddress),1);
        uint tokensHeld = SafeMath.div((SafeMath.mul(SafeMath.mul(GD.getBalanceOfMember(_memberAddress),100),100)),GD.getTotalTokenInSupply());
        uint maxValue= Math.max256(tokensHeld,GD.membershipScalingFactor());

        finalOptionValue = SafeMath.mul(SafeMath.mul(GD.globalRiskFactor(),memberLevel),SafeMath.mul(_memberStake,maxValue));
    }

    function setVoteValue_givenByMember(address _memberAddress,uint _proposalId,uint _memberStake) onlyInternal returns (uint finalVoteValue)
    {
        GD=governanceData(GDAddress);
            
        uint tokensHeld = SafeMath.div((SafeMath.mul(SafeMath.mul(GD.getBalanceOfMember(_memberAddress),100),100)),GD.getTotalTokenInSupply());
        uint value= SafeMath.mul(Math.max256(_memberStake,GD.scalingWeight()),Math.max256(tokensHeld,GD.membershipScalingFactor()));
        finalVoteValue = SafeMath.mul(GD.getMemberReputation(_memberAddress),value);
    }  
    
    function checkForOption(uint _proposalId,address _memberAddress) internal constant returns(uint check)
    {
        GD=governanceData(GDAddress);
        for(uint i=0; i<GD.getProposalAnsLength(_memberAddress); i++)
        {
            if(GD.getProposalAnsId(_memberAddress,i) == _proposalId)
                check = 1;
            else 
                check = 0;
        }
    }

    function addVerdictOptionSVT(uint _proposalId,address _memberAddress,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress,uint _GBTPayableTokenAmount,string _optionDescHash) onlyInternal
    {
        GD=governanceData(GDAddress);
        MR=memberRoles(MRAddress);
        PC=ProposalCategory(PCAddress);
        checkForOption(_proposalId,_memberAddress);

        uint currentVotingId;
        (,,currentVotingId,,,) = GD.getProposalDetailsById2(_proposalId);

        require(currentVotingId == 0 && GD.getProposalStatus(_proposalId) == 2 && GD.getBalanceOfMember(_memberAddress) != 0);
        require(GD.getVoteId_againstMember(_memberAddress,_proposalId) == 0 && _GBTPayableTokenAmount > 0);
        
        uint8 paramInt; uint8 paramBytes32; uint8 paramAddress;
        (,,,,paramInt,paramBytes32,paramAddress,,) = PC.getCategoryDetails(GD.getProposalCategory(_proposalId));

        require(paramInt == _paramInt.length && paramBytes32 == _paramBytes32.length && paramAddress == _paramAddress.length);
            addVerdictOptionSVT2(_proposalId,GD.getProposalCategory(_proposalId),_paramInt,_paramBytes32,_paramAddress);
            addVerdictOptionSVT1(_proposalId,_memberAddress,_GBTPayableTokenAmount,_optionDescHash);
    }

    function addVerdictOptionSVT1(uint _proposalId,address _memberAddress,uint _GBTPayableTokenAmount,string _optionDescHash) internal
    {
        setOptionDetails(_proposalId,_memberAddress,_GBTPayableTokenAmount,setOptionValue_givenByMemberSVT(_memberAddress,_proposalId,_GBTPayableTokenAmount),_optionDescHash);
    }

    function addVerdictOptionSVT2(uint _proposalId,uint _categoryId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress) internal
    {
        setProposalCategoryParams(_categoryId,_proposalId,_paramInt,_paramBytes32,_paramAddress);
    }
    
    function setProposalCategoryParams(uint _category,uint _proposalId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress) internal
    {
      GD=governanceData(GDAddress);
      PC=ProposalCategory(PCAddress);
      setProposalCategoryParams1(_proposalId,_paramInt,_paramBytes32,_paramAddress);

      uint8 paramInt; uint8 paramBytes32; uint8 paramAddress;bytes32 parameterName; uint j;
      (,,,,paramInt,paramBytes32,paramAddress,,) = PC.getCategoryDetails(_category);
      
      for(j=0; j<paramInt; j++)
      {
          parameterName = PC.getCategoryParamNameUint(_category,j);
          GD.setParameterDetails1(_proposalId,parameterName,_paramInt[j]);
      }

      for(j=0; j<paramBytes32; j++)
      {
          parameterName = PC.getCategoryParamNameBytes(_category,j); 
          GD.setParameterDetails2(_proposalId,parameterName,_paramBytes32[j]);
      }

      for(j=0; j<paramAddress; j++)
      {
          parameterName = PC.getCategoryParamNameAddress(_category,j);
          GD.setParameterDetails3(_proposalId,parameterName,_paramAddress[j]); 
      }
    }
    
    function setProposalCategoryParams1(uint _proposalId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress) internal
    {
        GD=governanceData(GDAddress);
        uint i;
        GD.setTotalOptions(_proposalId);

        for(i=0;i<_paramInt.length;i++)
        {
            GD.setOptionIntParameter(_proposalId,_paramInt[i]);
        }

        for(i=0;i<_paramBytes32.length;i++)
        {
            GD.setOptionBytesParameter(_proposalId,_paramBytes32[i]);
        }

        for(i=0;i<_paramAddress.length;i++)
        {
            GD.setOptionAddressParameter(_proposalId,_paramAddress[i]); 
        }   
    }

    uint _closingTime;
    function closeProposalVoteSVT(uint _proposalId) 
    {   
        GD=governanceData(GDAddress);
        MR=memberRoles(MRAddress);
        PC=ProposalCategory(PCAddress);
        G1=Governance(G1Address);
        
          address votingTypeAddress;
        (,,,,,votingTypeAddress) = GD.getProposalDetailsById2(_proposalId);
        VT=VotingType(votingTypeAddress);
        
        uint8 currentVotingId; uint8 category;
        uint8 max; uint totalVotes;
        uint verdictVal; uint majorityVote;
    
        (,category,currentVotingId,,,) = GD.getProposalDetailsById2(_proposalId);
        uint8 verdictOptions = GD.getTotalVerdictOptions(_proposalId);

        require(G1.checkProposalVoteClosing(_proposalId)==1); //1
        uint roleId = PC.getRoleSequencAtIndex(category,currentVotingId);
    
        max=0;  
        for(uint8 i = 0; i < verdictOptions; i++)
        {
            totalVotes = SafeMath.add(totalVotes,GD.getVoteValuebyOption_againstProposal(_proposalId,roleId,i)); 
            if(GD.getVoteValuebyOption_againstProposal(_proposalId,roleId,max) < GD.getVoteValuebyOption_againstProposal(_proposalId,roleId,i))
            {  
                max = i; 
            }
        }
        
        verdictVal = GD.getVoteValuebyOption_againstProposal(_proposalId,roleId,max);
        majorityVote= PC.getRoleMajorityVote(category,currentVotingId);
       
        if(totalVotes != 0)
        {
            if(SafeMath.div(SafeMath.mul(verdictVal,100),totalVotes)>=majorityVote)
                {   
                    currentVotingId = currentVotingId+1;
                    if(max > 0 )
                    {
                        if(currentVotingId < PC.getRoleSequencLength(category))
                        {
                            G1.updateProposalDetails(_proposalId,currentVotingId,max,0);
                            P1=Pool(P1Address);
                            P1.closeProposalOraclise(_proposalId,PC.getClosingTimeByIndex(category,currentVotingId));
                            _closingTime = PC.getClosingTimeByIndex(category,currentVotingId);  
                            GD.callOraclizeCallEvent(_proposalId,GD.getProposalDateAdd(_proposalId),_closingTime);
                        } 
                        else
                        {
                            G1.updateProposalDetails(_proposalId,currentVotingId,max,max);
                            GD.changeProposalStatus(_proposalId,3);
                            // PC.actionAfterProposalPass(_proposalId ,category);
                            VT.giveReward_afterFinalDecision(_proposalId);
                        }
                    }
                    else
                    {
                        G1.updateProposalDetails(_proposalId,currentVotingId,max,max);
                        GD.changeProposalStatus(_proposalId,4);
                        G1.changePendingProposalStart();
                    }      
                } 
                else
                {
                    G1.updateProposalDetails(_proposalId,currentVotingId,max,max);
                    GD.changeProposalStatus(_proposalId,5);
                    G1.changePendingProposalStart();
                } 
        }
        else
        {
            G1.updateProposalDetails(_proposalId,currentVotingId,max,max);
            GD.changeProposalStatus(_proposalId,5);
            G1.changePendingProposalStart();
        }
    }
      /// @dev Set the Deatils of added verdict i.e. Verdict Stake, Verdict value and Address of the member whoever added the verdict.
    function setOptionDetails(uint _proposalId,address _memberAddress,uint _stakeValue,uint _optionValue,string _optionHash) internal
    {
        GD=governanceData(GDAddress);
        GD.setOptionAddress(_proposalId,_memberAddress);
        GD.setOptionStake(_proposalId,_stakeValue);
        GD.setOptionValue(_proposalId,_optionValue);
        GD.setOptionDesc(_proposalId,_optionHash);
        GD.setOptionDateAdded(_proposalId);
        GD.setProposalAnsByAddress(_proposalId,_memberAddress); // Saving proposal id against memebr to which solution is provided
        GD.setOptionIdByAddress(_proposalId,_memberAddress);
    }
}







