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
import "./GovernanceData.sol";
import "./ProposalCategory.sol";
import "./MemberRoles.sol";
import "./Master.sol";
// import "./BasicToken.sol";
// import "./SafeMath.sol";
// import "./Math.sol";
import "./Pool.sol";
import "./GBTController.sol";
import "./VotingType.sol";
import "./zeppelin-solidity/contracts/token/BasicToken.sol";
import "./zeppelin-solidity/contracts/math/SafeMath.sol";
import "./zeppelin-solidity/contracts/math/Math.sol";

contract Governance {
    
  using SafeMath for uint;
  using Math for uint;
  address GDAddress;
  address PCAddress;
  address MRAddress;
  address masterAddress;
  address BTAddress;
  address P1Address;
  address GBTCAddress;
  GBTController GBTC;
  Master MS;
  MemberRoles MR;
  ProposalCategory PC;
  GovernanceData GD;
  BasicToken BT;
  Pool P1;
  VotingType VT;

    modifier onlyInternal {
        MS=Master(masterAddress);
        require(MS.isInternal(msg.sender) == 1);
        _; 
    }
     modifier onlyOwner{
        MS=Master(masterAddress);
        require(MS.isOwner(msg.sender) == 1);
        _; 
    }

  function changeAllContractsAddress(address _GDContractAddress,address _MRContractAddress,address _PCContractAddress) onlyInternal
  {
     GDAddress = _GDContractAddress;
     PCAddress = _PCContractAddress;
     MRAddress = _MRContractAddress;
  }

  function changeGBTControllerAddress(address _GBTCAddress)
  {
     GBTCAddress = _GBTCAddress;
  }

  function changeMasterAddress(address _MasterAddress)
  {
    if(masterAddress == 0x000)
        masterAddress = _MasterAddress;
    else
    {
        MS=Master(masterAddress);
        require(MS.isInternal(msg.sender) == 1);
          masterAddress = _MasterAddress;
    }
  }
  
  function changePoolAddress(address _PoolContractAddress) onlyInternal
  {
     P1Address = _PoolContractAddress;
  }

  /// @dev Transfer reward after Final Proposal Decision.
  function transferBackGBTtoken(address _memberAddress, uint _value) onlyInternal
  {
      GBTC=GBTController(GBTCAddress);
      GBTC.transferGBT(_memberAddress,_value);
  }

  function openProposalForVoting(uint _proposalId,uint _TokenAmount) public
  {
      PC = ProposalCategory(PCAddress);
      GD =GovernanceData(GDAddress);
      P1 = Pool(P1Address);

      require(GD.getProposalCategory(_proposalId) != 0 && GD.getProposalStatus(_proposalId) < 2);
      require(_TokenAmount >= PC.getMinStake(GD.getProposalCategory(_proposalId)) && _TokenAmount <= PC.getMaxStake(GD.getProposalCategory(_proposalId)));

      payableGBTTokens(_TokenAmount);
      setProposalValue(_proposalId,_TokenAmount);
      GD.pushInProposalStatus(_proposalId,2);
      GD.updateProposalStatus(_proposalId,2);
      P1.closeProposalOraclise(_proposalId,PC.getClosingTimeByIndex(GD.getProposalCategory(_proposalId),0));
  }
  
 /// @dev Some amount to be paid while using GovBlocks contract service - Approve the contract to spend money on behalf of msg.sender
  function payableGBTTokens(uint _TokenAmount) 
  {
      GBTC=GBTController(GBTCAddress);
      GD=GovernanceData(GDAddress);
      require(_TokenAmount >= GD.GBTStakeValue());
      GBTC.receiveGBT(msg.sender,_TokenAmount);
  }

  /// @dev Edits a proposal and Only owner of a proposal can edit it.
  function editProposal(uint _proposalId ,string _proposalDescHash) onlyOwner public
  {
      GD=GovernanceData(GDAddress);
      GD.storeProposalVersion(_proposalId);
      GD.updateProposal(_proposalId,_proposalDescHash);
      GD.changeProposalStatus(_proposalId,1);
      
      require(GD.getProposalCategory(_proposalId) > 0);
        GD.setProposalCategory(_proposalId,0);
  }

  /// @dev Calculate the proposal value to distribute it later - Distribute amount depends upon the final decision against proposal.
  function setProposalValue(uint _proposalId,uint _memberStake) 
  {
      GD=GovernanceData(GDAddress);
      GD.setProposalStake(_proposalId,_memberStake);
      uint memberLevel = Math.max256(GD.getMemberReputation(msg.sender),1);
      uint tokensHeld = SafeMath.div((SafeMath.mul(SafeMath.mul(GD.getBalanceOfMember(msg.sender),100),100)),GD.getTotalTokenInSupply());
      uint maxValue= Math.max256(tokensHeld,GD.membershipScalingFactor());

      uint finalProposalValue = SafeMath.mul(SafeMath.mul(GD.globalRiskFactor(),memberLevel),SafeMath.mul(_memberStake,maxValue));
      GD.setProposalValue(_proposalId,finalProposalValue);
  }

  function setProposalCategoryParams(uint _category,uint _proposalId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress,uint8 _verdictOptions) onlyInternal
  {
      GD=GovernanceData(GDAddress);
      PC=ProposalCategory(PCAddress);
      GD.setProposalCategoryParams1(_proposalId,_paramInt,_paramBytes32,_paramAddress,_verdictOptions);

      uint8 paramInt; uint8 paramBytes32; uint8 paramAddress;bytes32 parameterName; uint j;
      (,,,,paramInt,paramBytes32,paramAddress,,) = PC.getCategoryDetails(_category);
      
      for(j=0; j<paramInt; j++)
      {
          parameterName = PC.getCategoryParamNameUint(_category,j);
          GD.setParameterDetails1(_proposalId,j+1,parameterName,_paramInt);
      }

      for(j=0; j<paramBytes32; j++)
      {
          parameterName = PC.getCategoryParamNameBytes(_category,j); 
          GD.setParameterDetails2(_proposalId,j+1,parameterName,_paramBytes32);
      }

      for(j=0; j<paramAddress; j++)
      {
          parameterName = PC.getCategoryParamNameAddress(_category,j);
          GD.setParameterDetails3(_proposalId,j+1,parameterName,_paramAddress); 
      }
  }

  /// @dev categorizing proposal to proceed further.
  function categorizeProposal(uint _proposalId , uint8 _categoryId,uint8 _proposalComplexityLevel,uint _reward) public
  {
      MR = MemberRoles(MRAddress);
      PC = ProposalCategory(PCAddress);
      GD = GovernanceData(GDAddress);

      require(MR.getMemberRoleIdByAddress(msg.sender) == MR.getAuthorizedMemberId());
      require(GD.getProposalStatus(_proposalId) == 1 || GD.getProposalStatus(_proposalId) == 0);

      addComplexityLevelAndReward(_proposalId,_categoryId,_proposalComplexityLevel,_reward);
      GD.addInitialOptionDetails(_proposalId);
      GD.setCategorizedBy(_proposalId,msg.sender);
      GD.setProposalCategory(_proposalId,_categoryId);
  }

  /// @dev Proposal's complexity level and reward is added 
  function addComplexityLevelAndReward(uint _proposalId,uint _category,uint8 _proposalComplexityLevel,uint _reward) internal
  {
      PC=ProposalCategory(PCAddress);
      uint votingLength = PC.getRoleSequencLength(_category);
      GD.setProposalLevel(_proposalId,_proposalComplexityLevel);
      GD.setProposalIncentive(_proposalId,_reward); 
  }

 /// @dev Creates a new proposal.
  function createProposal(string _proposalDescHash,uint _votingTypeId,uint8 _categoryId,uint _TokenAmount) public
  {
      GD=GovernanceData(GDAddress);
      PC=ProposalCategory(PCAddress);
      require(GD.getBalanceOfMember(msg.sender) != 0);

      GD.setMemberReputation(msg.sender,1);
      GD.addTotalProposal(GD.getProposalLength(),msg.sender);

      if(_categoryId > 0)
      {
          uint _proposalId = GD.getProposalLength()-1;
          GD.addNewProposal(msg.sender,_proposalDescHash,_categoryId,GD.getVotingTypeAddress(_votingTypeId));
          openProposalForVoting(_proposalId,_TokenAmount);
          GD.addInitialOptionDetails(_proposalId);
          GD.setCategorizedBy(_proposalId,msg.sender);
          uint incentive;
          (,incentive) = PC.getCategoryIncentive(_categoryId);
          GD.setProposalIncentive(_proposalId,incentive); 
      }
      else
          GD.addNewProposal(msg.sender,_proposalDescHash,_categoryId,GD.getVotingTypeAddress(_votingTypeId));          
  }
  
 /// @dev Creates a new proposal.
  function createProposalwithOption(string _proposalDescHash,uint _votingTypeId,uint8 _categoryId,uint _TokenAmount,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress,string _optionDescHash) public
  {
      GD=GovernanceData(GDAddress);

      require(GD.getBalanceOfMember(msg.sender) != 0);
      require(_categoryId != 0);
      GD.setMemberReputation(msg.sender,1);
      
      GD.addTotalProposal(GD.getProposalLength(),msg.sender);
      uint _proposalId = GD.getProposalLength()-1;
      GD.addNewProposal(msg.sender,_proposalDescHash,_categoryId,GD.getVotingTypeAddress(_votingTypeId));
      openProposalForVoting(_proposalId,_TokenAmount/2);
      GD.addInitialOptionDetails(_proposalId);
      GD.setCategorizedBy(_proposalId,msg.sender);
      VT=VotingType(GD.getVotingTypeAddress(_votingTypeId));
      VT.addVerdictOption(_proposalId,msg.sender,_paramInt,_paramBytes32,_paramAddress,_TokenAmount,_optionDescHash);
  }
  /// @dev AFter the proposal final decision, member reputation will get updated.
  function updateMemberReputation(uint _proposalId,uint _finalVerdict) onlyInternal
  {
    GD=GovernanceData(GDAddress);
    address _proposalOwner =  GD.getProposalOwner(_proposalId);
    address _finalOptionOwner = GD.getOptionAddressByProposalId(_proposalId,_finalVerdict);
    uint addProposalOwnerPoints; uint addOptionOwnerPoints; uint subProposalOwnerPoints; uint subOptionOwnerPoints;
    (addProposalOwnerPoints,addOptionOwnerPoints,,subProposalOwnerPoints,subOptionOwnerPoints,)= GD.getMemberReputationPoints();

    if(_finalVerdict>0)
    {
        GD.setMemberReputation(_proposalOwner,SafeMath.add(GD.getMemberReputation(_proposalOwner),addProposalOwnerPoints));
        GD.setMemberReputation(_finalOptionOwner,SafeMath.add(GD.getMemberReputation(_finalOptionOwner),addOptionOwnerPoints)); 
    }
    else
    {
        GD.setMemberReputation(_proposalOwner,SafeMath.sub(GD.getMemberReputation(_proposalOwner),subProposalOwnerPoints));
        for(uint i=0; i<GD.getOptionAddedAddressLength(_proposalId); i++)
        {
            address memberAddress = GD.getOptionAddressByProposalId(_proposalId,i);
            GD.setMemberReputation(memberAddress,SafeMath.sub(GD.getMemberReputation(memberAddress),subOptionOwnerPoints));
        }
    }   
  }

  /// @dev Afer proposal Final Decision, Member reputation will get updated.
  function updateMemberReputation1(address _voterAddress,uint _voterPoints) onlyInternal
  {
     GD=GovernanceData(GDAddress);
     GD.setMemberReputation(_voterAddress,_voterPoints);
  }

  function checkProposalVoteClosing(uint _proposalId) onlyInternal constant returns(uint8 closeValue) 
  {
      PC=ProposalCategory(PCAddress);
      GD=GovernanceData(GDAddress);
      
      uint currentVotingId;uint category;
      (,category,currentVotingId,,,) = GD.getProposalDetailsById2(_proposalId);
      uint dateUpdate;
      (,,,,dateUpdate,,) = GD.getProposalDetailsById1(_proposalId);
      require(SafeMath.add(dateUpdate,PC.getClosingTimeByIndex(category,currentVotingId)) <= now);
       closeValue=1;
  }

 function checkRoleVoteClosing(uint _proposalId,uint _roleVoteLength) 
  {
     PC=ProposalCategory(PCAddress);
     GD=GovernanceData(GDAddress);
     MR=MemberRoles(MRAddress);
     P1=Pool(P1Address);

      uint currentVotingId;uint category;
      (,category,currentVotingId,,,) = GD.getProposalDetailsById2(_proposalId);
      
      uint roleId = PC.getRoleSequencAtIndex(category,currentVotingId);
      if(_roleVoteLength == MR.getAllMemberLength(roleId))
        P1.closeProposalOraclise1(_proposalId);
  }
  
  function getStatusOfProposalsForMember(uint[] _proposalsIds)constant returns (uint proposalLength,uint draftProposals,uint pendingProposals,uint acceptedProposals,uint rejectedProposals)
  {
       GD=GovernanceData(GDAddress);
       uint proposalStatus;

       for(uint i=0;i<_proposalsIds.length; i++)
       {
         proposalStatus=GD.getProposalStatus(_proposalsIds[i]);
         if(proposalStatus<2)
             draftProposals++;
         else if(proposalStatus==2)
           pendingProposals++;
         else if(proposalStatus==3)
           acceptedProposals++;
         else if(proposalStatus>=4)
           rejectedProposals++;
       }
 }
 
  //get status of proposals
  function getStatusOfProposals()constant returns (uint _proposalLength,uint _draftProposals,uint _pendingProposals,uint _acceptedProposals,uint _rejectedProposals)
  {
    GD=GovernanceData(GDAddress);
    uint proposalStatus;
    _proposalLength=GD.getProposalLength();

    for(uint i=0;i<_proposalLength;i++){
      proposalStatus=GD.getProposalStatus(i);
      if(proposalStatus<2)
          _draftProposals++;
      else if(proposalStatus==2)
        _pendingProposals++;
      else if(proposalStatus==3)
        _acceptedProposals++;
      else if(proposalStatus>=4)
        _rejectedProposals++;
        }
  }

}