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
import "./zeppelin-solidity/contracts/token/BasicToken.sol";
import "./zeppelin-solidity/contracts/token/MintableToken.sol";
import "./zeppelin-solidity/contracts/math/Math.sol";
import "./MemberRoles.sol";
import "./ProposalCategory.sol";
// import "./BasicToken.sol";
// import "./MintableToken.sol";
// import "./Math.sol";

contract GovernanceData is Ownable {
    using SafeMath for uint;
    struct proposal{
        address owner;
        string shortDesc;
        string longDesc;
        uint date_add;
        uint date_upd;
        uint versionNum;
        uint currVotingStatus;
        uint propStatus;  
        uint category;
        uint finalVerdict;
        uint currentVerdict;
        address votingTypeAddress;
        uint proposalValue;
        uint proposalStake;
    }

    struct proposalCategory{
        address categorizedBy;
        uint[] paramInt;
        bytes32[] paramBytes32;
        address[] paramAddress;
        uint verdictOptions;
        address[] verdictAddedByAddress;
        uint[] valueOfVerdict;
        uint[] stakeOnVerdict;
    }

    struct proposalCategoryParams
    {
        mapping(uint=>mapping(bytes32=>uint)) optionNameIntValue;
        mapping(uint=>mapping(bytes32=>bytes32)) optionNameBytesValue;
        mapping(uint=>mapping(bytes32=>address)) optionNameAddressValue;
    }

    mapping(uint=>proposalCategoryParams) allProposalCategoryParams;
    
    struct proposalVersionData{
        uint versionNum;
        string shortDesc;
        string longDesc;
        uint date_add;
    }

    struct Status{
        uint statusId;
        uint date;
    }
    
    struct proposalPriority 
    {
        uint8 complexityLevel;
        uint[] levelReward;
    }

    function GovernanceData() 
    {
        setGlobalParameters();
        addStatus();
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

    uint public proposalVoteClosingTime;
    uint public quorumPercentage;
    uint public pendingProposalStart;
    uint public GNTStakeValue; uint public globalRiskFactor; uint public membershipScalingFactor;
    uint public scalingWeight;
    uint public categoryFunctionValue;

    string[] public status;
    proposal[] allProposal;
    votingTypeDetails[] allVotingTypeDetails;

    address GNTAddress;
    address BTAddress;
    BasicToken BT;
    MintableToken MT;
    address MRAddress;
    address PCAddress;
    MemberRoles MR;
    ProposalCategory Pcategory;

    /// @dev Check if the member who wants to change in contracts, is owner.
    function isOwner(address _memberAddress) returns(uint checkOwner)
    {
        require(owner == _memberAddress);
            checkOwner=1;
    }

    /// @dev Change current owner.
    function changeOwner(address _memberAddress) onlyOwner public
    {
        transferOwnership(_memberAddress);
    }

    /// @dev add status.
    function addStatus() 
    {
        status.push("Draft for discussion"); 
        status.push("Draft Ready for submission");
        status.push("Voting started"); 
        status.push("Proposal Decision - Accepted by Majority Voting"); 
        status.push("Proposal Decision - Rejected by Majority voting"); 
        status.push("Proposal Denied, Threshold not reached"); 
    }

    /// @dev Set Parameters value that will help in Distributing reward.
    function setGlobalParameters()
    {
        proposalVoteClosingTime = 20;
        pendingProposalStart=0;
        quorumPercentage=25;
        GNTStakeValue=10;
        globalRiskFactor=5;
        membershipScalingFactor=1;
        scalingWeight=1;
    }

    /// @dev change all contract's addresses.
    function changeAllContractsAddress(address _GNTcontractAddress,address _BTcontractAddress, address _MRcontractAddress, address _PCcontractAddress) public
    {
        GNTAddress = _GNTcontractAddress;
        BTAddress = _BTcontractAddress;
        MRAddress = _MRcontractAddress;
        PCAddress = _PCcontractAddress;
    }

    /// @dev Checks if voting time of a given proposal should be closed or not. 
    function checkProposalVoteClosing(uint _proposalId) constant returns(uint8 closeValue)
    {
        require(SafeMath.add(allProposal[_proposalId].date_upd,proposalVoteClosingTime) <= now);
        closeValue=1;
    }

    /// @dev Changes the status of a given proposal to open it for voting. // wil get called when we submit the proposal on submit button
    function openProposalForVoting(uint _proposalId,uint _TokenAmount) onlyOwner public
    {
        require(allProposal[_proposalId].category != 0);
        payableGNTTokens(_TokenAmount);
        setProposalValue(_proposalId,_TokenAmount);
        pushInProposalStatus(_proposalId,2);
        updateProposalStatus(_proposalId,2);
    }

    /// @dev Calculate the proposal value to distribute it later - Distribute amount depends upon the final decision against proposal.
    function setProposalValue(uint _proposalId,uint _memberStake) public
    {
        allProposal[_proposalId].proposalStake = _memberStake;
        uint memberLevel = Math.max256(getMemberReputation(msg.sender),1);
        uint tokensHeld = SafeMath.div((SafeMath.mul(SafeMath.mul(getBalanceOfMember(msg.sender),100),100)),getTotalTokenInSupply());
        uint maxValue= Math.max256(tokensHeld,membershipScalingFactor);

        uint finalProposalValue = SafeMath.mul(SafeMath.mul(globalRiskFactor,memberLevel),SafeMath.mul(_memberStake,maxValue));
        allProposal[_proposalId].proposalValue = finalProposalValue;
    }

    /// @dev Set Vote Id against given proposal.
    function setVoteidAgainstProposal(uint _proposalId,uint _voteId) public
    {
        totalVotesAgainstProposal[_proposalId].push(_voteId);
    }

    /// @dev Set all the voting type names and thier addresses.
    function setVotingTypeDetails(bytes32 _votingTypeName,address _votingTypeAddress) onlyOwner
    {
        allVotingTypeDetails.push(votingTypeDetails(_votingTypeName,_votingTypeAddress));   
    }

    function setProposalCategoryParams(uint _category,uint _proposalId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress,uint _verdictOptions) 
    {
        uint optionIndex;bytes32 parameterName;
        setProposalCategoryParams1(_proposalId,_paramInt,_paramBytes32,_paramAddress,_verdictOptions);
        Pcategory=ProposalCategory(PCAddress);
    
        for(uint j=0; j<allProposalCategory[_proposalId].paramInt.length; j++)
        {
            parameterName = Pcategory.getCategoryParamNameUint(_category,j);
            allProposalCategoryParams[_proposalId].optionNameIntValue[j][parameterName] = _paramInt[j];
        }

        for(j=0; j<allProposalCategory[_proposalId].paramBytes32.length; j++)
        {
            parameterName = Pcategory.getCategoryParamNameBytes(_category,j); 
            allProposalCategoryParams[_proposalId].optionNameBytesValue[j][parameterName] = _paramBytes32[j];
        }

        for(j=0; j<allProposalCategory[_proposalId].paramAddress.length; j++)
        {
            parameterName = Pcategory.getCategoryParamNameAddress(_category,j); 
            allProposalCategoryParams[_proposalId].optionNameAddressValue[j][parameterName] = _paramAddress[j];  
        }
    }

    /// @dev When member manually verdict options before proposal voting. (To be called from All type of votings - Add verdict Options)
    function setProposalCategoryParams1(uint _proposalId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress,uint _verdictOptions) 
    {
        uint i;
        allProposalCategory[_proposalId].verdictOptions = _verdictOptions;
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

    /// @dev Set the Deatils of added verdict i.e. Verdict Stake, Verdict value and Address of the member whoever added the verdict.
    function setProposalVerdictAddressAndStakeValue(uint _proposalId,address _memberAddress,uint _stakeValue,uint _verdictValue)
    {
        allProposalCategory[_proposalId].verdictAddedByAddress.push(_memberAddress);
        allProposalCategory[_proposalId].valueOfVerdict.push(_verdictValue);
        allProposalCategory[_proposalId].stakeOnVerdict.push(_stakeValue);
    }

    /// @dev Some amount to be paid while using GovBlocks contract service - Approve the contract to spend money on behalf of msg.sender
    function payableGNTTokens(uint _TokenAmount) public
    {
        MT=MintableToken(GNTAddress);
        require(_TokenAmount >= GNTStakeValue);
        MT.transferFrom(msg.sender,GNTAddress,_TokenAmount);
    }

    /// @dev Updates  status of an existing proposal.
    function updateProposalStatus(uint _id ,uint _status) internal
    {
        allProposal[_id].propStatus = _status;
        allProposal[_id].date_upd = now;
    }

    /// @dev Stores the status information of a given proposal.
    function pushInProposalStatus(uint _proposalId , uint _status) internal
    {
        proposalStatus[_proposalId].push(Status(_status,now));
    }

    /// @dev Creates a new proposal.
    function addNewProposal(string _shortDesc,string _longDesc,uint _votingTypeId) public
    {
        require(getBalanceOfMember(msg.sender) != 0);
        allMemberReputationByAddress[msg.sender]=1;
        address votingTypeAddress = allVotingTypeDetails[_votingTypeId].votingTypeAddress;
        allProposal.push(proposal(msg.sender,_shortDesc,_longDesc,now,now,0,0,0,0,0,0,votingTypeAddress,0,0));   
    }

    /// @dev function to get called after Proposal Pass
    function categoryFunction(uint256 _proposalId) public
    {
        // uint _categoryId;
        // (_categoryId,,,,)= getProposalDetailsById2(_proposalId);
        // uint paramint;
        // bytes32 parambytes32;
        // address paramaddress;
        // (paramint,parambytes32,paramaddress) = getProposalFinalVerdictDetails(_proposalId);
        categoryFunctionValue = 5;
        // add your functionality here;
        // gd1.updateCategoryMVR(_categoryId);
    }

    /// @dev As bydefault first verdict is alwayd deny option. One time configurable.
    function addInitialVerdictDetails(uint _proposalId)
    {
        if(allProposalCategory[_proposalId].verdictAddedByAddress.length == 0)
        {
            allProposalCategory[_proposalId].verdictAddedByAddress.push(0x00);
            allProposalCategory[_proposalId].valueOfVerdict.push(0);
            allProposalCategory[_proposalId].stakeOnVerdict.push(0);
        }      
    }

    /// @dev categorizing proposal to proceed further.
    function categorizeProposal(uint _proposalId , uint _categoryId,uint8 _proposalComplexityLevel,uint[] _levelReward) public
    {
        MR = MemberRoles(MRAddress); uint i;
        Pcategory=ProposalCategory(PCAddress);
        require(MR.getMemberRoleIdByAddress(msg.sender) == MR.getAuthorizedMemberId());
        require(allProposal[_proposalId].propStatus == 1 || allProposal[_proposalId].propStatus == 0);
        addComplexityLevelAndReward(_proposalId,_categoryId,_proposalComplexityLevel,_levelReward);
        addInitialVerdictDetails(_proposalId);
        allProposalCategory[_proposalId].categorizedBy = msg.sender;
        allProposal[_proposalId].category = _categoryId;
    }

    /// @dev Proposal's complexity level and reward is added 
    function addComplexityLevelAndReward(uint _proposalId,uint _category,uint8 _proposalComplexityLevel,uint[] _levelReward) internal
    {
        Pcategory=ProposalCategory(PCAddress);
        uint votingLength = Pcategory.getRoleSequencLength(_category);
        if(_levelReward.length != 0)
            require(votingLength == _levelReward.length);
            allProposalPriority[_proposalId].complexityLevel = _proposalComplexityLevel;
            for(uint i=0; i<_levelReward.length; i++)
            {
                allProposalPriority[_proposalId].levelReward.push(_levelReward[i]);
            }       
    }

    /// @dev Transfer reward after Final Proposal Decision.
    function transferBackGNTtoken(address _memberAddress, uint _value)
    {
        BT=BasicToken(BTAddress);
        BT.transfer(_memberAddress,_value);
    }

    /// @dev Change pending proposal start variable
    function changePendingProposalStart() public
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
    function changeProposalStatus(uint _id,uint _status) 
    {
        require(allProposal[_id].category != 0);
        pushInProposalStatus(_id,_status);
        updateProposalStatus(_id,_status);
    }

    /// @dev Change Variables that helps in Calculation of reward distribution. Risk Factor, GNT Stak Value, Scaling Factor,Scaling weight.
    function changeGlobalRiskFactor(uint _riskFactor) onlyOwner
    {
        globalRiskFactor = _riskFactor;
    }

    function changeGNTStakeValue(uint _GNTStakeValue) onlyOwner
    {
        GNTStakeValue = _GNTStakeValue;
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
    function updateProposalDetails(uint _proposalId,uint _currVotingStatus, uint _intermediateVerdict,uint _finalVerdict)
    {
        allProposal[_proposalId].currVotingStatus = _currVotingStatus;
        allProposal[_proposalId].currentVerdict = _intermediateVerdict;
        allProposal[_proposalId].finalVerdict = _finalVerdict;
    }

    /// @dev Edits a proposal and Only owner of a proposal can edit it.
    function editProposal(uint _proposalId , string _shortDesc, string _longDesc) onlyOwner public
    {
        storeProposalVersion(_proposalId);
        updateProposal(_proposalId,_shortDesc,_longDesc);
        changeProposalStatus(_proposalId,1);
        
        require(allProposal[_proposalId].category > 0);
            uint category;
            (category,,,,) = getProposalDetailsById2(_proposalId); 
            allProposal[_proposalId].category = 0;
    }

    /// @dev Edit details of a type of voting.
    function editVotingTypeDetails(uint[] _votingTypeId, address[] _votingTypeAddress) onlyOwner
    {
        require(_votingTypeId.length == _votingTypeAddress.length);
        for(uint i=0; i<_votingTypeAddress.length; i++)
        {
            allVotingTypeDetails[_votingTypeId[i]].votingTypeAddress = _votingTypeAddress[i];
        }
    }

    /// @dev Stores the information of a given version number of a given proposal. Maintains the record of all the versions of a proposal.
    function storeProposalVersion(uint _id) internal 
    {
        proposalVersions[_id].push(proposalVersionData(allProposal[_id].versionNum,allProposal[_id].shortDesc,allProposal[_id].longDesc,allProposal[_id].date_add));            
    }

    /// @dev Edits the details of an existing proposal and creates new version.
    function updateProposal(uint _id,string _shortDesc,string _longDesc) internal
    {
        allProposal[_id].shortDesc = _shortDesc;
        allProposal[_id].longDesc = _longDesc;
        allProposal[_id].date_upd = now;
        allProposal[_id].versionNum = SafeMath.add(allProposal[_id].versionNum,1);
    }

    /// @dev Get All Address for different types of voting.
    function getVotingTypeAllAddress() public returns(address[])
    {
        address[] VTaddresses;
        for(uint i=0; i<allVotingTypeDetails.length; i++)
        {
            VTaddresses[i] = allVotingTypeDetails[i].votingTypeAddress;
        }
        return VTaddresses;
    }

    /// @dev Get All names for different types of voting.
    function getVotingTypeAllName() public returns(bytes32[] votingName)
    {
        for(uint i=0; i<allVotingTypeDetails.length; i++)
        {
            votingName[i] = allVotingTypeDetails[i].votingTypeName;
        }
        return votingName;
    }
    
    /// @dev Get Address of a type of voting when given Id. 
    function getVotingTypeDetailsById(uint _votingTypeId) public returns(address votingTypeAddress)
    {
        return allVotingTypeDetails[_votingTypeId].votingTypeAddress;
    }

    /// @dev Fetch user balance when giving member address.
    function getBalanceOfMember(address _memberAddress) public constant returns (uint totalBalance)
    {
        BT=BasicToken(BTAddress);
        totalBalance = BT.balanceOf(_memberAddress);
    }

    /// @dev Fetch details of proposal by giving proposal Id
    function getProposalDetailsById1(uint _proposalId) public constant returns (address owner,string shortDesc,string longDesc,uint date_add,uint date_upd,uint versionNum,uint propStatus)
    {
        return (allProposal[_proposalId].owner,allProposal[_proposalId].shortDesc,allProposal[_proposalId].longDesc,allProposal[_proposalId].date_add,allProposal[_proposalId].date_upd,allProposal[_proposalId].versionNum,allProposal[_proposalId].propStatus);
    }

    /// @dev Get the category, of given proposal. 
    function getProposalDetailsById2(uint _proposalId) public constant returns(uint category,uint currentVotingId,uint intermediateVerdict,uint finalVerdict,address votingTypeAddress) 
    {
        category = allProposal[_proposalId].category;
        currentVotingId = allProposal[_proposalId].currVotingStatus;
        intermediateVerdict = allProposal[_proposalId].currentVerdict; 
        finalVerdict = allProposal[_proposalId].finalVerdict;
        votingTypeAddress = allProposal[_proposalId].votingTypeAddress;   
    }

    /// @dev Gets version details of a given proposal id.
    function getProposalDetailsByIdAndVersion(uint _proposalId,uint _versionNum) public constant returns( uint versionNum,string shortDesc,string longDesc,uint date_add)
    {
        return (proposalVersions[_proposalId][_versionNum].versionNum,proposalVersions[_proposalId][_versionNum].shortDesc,proposalVersions[_proposalId][_versionNum].longDesc,proposalVersions[_proposalId][_versionNum].date_add);
    }
   
    /// @dev Get proposal Reward and complexity level Against proposal
    function getProposalRewardAndComplexity(uint _proposalId,uint _rewardIndex) public constant returns (uint reward)
    {
       reward = allProposalPriority[_proposalId].levelReward[_rewardIndex];
    }

    /// @dev Get the category parameters given against a proposal after categorizing the proposal.
    function getProposalCategoryParams(uint _proposalId) constant returns(uint[] paramsInt,bytes32[] paramsBytes,address[] paramsAddress,uint verdictOptions)
    {
        paramsInt = allProposalCategory[_proposalId].paramInt;
        paramsBytes = allProposalCategory[_proposalId].paramBytes32;
        paramsAddress = allProposalCategory[_proposalId].paramAddress;
        verdictOptions = allProposalCategory[_proposalId].verdictOptions;
    }

    /// @dev Get Total number of verdict options against proposal.
    function getTotalVerdictOptions(uint _proposalId) constant returns(uint verdictOptions)
    {
        verdictOptions = allProposalCategory[_proposalId].verdictOptions;
    }

    /// @dev Get Current Status of proposal when given proposal Id
    function getProposalStatus(uint _proposalId) constant returns (uint proposalStatus)
    {
        proposalStatus = allProposal[_proposalId].propStatus;
    }

    /// @dev fetch the parameter details for the final verdict (Final Verdict - Option having maximum votes)
    function getProposalFinalVerdictDetails(uint _proposalId) public returns(uint paramint, bytes32 parambytes32,address paramaddress)
    {
        uint category = allProposal[_proposalId].category;
        uint verdictChosen = allProposal[_proposalId].finalVerdict;

        if(allProposalCategory[_proposalId].paramInt.length != 0)
        {
             paramint = allProposalCategory[_proposalId].paramInt[verdictChosen];
        }

        if(allProposalCategory[_proposalId].paramBytes32.length != 0)
        {
            parambytes32 = allProposalCategory[_proposalId].paramBytes32[verdictChosen];
        }

        if(allProposalCategory[_proposalId].paramAddress.length != 0)
        {
            paramaddress = allProposalCategory[_proposalId].paramAddress[verdictChosen];
        }  
    }

    /// @dev Get the number of tokens already distributed among members.
    function getTotalTokenInSupply() constant returns(uint _totalSupplyToken)
    {
        BT=BasicToken(BTAddress);
        _totalSupplyToken = BT.totalSupply();
    }

    /// @dev Member Reputation is set according to if Member's Decision is Final decision.
    function getMemberReputation(address _memberAddress) constant returns(uint reputationLevel)
    {
        reputationLevel = allMemberReputationByAddress[_memberAddress];
    }

    /// @dev Get proposal Value and Member Stake on that proposal
    function getProposalValueAndStake(uint _proposalId) constant returns(uint proposalValue,uint proposalStake)
    {
        proposalValue = allProposal[_proposalId].proposalValue;
        proposalStake = allProposal[_proposalId].proposalStake;
    }

    /// @dev Get proposal Value when given proposal Id.
    function getProposalValue(uint _proposalId) constant returns(uint proposalValue)
    {
        proposalValue = allProposal[_proposalId].proposalValue;
    }

    /// @dev Get proposal Stake by member when given proposal Id.
    function getProposalStake(uint _proposalId) constant returns(uint proposalStake)
    {
        proposalStake = allProposal[_proposalId].proposalStake;
    }

    /// @dev Fetch Total length of Member address array That added number of verdicts against proposal.
    function getVerdictAddedAddressLength(uint _proposalId) constant returns(uint length)
    {
        return  allProposalCategory[_proposalId].verdictAddedByAddress.length;
    }

    /// @dev Get the Stake of verdict when given Proposal Id and Verdict index.
    function getVerdictStakeByProposalId(uint _proposalId,uint _verdictIndex) constant returns(uint verdictStake)
    {
        verdictStake = allProposalCategory[_proposalId].stakeOnVerdict[_verdictIndex];
    }

    /// @dev Get the value of verdict when given Proposal Id and Verdict Index.
    function getVerdictValueByProposalId(uint _proposalId,uint _verdictIndex) constant returns(uint verdictValue)
    {
        verdictValue = allProposalCategory[_proposalId].valueOfVerdict[_verdictIndex];
    }

    /// @dev Get the Address of member whosoever added the verdict when given Proposal Id and Verdict Index.
    function getVerdictAddressByProposalId(uint _proposalId,uint _verdictIndex) constant returns(address memberAddress)
    {
        memberAddress = allProposalCategory[_proposalId].verdictAddedByAddress[_verdictIndex];
    }

    /// @dev Get the Value, stake and Address of the member whosoever added that verdict option.
    function getVerdictAddedDetails(uint _proposalId,uint _verdictIndex) constant returns(uint verdictStake,uint verdictValue,address memberAddress)
    {
        verdictStake = allProposalCategory[_proposalId].stakeOnVerdict[_verdictIndex];
        verdictValue = allProposalCategory[_proposalId].valueOfVerdict[_verdictIndex];
        memberAddress = allProposalCategory[_proposalId].verdictAddedByAddress[_verdictIndex];
    }

    /// @dev Get Total votes against a proposal when given proposal id.
    function getTotalVoteLengthAgainstProposal(uint _proposalId) constant returns(uint totalVotesLength)
    {
        totalVotesLength =  totalVotesAgainstProposal[_proposalId].length;
    }

    /// @dev Get Array of All vote id's against a given proposal when given _proposalId.
    function getTotalVoteArrayAgainstProposal(uint _proposalId) constant returns(uint[] totalVotes)
    {
        return totalVotesAgainstProposal[_proposalId];
    }

    /// @dev Get Vote id one by one against a proposal when given proposal Id and Index to traverse vote array.
    function getVoteIdByProposalId(uint _proposalId,uint _voteArrayIndex) constant returns (uint voteId)
    {
        voteId = totalVotesAgainstProposal[_proposalId][_voteArrayIndex];
    }
    

}  




