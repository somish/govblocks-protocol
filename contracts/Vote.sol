// /* Copyright (C) 2017 GovBlocks.io

//   This program is free software: you can redistribute it and/or modify
//     it under the terms of the GNU General Public License as published by
//     the Free Software Foundation, either version 3 of the License, or
//     (at your option) any later version.

//   This program is distributed in the hope that it will be useful,
//     but WITHOUT ANY WARRANTY; without even the implied warranty of
//     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//     GNU General Public License for more details.

//   You should have received a copy of the GNU General Public License
//     along with this program.  If not, see http://www.gnu.org/licenses/ */

// /**
//  * @title votingType interface for All Types of voting.
//  */

pragma solidity ^0.4.24;


// contract Vote {

//     modifier validateStake(uint _proposalId, uint _stake) {    
//         uint stake = _stake / (10 ** gbt.decimals());
//         uint _category = proposalCategory.getCategoryIdBySubId(governanceDat.getProposalCategory(_proposalId));
//         require(stake <= proposalCategory.getMaxStake(_category) && stake >= proposalCategory.getMinStake(_category));
//         _;
//     }

//     function allowedToAddSolution(uint _proposalId, address _memberAddress) public view returns(bool) {
//         for (uint i = 0; i < governanceDat.getTotalSolutions(_proposalId); i++) {
//             if (governanceDat.getSolutionAddedByProposalId(_proposalId, i) == _memberAddress)
//                 return true;
//         }
//     }

//     function allowedToVote(uint _proposalId, uint64[] _solutionChosen) public view returns(bool) {
//         uint8 _mrSequence;
//         uint8 category;
//         uint currentVotingId;
//         uint intermediateVerdict;
//         (, category, currentVotingId, intermediateVerdict, , , ) = governanceDat.getProposalDetailsById2(_proposalId);
//         uint _categoryId = proposalCategory.getCategoryIdBySubId(category);
//         (_mrSequence, , ) = proposalCategory.getCategoryData3(_categoryId, currentVotingId);

//         require(memberRole.checkRoleIdByAddress(msg.sender, _mrSequence) 
//                 && _solutionChosen.length == 1
//                 && !governanceDat.checkVoteIdAgainstMember(msg.sender, _proposalId));
//         if (currentVotingId == 0)
//             require(_solutionChosen[0] <= governanceDat.getTotalSolutions(_proposalId));
//         else
//             require(_solutionChosen[0] == intermediateVerdict || _solutionChosen[0] == 0);

//         return true;
//     }

//     function getVoteValueGivenByMember(address _memberAddress, uint _memberStake)  
//         public
//         view 
//         returns(uint128 finalVoteValue) 
//     {
//         uint tokensHeld = 
//             SafeMath.div(
//                 SafeMath.mul(
//                     SafeMath.mul(basicToken.balanceOf(_memberAddress), 100), 
//                     100
//                 ), 
//                 basicToken.totalSupply()
//             );
//         uint value = 
//             SafeMath.mul(
//                 Math.max256(_memberStake, governanceDat.scalingWeight()), 
//                 Math.max256(tokensHeld, governanceDat.membershipScalingFactor())
//             );
//         finalVoteValue = SafeMath.mul128(governanceDat.getMemberReputation(_memberAddress), uint128(value));
//     }

//     function checkForThreshold(uint _proposalId, uint32 _mrSequenceId) internal view returns(bool) {
//         uint thresHoldValue;
//         if (_mrSequenceId == 2) {
//             uint totalTokens;

//             for (uint8 i = 0; i < governanceDat.getAllVoteIdsLengthByProposalRole(_proposalId, _mrSequenceId); i++) {
//                 uint voteId = governanceDat.getVoteIdAgainstProposalRole(_proposalId, _mrSequenceId, i);
//                 address voterAddress = governanceDat.getVoterAddress(voteId);
//                 totalTokens = totalTokens + basicToken.balanceOf(voterAddress);
//             }

//             thresHoldValue = totalTokens * 100 / basicToken.totalSupply();
//             if (thresHoldValue > governanceDat.quorumPercentage())
//                 return true;
//         } else {
//             thresHoldValue = (governanceDat.getAllVoteIdsLengthByProposalRole(_proposalId, _mrSequenceId) * 100)
//                 / memberRole.getAllMemberLength(_mrSequenceId);
//             if (thresHoldValue > governanceDat.quorumPercentage())
//                 return true;
//         }
//     }

// }