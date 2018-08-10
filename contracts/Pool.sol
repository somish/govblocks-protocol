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

pragma solidity 0.4.24;

import "./Master.sol";
import "./imports/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./GBTStandardToken.sol";
import "./Upgradeable.sol";
import "./SimpleVoting.sol";
import "./Governance.sol";
import "./GovernanceData.sol";
import "./ProposalCategory.sol";


contract Pool is Upgradeable {
    using SafeMath for uint;

    address public masterAddress;
    Master internal master;
    SimpleVoting internal simpleVoting;
    GBTStandardToken internal gbt;
    Governance internal gov;
    GovernanceData internal governanceDat;
    ProposalCategory internal proposalCategory;

    function () public payable {}

    modifier onlySV {
        master = Master(masterAddress);
        require(
            master.getLatestAddress("SV") == msg.sender 
            || master.isInternal(msg.sender) 
        );
        _;
    }

    /// @dev just to adhere to the interface
    function updateDependencyAddresses() public {
        master = Master(masterAddress);
        gbt = GBTStandardToken(master.getLatestAddress("GS"));
        simpleVoting = SimpleVoting(master.getLatestAddress("SV"));
        gov = Governance(master.getLatestAddress("GV"));
        governanceDat = GovernanceData(master.getLatestAddress("GD"));
        proposalCategory = ProposalCategory(master.getLatestAddress("PC"));
    }

    function transferAssets() public {
        address newPool = master.getLatestAddress("PL");
        if(address(this) != newPool) {
           gbt.transfer(newPool, gbt.balanceOf(address(this)));
           if (!newPool.send(address(this).balance))
                newPool = address(this); //just to stub the warning
        }
    }

    /// @dev converts pool ETH to GBT
    /// @param _gbt number of GBT to buy multiplied 10^decimals
    function buyPoolGBT(uint _gbt) public onlySV {
        uint _wei = SafeMath.mul(_gbt, gbt.tokenPrice());
        _wei = SafeMath.div(_wei, uint256(10) ** gbt.decimals());
        gbt.buyToken.value(_wei)();
    }

    function putDeposit(address _memberAddress, uint _amount) public returns(bool) {
        return gbt.transferFrom(_memberAddress, address(this), _amount);
    }

    /// @dev user can calim the tokens rewarded them till now
    function claimReward(address _claimer) public {
        uint rewardToClaim = gov.calculateMemberReward(_claimer);
        if (rewardToClaim != 0) {
            gbt.transfer(_claimer, rewardToClaim);
        }
    }

    /// @dev checks and closes proposal if required
    function checkRoleVoteClosing(uint _proposalId, uint32 _roleId, address _memberAddress) public {
        uint gasLeft = gasleft();
        if (gov.checkForClosing(_proposalId, _roleId) == 1) {
            simpleVoting.closeProposalVote(_proposalId);
            _memberAddress.transfer((gasLeft - gasleft()) * uint256(10) ** 9);
        }
    }

    function getPendingReward() public view returns (uint pendingReward) {
        uint lastRewardProposalId;
        uint lastRewardSolutionProposalId;
        uint lastRewardVoteId;
        (lastRewardProposalId, lastRewardSolutionProposalId, lastRewardVoteId) = 
            governanceDat.getAllidsOfLastReward(msg.sender);

        pendingReward = 
            getPendingProposalReward(msg.sender, lastRewardProposalId) 
            + getPendingSolutionReward(msg.sender, lastRewardSolutionProposalId) 
            + getPendingVoteReward(msg.sender, lastRewardVoteId);
    }

    function getPendingProposalReward(address _memberAddress, uint _lastRewardProposalId)
        public
        view
        returns (uint pendingProposalReward)
    {
        uint allProposalLength = governanceDat.getProposalLength();
        uint finalVredict;
        uint8 proposalStatus;
        uint calcReward;
        uint category;

        for (uint i = _lastRewardProposalId; i < allProposalLength; i++) {
            if (_memberAddress == governanceDat.getProposalOwner(i)) {
                (, , category, proposalStatus, finalVredict) = governanceDat.getProposalDetailsById3(i);
                if (
                    proposalStatus > 2 && 
                    finalVredict > 0 && 
                    governanceDat.getProposalIncentive(i) != 0
                ) 
                {
                    category = proposalCategory.getCategoryIdBySubId(category);
                    calcReward = 
                        proposalCategory.getRewardPercProposal(category) 
                        * governanceDat.getProposalIncentive(i)
                        / 100;
                    pendingProposalReward = pendingProposalReward + calcReward;
                }
            }
        }
    }

    function getPendingSolutionReward(address _memberAddress, uint _lastRewardSolutionProposalId)
        public
        view
        returns (uint pendingSolutionReward)
    {
        uint allProposalLength = governanceDat.getProposalLength();
        uint calcReward;
        uint i;
        uint finalVerdict;
        uint solutionId;
        uint proposalId;
        uint totalReward;
        uint category;

        for (i = _lastRewardSolutionProposalId; i < allProposalLength; i++) {
            (proposalId, solutionId, , finalVerdict, totalReward, category) = 
                gov.getSolutionIdAgainstAddressProposal(_memberAddress, i);
            if (finalVerdict > 0 && finalVerdict == solutionId && proposalId == i) {
                calcReward = (proposalCategory.getRewardPercSolution(category) * totalReward) / 100;
                pendingSolutionReward = pendingSolutionReward + calcReward;                
            }
        }
    }

    function getPendingVoteReward(address _memberAddress, uint _lastRewardVoteId)
        public
        view
        returns (uint pendingVoteReward)
    {
        uint i;
        uint totalVotes = governanceDat.getTotalNumberOfVotesByAddress(_memberAddress);
        uint voteId;
        uint proposalId;
        uint solutionChosen;
        uint finalVredict;
        uint voteValue;
        uint totalReward;
        uint category;
        uint calcReward;
        for (i = _lastRewardVoteId; i < totalVotes; i++) {
            voteId = governanceDat.getVoteIdOfNthVoteOfMember(_memberAddress, i);
            (, , , proposalId) = governanceDat.getVoteDetailById(voteId);
            (solutionChosen, , finalVredict, voteValue, totalReward, category, ) = 
                gov.getVoteDetailsToCalculateReward(_memberAddress, i);

            if (finalVredict > 0 && solutionChosen == finalVredict && totalReward != 0) {
                calcReward = (proposalCategory.getRewardPercVote(category) * voteValue * totalReward) 
                    / (100 * governanceDat.getProposalTotalVoteValue(proposalId));

                pendingVoteReward = pendingVoteReward + calcReward;
            } else if (!governanceDat.punishVoters() && finalVredict > 0 && totalReward != 0) {
                calcReward = (proposalCategory.getRewardPercVote(category) * voteValue * totalReward) 
                    / (100 * governanceDat.getProposalTotalVoteValue(proposalId));
                pendingVoteReward = pendingVoteReward + calcReward;
            }
        }
    }

    /// @dev Transfer Ether to someone    
    /// @param _amount Amount to be transferred back
    /// @param _receiverAddress address where ether has to be sent
    function transferEther(address _receiverAddress, uint256 _amount) public onlySV {
        _receiverAddress.transfer(_amount);
    }

    /// @dev Transfer token to someone    
    /// @param _amount Amount to be transferred back
    /// @param _receiverAddress address where tokens have to be sent
    /// @param _token address of token to transfer
    function transferToken(address _token, address _receiverAddress, uint256 _amount) public onlySV {
        GBTStandardToken token = GBTStandardToken(_token);
        token.transfer(_receiverAddress, _amount);
    }

}