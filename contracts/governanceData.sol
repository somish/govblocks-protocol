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
import "./Master.sol";
import "./Pool.sol";
import "./GBTStandardToken.sol";
import "./GBTController.sol";
import "./ProposalCategory.sol";

contract GovernanceData {
    using SafeMath for uint;
    struct proposal{
        address owner;
        string proposalDescHash;
        uint date_add;
        uint date_upd;
        uint8 versionNum;
        uint8 currVotingStatus;
        uint8 propStatus;  
        uint8 category;
        uint8 finalVerdict;
        uint8 currentVerdict;
        address votingTypeAddress;
        uint proposalValue;
        uint proposalStake;
        uint proposalReward;
        uint totalreward;
        uint blocknumber;
    }

    struct proposalCategory{
        address categorizedBy;
        uint[] paramInt;
        bytes32[] paramBytes32;
        address[] paramAddress;
        uint8 verdictOptions;
        address[] optionAddedByAddress;
        uint[] valueOfOption;
        uint[] stakeOnOption;
        string[] optionDescHash;
        uint[] optionDateAdd;
        mapping(uint=>uint) rewardOption;
    }

    struct proposalCategoryParams
    {
        mapping(bytes32=>uint[]) optionNameIntValue;
        mapping(bytes32=>bytes32[]) optionNameBytesValue;
        mapping(bytes32=>address[]) optionNameAddressValue;
    }

    mapping(uint=>proposalCategoryParams) allProposalCategoryParams;

    struct proposalVersionData{
        uint versionNum;
        string proposalDescHash;
        uint date_add;
    }

    struct Status{
        uint statusId;
        uint date;
    }
    
    struct proposalPriority 
    {
        uint8 complexityLevel;
        uint commonIncentive;
    }

   
    struct votingTypeDetails
    {
        bytes32 votingTypeName;
        address votingTypeAddress;
    }

    mapping(uint=>proposalCategory) allProposalCategory;
    mapping(uint=>proposalVersionData[]) proposalVersions;
    mapping(uint=>Status[]) proposalStatus;
    mapping(uint=>proposalPriority) allProposalPriority;
    mapping(address=>uint) allMemberReputationByAddress;
    mapping(uint=>uint[]) totalVotesAgainstProposal;
    mapping(address=>bytes32) votingTypeNameByAddress;
    mapping(address=>uint[]) allProposalMember; // Proposal Against Member
    mapping(address=>uint[]) allProposalOption; // Total Options against Member, array contains optionindexs;
    mapping(address=>uint) totalOptionStake; // total Optionstake Against member
    mapping(address=>uint) totalVotesAgainstMember; // Total Votes given by member till now..
    mapping(uint=>uint8) initialOptionsAdded;
    mapping(address=>mapping(uint=>uint)) allOptionDataAgainstMember;

    uint public quorumPercentage;
    uint public pendingProposalStart;
    uint public GBTStakeValue; 
    uint public globalRiskFactor; 
    uint public membershipScalingFactor;
    uint public scalingWeight;
    uint addProposalOwnerPoints;
    uint addOptionOwnerPoints;
    uint addMemberPoints;
    uint subProposalOwnerPoints;
    uint subOptionOwnerPoints;
    uint subMemberPoints;
    uint constructorCheck;

    string[]  status;
    proposal[] allProposal;
    // proposalReward[] allProposalReward;
    votingTypeDetails[] allVotingTypeDetails;

    address GBTSAddress;
    address PoolAddress;
    // address masterAddress;
    address PCAddress;
    address owner;
    address GBTCAddress;
    ProposalCategory PC;
    GBTController GBTC;
    GBTStandardToken GBTS;
    // Master MS;
    Pool P1;

    modifier onlyInternal {
        // MS=Master(masterAddress);
        // require(MS.isInternal(msg.sender) == 1);
        
        _; 
    }
    
     modifier onlyOwner {
        // MS=Master(masterAddress);
        // require(MS.isOwner(msg.sender) == 1);
        _; 
    }
    
    function GovernanceDataInitiate() 
    {
        require(constructorCheck == 0);
            setGlobalParameters();
            addStatus();
            addMemberReputationPoints();
            setVotingTypeDetails("Simple Voting",0x6c1493b7f50cc0ed3a3046a7f4954da556e142f6);
            setVotingTypeDetails("Rank Based Voting",0xf98056759d1590dd0714cfe3c688cc18b02c4a8c);
            setVotingTypeDetails("Feature Weighted Voting",0x416153329b7e9d78c0e72eef4fedd926807f700b);
            constructorCheck =1;
    }
    
    /// @dev Add points to add or subtract in memberReputation when proposal/option/vote gets denied or accepted.
    function addMemberReputationPoints() internal
    {
        addProposalOwnerPoints = 5;
        addOptionOwnerPoints = 5;
        addMemberPoints = 1;
        subProposalOwnerPoints = 1;
        subOptionOwnerPoints = 1;
        subMemberPoints = 1;
    }

    /// @dev Change points to add or subtract in memberReputation when proposal/option/vote gets denied or accepted.
    function changeMemberReputationPoints(uint _addProposalOwnerPoints,uint  _addOptionOwnerPoints, uint _addMemberPoints,uint _subProposalOwnerPoints,uint  _subOptionOwnerPoints, uint _subMemberPoints) onlyOwner
    {
        addProposalOwnerPoints = _addProposalOwnerPoints;
        addOptionOwnerPoints= _addOptionOwnerPoints;
        addMemberPoints = _addMemberPoints;
        subProposalOwnerPoints = _subProposalOwnerPoints;
        subOptionOwnerPoints= _subOptionOwnerPoints;
        subMemberPoints = _subMemberPoints;
    }

    /// @dev Get points to proceed with updating the member reputation level.
    function getMemberReputationPoints() constant returns(uint addProposalOwnPoints,uint addOptionOwnPoints,uint addMemPoints,uint subProposalOwnPoints,uint subOptionOwnPoints,uint subMemPoints)
    {
        return (addProposalOwnerPoints,addOptionOwnerPoints,addMemberPoints,subProposalOwnerPoints,subOptionOwnerPoints,subMemberPoints);
    } 


    /// @dev add status.
    function addStatus() internal
    {
        status.push("Draft for discussion"); 
        status.push("Draft Ready for submission");
        status.push("Voting started"); 
        status.push("Proposal Decision - Accepted by Majority Voting"); 
        status.push("Proposal Decision - Rejected by Majority voting"); 
        status.push("Proposal Denied, Threshold not reached"); 
    }

    /// @dev Set Parameters value that will help in Distributing reward.
    function setGlobalParameters() internal
    {
        pendingProposalStart=0;
        quorumPercentage=25;
        GBTStakeValue=0;
        globalRiskFactor=5;
        membershipScalingFactor=1;
        scalingWeight=1;
    }

    /// @dev Change master's contract address
    function changeMasterAddress(address _masterContractAddress) 
    {
        // if(masterAddress == 0x000)
        //     masterAddress = _masterContractAddress;
        // else
        // {
        //     MS=Master(masterAddress);
        //     require(MS.isInternal(msg.sender) == 1);
        //         masterAddress = _masterContractAddress;
        // }
    }

    /// @dev change all contract's addresses.
    function changeAllContractsAddress(address _poolAddress) onlyInternal
    {
        PoolAddress = _poolAddress;
    }

    /// @dev Changes GBT contract Address. //NEW
    function changeGBTtokenAddress(address _GBTcontractAddress) onlyInternal
    {
        GBTSAddress = _GBTcontractAddress;
    }

    function changeGBTControllerAddress(address _GBTCAddress)
    {
        GBTCAddress = _GBTCAddress;
    }

    function changeProposalCategoryAddress(address _PCAddress)
    {
        PCAddress = _PCAddress;
    }
    
    /// @dev Set Vote Id against given proposal.
    function setVoteIdAgainstProposal(uint _proposalId,uint _voteId) onlyInternal
    {
        totalVotesAgainstProposal[_proposalId].push(_voteId);
    }

    /// @dev Set all the voting type names and thier addresses.
    function setVotingTypeDetails(bytes32 _votingTypeName,address _votingTypeAddress) onlyOwner
    {
        allVotingTypeDetails.push(votingTypeDetails(_votingTypeName,_votingTypeAddress)); 
        votingTypeNameByAddress[_votingTypeAddress] = _votingTypeName;
    }

    function editVotingType(uint _votingTypeId,address _votingTypeAddress)
    {
        allVotingTypeDetails[_votingTypeId].votingTypeAddress = _votingTypeAddress;
    }
    
    function setTotalOptions(uint _proposalId,uint8 _options)
    {
        allProposalCategory[_proposalId].verdictOptions = _options;
    }

    /// @dev Set the Deatils of added verdict i.e. Verdict Stake, Verdict value and Address of the member whoever added the verdict.
    function setOptionAddressAndStake(uint _proposalId,address _memberAddress,uint _stakeValue,uint _optionValue,string _optionHash) onlyInternal
    {
        allProposalCategory[_proposalId].optionAddedByAddress.push(_memberAddress);
        allProposalCategory[_proposalId].valueOfOption.push(_optionValue);
        allProposalCategory[_proposalId].stakeOnOption.push(_stakeValue);
        allProposalCategory[_proposalId].optionDescHash.push(_optionHash);
        allProposalCategory[_proposalId].optionDateAdd.push(now);
        allProposalOption[_memberAddress].push(getTotalVerdictOptions(_proposalId)+1); // saving the option index in each index of array
        totalOptionStake[_memberAddress] = SafeMath.add(totalOptionStake[_memberAddress],_stakeValue);
        allOptionDataAgainstMember[_memberAddress][_proposalId] = getTotalVerdictOptions(_proposalId)+1;
    }

    function setProposalCategory(uint _proposalId,uint8 _categoryId)
    {
        allProposal[_proposalId].category = _categoryId;
    }

    function setProposalStake(uint _proposalId,uint _memberStake)
    {
        allProposal[_proposalId].proposalStake = _memberStake;
    }

    function setProposalValue(uint _proposalId,uint _proposalValue)
    {
        allProposal[_proposalId].proposalValue = _proposalValue;
    }

    /// @dev Updates  status of an existing proposal.
    function updateProposalStatus(uint _id ,uint8 _status) onlyInternal
    {
        allProposal[_id].propStatus = _status;
        allProposal[_id].date_upd = now;
    }

    /// @dev Stores the status information of a given proposal.
    function pushInProposalStatus(uint _proposalId , uint8 _status) onlyInternal
    {
        proposalStatus[_proposalId].push(Status(_status,now));
    }

    /// @dev As bydefault first option is alwayd deny option. One time configurable.
    function addInitialOptionDetails(uint _proposalId) 
    {
        if(initialOptionsAdded[_proposalId] == 0)
        {
            allProposalCategory[_proposalId].optionAddedByAddress.push(0x00);
            allProposalCategory[_proposalId].valueOfOption.push(0);
            allProposalCategory[_proposalId].stakeOnOption.push(0);

            allProposalCategory[_proposalId].paramInt.push(0);
            allProposalCategory[_proposalId].paramBytes32.push("");
            allProposalCategory[_proposalId].paramAddress.push(0x00);
            allProposalCategory[_proposalId].optionDescHash.push("");
            allProposalCategory[_proposalId].rewardOption[0] = 0;
            allProposalCategory[_proposalId].verdictOptions = allProposalCategory[_proposalId].verdictOptions +1;
            initialOptionsAdded[_proposalId] =1;
        }
    }

    function setProposalIncentive(uint _proposalId,uint _reward)
    {
        allProposalPriority[_proposalId].commonIncentive = _reward;  
    }

    function setCategorizedBy(uint _proposalId,address _memberAddress)
    {
        allProposalCategory[_proposalId].categorizedBy = _memberAddress;
    }

    function setProposalLevel(uint _proposalId,uint8 _proposalComplexityLevel)
    {
         allProposalPriority[_proposalId].complexityLevel = _proposalComplexityLevel;
    }

    /// @dev Change pending proposal start variable
    function changePendingProposalStart() onlyInternal
    {
        uint pendingPS = pendingProposalStart;
        uint proposalLength = allProposal.length;
        for(uint j=pendingPS; j<proposalLength; j++)
        {
            if(allProposal[j].propStatus > 3)
                pendingPS = SafeMath.add(pendingPS,1);
            else
                break;
        }
        if(j!=pendingPS)
        {
            pendingProposalStart = j;
        }
    }

    /// @dev Changes the status of a given proposal.
    function changeProposalStatus(uint _id,uint8 _status) onlyInternal
    {
        require(allProposal[_id].category != 0);
        pushInProposalStatus(_id,_status);
        updateProposalStatus(_id,_status);
    }

    /// @dev Change Variables that helps in Calculation of reward distribution. Risk Factor, GBT Stak Value, Scaling Factor,Scaling weight.
    function changeGlobalRiskFactor(uint _riskFactor) onlyOwner
    {
        globalRiskFactor = _riskFactor;
    }

    function changeGBTStakeValue(uint _GBTStakeValue) onlyOwner
    {
        GBTStakeValue = _GBTStakeValue;
    }

    function changeMembershipScalingFator(uint _membershipScalingFactor) onlyOwner
    {
        membershipScalingFactor = _membershipScalingFactor;
    }

    function changeScalingWeight(uint _scalingWeight) onlyOwner
    {
        scalingWeight = _scalingWeight;
    }

    /// @dev Change quoram percentage. Value required to proposal pass.
    function changeQuorumPercentage(uint _quorumPercentage) onlyOwner
    {
        quorumPercentage = _quorumPercentage;
    }

    /// @dev Updating proposal's Major details (Called from close proposal Vote).
    function updateProposalDetails(uint _proposalId,uint8 _currVotingStatus, uint8 _intermediateVerdict,uint8 _finalVerdict) onlyInternal 
    {
        allProposal[_proposalId].currVotingStatus = _currVotingStatus;
        allProposal[_proposalId].currentVerdict = _intermediateVerdict;
        allProposal[_proposalId].finalVerdict = _finalVerdict;
    }

    function setMemberReputation(address _memberAddress,uint _repPoints)
    {
        allMemberReputationByAddress[_memberAddress] = _repPoints;
    }

    /// @dev Stores the information of a given version number of a given proposal. Maintains the record of all the versions of a proposal.
    function storeProposalVersion(uint _proposalId) onlyInternal 
    {
        proposalVersions[_proposalId].push(proposalVersionData(allProposal[_proposalId].versionNum,allProposal[_proposalId].proposalDescHash,allProposal[_proposalId].date_add));            
    }

    /// @dev Edits the details of an existing proposal and creates new version.
    function updateProposal(uint _id,string _proposalDescHash) onlyInternal
    {
        allProposal[_id].proposalDescHash = _proposalDescHash;
        allProposal[_id].date_upd = now;
        allProposal[_id].versionNum = allProposal[_id].versionNum+1;
    }
     
    function setProposalCategoryParams1(uint _proposalId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress,uint8 _verdictOptions) onlyInternal
    {
      uint i;
      setTotalOptions(_proposalId,_verdictOptions);
      for(i=0;i<_paramInt.length;i++)
      {
          allProposalCategory[_proposalId].paramInt.push(_paramInt[i]);
      }

      for(i=0;i<_paramBytes32.length;i++)
      {
          allProposalCategory[_proposalId].paramBytes32.push(_paramBytes32[i]);
      }

      for(i=0;i<_paramAddress.length;i++)
      {
          allProposalCategory[_proposalId].paramAddress.push(_paramAddress[i]);
      }   
    }

    function getVotingTypeLength() public constant returns(uint) 
    {
        return allVotingTypeDetails.length;
    }

    function getVotingTypeDetailsById(uint _votingTypeId) public constant returns(uint votingTypeId,bytes32 VTName,address VTAddress)
    {
        votingTypeId = _votingTypeId;
        VTName = allVotingTypeDetails[_votingTypeId].votingTypeName;
        VTAddress = allVotingTypeDetails[_votingTypeId].votingTypeAddress;
    }

    function getVotingTypeAddress(uint _votingTypeId)constant returns (address votingAddress)
    {
        return (allVotingTypeDetails[_votingTypeId].votingTypeAddress);
    }

    /// @dev Fetch user balance when giving member address.
    function getBalanceOfMember(address _memberAddress) public constant returns (uint totalBalance)
    {
        GBTS=GBTStandardToken(GBTSAddress);
        totalBalance = GBTS.balanceOf(_memberAddress);
    }

    /// @dev Fetch details of proposal by giving proposal Id
    function getProposalDetailsById1(uint _proposalId) public constant returns (uint id,address owner,string proposalDescHash,uint date_add,uint date_upd,uint versionNum,uint propStatus)
    {
        return (_proposalId,allProposal[_proposalId].owner,allProposal[_proposalId].proposalDescHash,allProposal[_proposalId].date_add,allProposal[_proposalId].date_upd,allProposal[_proposalId].versionNum,allProposal[_proposalId].propStatus);
    }

    /// @dev Get the category, of given proposal. 
    function getProposalDetailsById2(uint _proposalId) public constant returns(uint id,uint8 category,uint8 currentVotingId,uint8 intermediateVerdict,uint8 finalVerdict,address votingTypeAddress) 
    {
        return (_proposalId,allProposal[_proposalId].category,allProposal[_proposalId].currVotingStatus,allProposal[_proposalId].currentVerdict,allProposal[_proposalId].finalVerdict,allProposal[_proposalId].votingTypeAddress); 
    }

    /// @dev Get member address who created the proposal.
    function getProposalOwner(uint _proposalId) public constant returns(address)
    {
        return allProposal[_proposalId].owner;
    }

    /// @dev Gets version details of a given proposal id.
    function getProposalDetailsByIdAndVersion(uint _proposalId,uint _versionNum) public constant returns(uint id,uint versionNum,string proposalDescHash,uint date_add)
    {
        return (_proposalId,proposalVersions[_proposalId][_versionNum].versionNum,proposalVersions[_proposalId][_versionNum].proposalDescHash,proposalVersions[_proposalId][_versionNum].date_add);
    }
   
    /// @dev Get proposal Reward and complexity level Against proposal
    function getProposalIncentiveAndComplexity(uint _proposalId) public constant returns (uint incentive,uint complexity)
    {
        incentive = allProposalPriority[_proposalId].commonIncentive;
        complexity = allProposalPriority[_proposalId].complexityLevel;
    }

    function getProposalIncentive(uint _proposalId)constant returns(uint reward)
    {
        reward = allProposalPriority[_proposalId].commonIncentive;
    }

    function getProposalComplexity(uint _proposalId)constant returns(uint level)
    {
        level =  allProposalPriority[_proposalId].complexityLevel;
    }

    /// @dev Get Total number of verdict options against proposal.
    function getTotalVerdictOptions(uint _proposalId) constant returns(uint8 verdictOptions)
    {
        verdictOptions = allProposalCategory[_proposalId].verdictOptions;
    }

    /// @dev Get Current Status of proposal when given proposal Id
    function getProposalStatus(uint _proposalId) constant returns (uint proposalStatus)
    {
        proposalStatus = allProposal[_proposalId].propStatus;
    }

    function getProposalCategory(uint _proposalId) constant returns(uint8 categoryId)
    {
        return allProposal[_proposalId].category;
    }

    // /// @dev fetch the parameter details for the final verdict (Final Verdict - Option having maximum votes)
    // function getProposalFinalVerdictDetails(uint _proposalId) constant public returns(uint id,uint paramint, bytes32 parambytes32,address paramaddress)
    // {
    //     id = _proposalId;
    //     uint category = allProposal[_proposalId].category;
    //     uint verdictChosen = allProposal[_proposalId].finalVerdict;

    //     if(allProposalCategory[_proposalId].paramInt.length != 0)
    //     {
    //          paramint = allProposalCategory[_proposalId].paramInt[verdictChosen];
    //     }

    //     if(allProposalCategory[_proposalId].paramBytes32.length != 0)
    //     {
    //         parambytes32 = allProposalCategory[_proposalId].paramBytes32[verdictChosen];
    //     }

    //     if(allProposalCategory[_proposalId].paramAddress.length != 0)
    //     {
    //         paramaddress = allProposalCategory[_proposalId].paramAddress[verdictChosen];
    //     }  
    // }
    
    /// @dev Get the number of tokens already distributed among members.
    function getTotalTokenInSupply() constant returns(uint _totalSupplyToken)
    {
        GBTS=GBTStandardToken(GBTSAddress);
        _totalSupplyToken = GBTS.totalSupply();
    }

    /// @dev Member Reputation is set according to if Member's Decision is Final decision.
    function getMemberReputation(address _memberAddress) constant returns(uint memberPoints)
    {
        memberPoints = allMemberReputationByAddress[_memberAddress];
    }

    /// @dev Get proposal Value and Member Stake on that proposal
    function getProposalValueAndStake(uint _proposalId) constant returns(uint id,uint proposalValue,uint proposalStake)
    {
        id = _proposalId;
        proposalValue = allProposal[_proposalId].proposalValue;
        proposalStake = allProposal[_proposalId].proposalStake;
    }

    /// @dev Get proposal Value when given proposal Id.
    function getProposalValue(uint _proposalId) constant  returns(uint proposalValue) 
    {
        proposalValue = allProposal[_proposalId].proposalValue;
    }

    /// @dev Get proposal Stake by member when given proposal Id.
    function getProposalStake(uint _proposalId) constant returns(uint proposalStake)
    {
        proposalStake = allProposal[_proposalId].proposalStake;
    }

    /// @dev Fetch Total length of Member address array That added number of verdicts against proposal.
    function getOptionAddedAddressLength(uint _proposalId) constant returns(uint length)
    {
        return  allProposalCategory[_proposalId].optionAddedByAddress.length;
    }

    function getOptionDescByProposalId(uint _proposalId,uint _optionIndex) constant returns(string)
    {
        return allProposalCategory[_proposalId].optionDescHash[_optionIndex];
    }

    /// @dev Get the Stake of verdict when given Proposal Id and Verdict index.
    function getOptionStakeByProposalId(uint _proposalId,uint _optionIndex) constant returns(uint optionStake)
    {
        optionStake = allProposalCategory[_proposalId].stakeOnOption[_optionIndex];
    }

    /// @dev Get the value of verdict when given Proposal Id and Verdict Index.
    function getOptionValueByProposalId(uint _proposalId,uint _optionIndex) constant returns(uint optionValue)
    {
        optionValue = allProposalCategory[_proposalId].valueOfOption[_optionIndex];
    }

    /// @dev Get the Address of member whosoever added the verdict when given Proposal Id and Verdict Index.
    function getOptionAddressByProposalId(uint _proposalId,uint _optionIndex) constant returns(address memberAddress)
    {
        memberAddress = allProposalCategory[_proposalId].optionAddedByAddress[_optionIndex];
    }

    /// @dev Get the Value, stake and Address of the member whosoever added that verdict option.
    function getOptionAddedDetails(uint _proposalId,uint _optionIndex) constant returns(uint id, uint optionid,uint optionStake,uint optionValue,address memberAddress,string optionHash)
    {
        id = _proposalId;
        optionid = _optionIndex;
        optionStake = allProposalCategory[_proposalId].stakeOnOption[_optionIndex];
        optionValue = allProposalCategory[_proposalId].valueOfOption[_optionIndex];
        memberAddress = allProposalCategory[_proposalId].optionAddedByAddress[_optionIndex];
        return (id,optionid,optionStake,optionValue,memberAddress,allProposalCategory[_proposalId].optionDescHash[_optionIndex]);
    }

    /// @dev Get Total votes against a proposal when given proposal id.
    function getTotalVoteLengthAgainstProposal(uint _proposalId) constant returns(uint totalVotesLength)
    {
        totalVotesLength =  totalVotesAgainstProposal[_proposalId].length;
    }

    /// @dev Get Array of All vote id's against a given proposal when given _proposalId.
    function getTotalVoteArrayAgainstProposal(uint _proposalId) constant returns(uint id,uint[] totalVotes)
    {
        return (_proposalId,totalVotesAgainstProposal[_proposalId]);
    }

    /// @dev Get Vote id one by one against a proposal when given proposal Id and Index to traverse vote array.
    function getVoteIdByProposalId(uint _proposalId,uint _voteArrayIndex) constant returns (uint voteId)
    {
        voteId = totalVotesAgainstProposal[_proposalId][_voteArrayIndex];
    }

    /// @dev Get the category parameters given against a proposal after categorizing the proposal.
    function getProposalOptionAll(uint _proposalId) constant returns(uint id,uint[] paramsInt,bytes32[] paramsBytes,address[] paramsAddress,uint8 verdictOptions)
    {
        id = _proposalId;
        return (id,allProposalCategory[_proposalId].paramInt,allProposalCategory[_proposalId].paramBytes32,allProposalCategory[_proposalId].paramAddress,allProposalCategory[_proposalId].verdictOptions);
    }

    /// @dev Fetch the parameter details for final option won (Final Verdict) when giving Proposal ID and Parameter Name Against proposal.
    function getProposalOptionAllByParameter(uint _proposalId,bytes32 _parameterNameUint,bytes32 _parameterNameBytes,bytes32 _parameterNameAddress) constant returns (uint id,uint[] intParameter,bytes32[] bytesParameter,address[] addressParameter)
    {   
        id = _proposalId;
        intParameter = getParameterDetails1(_proposalId,_parameterNameUint);
        bytesParameter = getParameterDetails2(_proposalId,_parameterNameBytes);
        addressParameter = getParameterDetails3(_proposalId,_parameterNameAddress);
    }

    function getProposalOptionAllById(uint _proposalId,uint _optionIndex)constant returns(uint proposalId,uint[] intParam,bytes32[] bytesParam,address[] addressParam)
    {
        
        PC=ProposalCategory(PCAddress);
        proposalId = _proposalId;
        // uint finalOption = allProposal[_proposalId].finalVerdict;

        uint8 paramInt; uint8 paramBytes32; uint8 paramAddress;bytes32 parameterName; uint j;
        (,,,,paramInt,paramBytes32,paramAddress,,) = PC.getCategoryDetails(allProposal[_proposalId].category);
        
        intParam=new uint[](paramInt);
        bytesParam = new bytes32[](paramBytes32);
        addressParam = new address[](paramAddress);

        for(j=0; j<paramInt; j++)
        {
            parameterName = PC.getCategoryParamNameUint(allProposal[_proposalId].category,j);
            intParam[j] = getParameterDetailsById1(_proposalId,parameterName,_optionIndex);
        }

        for(j=0; j<paramBytes32; j++)
        {
            parameterName = PC.getCategoryParamNameBytes(allProposal[_proposalId].category,j); 
            bytesParam[j] = getParameterDetailsById2(_proposalId,parameterName,_optionIndex);
        }

        for(j=0; j<paramAddress; j++)
        {
            parameterName = PC.getCategoryParamNameAddress(allProposal[_proposalId].category,j);
            addressParam[j] = getParameterDetailsById3(_proposalId,parameterName,_optionIndex);              
        }  
    }

    function getParameterDetailsById1(uint _proposalId,bytes32 _parameterName,uint _index)constant returns(uint result)
    {   
        uint optionIndex = _index-1;
        return (allProposalCategoryParams[_proposalId].optionNameIntValue[_parameterName][optionIndex]);
    }

    function getParameterDetailsById2(uint _proposalId,bytes32 _parameterName,uint _index)constant returns(bytes32 result)
    {   
        uint optionIndex = _index-1;
        return (allProposalCategoryParams[_proposalId].optionNameBytesValue[_parameterName][optionIndex]);
    }

    function getParameterDetailsById3(uint _proposalId,bytes32 _parameterName,uint _index)constant returns(address result)
    {   
        uint optionIndex = _index-1;
        return (allProposalCategoryParams[_proposalId].optionNameAddressValue[_parameterName][optionIndex]);
    }

    /// @dev Fetch the Integer parameter details by parameter name against the final option.
    function getParameterDetails1(uint _proposalId,bytes32 _parameterName) internal returns (uint[] intParameter)
    {   
        return (allProposalCategoryParams[_proposalId].optionNameIntValue[_parameterName]);
    }

    /// @dev Fetch the Bytes parameter details by parameter name against the final option.
    function getParameterDetails2(uint _proposalId,bytes32 _parameterName) internal returns (bytes32[] bytesParameter)
    {   
        return (allProposalCategoryParams[_proposalId].optionNameBytesValue[_parameterName]);
    }

    /// @dev Fetch the Address parameter details by parameter name against the final option.
    function getParameterDetails3(uint _proposalId,bytes32 _parameterName) internal returns (address[] addressParameter)
    {   
        return (allProposalCategoryParams[_proposalId].optionNameAddressValue[_parameterName]);
    }

    function setParameterDetails1(uint _proposalId,bytes32 parameterName,uint _paramInt)
    {
        allProposalCategoryParams[_proposalId].optionNameIntValue[parameterName].push(_paramInt);
    }

    function setParameterDetails2(uint _proposalId,bytes32 parameterName,bytes32 _paramBytes32)
    {
        allProposalCategoryParams[_proposalId].optionNameBytesValue[parameterName].push(_paramBytes32);
    }

    function setParameterDetails3(uint _proposalId,bytes32 parameterName,address _paramAddress)
    {
        allProposalCategoryParams[_proposalId].optionNameAddressValue[parameterName].push(_paramAddress);  
    }

    function getProposalLength()constant returns(uint)
    {  
        return (allProposal.length);
    } 

    function getProposalDetailsById3(uint _proposalId) constant returns(uint proposalIndex,string proposalDescHash,uint dateAdded,string propStatus,uint propCategory,uint totalVotes,uint8 totalOption)
    {
        return (_proposalId,allProposal[_proposalId].proposalDescHash,allProposal[_proposalId].date_add,status[allProposal[_proposalId].propStatus],allProposal[_proposalId].category,totalVotesAgainstProposal[_proposalId].length,allProposalCategory[_proposalId].verdictOptions);
    }  

    function getMemberDetails(address _memberAddress) constant returns(uint memberReputation, uint totalProposal,uint proposalStake,uint totalOption,uint optionStake,uint totalVotes)
    {
        memberReputation = allMemberReputationByAddress[_memberAddress];
        totalProposal = allProposalMember[_memberAddress].length;
        proposalStake = getProposalStakeByMember(_memberAddress);
        totalOption = allProposalOption[_memberAddress].length;
        optionStake = totalOptionStake[_memberAddress];
        totalVotes = totalVotesAgainstMember[_memberAddress];
    }

    function getStakeByProposal(uint _proposalId)internal constant returns(uint stake)
    {
        return (allProposal[_proposalId].proposalStake);
    }

    function getProposalStakeByMember(address _memberAddress) returns(uint stakeValueProposal)
    {
        for(uint i=0; i<allProposalMember[_memberAddress].length; i++)
        {
            stakeValueProposal = stakeValueProposal + getStakeByProposal(allProposalMember[_memberAddress][i]);
        }
    }

    function getTotalOptionAgainstMember(address _memberAddress)constant returns(uint[] allOptions)
    {
        return (allProposalOption[_memberAddress]);
    }

    function addInTotalVotes(address _memberAddress)
    {
        totalVotesAgainstMember[_memberAddress] = totalVotesAgainstMember[_memberAddress] + 1;
    }

    function getTotalVotesAgainstMember(address _memberAddress) constant returns(uint total)
    {
        total = totalVotesAgainstMember[_memberAddress];
    }

    function addTotalProposal(uint _proposalId,address _memberAddress)
    {
        allProposalMember[_memberAddress].push(_proposalId);
    }

    function getTotalProposal(address _memberAddress) constant returns(uint)
    {
        return allProposalMember[_memberAddress].length;
    }

    function addNewProposal(address _memberAddress,string _proposalDescHash,uint8 _categoryId,address _votingTypeAddress)
    {
        allProposal.push(proposal(_memberAddress,_proposalDescHash,now,now,0,0,0,_categoryId,0,0,_votingTypeAddress,0,0,0,0,0));               
    }
    
    function getProposalsbyAddress(address _memberAddress) constant returns(uint[] proposalid)
    {
       return  allProposalMember[_memberAddress];
    }

    function setProposalReward(uint _proposalId,uint _totalTokenToDistribute,uint _blockNumber,uint _reward)
    {
        allProposal[_proposalId].totalreward = _totalTokenToDistribute;
        allProposal[_proposalId].blocknumber = _blockNumber;
        allProposal[_proposalId].proposalReward = _reward;
    }

    function setOptionReward(uint _proposalId,uint _reward,uint _optionIndex)
    {
        allProposalCategory[_proposalId].rewardOption[_optionIndex] = _reward;
    }

    function getProposalReward(uint _proposalId)constant returns(uint totalTokenToDistribute,uint numberBlock,uint propReward)
    {
        return(allProposal[_proposalId].totalreward,allProposal[_proposalId].blocknumber,allProposal[_proposalId].proposalReward);
    }

    function getOptionReward(uint _proposalId,uint _optionIndex)constant returns(uint)
    {
        return (allProposalCategory[_proposalId].rewardOption[_optionIndex]);
    }

    function getProposalFinalOption(uint _proposalId) constant returns(uint finalOptionIndex)
    {
        finalOptionIndex = allProposal[_proposalId].finalVerdict;
    }

    function getProposalRewardByMember(address _memberAddress) constant returns(uint[] propStake,uint[] propReward)
    {
        propStake = new uint[](allProposalMember[_memberAddress].length);
        propReward = new uint[](allProposalMember[_memberAddress].length);

        for(uint i=0; i<allProposalMember[_memberAddress].length; i++)
        {
            propStake[i] = allProposal[allProposalMember[_memberAddress][i]].proposalStake;
            propReward[i] = allProposal[allProposalMember[_memberAddress][i]].proposalReward;
        }
    }

    function getProposalRewardById(uint _proposalId) constant returns(uint propStake,uint propReward)
    {
        return(allProposal[_proposalId].proposalStake,allProposal[_proposalId].proposalReward);
    }

    function getOptionData(address _memberAddress)constant returns(uint[] optionIndex,uint[] dateAdded,uint[] proposalId)
    {
        optionIndex = new uint[](allProposalOption[_memberAddress].length);
        dateAdded = new uint[](allProposalOption[_memberAddress].length);
        proposalId = new uint[](allProposalOption[_memberAddress].length);

        for(uint i=0; i<allProposal.length; i++)
        {
            require(allOptionDataAgainstMember[_memberAddress][i] != 0);
            {
                uint optionId = allOptionDataAgainstMember[_memberAddress][i];
                
                optionIndex[i] = allOptionDataAgainstMember[_memberAddress][i];
                dateAdded[i] = allProposalCategory[i].optionDateAdd[optionId];
                proposalId[i] = i;
            }
        }   
    }

}  
 

