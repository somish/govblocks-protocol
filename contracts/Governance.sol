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
import "./governanceData.sol";
import "./ProposalCategory.sol";
import "./memberRoles.sol";
import "./Master.sol";
import "./BasicToken.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./Pool.sol";
import "./GBTStandardToken.sol";
import "./VotingType.sol";

contract Governance {
    
  using SafeMath for uint;
  using Math for uint;
  address GDAddress;
  address PCAddress;
  address MRAddress;
  address masterAddress;
  address BTAddress;
  address P1Address;
  address GBTSAddress;
  GBTStandardToken GBTS;
  GBTController GBTC;
  Master MS;
  memberRoles MR;
  ProposalCategory PC;
  governanceData GD;
  BasicToken BT;
  Pool P1;
  VotingType VT;
  uint finalRewardToDistribute;

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

    modifier onlyMaster {    
        require(msg.sender == masterAddress);
        _; 
    }


  function changeAllContractsAddress(address _GDContractAddress,address _MRContractAddress,address _PCContractAddress,address _PoolContractAddress) onlyInternal
  {
     GDAddress = _GDContractAddress;
     PCAddress = _PCContractAddress;
     MRAddress = _MRContractAddress;
     P1Address = _PoolContractAddress;
  }

  function changeGBTSAddress(address _GBTAddress) onlyMaster
  {
      GBTSAddress = _GBTAddress;
  }

  function changeMasterAddress(address _MasterAddress) onlyInternal
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
  
  function createProposal(string _proposalDescHash,uint _votingTypeId,uint8 _categoryId,uint _dateAdd) public
  {
      GD=governanceData(GDAddress);
      PC=ProposalCategory(PCAddress);
      uint _proposalId = GD.getProposalLength();
      address votingAddress = GD.getVotingTypeAddress(_votingTypeId); 
      if(_categoryId > 0)
      {
          GD.addNewProposal(_proposalId,msg.sender,_proposalDescHash,_categoryId,votingAddress,_dateAdd);
          GD.setProposalIncentive(_proposalId,PC.getCatIncentive(_categoryId));
      }
      else
          GD.createProposal1(_proposalId,msg.sender,_proposalDescHash,votingAddress,now);          
  }

  /// @dev Creates a new proposal.
  function createProposalwithSolution(string _proposalDescHash,uint _votingTypeId,uint8 _categoryId,uint _proposalSolutionStake,string _solutionHash) public
  {
      GD=governanceData(GDAddress);
      uint proposalDateAdd = now;
      uint _proposalId = GD.getProposalLength();
      uint proposalStake = SafeMath.div(_proposalSolutionStake,2);
      createProposal(_proposalDescHash,_votingTypeId,_categoryId,nowDate);
      openProposalForVoting(_proposalId,_categoryId,proposalStake);
      receiveStake(_proposalId,SafeMath.sub(_proposalSolutionStake,proposalStake),GD.getVotingTypeAddress(_votingTypeId),proposalDateAdd,_solutionHash);
  }

  function submitProposalWithSolution(uint _proposalId,uint _proposalSolutionStake,string _optionHash) public
  {
      GD=governanceData(GDAddress); 
      require(msg.sender == GD.getProposalOwner(_proposalId));
      uint proposalDateAdd = GD.getProposalDateAdd(_proposalId);
      uint proposalStake = SafeMath.div(_proposalSolutionStake,2); 
      openProposalForVoting(_proposalId,GD.getProposalCategory(_proposalId),proposalStake);
      receiveStake(_proposalId,SafeMath.sub(_TokenAmount,proposalGBT),GD.getProposalVotingType(_proposalId),proposalDateAdd,_solutionHash);
  }

  function receiveStake(uint _proposalId,uint _solutionStake,address _VTAddress,uint _proposalDateAdd,string _solutionHash) internal
  {
        VT=VotingType(_VTAddress);
        GD=governanceData(GDAddress);
        GBTS=GBTStandardToken(GBTSAddress);

        uint depositAmount = ((_solutionStake*GD.depositPercOption())/100);
        uint finalAmount = depositAmount + GD.getDepositTokensByAddress(msg.sender,_proposalId);
        GD.setDepositTokens(msg.sender,_proposalId,finalAmount,'S');
        GBTS.lockToken(_gbUserName,_proposalId,SafeMath.sub(_solutionStake,finalAmount)); 
        VT.addVerdictOption(_proposalId,msg.sender,_solutionHash,_proposalDateAdd,_solutionStake);
  }

  function openProposalForVoting(uint _proposalId,uint _categoryId,uint _tokenAmount) public 
  {
      PC = ProposalCategory(PCAddress);
      GD = governanceData(GDAddress);
      P1 = Pool(P1Address);
      GBTS=GBTStandardToken(GBTSAddress); uint pStatus;uint pCategory;
      (,pStatus,pCategory) = GD.getProposalDetailsById3(_proposalId);

      require(pStatus != 0 && pStatus < 2 && GD.getProposalOwner(_proposalId) == msg.sender);
      uint closingTime = SafeMath.add(PC.getClosingTimeAtIndex(_categoryId,0),GD.getProposalDateUpd(_proposalId));
      uint remainingTime = PC.getRemainingClosingTime(_proposalId,pCategory,GD.getProposalCurrentVotingId(_proposalId));

      uint depositAmount = SafeMath.div(SafeMath.mul(_TokenAmount,GD.depositPercProposal()),100);
      uint finalAmount = depositAmount + GD.getDepositTokensByAddress(msg.sender,_proposalId);
      GBTS.lockToken(msg.sender,SafeMath.sub(_TokenAmount,finalAmount),remainingTime);
      GD.setDepositTokens(msg.sender,_proposalId,finalAmount,'P');
      GD.changeProposalStatus(_proposalId,2);
      callOraclize(_proposalId,closingTime);
  }

  function callOraclize(uint _proposalId,uint _closeTime) internal
  {
      GD = governanceData(GDAddress);
      P1 = Pool(P1Address);
      P1.closeProposalOraclise(_proposalId,_closeTime);
      GD.callOraclizeCallEvent(_proposalId,GD.getProposalDateAdd(_proposalId),_closeTime);
  }

  /// @dev Edits a proposal and Only owner of a proposal can edit it.
  function editProposal(uint _proposalId ,string _proposalDescHash) public
  {
      GD=governanceData(GDAddress);
      require(msg.sender == GD.getProposalOwner(_proposalId));
      GD.storeProposalVersion(_proposalId,_proposalDescHash);
      updateProposalDetails1(_proposalId,_proposalDescHash);
      GD.changeProposalStatus(_proposalId,1);
      
      if(GD.getProposalCategory(_proposalId) > 0)
        GD.setProposalCategory(_proposalId,0);
  }
  
  /// @dev categorizing proposal to proceed further. _reward is the company incentive to distribute to End Members.
  function categorizeProposal(uint _proposalId , uint8 _categoryId,uint8 _proposalComplexityLevel,uint _dappIncentive) public
  {
      MR = memberRoles(MRAddress);
      GD = governanceData(GDAddress);
      P1 = Pool(P1Address);
      GBTS=GBTStandardToken(GBTSAddress);

      require(MR.getMemberRoleIdByAddress(msg.sender) == MR.getAuthorizedMemberId());
      require(GD.getProposalStatus(_proposalId) == 1 || GD.getProposalStatus(_proposalId) == 0);
      uint gbtBalanceOfPool = GBTS.balanceOf(P1Address);
      require (_dappIncentive <= gbtBalanceOfPool);
  
      GD.setProposalIncentive(_proposalId,_dappIncentive);
      GD.setProposalCategory(_proposalId,_categoryId);
  }

  /// @dev AFter the proposal final decision, member reputation will get updated.
  function updateMemberReputation(uint _proposalId,uint _finalVerdict) onlyInternal
  {
    GD=governanceData(GDAddress);
    address _proposalOwner =  GD.getProposalOwner(_proposalId);
    address _finalOptionOwner = GD.getOptionAddressByProposalId(_proposalId,_finalVerdict);
    uint addProposalOwnerPoints; uint addOptionOwnerPoints; uint subProposalOwnerPoints; uint subOptionOwnerPoints;
    (addProposalOwnerPoints,addOptionOwnerPoints,,subProposalOwnerPoints,subOptionOwnerPoints,)= GD.getMemberReputationPoints();

    if(_finalVerdict>0)
    {
        GD.setMemberReputation("Reputation credit for proposal owner - Accepted",_proposalId,_proposalOwner,SafeMath.add(GD.getMemberReputation(_proposalOwner),addProposalOwnerPoints),addProposalOwnerPoints,"C");
        GD.setMemberReputation("Reputation credit for option owner - Final option selected by majority voting",_proposalId,_finalOptionOwner,SafeMath.add(GD.getMemberReputation(_finalOptionOwner),addOptionOwnerPoints),addOptionOwnerPoints,"C"); 
    }
    else
    {
        GD.setMemberReputation("Reputation debit for proposal owner - Rejected",_proposalId,_proposalOwner,SafeMath.sub(GD.getMemberReputation(_proposalOwner),subProposalOwnerPoints),subProposalOwnerPoints,"D");
        for(uint i=0; i<GD.getTotalVerdictOptions(_proposalId); i++)
        {
            address memberAddress = GD.getOptionAddressByProposalId(_proposalId,i);
            GD.setMemberReputation("Reputation debit for option owner - Rejected by majority voting",_proposalId,memberAddress,SafeMath.sub(GD.getMemberReputation(memberAddress),subOptionOwnerPoints),subOptionOwnerPoints,"D");
        }
    }   
  }

  /// @dev Afer proposal Final Decision, Member reputation will get updated.
  // function updateMemberReputation1(string _desc,uint _proposalId,address _voterAddress,uint _voterPoints,uint _repPointsEvent,bytes4 _typeOf) onlyInternal
  // {
  //    GD=governanceData(GDAddress);
  //    GD.setMemberReputation(_desc,_proposalId,_voterAddress,_voterPoints,_repPointsEvent,_typeOf);
  // }

  function checkProposalVoteClosing(uint _proposalId,uint _roleId,uint _closingTime,uint _majorityVote) onlyInternal constant returns(uint8 closeValue) 
  {
      GD=governanceData(GDAddress);
      MR=memberRoles(MRAddress);
      uint dateUpdate;uint pStatus;
      (,,dateUpdate,,pStatus) = GD.getProposalDetailsById1(_proposalId);

      if(pStatus == 2 && _roleId != 2)
      {
        if(SafeMath.add(dateUpdate,_closingTime) <= now || GD.getVoteLength(_proposalId,_roleId) == MR.getAllMemberLength(_roleId))
          closeValue=1;
      }
      else if(pStatus == 2)
      {
         if(SafeMath.add(dateUpdate,_closingTime) <= now)
              closeValue=1;
      }
      else if(pStatus > 2)
      {
         closeValue=2;
      }
      else
      {
        closeValue=0;
      }
  }

   function checkRoleVoteClosing(uint _proposalId,uint _roleId,uint _closingTime,uint _majorityVote) onlyInternal
   {    
    if(checkProposalVoteClosing(_proposalId,_roleId,_closingTime,_majorityVote)==1)
      callOraclize(_proposalId,0);
   }

  function getStatusOfProposalsForMember(uint[] _proposalsIds)constant returns (uint proposalLength,uint draftProposals,uint pendingProposals,uint acceptedProposals,uint rejectedProposals)
  {
      GD=governanceData(GDAddress);
      uint proposalStatus;
      proposalLength=GD.getProposalLength();

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
    GD=governanceData(GDAddress);
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

    function setProposalDetails(uint _proposalId,uint _totaltoken,uint _totalVoteValue) onlyInternal
    {
       GD=governanceData(GDAddress);
       GD.setProposalTotalToken(_proposalId,_totaltoken);
       GD.setProposalTotalVoteValue(_proposalId,_totalVoteValue);
    }

    function getMemberDetails(address _memberAddress) constant returns(uint memberReputation, uint totalProposal,uint totalSolution,uint totalVotes)
    {
        GD=governanceData(GDAddress);
        memberReputation = GD.getMemberReputation(_memberAddress);
        uint totalProposal; uint totalSolution;
        (,,totalProposal,totalSolution) = GD.getProposalAnsByAddress(_memberAddress);
        totalVotes = GD.getTotalVotesByAddress(_memberAddress);
    }

    /// @dev Change pending proposal start variable
    function changePendingProposalStart() onlyInternal
    {
        GD=governanceData(GDAddress);
        uint pendingPS = GD.pendingProposalStart();
        for(uint j=pendingPS; j<GD.getProposalLength(); j++)
        {
            if(GD.getProposalStatus(j) > 3)
                pendingPS = SafeMath.add(pendingPS,1);
            else
                break;
        }
        if(j!=pendingPS)
        {
            GD.changePendingProposalStart(j);
        }
    }
    /// @dev Updating proposal's Major details (Called from close proposal Vote).
    function updateProposalDetails(uint _proposalId,uint8 _currVotingStatus, uint8 _intermediateVerdict,uint8 _finalVerdict) onlyInternal 
    {
        GD=governanceData(GDAddress);
        GD.setProposalCurrentVotingId(_proposalId,_currVotingStatus);
        GD.setProposalIntermediateVerdict(_proposalId,_intermediateVerdict);
        GD.setProposalFinalVerdict(_proposalId,_finalVerdict);
        GD.setProposalDateUpd(_proposalId);
    }

    /// @dev Edits the details of an existing proposal and creates new version.
    function updateProposalDetails1(uint _proposalId,string _proposalDescHash) internal
    {
        GD=governanceData(GDAddress);
        GD.setProposalDesc(_proposalId,_proposalDescHash);
        GD.setProposalDateUpd(_proposalId);
        GD.setProposalVersion(_proposalId);
    }

    function getTotalIncentiveByDapp()constant returns (uint allIncentive)
    {
        GD=governanceData(GDAddress);
        for(uint i=0; i<GD.getProposalLength(); i++)
        {
            allIncentive =  allIncentive + GD.getProposalIncentive(i);
        }
    }

    function calculateProposalReward(address  _memberAddress,uint _createId,uint _proposalCreateLength) internal
    {
        GD=governanceData(GDAddress);
        uint lastIndex = 0; uint proposalId;uint category;uint finalVredict;uint proposalStatus;uint calcReward
        for(i=createId; i<proposalCreateLength; i++)
        {   
            (proposalId,category,finalVredict,proposalStatus) = GD.getProposalDetailsByAddress(_memberAddress,i);
            if(proposalStatus< 2)
                lastIndex = i;

            if(finalVredict > 0 && GD.getReturnedTokens(_memberAddress,proposalId,'P') == 0)
            {
                calcReward = (PC.getRewardPercProposal(category)*GD.getProposalTotalReward(proposalId))/100;
                finalRewardToDistribute = finalRewardToDistribute + calcReward + GD.getDepositedTokens(_memberAddress,_proposalId,'P');
                GD.callRewardEvent(_memberAddress,proposalId,"GBT Reward for being Proposal owner - Accepted ",calcReward)
                GD.setReturnedTokens(_memberAddress,proposalId,'P',1);
            }
        }

        if(lastIndex == 0)
          lastIndex = i;
        setProposalCreate(_memberAddress,lastIndex);
    }

    function calculateOptionReward(address _memberAddress,uint _optionId,uint _optionCreateLength) internal
    {
        GD=governanceData(GDAddress);
        uint lastIndex = 0;uint i;uint proposalId;uint optionId;uint proposalStatus;uint finalVredict;
        for(i=optionId; i<optionCreateLength; i++)
        {
            (proposalId,optionId,proposalStatus,finalVredict) = GD.getOptionIdAgainstProposalByAddress(GD.getAllProposalIdByMember(_memberAddress,i));
            if(propStatus< 2)
                lastIndex = i;

            if(finalVredict> 0 && finalVredict == optionId && GD.getReturnedTokens(_memberAddress,proposalId,'S') == 0)
            {
                calcReward = (PC.getRewardPercOption(category)*GD.getProposalTotalReward(proposalId))/100;
                finalRewardToDistribute = finalRewardToDistribute + calcReward + GD.getDepositedTokens(_memberAddress,_proposalId,'S');
                GD.callRewardEvent(_memberAddress,_proposalId,"GBT Reward earned for being Solution owner - Final Solution by majority voting",calcReward);
                GD.setReturnedTokens(_memberAddress,proposalId,'S',1);
            }
        }

         if(lastIndex == 0)
          lastIndex = i;
        setOptionCreate(_memberAddress,lastIndex);
    }

    function calculateVoteReward(address _memberAddress,uint _voteId,uint _proposalVoteLength) internal
    {
        GD=governanceData(GDAddress);
        uint lastIndex = 0;uint i;uint proposalId;uint voteId;uint optionChosen;uint proposalStatus;uint finalVredict;
        for(i=voteId; i<proposalVoteLength; i++)
        {
            (voteId,proposalId,optionChosen,proposalStatus,finalVredict) = GD.getProposalDetailsByVoteId(_memberAddress,i,0);
            if(proposalStatus < 2)
                lastIndex = i;

            if(finalVredict > 0 && optionChosen == finalVredict && GD.getReturnedTokens(_memberAddress,proposalId,'V') == 0)
            {
                calcReward = (PC.getRewardPercVote(category)*GD.getProposalTotalReward(proposalId)*GD.getVoteValue(voteid))/(100*GD.getProposalReward(proposalId));
                finalRewardToDistribute = finalRewardToDistribute + calcReward + GD.getDepositedTokens(_memberAddress,_proposalId,'V');
                GD.callRewardEvent(_memberAddress,_proposalId,"GBT Reward earned for voting in favour of final option",calcReward);
                GD.setReturnedTokens(_memberAddress,proposalId,'V',1);
            }
        }
        if(lastIndex == 0)
          lastIndex = i;
        setProposalVote(_memberAddress,lastIndex);
    }


    function calculateMemberReward(address _memberAddress) constant returns(uint rewardToClaim)
    {
        uint createId;uint optionid;uint voteId; uint proposalCreateLength;uint optionCreateLength; uint proposalVoteLength;
        PC=ProposalCategory(PCAddress);
        GD=governanceData(GDAddress);
        GBTS=GBTStandardToken(GBTSAddress);
        (,proposalCreateLength,,optionCreateLength,,proposalVoteLength) = getMemberDetails(_memberAddress);
        (createId,optionId,voteId) = GD.getIdOfLastReward(_memberAddress);

        calculateProposalReward(_memberAddress,createId,proposalCreateLength);
        calculateOptionReward(_memberAddress,optionId,optionCreateLength);
        calculateVoteReward(_memberAddress,voteId,proposalVoteLength);
        return finalRewardToDistribute;
    }

}