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
import "./MemberRoles.sol";
import "./ProposalCategory.sol";
import "./GovernanceData.sol";
import "./zeppelin-solidity/contracts/math/SafeMath.sol";
// import "./Safe/Math.sol";

contract FeatureWeighted is VotingType
{
    using SafeMath for uint;
    address GDAddress;
    address MRAddress;
    address PCAddress;
    MemberRoles MR;
    ProposalCategory PC;
    GovernanceData GD;
    mapping(uint=>uint[]) allVoteValueAgainstOption;
    mapping(uint=>uint[]) allProposalFeatures;
    uint[] changeVoteOptions;

    function FeatureWeighted()
    {
        uint[] option;
        allVotes.push(proposalVote(0x00,0,option,now,0));
    }

    function changeAllContractsAddress(address _GDcontractAddress, address _MRcontractAddress, address _PCcontractAddress) public
    {
        GDAddress = _GDcontractAddress;
        MRAddress = _MRcontractAddress;
        PCAddress = _PCcontractAddress;
    }

    function getTotalVotes()  constant returns (uint votesTotal)
    {
        return(allVotes.length);
    }

    function increaseTotalVotes() returns (uint _totalVotes)
    {
        _totalVotes = SafeMath.add(totalVotes,1);  
        totalVotes=_totalVotes;
    } 

    function getVoteDetailByid(uint _voteid) public constant returns(address voter,uint proposalId,uint[] verdictChosen,uint dateSubmit,uint voterTokens)
    {
        return(allVotes[_voteid].voter,allVotes[_voteid].proposalId,allVotes[_voteid].verdictChosen,allVotes[_voteid].dateSubmit,allVotes[_voteid].voterTokens);
    }

    function getProposalRoleVoteLength(uint _proposalId,uint _roleId) public constant returns(uint length)
    {
         length = ProposalRoleVote[_proposalId][_roleId].length;
    }

    /// @dev Get Vote id of a _roleId against given proposal.
    function getProposalRoleVote(uint _proposalId,uint _roleId,uint _voteArrayIndex) public constant returns(uint voteId) 
    {
        voteId = ProposalRoleVote[_proposalId][_roleId][_voteArrayIndex];
    }

    /// @dev Get the vote count for options of proposal when giving Proposal id and Option index.
    function getProposalVoteAndTokenCountByRoleId(uint _proposalId,uint _roleId,uint _optionIndex) constant returns(uint totalVotes,uint totalToken)
    {
        totalVotes = allProposalVoteAndTokenCount[_proposalId].totalVoteCount[_roleId][_optionIndex];
        totalToken = allProposalVoteAndTokenCount[_proposalId].totalTokenCount[_roleId];
    }

    /// @dev Get Vote id of a _roleId against given proposal.
    function getProposalRoleVoteArray(uint _proposalId,uint _roleId) public constant returns(uint[] voteId) 
    {
        return ProposalRoleVote[_proposalId][_roleId];
    }

    function addProposalFeature(uint _proposalId,uint[] _featureArray) 
    {
        require(allProposalFeatures[_proposalId].length == 0);
        for(uint i=0; i<_featureArray.length; i++)
        {
            allProposalFeatures[_proposalId].push(_featureArray[i]);
        }    
    }

    function getMaxLength(uint _verdictOptions,uint _featureLength) returns (uint maxLength)
    {
        if(_verdictOptions < _featureLength)
            maxLength = _featureLength;
        else
            maxLength = _verdictOptions;
    }

    function getFeatureRankTotal(uint _featureLength,uint[] _verdictChosen,uint _index) returns (uint sum)
    {
        for(uint j=0; j<_featureLength; j++)
        {
            _index+=1;
            sum = sum + _verdictChosen[_index];
        }
    }
    
    function addInTotalVotes(uint _proposalId,uint[] _verdictChosen)
    {
        increaseTotalVotes();
        allVotes.push(proposalVote(msg.sender,_proposalId,_verdictChosen,now,GD.getBalanceOfMember(msg.sender)));
    }
    
    function getAllVoteValueAgainstOption(uint _voteid) public constant returns(uint[] val)
    {
        return allVoteValueAgainstOption[_voteid];
    }

    function getAddressProposalVote(uint _proposalId) constant returns (uint check)
    {
        check = AddressProposalVote[msg.sender][_proposalId];
    }

    function changeInVoteArray(uint[] _changeVoteOptions,uint _voteId)
    {
        allVoteValueAgainstOption[_voteId]=new uint[](_changeVoteOptions.length);
        for(uint i=0; i<_changeVoteOptions.length; i++)
        {
            allVoteValueAgainstOption[_voteId][i] = _changeVoteOptions[i];
        }
    }

    function addVerdictOption(uint _proposalId,uint[] _paramInt,bytes32[] _paramBytes32,address[] _paramAddress,uint _GNTPayableTokenAmount)
    {
        GD=GovernanceData(GDAddress);
        MR=MemberRoles(MRAddress);
        PC=ProposalCategory(PCAddress);
        GD.payableGNTTokens(_GNTPayableTokenAmount);

        uint currentVotingId; uint category; uint intermediateVerdict;
        (category,currentVotingId,intermediateVerdict,,) = GD.getProposalDetailsById2(_proposalId);
        uint verdictOptions;
        (,,,verdictOptions) = GD.getProposalCategoryParams(_proposalId);
        require( currentVotingId == 0);
        require(GD.getBalanceOfMember(msg.sender) != 0 && GD.getProposalStatus(_proposalId) == 2);
        uint _categoryId;
        (_categoryId,,,,) = GD.getProposalDetailsById2(_proposalId); 
        require(MR.getMemberRoleIdByAddress(msg.sender) == PC.getRoleSequencAtIndex(_categoryId,currentVotingId) && AddressProposalVote[msg.sender][_proposalId] == 0 );
        
        uint8 paramInt; uint8 paramBytes32; uint8 paramAddress;
        (,,,paramInt,paramBytes32,paramAddress,,) = PC.getCategoryDetails(_categoryId);

        if(paramInt == _paramInt.length && paramBytes32 == _paramBytes32.length && paramAddress == _paramAddress.length)
        {
            verdictOptions = SafeMath.add(verdictOptions,1);
            GD.setProposalCategoryParams(_proposalId,_paramInt,_paramBytes32,_paramAddress,verdictOptions);  
        } 
    }

    function proposalVoting(uint _proposalId,uint[] _verdictChosen)
    {    
        GD=GovernanceData(GDAddress);
        MR=MemberRoles(MRAddress);
        PC=ProposalCategory(PCAddress);

        uint voteValue; uint voteLength;
        uint currentVotingId; uint category; uint intermediateVerdict;
        uint featureLength = allProposalFeatures[_proposalId].length;
        (category,currentVotingId,intermediateVerdict,,) = GD.getProposalDetailsById2(_proposalId);

        require(GD.getBalanceOfMember(msg.sender) != 0 && GD.getProposalStatus(_proposalId) == 2 && _verdictChosen.length <=  SafeMath.mul(featureLength+1,GD.getTotalVerdictOptions(_proposalId)));
        require(MR.getMemberRoleIdByAddress(msg.sender) == PC.getRoleSequencAtIndex(category,currentVotingId));

        if(currentVotingId == 0)
        {
            for(uint i=0; i<_verdictChosen.length; i++)
            {
                require(_verdictChosen[i] <= getMaxLength(GD.getTotalVerdictOptions(_proposalId),featureLength));
            }
        }   
        else
            require(_verdictChosen[0]==intermediateVerdict || _verdictChosen[0]==0);

        if(AddressProposalVote[msg.sender][_proposalId] == 0)
        {
            voteLength = getTotalVotes();
            addInTotalVotes(_proposalId,_verdictChosen);
            submitAndUpdateNewMemberVote(_proposalId,currentVotingId,_verdictChosen,featureLength);
            allProposalVoteAndTokenCount[_proposalId].totalTokenCount[MR.getMemberRoleIdByAddress(msg.sender)] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalTokenCount[MR.getMemberRoleIdByAddress(msg.sender)],GD.getBalanceOfMember(msg.sender));
            AddressProposalVote[msg.sender][_proposalId] = voteLength;
            ProposalRoleVote[_proposalId][MR.getMemberRoleIdByAddress(msg.sender)].push(voteLength);
        }
        else 
            changeMemberVote(_proposalId,_verdictChosen,featureLength);
    }

    function changeMemberVote(uint _proposalId,uint[] _verdictChosen,uint featureLength)  
    {
        MR=MemberRoles(MRAddress);
        GD=GovernanceData(GDAddress);
        uint voteId = AddressProposalVote[msg.sender][_proposalId];
        uint[] verdictChosen = allVotes[voteId].verdictChosen;
        uint currentVotingId;
        (,currentVotingId,,,) = GD.getProposalDetailsById2(_proposalId);

        revertChangesInMemberVote(_proposalId,currentVotingId,verdictChosen,voteId,featureLength);
        submitAndUpdateNewMemberVote(_proposalId,currentVotingId,_verdictChosen,featureLength);
        allVotes[voteId].verdictChosen = _verdictChosen;
    }

    function revertChangesInMemberVote(uint _proposalId,uint currentVotingId,uint[] verdictChosen,uint voteId,uint featureLength)
    {
        if(currentVotingId == 0)
        {
            for(uint i=0; i<verdictChosen.length; i=i+featureLength+1)
            {
                for(uint j=0; j<allVoteValueAgainstOption[voteId].length; j++)
                {
                    uint voteValue = allVoteValueAgainstOption[voteId][j];
                    allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][verdictChosen[i]] = SafeMath.sub(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][verdictChosen[i]],voteValue);
                }    
            }
        }
        else
        {
            allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][verdictChosen[0]] = SafeMath.sub(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][verdictChosen[0]],1);
        }
    }

    function submitAndUpdateNewMemberVote(uint _proposalId,uint currentVotingId,uint[] _verdictChosen,uint featureLength)
    {
        if(currentVotingId == 0)
        {
            for(uint i=0; i<_verdictChosen.length; i=i+featureLength+1)
            {
                uint sum =0;      
                for(uint j=i+1; j<=featureLength+i; j++)
                {
                    sum = sum + _verdictChosen[j];
                }
                uint voteValue = SafeMath.div(SafeMath.mul(sum,100),featureLength);
                allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][_verdictChosen[i]] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][_verdictChosen[i]],voteValue);
            }
        }  
        else
        {
            allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][_verdictChosen[0]] = SafeMath.add(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[MR.getMemberRoleIdByAddress(msg.sender)][_verdictChosen[0]],1);
        }
    }  

    function closeProposalVote(uint _proposalId)
    {
        GD=GovernanceData(GDAddress);
        MR=MemberRoles(MRAddress);
        PC=ProposalCategory(PCAddress);
    
        uint propStatus;
        (,,,,,,propStatus) = GD.getProposalDetailsById1(_proposalId);
        uint currentVotingId; uint category; uint intermediateVerdict;
        (category,currentVotingId,intermediateVerdict,,) = GD.getProposalDetailsById2(_proposalId);
        uint verdictOptions;
        (,,,verdictOptions) = GD.getProposalCategoryParams(_proposalId);
    
        require(GD.checkProposalVoteClosing(_proposalId)==1);
        uint max; uint totalVotes; uint verdictVal; uint majorityVote;
        uint roleId = MR.getMemberRoleIdByAddress(msg.sender);

        max=0;  
        for(uint i = 0; i < verdictOptions; i++)
        {
            totalVotes = SafeMath.add(totalVotes,allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][i]); 
            if(allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][max] < allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][i])
            {  
                max = i; 
            }
        }
        verdictVal = allProposalVoteAndTokenCount[_proposalId].totalVoteCount[roleId][max];
        majorityVote= PC.getRoleMajorityVote(category,currentVotingId);
       
        if(SafeMath.div(SafeMath.mul(verdictVal,100),totalVotes)>=majorityVote)
        {   
            currentVotingId = SafeMath.add(currentVotingId,1);
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
                    giveReward_afterFinalDecision(_proposalId);
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
     
    function giveReward_afterFinalDecision(uint _proposalId) public 
    {
        address voter; uint[] verdict;uint category;uint roleId; uint reward;uint voteid;
        PC=ProposalCategory(PCAddress); 
        GD=GovernanceData(GDAddress);
        uint currentVotingId;uint intermediateVerdict;uint finalVerdict;
        (category,currentVotingId,intermediateVerdict,finalVerdict,) = GD.getProposalDetailsById2(_proposalId);

        for(uint index=0; index<PC.getRoleSequencLength(category); index++)
        {
            roleId = PC.getRoleSequencAtIndex(category,index);
            reward = GD.getProposalRewardAndComplexity(_proposalId,index);
            for(uint i=0; i<getProposalRoleVoteLength(_proposalId,roleId); i++)
            {
                voteid = getProposalRoleVote(_proposalId,roleId,i);
                verdict = allVotes[voteid].verdictChosen;
                require(verdict[0] == finalVerdict);
                GD.transferTokenAfterFinalReward(voter,reward);  
            }
        }    
    }
}
