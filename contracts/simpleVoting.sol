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
    // address GDAddress;
    // address MRAddress;
    // address PCAddress;
    // address GBTAddress;
    // address G1Address;
    // address SVTAddress;
    // address GBTSAddress;
    GBTStandardToken GBTS;
    governanceData GD;
    memberRoles MR;
    Governance GOV;
    ProposalCategory PC;
    StandardVotingType SVT;
    Master MS;
    uint public constructorCheck;
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

    /// @dev Initiates simple voting contract
    function SimpleVotingInitiate()
    {
        require(constructorCheck == 0);
        votingTypeName = "Simple Voting";
        constructorCheck=1;
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
    
 
    // function changeAllContractsAddress(address _StandardVotingAddress,address _GDcontractAddress, address _MRcontractAddress, address _PCcontractAddress,address _G1ContractAddress) onlyInternal
    // {
    //     SVTAddress = _StandardVotingAddress;
    //     GDAddress = _GDcontractAddress;
    //     MRAddress = _MRcontractAddress;
    //     PCAddress = _PCcontractAddress;
    //     G1Address = _G1ContractAddress;
    // }

    /// @dev Changes Global objects of the contracts || Uses latest version
    /// @param contractName Contract name 
    /// @param contractAddress Contract addresses
    function changeAddress(bytes4 contractName, address contractAddress) onlyInternal{
        if(contractName == 'GD'){
            GD = governanceData(contractAddress);
        } else if(contractName == 'MR'){
            MR = memberRoles(contractAddress);
        } else if(contractName == 'PC'){
            PC = ProposalCategory(contractAddress);
        } else if(contractName == 'SVT'){
            SVT = StandardVotingType(contractAddress);
        } else if(contractName == 'GOV'){
            GOV = Governance(contractAddress);
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
   function addSolution_inEther(uint _proposalId,string _solutionHash,uint8 _v,bytes32 _r,bytes32 _s) payable
   {
      uint tokenAmount = GBTS.buyToken.value(msg.value)();
      initiateAddSolution(_proposalId,tokenAmount,_solutionHash, _v, _r, _s);
   }

    /// @dev Initiates add solution 
    /// @param _proposalId Proposal id
    /// @param _memberAddress Member address
    /// @param _solutionStake Solution stake
    /// @param _solutionHash Solution hash
    /// @param _dateAdd Date when the solution was added
    function addSolution(uint _proposalId,address _memberAddress,uint _solutionStake,string _solutionHash,uint _dateAdd,uint8 _v,bytes32 _r,bytes32 _s) public
    {
        // SVT=StandardVotingType(SVTAddress);
        MS=Master(masterAddress);
        require(MS.isInternal(msg.sender) == true || msg.sender == _memberAddress);
        if(_solutionStake!=0)
            receiveSolutionStakeSV(_proposalId,_solutionStake,_solutionHash,_dateAdd,_v,_r,_s);
        addSolution1(_proposalId,_memberAddress,_solutionHash,_dateAdd);
    }

    /// @dev Adds solution against proposal.
    /// @param _proposalId Proposal id
    /// @param _memberAddress Member address
    /// @param _solutionHash Solution hash
    /// @param _dateAdd Date proposal was added
    function addSolution1(uint _proposalId,address _memberAddress,string _solutionHash,uint _dateAdd) internal
    {
        // GBTS=GBTStandardToken(GBTSAddress);
        uint currentVotingId;uint check;
        (,,currentVotingId,,,,) = GD.getProposalDetailsById2(_proposalId);

        for(uint i=0; i<GD.getTotalSolutions(_proposalId); i++)
        {
            if(GD.getSolutionAddedByProposalId(_proposalId,i) == _memberAddress)
                check = 1;
            else 
                check = 0;
        }
        require(check == 0 && currentVotingId == 0 && GD.getProposalStatus(_proposalId) == 2 && GBTS.balanceOf(_memberAddress) != 0 && GD.getVoteId_againstMember(_memberAddress,_proposalId) == 0);
    }

    /// @dev Adds solution
    /// @param _proposalId Proposal id
    /// @param _solutionStake Stake put by the member when providing a solution
    /// @param _solutionHash Solution hash
    function initiateAddSolution(uint _proposalId,uint _solutionStake,string _solutionHash,uint8 _v,bytes32 _r,bytes32 _s) 
    {
        addSolution(_proposalId,msg.sender,_solutionStake, _solutionHash,now,_v,_r,_s); 
    }

    /// @dev Receives solution stake against solution in simple voting
    /// @param _proposalId Proposal id
    /// @param _solutionStake Solution stake
    /// @param _solutionHash Solution hash
    /// @param _dateAdd Date when solution was added
    function receiveSolutionStakeSV(uint _proposalId,uint _solutionStake,string _solutionHash,uint _dateAdd,uint8 _v,bytes32 _r,bytes32 _s) internal
    {
        // GD=governanceData(GDAddress);
        // PC=ProposalCategory(PCAddress);
        uint remainingTime = PC.getRemainingClosingTime(_proposalId,GD.getProposalCategory(_proposalId),GD.getProposalCurrentVotingId(_proposalId));
        uint depositAmount = ((_solutionStake*GD.depositPercSolution())/100);
        uint finalAmount = depositAmount + GD.getDepositedTokens(msg.sender,_proposalId,'S');
        GD.setDepositTokens(msg.sender,_proposalId,'S',finalAmount);
        GBTS.lockToken(msg.sender,SafeMath.sub(_solutionStake,finalAmount),remainingTime,_v,_r,_s);  
        GD.callSolutionEvent(_proposalId,msg.sender,_solutionHash,_dateAdd,_solutionStake);    
    }

   /// @dev Creates proposal for voting (Stake in ether)
   /// @param _proposalId Proposal id
   /// @param _solutionChosen solution chosen while voting
   function proposalVoting_inEther(uint _proposalId,uint[] _solutionChosen,uint8 _v,bytes32 _r,bytes32 _s) payable
   {
       uint tokenAmount = GBTS.buyToken.value(msg.value)();
       proposalVoting(_proposalId, _solutionChosen, tokenAmount,_v,_r,_s);
   }


    /// @dev Creates proposal for voting
    /// @param _proposalId Proposal id
    /// @param _solutionChosen solution chosen while voting
    /// @param _voteStake Amount payable in GBT tokens
    function proposalVoting(uint _proposalId,uint[] _solutionChosen,uint _voteStake,uint8 _v,bytes32 _r,bytes32 _s) public
    {
        // GD=governanceData(GDAddress);
        // MR=memberRoles(MRAddress);
        // GBTS=GBTStandardToken(GBTSAddress);
        uint8 _mrSequence;uint _closingTime; uint currentVotingId;uint intermediateVerdict;uint category;
        (,category,currentVotingId,intermediateVerdict,,,) = GD.getProposalDetailsById2(_proposalId);
        (_mrSequence,,_closingTime) = PC.getCategoryData3(category,currentVotingId);
        uint _proposalDateUpd = GD.getProposalDateUpd(_proposalId);
        uint roleId = MR.getMemberRoleIdByAddress(msg.sender);

        require(SafeMath.add(_proposalDateUpd,_closingTime) >= now && msg.sender != GD.getSolutionAddedByProposalId(_proposalId,_solutionChosen[0]));
        require(roleId == _mrSequence && GBTS.balanceOf(msg.sender) != 0 && GD.getProposalStatus(_proposalId) == 2 && _solutionChosen.length == 1);

        if(currentVotingId == 0)
            require(_solutionChosen[0] <= GD.getTotalSolutions(_proposalId));
        else
            require(_solutionChosen[0]==intermediateVerdict || _solutionChosen[0]==0);
            
        castVote(_proposalId,_solutionChosen,msg.sender,_voteStake,roleId,_v,_r,_s);    
    }

    /// @dev Castes vote
    /// @param _proposalId Proposal id
    /// @param _solutionChosen solution chosen
    /// @param _memberAddress Member address
    /// @param _voteStake Vote stake
    /// @param _roleId Role id
    function castVote(uint _proposalId,uint[] _solutionChosen,address _memberAddress,uint _voteStake,uint _roleId,uint8 _v,bytes32 _r,bytes32 _s) internal
    {
        // GD=governanceData(GDAddress);
        // SVT=StandardVotingType(SVTAddress);
        // GOV=Governance(G1Address);
        if(GD.getVoteId_againstMember(_memberAddress,_proposalId) == 0)
        {
            uint voteId = GD.allVotesTotal();
            uint finalVoteValue = SVT.setVoteValue_givenByMember(_memberAddress,_proposalId,_voteStake);
            GD.setVoteId_againstMember(_memberAddress,_proposalId,voteId);
            GD.setVoteId_againstProposalRole(_proposalId,_roleId,voteId);
            GOV.checkRoleVoteClosing(_proposalId,_roleId);
            GD.callVoteEvent(_memberAddress,_proposalId,now,_voteStake,voteId);
            receiveVoteStakeSV(_voteStake,_proposalId,_v,_r,_s);
        }
        // else 
            // changeMemberVote(_proposalId,_solutionChosen,_memberAddress,_GBTPayableTokenAmount);
    }
    
    /// @dev Receives vote stake against solution in simple voting
    /// @param _memberStake Member stake
    /// @param _proposalId Proposal id
     function receiveVoteStakeSV(uint _memberStake,uint _proposalId,uint8 _v,bytes32 _r,bytes32 _s) internal
    {
        // GBTS=GBTStandardToken(GBTSAddress);
        // GD=governanceData(GDAddress);
        if(_memberStake != 0)
        {
            uint remainingTime = PC.getRemainingClosingTime(_proposalId,GD.getProposalCategory(_proposalId),GD.getProposalCurrentVotingId(_proposalId));
            uint depositAmount = ((_memberStake*GD.depositPercVote())/100);
            uint finalAmount = depositAmount + GD.getDepositedTokens(msg.sender,_proposalId,'V');
            GD.setDepositTokens(msg.sender,_proposalId,'V',finalAmount);
            GBTS.lockToken(msg.sender,SafeMath.sub(_memberStake,finalAmount),remainingTime,_v,_r,_s);
        }  
    }

    /// @dev Closes proposal for voting
    /// @param _proposalId Proposal id
    function closeProposalVote(uint _proposalId) public
    {
        // SVT=StandardVotingType(SVTAddress);
        SVT.closeProposalVoteSVT(_proposalId);
    }

    /// @dev Gives rewards to respective members after final decision
    /// @param _proposalId Proposal id
    function giveReward_afterFinalDecision(uint _proposalId) onlyInternal
    {   
        // GD=governanceData(GDAddress); 
        uint totalReward; uint finalVerdict = GD.getProposalFinalVerdict(_proposalId);
        uint totalVoteValue;
        // GOV=Governance(G1Address); 

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

