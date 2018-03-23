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
import "./GBTController.sol";
import "./VotingType.sol";
// import "./zeppelin-solidity/contracts/token/BasicToken.sol";
// import "./zeppelin-solidity/contracts/math/SafeMath.sol";
// import "./zeppelin-solidity/contracts/math/Math.sol";

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
  memberRoles MR;
  ProposalCategory PC;
  governanceData GD;
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

  function changeAllContractsAddress(address _GDContractAddress,address _MRContractAddress,address _PCContractAddress,address _PoolContractAddress) onlyInternal
  {
     GDAddress = _GDContractAddress;
     PCAddress = _PCContractAddress;
     MRAddress = _MRContractAddress;
     P1Address = _PoolContractAddress;
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
  
  /// @dev Transfer reward after Final Proposal Decision.
  function transferBackGBTtoken(address _memberAddress, uint _value,string _description) onlyInternal
  {
      GBTC=GBTController(GBTCAddress);
      GBTC.transferGBT(_memberAddress,_value,_description);
  }

  function openProposalForVoting(uint _proposalId,uint _TokenAmount,uint24 _closeTime) public
  {
      PC = ProposalCategory(PCAddress);
      GD = governanceData(GDAddress);
      P1 = Pool(P1Address);

      require(GD.getProposalCategory(_proposalId) != 0 && GD.getProposalStatus(_proposalId) < 2);
      require(GD.getProposalOwner(_proposalId) == msg.sender);
      // require(_TokenAmount >= PC.getMinStake(GD.getProposalCategory(_proposalId)) && _TokenAmount <= PC.getMaxStake(GD.getProposalCategory(_proposalId)));

      uint closingTime = SafeMath.add(_closeTime,GD.getProposalDateUpd(_proposalId));
      payableGBTTokens(_TokenAmount,"Payable GBT Stake to submit proposal for voting");
      setProposalValue(_proposalId,_TokenAmount);
      // P1.closeProposalOraclise(_proposalId,PC.getClosingTimeByIndex(GD.getProposalCategory(_proposalId),0));
      // uint closingTime = SafeMath.add(PC.getClosingTimeByIndex(GD.getProposalCategory(_proposalId),0),GD.getProposalDateUpd(_proposalId));
      
      transferGBTtoPool(GD.getProposalIncentive(_proposalId));
      GD.changeProposalStatus(_proposalId,2);
      P1.closeProposalOraclise(_proposalId,_closeTime);
      GD.callOraclizeCallEvent(_proposalId,GD.getProposalDateAdd(_proposalId),closingTime);
  }
  
 /// @dev Some amount to be paid while using GovBlocks contract service - Approve the contract to spend money on behalf of msg.sender
  function payableGBTTokens(uint _TokenAmount,string _description) internal
  {
      GBTC=GBTController(GBTCAddress);
      GD=governanceData(GDAddress);
      require(_TokenAmount >= GD.GBTStakeValue());
      GBTC.receiveGBT(msg.sender,_TokenAmount,_description);
  }

  /// @dev Edits a proposal and Only owner of a proposal can edit it.
  function editProposal(uint _proposalId ,string _proposalDescHash) onlyOwner public
  {
      GD=governanceData(GDAddress);
      GD.storeProposalVersion(_proposalId);
      updateProposalDetails1(_proposalId,_proposalDescHash);
      GD.changeProposalStatus(_proposalId,1);
      
      require(GD.getProposalCategory(_proposalId) > 0);
        GD.setProposalCategory(_proposalId,0);
  }

  /// @dev Calculate the proposal value to distribute it later - Distribute amount depends upon the final decision against proposal.
  function setProposalValue(uint _proposalId,uint _memberStake) internal
  {
      GD=governanceData(GDAddress);
      GD.setProposalStake(_proposalId,_memberStake);

      uint memberLevel = Math.max256(GD.getMemberReputation(msg.sender),1);
      uint tokensHeld = SafeMath.div((SafeMath.mul(SafeMath.mul(GD.getBalanceOfMember(msg.sender),100),100)),GD.getTotalTokenInSupply());
      uint maxValue= Math.max256(tokensHeld,GD.membershipScalingFactor());

      uint finalProposalValue = SafeMath.mul(SafeMath.mul(GD.globalRiskFactor(),memberLevel),SafeMath.mul(_memberStake,maxValue));
      GD.setProposalValue(_proposalId,finalProposalValue);
  }
  
  /// @dev categorizing proposal to proceed further. _reward is the company incentive to distribute to End Members.
  function categorizeProposal(uint _proposalId , uint8 _categoryId,uint8 _proposalComplexityLevel,uint _dappIncentive) public
  {
      MR = memberRoles(MRAddress);
      GD = governanceData(GDAddress);
      P1 = Pool(P1Address);

      require(MR.getMemberRoleIdByAddress(msg.sender) == MR.getAuthorizedMemberId());
      require(GD.getProposalStatus(_proposalId) == 1 || GD.getProposalStatus(_proposalId) == 0);
      
      addComplexityLevelAndIncentive(_proposalId,_categoryId,_proposalComplexityLevel,_dappIncentive);
      addInitialOptionDetails(_proposalId);
      

     if(_dappIncentive != 0)
        uint gbtBalanceOfPool = GD.getBalanceOfMember(P1Address);
        require (gbtBalanceOfPool > _dappIncentive);
       
     GD.setProposalIncentive(_proposalId,_dappIncentive);
      GD.setCategorizedBy(_proposalId,msg.sender);
      GD.setProposalCategory(_proposalId,_categoryId);
  }

  /// @dev Proposal's complexity level and reward is added 
  function addComplexityLevelAndIncentive(uint _proposalId,uint _category,uint8 _proposalComplexityLevel,uint _reward) internal
  {
      GD=governanceData(GDAddress);
      GD.setProposalLevel(_proposalId,_proposalComplexityLevel);
      GD.setProposalIncentive(_proposalId,_reward); 
  }

 /// @dev Creates a new proposal.
  function createProposal(string _proposalDescHash,uint _votingTypeId,uint8 _categoryId,uint _categoryIncentive,uint _TokenAmount,uint24 _closeTime,uint _dateAdd) public
  {
      GD=governanceData(GDAddress);
      PC=ProposalCategory(PCAddress);
      require(GD.getBalanceOfMember(msg.sender) != 0);
      uint _proposalId = GD.getProposalLength();
      address votingAddress = GD.getVotingTypeAddress(_votingTypeId);

      GD.addTotalProposal(_proposalId,msg.sender);

      if(_categoryId > 0)
      {
          address VTAddress = GD.getVotingTypeAddress(_votingTypeId);
          GD.addNewProposal(msg.sender,_proposalDescHash,_categoryId,VTAddress,_dateAdd);
          openProposalForVoting(_proposalId,_TokenAmount,_closeTime);
          addInitialOptionDetails(_proposalId);
          GD.setCategorizedBy(_proposalId,msg.sender);
          GD.setProposalIncentive(_proposalId,_categoryIncentive);
          transferGBTtoPool(_categoryIncentive); 
          // payableGBTTokens(_categoryIncentive);
      }
      else
          GD.addNewProposal(msg.sender,_proposalDescHash,_categoryId,votingAddress,now);          
  }

  function transferGBTtoPool(uint _TokenAmount) internal
  {
     P1=Pool(P1Address);
     GD=governanceData(GDAddress);
     P1.transferGBTtoController(_TokenAmount,"Dapp incentive to be distributed in GBT");
  }
  
 // /// @dev Creates a new proposal.
 //  function createProposalwithOption(string _proposalDescHash,uint _votingTypeId,uint8 _categoryId,uint _TokenAmount,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress,string _optionDescHash) public
 //  {
 //      createProposal(_proposalIdDescHash,_votingTypeId,_categoryId,_TokenAmount);
 //      VT=VotingType(GD.getVotingTypeAddress(_votingTypeId));
 //      uint _proposalId = GD.getProposalLength()-1;
 //      VT.addVerdictOption(_proposalId,msg.sender,_paramInt,_paramBytes32,_paramAddress,_TokenAmount,_optionDescHash);
 //  }

  /// @dev Creates a new proposal.
  function createProposalwithOption(string _proposalDescHash,uint _votingTypeId,uint8 _categoryId,uint _categoryIncentive,uint _TokenAmount,string _optionHash,uint24 _closeTime) public
  {
      GD=governanceData(GDAddress);
      uint nowDate = now;
      createProposal(_proposalDescHash,_votingTypeId,_categoryId,_categoryIncentive,_TokenAmount,_closeTime,nowDate);
      uint _proposalId = GD.getProposalLength()-1;
      VT=VotingType(GD.getProposalVotingType(_proposalId));
      VT.addVerdictOption(_proposalId,msg.sender,_TokenAmount,_optionHash,nowDate); 
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
        for(uint i=0; i<GD.getOptionAddedAddressLength(_proposalId); i++)
        {
            address memberAddress = GD.getOptionAddressByProposalId(_proposalId,i);
            GD.setMemberReputation("Reputation debit for option owner - Rejected by majority voting",_proposalId,memberAddress,SafeMath.sub(GD.getMemberReputation(memberAddress),subOptionOwnerPoints),subOptionOwnerPoints,"D");
        }
    }   
  }

  /// @dev Afer proposal Final Decision, Member reputation will get updated.
  function updateMemberReputation1(string _desc,uint _proposalId,address _voterAddress,uint _voterPoints,uint _repPointsEvent,bytes4 _typeOf) onlyInternal
  {
     GD=governanceData(GDAddress);
     GD.setMemberReputation(_desc,_proposalId,_voterAddress,_voterPoints,_repPointsEvent,_typeOf);
  }

  // function checkProposalVoteClosing(uint _proposalId) onlyInternal constant returns(uint8 closeValue) 
  // {
  //     PC=ProposalCategory(PCAddress);
  //     GD=governanceData(GDAddress);
  //     MR=memberRoles(MRAddress);
      
  //     uint currentVotingId;uint category;
  //     (,category,currentVotingId,,,) = GD.getProposalDetailsById2(_proposalId);
  //     uint dateUpdate;
  //     (,,,,dateUpdate,,) = GD.getProposalDetailsById1(_proposalId);
  //     address votingTypeAddress;
  //     (,,,,,votingTypeAddress) = GD.getProposalDetailsById2(_proposalId);
  //     VT=VotingType(votingTypeAddress);
  //     uint roleId = PC.getRoleSequencAtIndex(category,currentVotingId);

  //     if(SafeMath.add(dateUpdate,PC.getClosingTimeByIndex(category,currentVotingId)) <= now || GD.getVoteLength(_proposalId,roleId) == MR.getAllMemberLength(roleId))
  //       closeValue=1;
  // }

  function checkProposalVoteClosing(uint _proposalId,uint _roleId,uint _closingTime) onlyInternal constant returns(uint8 closeValue) 
  {
      GD=governanceData(GDAddress);
      MR=memberRoles(MRAddress);
      
      uint dateUpdate;
      (,,,,dateUpdate,,) = GD.getProposalDetailsById1(_proposalId);

      if(SafeMath.add(dateUpdate,_closingTime) <= now || GD.getVoteLength(_proposalId,_roleId) == MR.getAllMemberLength(_roleId))
        closeValue=1;
  }

 function checkRoleVoteClosing(uint _proposalId,uint _roleVoteLength,uint _authRoleId) 
  {
     GD=governanceData(GDAddress);
     P1=Pool(P1Address);
     MR = memberRoles(MRAddress);
      
      if(_roleVoteLength == MR.getAllMemberLength(_authRoleId))
        P1.closeProposalOraclise(_proposalId,0);
        GD.callOraclizeCallEvent(_proposalId,GD.getProposalDateAdd(_proposalId),0);
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

    function getVoteDetailById(address _memberAddress,address _votingTypeAddress,uint _voteId)constant returns(uint id, uint proposalId,uint dateAdded,uint voteStake,uint voteReward)
    {
        id = _voteId;
        VT=VotingType(_votingTypeAddress);
        GD=governanceData(GDAddress);
        require(GD.getVoterAddress(_voteId) == _memberAddress);
          (,proposalId,,dateAdded,,voteStake,) = GD.getVoteDetailByid(_voteId);
          voteReward = GD.getVoteReward(_voteId); 
    } 

    /// @dev Get the Value, stake and Address of the member whosoever added that verdict option.
    function getOptionDetailsById(uint _proposalId,uint _optionIndex) constant returns(uint id, uint optionid,uint optionStake,uint optionValue,address memberAddress,uint optionReward)
    {
        GD=governanceData(GDAddress);
        id = _proposalId;
        optionid = _optionIndex;
        optionStake = GD.getOptionStakeById(_proposalId,_optionIndex);
        optionValue = GD.getOptionValueByProposalId(_proposalId,_optionIndex);
        memberAddress = GD.getOptionAddressByProposalId(_proposalId,_optionIndex);
        optionReward = GD.getOptionReward(_proposalId,_optionIndex);
        return (_proposalId,optionid,optionStake,optionValue,memberAddress,optionReward);
    }

    function getOptionDetailsByAddress(uint _proposalId,address _memberAddress) constant returns(uint optionIndex,uint optionStake,uint optionReward,uint dateAdded,uint proposalId)
    {
        GD=governanceData(GDAddress);
        optionIndex = GD.getOptionIdByAddress(_proposalId,_memberAddress);
        optionStake = GD.getOptionStakeById(_proposalId,optionIndex);
        optionReward = GD.getOptionReward(_proposalId,optionIndex);
        dateAdded = GD.getOptionDateAdded(_proposalId,optionIndex);
        proposalId = _proposalId;    
    }

    function getProposalRewardByMember(address _memberAddress) constant returns(uint[] propStake,uint[] propReward)
    {
        GD=governanceData(GDAddress);
        propStake = new uint[](GD.getTotalProposal(_memberAddress));
        propReward = new uint[](GD.getTotalProposal(_memberAddress));

        for(uint i=0; i<GD.getTotalProposal(_memberAddress); i++)
        {
            propStake[i] = GD.getProposalStake(GD.getProposalIdByAddress(_memberAddress,i));
            propReward[i] = GD.getProposalReward(GD.getProposalIdByAddress(_memberAddress,i));
        }
    }

    function getProposalStakeByMember(address _memberAddress) constant returns(uint stakeValueProposal)
    {
        GD=governanceData(GDAddress);
        for(uint i=0; i<GD.getTotalProposal(_memberAddress); i++)
        {
            stakeValueProposal = stakeValueProposal + GD.getProposalStake(GD.getProposalIdByAddress(_memberAddress,i));
        }
    }

    function getOptionStakeByMember(address _memberAddress)constant returns(uint stakeValueOption)
    {
        GD=governanceData(GDAddress); stakeValueOption;

        for(uint i=0; i<GD.getProposalAnsLength(_memberAddress); i++)
        {
            uint _proposalId = GD.getProposalAnsId(_memberAddress,i);
            uint _optionId = GD.getOptionIdByAddress(_proposalId,_memberAddress);
            uint stake = GD.getOptionStakeById(_proposalId,_optionId);
            stakeValueOption = stakeValueOption + stake;
        }
    }

    function setProposalDetails(uint _proposalId,uint _totaltoken,uint _blockNumber,uint _reward)
    {
       GD=governanceData(GDAddress);
       GD.setProposalTotalToken(_proposalId,_totaltoken);
       GD.setProposalBlockNo(_proposalId,_blockNumber);
       GD.setProposalReward(_proposalId,_reward);
    }

    function getMemberDetails(address _memberAddress) constant returns(uint memberReputation, uint totalProposal,uint proposalStake,uint totalOption,uint optionStake,uint totalVotes)
    {
        GD=governanceData(GDAddress);
        memberReputation = GD.getMemberReputation(_memberAddress);
        totalProposal = GD.getTotalProposal(_memberAddress);
        proposalStake = getProposalStakeByMember(_memberAddress);
        totalOption = GD.getProposalAnsLength(_memberAddress);
        optionStake = getOptionStakeByMember(_memberAddress);
        totalVotes = GD.getTotalVotesByAddress(_memberAddress);
    }

    /// @dev As bydefault first option is alwayd deny option. One time configurable.
    function addInitialOptionDetails(uint _proposalId) 
    {
        GD=governanceData(GDAddress);
        if(GD.getInitialOptionsAdded(_proposalId) == 0)
        {
            GD.setOptionAddress(_proposalId,0x00);
            GD.setOptionStake(_proposalId,0);
            GD.setOptionValue(_proposalId,0);
            GD.setOptionHash(_proposalId,"");
            GD.setOptionDateAdded(_proposalId,0);
            GD.setTotalOptions(_proposalId);
            GD.setInitialOptionsAdded(_proposalId);
        }
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

    function submitProposalWithOption(uint _proposalId,uint _TokenAmount,uint24 _closeTime,string _optionHash)
    {
        GD=governanceData(GDAddress);
        openProposalForVoting(_proposalId,_TokenAmount,_closeTime);
        VT=VotingType(GD.getProposalVotingType(_proposalId));
        uint nowDate = GD.getProposalDateAdd(_proposalId);
        VT.addVerdictOption(_proposalId,msg.sender,_TokenAmount,_optionHash,nowDate); 
    }

}