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
import "./ProposalCategory.sol";

contract simpleVoting is VotingType
{
    using SafeMath for uint;
    using Math for uint;
    GBTStandardToken GBTS;
    governanceData GD;
    memberRoles MR;
    Governance GOV;
    ProposalCategory PC;
    StandardVotingType SVT;
    Master MS;
    address govAddress;
    bool public constructorCheck;
    address public masterAddress;

    modifier onlyInternal {
        MS=Master(masterAddress);
        require(MS.isInternal(msg.sender) == true);
        _; 
    }

    modifier onlyMaster {    
        require(msg.sender == masterAddress);
        _; 
    }

   modifier validateStake(uint _proposalId,uint _stake) {    
        uint stake = _stake/(10**GBTS.decimals());
        uint _category = PC.getCategoryId_bySubId(GD.getProposalCategory(_proposalId));

        // uint _category = GD.getProposalCategory(_proposalId);
        require(stake <= PC.getMaxStake(_category) && stake >= PC.getMinStake(_category));
        _; 
    }

    /// @dev Initiates simple voting contract
    function SimpleVotingInitiate()
    {
        require(constructorCheck == false);
        votingTypeName = "Simple Voting";
        constructorCheck=true;
    }
    
    /// @dev Changes master address
    /// @param _masterContractAddress New master contract address
    function changeMasterAddress(address _masterContractAddress)
    {
        if(masterAddress == 0x000)
            masterAddress = _masterContractAddress;
        else
        {
            MS=Master(masterAddress);
            require(MS.isInternal(msg.sender) == true);
                masterAddress = _masterContractAddress;
        }
    }

    /// @dev Changes Global objects of the contracts || Uses latest version
    /// @param contractName Contract name 
    /// @param contractAddress Contract addresses
    function changeAddress(bytes4 contractName, address contractAddress) onlyInternal
    {
        if(contractName == 'GD'){
            GD = governanceData(contractAddress);
        } else if(contractName == 'MR'){
            MR = memberRoles(contractAddress);
        } else if(contractName == 'PC'){
            PC = ProposalCategory(contractAddress);
        } else if(contractName == 'VT'){
            SVT = StandardVotingType(contractAddress);
        } else if(contractName == 'GV'){
            GOV = Governance(contractAddress);
            govAddress = contractAddress;
        }
    }

    /// @dev Changes GBT controller address
    /// @param _GBTSAddress New GBT controller address
    function changeGBTSAddress(address _GBTSAddress) onlyMaster
    {
        GBTS = GBTStandardToken(_GBTSAddress);
    }

   /// @dev Initiates add solution (Stake in ether)
   /// @param _proposalId Proposal id
   /// @param _solutionHash Solution hash
   function addSolution_inEther(uint _proposalId,string _solutionHash,uint _validityUpto,uint8 _v,bytes32 _r,bytes32 _s,bytes32 _lockTokenTxHash) payable
   {
      uint tokenAmount = GBTS.buyToken.value(msg.value)();
      initiateAddSolution(_proposalId,tokenAmount,_solutionHash,_validityUpto,_v, _r, _s,_lockTokenTxHash);
   }

    /// @dev Initiates add solution 
    /// @param _proposalId Proposal id
    /// @param _memberAddress Member address
    /// @param _solutionStake Solution stake
    /// @param _solutionHash Solution hash
    /// @param _dateAdd Date when the solution was added
    function addSolution(uint _proposalId,address _memberAddress,uint _solutionStake,string _solutionHash,uint _dateAdd,uint _validityUpto,uint8 _v,bytes32 _r,bytes32 _s,bytes32 _lockTokenTxHash) public validateStake(_proposalId,_solutionStake)
    {
        MS=Master(masterAddress);
        require(MS.isInternal(msg.sender) == true || msg.sender == _memberAddress);
        require(alreadyAdded(_proposalId,_memberAddress) == false);
        // if(msg.sender == _memberAddress) 
        //     receiveStake('S',_proposalId,_solutionStake,_validityUpto,_v,_r,_s,_lockTokenTxHash);
       addSolution1(_proposalId,_memberAddress,_solutionStake,_solutionHash,_dateAdd,_validityUpto,_v,_r,_s,_lockTokenTxHash);
       

    }
    
    function addSolution1(uint _proposalId,address _memberAddress,uint _solutionStake,string _solutionHash,uint _dateAdd,uint _validityUpto,uint8 _v,bytes32 _r,bytes32 _s,bytes32 _lockTokenTxHash)internal
    {
        require(GD.getProposalCategory(_proposalId)>0);
        if(msg.sender == _memberAddress) 
            receiveStake('S',_proposalId,_solutionStake,_validityUpto,_v,_r,_s,_lockTokenTxHash);
        uint solutionId=GD.getTotalSolutions(_proposalId); 
        GD.setSolutionAdded(_proposalId,_memberAddress);
        GD.callSolutionEvent(_proposalId,msg.sender,solutionId,_solutionHash,_dateAdd,_solutionStake);    
    }

    /// @dev Adds solution
    /// @param _proposalId Proposal id
    /// @param _solutionStake Stake put by the member when providing a solution
    /// @param _solutionHash Solution hash
    function initiateAddSolution(uint _proposalId,uint _solutionStake,string _solutionHash,uint _validityUpto,uint8 _v,bytes32 _r,bytes32 _s,bytes32 _lockTokenTxHash) public
    {
        addSolution(_proposalId,msg.sender,_solutionStake, _solutionHash,now,_validityUpto,_v,_r,_s,_lockTokenTxHash); 
    }


   /// @dev Creates proposal for voting (Stake in ether)
   /// @param _proposalId Proposal id
   /// @param _solutionChosen solution chosen while voting
   function proposalVoting_inEther(uint _proposalId,uint[] _solutionChosen,uint _validityUpto,uint8 _v,bytes32 _r,bytes32 _s,bytes32 _lockTokenTxHash) payable
   {
       uint tokenAmount = GBTS.buyToken.value(msg.value)();
       proposalVoting(_proposalId, _solutionChosen, tokenAmount,_validityUpto,_v,_r,_s,_lockTokenTxHash);
   }

    /// @dev Creates proposal for voting
    /// @param _proposalId Proposal id
    /// @param _solutionChosen solution chosen while voting
    /// @param _voteStake Amount payable in GBT tokens
    function proposalVoting(uint _proposalId,uint[] _solutionChosen,uint _voteStake,uint _validityUpto,uint8 _v,bytes32 _r,bytes32 _s,bytes32 _lockTokenTxHash) public validateStake(_proposalId,_voteStake)
    {
        require(validateMember(_proposalId,_solutionChosen) == true);
        require(GD.getProposalStatus(_proposalId) == 2);
        
        // uint32 _mrSequence;
        // uint category=GD.getProposalCategory(_proposalId);
        // uint currVotingId=GD.getProposalCurrentVotingId(_proposalId);
        // (_mrSequence,,) = PC.getCategoryData3(category,currVotingId);
        receiveStake('V',_proposalId,_voteStake,_validityUpto,_v,_r,_s,_lockTokenTxHash);
        castVote(_proposalId,_solutionChosen,msg.sender,_voteStake);    
    }

   
    /// @dev Castes vote
    /// @param _proposalId Proposal id
    /// @param _solutionChosen solution chosen
    /// @param _memberAddress Member address
    /// @param _voteStake Vote stake

    function castVote(uint _proposalId,uint[] _solutionChosen,address _memberAddress,uint _voteStake) internal
    {
        uint voteId = GD.allVotesTotal();
        uint finalVoteValue = SVT.setVoteValue_givenByMember(_memberAddress,_proposalId,_voteStake);
        uint32 _roleId;
        uint category = PC.getCategoryId_bySubId(GD.getProposalCategory(_proposalId));
        
        // uint category=GD.getProposalCategory(_proposalId);
        uint currVotingId=GD.getProposalCurrentVotingId(_proposalId);
        (_roleId,,) = PC.getCategoryData3(category,currVotingId);
        GD.setVoteId_againstMember(_memberAddress,_proposalId,voteId);
        GD.setVoteId_againstProposalRole(_proposalId,_roleId,voteId);
        GOV.checkRoleVoteClosing(_proposalId,_roleId);
        GD.setVoteValue(voteId,finalVoteValue);
        GD.callVoteEvent(_memberAddress,_proposalId,now,_voteStake,voteId);

    }
    
    /// @dev Closes proposal for voting
    /// @param _proposalId Proposal id
    function closeProposalVote(uint _proposalId) public
    {
        SVT.closeProposalVoteSVT(_proposalId);
    }

    /// @dev Gives rewards to respective members after final decision
    /// @param _proposalId Proposal id
    function giveReward_afterFinalDecision(uint _proposalId) onlyInternal
    {   
        uint totalVoteValue;uint totalReward; uint finalVerdict = GD.getProposalFinalVerdict(_proposalId);
        if(GD.getProposalFinalVerdict(_proposalId) < 0)
            totalReward = SafeMath.add(totalReward,GD.getDepositedTokens(GD.getProposalOwner(_proposalId),_proposalId,'P'));

        for(i=0; i<GD.getTotalSolutions(_proposalId); i++)
        {
            if(i!= finalVerdict)         
                totalReward = SafeMath.add(totalReward,GD.getDepositedTokens(GD.getSolutionAddedByProposalId(_proposalId,i),_proposalId,'S'));
        }

        uint mrLength = MR.getTotalMemberRoles();
        for(uint i=0; i<mrLength; i++) 
        {
            uint mrVoteLength = GD.getAllVoteIdsLength_byProposalRole(_proposalId,i);
            for(uint j =0; j<mrVoteLength; j++)
            {
                uint voteId = GD.getVoteId_againstProposalRole(_proposalId,j,0);
                if(GD.getSolutionByVoteIdAndIndex(voteId,0) != finalVerdict)
                {
                    totalReward = SafeMath.add(totalReward,GD.getDepositedTokens(GD.getVoterAddress(voteId),_proposalId,'V'));
                    totalVoteValue = SafeMath.add(totalVoteValue,GD.getVoteValue(voteId));
                } 
            }
        }

        totalReward = totalReward + GD.getProposalIncentive(_proposalId); 
        GOV.setProposalDetails(_proposalId,totalReward,totalVoteValue);         
    } 


// Other Functions


    /// @dev Adds solution against proposal.
    /// @param _proposalId Proposal id
    /// @param _memberAddress Member address
    function alreadyAdded(uint _proposalId,address _memberAddress) constant returns(bool)
    {
        for(uint i=0; i<GD.getTotalSolutions(_proposalId); i++)
        {
            if(GD.getSolutionAddedByProposalId(_proposalId,i) == _memberAddress)
                return true;
        }
    }

    /// @dev Receives solution stake against solution in simple voting
    /// @param _proposalId Proposal id
    function receiveStake(bytes2 _type,uint _proposalId,uint _Stake,uint _validityUpto,uint8 _v,bytes32 _r,bytes32 _s,bytes32 _lockTokenTxHash) internal
    {
        uint8 currVotingId = GD.getProposalCurrentVotingId(_proposalId);uint depositedTokens;
        uint depositPerc = GD.depositPercSolution();
        if(_type == 'S')
             depositedTokens = GD.getDepositedTokens(msg.sender,_proposalId,'S');
        else
             depositedTokens = GD.getDepositedTokens(msg.sender,_proposalId,'V');

        uint depositAmount = SafeMath.div(SafeMath.mul(_Stake,depositPerc),100) + depositedTokens;
        uint category = PC.getCategoryId_bySubId(GD.getProposalCategory(_proposalId));
        
        if(_Stake != 0)
        {
          require(_validityUpto > PC.getRemainingClosingTime(_proposalId,category,currVotingId));
          if(depositPerc !=0 && depositPerc!= 100)
          {
            GBTS.lockToken(msg.sender,SafeMath.sub(_Stake,depositAmount),_validityUpto,_v,_r,_s,_lockTokenTxHash);
            if(_type == 'S')
                GD.setDepositTokens(msg.sender,_proposalId,'S',depositAmount);  
            else
                GD.setDepositTokens(msg.sender,_proposalId,'V',depositAmount);  
          }
          else if(depositPerc == 100)
          {
            if(_type == 'S')
                GD.setDepositTokens(msg.sender,_proposalId,'S',_Stake); 
            else
                GD.setDepositTokens(msg.sender,_proposalId,'V',_Stake); 
          }
          else
            GBTS.lockToken(msg.sender,_Stake,_validityUpto,_v,_r,_s,_lockTokenTxHash);
        } 
    }

    function validateMember(uint _proposalId,uint[] _solutionChosen)constant returns(bool)
    {
        uint8 _mrSequence;uint currentVotingId;uint intermediateVerdict;uint category;
        (,category,currentVotingId,intermediateVerdict,,,) = GD.getProposalDetailsById2(_proposalId);
        (_mrSequence,,) = PC.getCategoryData3(category,currentVotingId);

        require(MR.checkRoleId_byAddress(msg.sender,_mrSequence) == true  && _solutionChosen.length == 1 && GD.checkVoteId_againstMember(msg.sender,_proposalId) == false);
        if(currentVotingId == 0)
            require(_solutionChosen[0] <= GD.getTotalSolutions(_proposalId));
        else
            require(_solutionChosen[0]==intermediateVerdict || _solutionChosen[0]==0);

        return true;
    }





    // function changeMemberVote(uint _proposalId,uint[] _solutionChosen,address _memberAddress,uint _GBTPayableTokenAmount) internal
    // {
    //     MR=memberRoles(MRAddress);
    //     GOV=Governance(G1Address);
    //     GD=governanceData(GDAddress);
    //     SVT=StandardVotingType(SVTAddress);

    //     uint roleId = MR.getMemberRoleIdByAddress(_memberAddress);
    //     uint voteId = GD.getVoteId_againstMember(_memberAddress,_proposalId);
    //     uint voteVal = GD.getVoteValue(voteId);
        
    //     GD.editProposalVoteCount(_proposalId,roleId,GD.getOptionById(voteId,0),voteVal);
    //     GD.setProposalVoteCount(_proposalId,roleId,_optionChosen[0],voteVal);
    //     GD.setOptionChosen(voteId,_optionChosen[0]);

        
    // }
    
}

