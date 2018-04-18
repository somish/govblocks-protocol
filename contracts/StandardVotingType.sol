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
import "./ProposalCategory";
import "./governanceData.sol";
import "./VotingType.sol";
import "./Pool.sol";
import "./Master.sol";
import "./Governance.sol";
import "./memberRoles";
import "./GBTStandardToken.sol";


contract StandardVotingType
{
    address GBTSAddress;
    address public masterAddress;
    GBTStandardToken GBTS;
    Master MS;
    Pool P1;
    Governance G1;
    memberRoles MR;
    ProposalCategory PC;
    governanceData  GD;
    // BasicToken BT;
    simpleVoting SV;
    RankBasedVoting RB;
    FeatureWeighted FW;
    VotingType VT;

    modifier onlyInternal {
        require(MS.isInternal(msg.sender) == 1);
        _; 
    }

    /// @dev Changes master's contract address
    /// @param _masterContractAddress New master contract address
    function changeMasterAddress(address _masterContractAddress)
    {
        if(masterAddress == 0x000)
            masterAddress = _masterContractAddress;
        else
        {
            require(MS.isInternal(msg.sender) == 1);
                masterAddress = _masterContractAddress;
        }
        MS=Master(masterAddress);
    }

    modifier onlyMaster
    {
        require(msg.sender == masterAddress);
        _;
    }
    
    /// @dev Changes other contracts' addresses
    /// @param _SVaddress New simple voting contract address
    /// @param _RBaddress New rank based contract address
    /// @param _FWaddress New feature weighted contracts address
    // function changeOtherContractAddress(bytes4 _contractName) onlyInternal 
    // {
    //     SVAddress = _SVaddress;
    //     RBAddress = _RBaddress;
    //     FWAddress = _FWaddress;
    // }

    /// @dev Changes all contracts' addresses
    /// @param _GDcontractAddress  New governance data contract address
    /// @param _MRcontractAddress New member roles contract address
    /// @param _PCcontractAddress New proposal category contract address
    /// @param _governanceContractAddress New governance contract address
    /// @param _poolContractAddress New pool contract address
    // function changeAllContractsAddress(address _GDcontractAddress, address _MRcontractAddress, address _PCcontractAddress,address _governanceContractAddress,address _poolContractAddress) onlyInternal 
    // {
    //     GDAddress = _GDcontractAddress;
    //     MRAddress = _MRcontractAddress;
    //     PCAddress = _PCcontractAddress;
    //     G1Address = _governanceContractAddress;
    //     P1Address = _poolContractAddress;
    // }

    /// @dev Changes Global objects of the contracts || Uses latest version
    /// @param contractName Contract name 
    /// @param contractAddress Contract addresses
    function changeAddress(bytes4 contractName, address contractAddress){
        if(contractName == 'GD'){
            GD = governanceData(contractAddress);
        } else if(contractName == 'MR'){
            MR = memberRoles(contractAddress);
        } else if(contractName == 'PC'){
            PC = ProposalCategory(contractAddress);
        } else if(contractName == 'SV'){
            SV = simpleVoting(contractAddress);
        } else if(contractName == 'RB'){
            RB = RankBasedVoting(contractAddress);
        } else if(contractName == 'FW'){
            FW = FeatureWeighted(contractAddress);
        } else if(contractName == 'GOV'){
            G1 = Governance(contractAddress);
        } else if(contractName == 'PL'){
            P1 = Pool(contractAddress);
        }
    }

    /// @dev Changes GBT standard token address
    /// @param _GBTSAddress GBT standard token address
    function changeGBTSAddress(address _GBTSAddress) onlyMaster
    {
        GBTSAddress = _GBTSAddress;
    }

    
    /// @dev Sets option value given by member in standard voting type
    /// @param _memberAddress Member address
    /// @param _proposalId Proposal id
    /// @param _memberStake Member stake
    /// @return finalOptionValue Final option value
    function setOptionValue_givenByMemberSVT(address _memberAddress,uint _proposalId,uint _memberStake) internal returns (uint finalOptionValue)
    {
        // GD=governanceData(GDAddress);
        // GBTS=GBTStandardToken(GBTSAddress);
        // uint memberLevel = Math.max256(GD.getMemberReputation(_memberAddress),1);
        // uint tokensHeld = SafeMath.div((SafeMath.mul(SafeMath.mul(GBTS.balanceOf(_memberAddress),100),100)),GBTS.totalSupply());
        // uint maxValue= Math.max256(tokensHeld,GD.membershipScalingFactor());

        // finalOptionValue = SafeMath.mul(SafeMath.mul(GD.globalRiskFactor(),memberLevel),SafeMath.mul(_memberStake,maxValue));
    }

    /// @dev Sets vote value given by member
    /// @param _memberAddress Member address
    /// @param _proposalId Proposal id
    /// @param _memberStake Member stake
    /// @return finalVoteValue Final vote value
    function setVoteValue_givenByMember(address _memberAddress,uint _proposalId,uint _memberStake) onlyInternal returns (uint finalVoteValue)
    {
        GBTS=GBTStandardToken(GBTSAddress);
        uint tokensHeld = SafeMath.div((SafeMath.mul(SafeMath.mul(GBTS.balanceOf(_memberAddress),100),100)),GBTS.totalSupply());
        uint value= SafeMath.mul(Math.max256(_memberStake,GD.scalingWeight()),Math.max256(tokensHeld,GD.membershipScalingFactor()));
        finalVoteValue = SafeMath.mul(GD.getMemberReputation(_memberAddress),value);
    }  
    
    /// @dev Checks for options
    /// @param _proposalId Proposal id
    /// @param _memberAddress Member address
    /// @return check Check flag
    function checkForOption(uint _proposalId,address _memberAddress) internal constant returns(uint check)
    {
        for(uint i=0; i<GD.getProposalAnsLength(_memberAddress); i++)
        {
            if(GD.getProposalAnsId(_memberAddress,i) == _proposalId)
                check = 1;
            else 
                check = 0;
        }
    }

    /// @dev Adds verdict option in standard voting type
    /// @param _proposalId Proposal id
    /// @param _memberAddress Member address
    /// @param _GBTPayableTokenAmount Amount payable in GBT token
    /// @param _optionHash Option hash
    /// @param _dateAdd Date proposal was added
    // function addVerdictOptionSVT(uint _proposalId,address _memberAddress,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress,uint _GBTPayableTokenAmount,string _optionDescHash) onlyInternal
    function addVerdictOptionSVT(uint _proposalId,address _memberAddress,uint _GBTPayableTokenAmount,string _optionHash,uint _dateAdd) onlyInternal
    {
        GBTS=GBTStandardToken(GBTSAddress);
        checkForOption(_proposalId,_memberAddress);

        uint currentVotingId;
        (,,currentVotingId,,,) = GD.getProposalDetailsById2(_proposalId);

        require(currentVotingId == 0 && GD.getProposalStatus(_proposalId) == 2 && GBTS.balanceOf(_memberAddress) != 0);
        require(GD.getVoteId_againstMember(_memberAddress,_proposalId) == 0);
        
        GD.setOptionIdByAddress(_proposalId,_memberAddress);
        
        // uint8 paramInt; uint8 paramBytes32; uint8 paramAddress;
        // (,,,,paramInt,paramBytes32,paramAddress,,) = PC.getCategoryDetails(GD.getProposalCategory(_proposalId));

        // require(paramInt == _paramInt.length && paramBytes32 == _paramBytes32.length && paramAddress == _paramAddress.length);
        // addVerdictOptionSVT2(_proposalId,GD.getProposalCategory(_proposalId),_paramInt,_paramBytes32,_paramAddress);
            addVerdictOptionSVT1(_proposalId,_memberAddress,_GBTPayableTokenAmount,_optionHash,_dateAdd);
    }

    /// @dev Adds verdict option in standard voting type
    /// @param _proposalId Proposal id
    /// @param _memberAddress Member address
    /// @param _GBTPayableTokenAmount Amount payable in GBT token
    /// @param _optionHash Option hash
    /// @param _dateAdd Date proposal was added
    function addVerdictOptionSVT1(uint _proposalId,address _memberAddress,uint _GBTPayableTokenAmount,string _optionHash,uint _dateAdd) internal
    {
        setOptionDetails(_proposalId,_memberAddress,_GBTPayableTokenAmount,setOptionValue_givenByMemberSVT(_memberAddress,_proposalId,_GBTPayableTokenAmount),_optionHash,_dateAdd);
    }

    uint24 _closingTime;uint _majorityVote;
    uint8 currentVotingId; uint8 max; uint totalVotes; uint verdictVal;

    /// @dev Closes voting proposal in standard voting type
    /// @param _proposalId Proposal id
    function closeProposalVoteSVT(uint _proposalId) onlyInternal
    {   
        VT=VotingType(GD.getProposalVotingType(_proposalId));


        uint majorityVote;
        (,,currentVotingId,,,) = GD.getProposalDetailsById2(_proposalId);
        uint8 verdictOptions = GD.getTotalVerdictOptions(_proposalId);
        _closingTime = PC.getClosingTimeAtIndex(GD.getProposalCategory(_proposalId),currentVotingId);
        _majorityVote= PC.getRoleMajorityVoteAtIndex(GD.getProposalCategory(_proposalId),currentVotingId);

        require(G1.checkProposalVoteClosing(_proposalId,_roleId,_closingTime,_majorityVote)==1); //1
        uint _roleId = PC.getRoleSequencAtIndex(GD.getProposalCategory(_proposalId),currentVotingId);
    
        max=0;  
        for(uint8 i = 0; i < verdictOptions; i++)
        {
            totalVotes = SafeMath.add(totalVotes,GD.getVoteValuebyOption_againstProposal(_proposalId,_roleId,i)); 
            if(GD.getVoteValuebyOption_againstProposal(_proposalId,_roleId,max) < GD.getVoteValuebyOption_againstProposal(_proposalId,_roleId,i))
            {  
                max = i; 
            }
        }
        
        verdictVal = GD.getVoteValuebyOption_againstProposal(_proposalId,_roleId,max);
        
        if(totalVotes != 0)
        {
            if(SafeMath.div(SafeMath.mul(verdictVal,100),totalVotes)>=_majorityVote)
                {   
                    currentVotingId = currentVotingId+1;
                    if(max > 0 )
                    {
                        if(currentVotingId < PC.getRoleSequencLength(GD.getProposalCategory(_proposalId)))
                        // if(currentVotingId < _roleSequenceLength)
                        {
                            G1.updateProposalDetails(_proposalId,currentVotingId,max,0);
                            P1.closeProposalOraclise(_proposalId,_closingTime); 
                            GD.callOraclizeCallEvent(_proposalId,GD.getProposalDateUpd(_proposalId),PC.getClosingTimeAtIndex(GD.getProposalCategory(_proposalId),currentVotingId+1));
                        } 
                        else
                        {
                            G1.updateProposalDetails(_proposalId,currentVotingId,max,max);
                            GD.changeProposalStatus(_proposalId,3);
                            VT.giveReward_afterFinalDecision(_proposalId);
                        }
                    }
                    else
                    {
                        G1.updateProposalDetails(_proposalId,currentVotingId,max,max);
                        GD.changeProposalStatus(_proposalId,4);
                        VT.giveReward_afterFinalDecision(_proposalId);
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
    /// @dev Sets the details of added verdict i.e. verdict stake, verdict value and address of the member whoever added the verdict.
    /// @param _proposalId Proposal id
    /// @param _memberAddress Member address
    /// @param _stakeValue Stake value
    /// @param _optionValue Option value
    /// @param _optionHash Option hash
    /// @param _dateAdd Date proposal was added
    function setOptionDetails(uint _proposalId,address _memberAddress,uint _stakeValue,uint _optionValue,string _optionHash,uint _dateAdd) internal
    { 
        uint currentDate;
        if(_dateAdd == 0)
            currentDate = now;
        else
            currentDate = _dateAdd;

        GD.setOptionAddress(_proposalId,_memberAddress);
        GD.setOptionStake(_proposalId,_stakeValue);
        GD.setOptionValue(_proposalId,_optionValue);
        GD.setOptionHash(_proposalId,_optionHash);
        GD.setOptionDateAdded(_proposalId,currentDate);
        GD.setProposalAnsByAddress(_proposalId,_memberAddress); // Saving proposal id against memebr to which solution is provided
        GD.setTotalOptions(_proposalId);
    }
}







