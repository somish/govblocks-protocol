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

import "./imports/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./imports/govern/Governed.sol";
import "./GBTStandardToken.sol";
import "./Upgradeable.sol";
import "./Governance.sol";
import "./GovernanceData.sol";
import "./ProposalCategory.sol";
import "./VotingType.sol";


contract Pool is Upgradeable, Governed {
    using SafeMath for uint;

    GBTStandardToken public gbt;
    GBTStandardToken public dAppToken;
    Governance public gov;
    GovernanceData public governanceDat;
    ProposalCategory public proposalCategory;
    bool internal locked;
    
    function () public payable {} //solhint-disable-line

    modifier noReentrancy() {
        require(!locked, "Reentrant call.");
        locked = true;
        _;
        locked = false;
    }

    /// @dev just to adhere to the interface
    function updateDependencyAddresses() public {
        gbt = GBTStandardToken(master.gbt());
        gov = Governance(master.getLatestAddress("GV"));
        governanceDat = GovernanceData(master.getLatestAddress("GD"));
        proposalCategory = ProposalCategory(master.getLatestAddress("PC"));
        dAppToken = GBTStandardToken(master.dAppToken());
        dappName = master.dAppName();
    }

    /// @dev transfers its assets to latest addresses
    function transferAssets() public {
        address newPool = master.getLatestAddress("PL");
        if (address(this) != newPool) {
            uint gbtBal = gbt.balanceOf(address(this));
            uint ethBal = address(this).balance;
            if (gbtBal > 0)
                gbt.transfer(newPool, gbtBal);
            if (ethBal > 0)
                newPool.transfer(ethBal);
        }
    }

    /// @dev converts pool ETH to GBT
    /// @param _gbt number of GBT to buy multiplied 10^decimals
    function buyPoolGBT(uint _gbt) public onlyAuthorizedToGovern {
        uint _wei = SafeMath.mul(_gbt, gbt.tokenPrice());
        _wei = SafeMath.div(_wei, uint256(10) ** gbt.decimals());
        gbt.buyToken.value(_wei)();
    }

    /// @dev user can calim the tokens rewarded them till now
    /// Index 0 of _ownerProposals, _voterProposals is not parsed. 
    /// proposal arrays of 1 length are treated as empty.
    function claimReward(address _claimer, uint[] _voterProposals) public noReentrancy {
        uint pendingGBTReward;
        uint pendingDAppReward;
        uint pendingReputation;

        VotingType votingType = VotingType(governanceDat.getLatestVotingAddress());
        (pendingGBTReward, pendingDAppReward) = 
            votingType.claimVoteReward(_claimer, _voterProposals);

        if (pendingGBTReward != 0) {
            gbt.transfer(_claimer, pendingGBTReward);
        }
        if (pendingDAppReward != 0) {
            dAppToken.transfer(_claimer, pendingDAppReward);
        }

        gov.callRewardClaimed(
            _claimer,
            _voterProposals,
            pendingGBTReward, 
            pendingDAppReward, 
            pendingReputation
        );
    }

    /// @dev Transfer Ether to someone    
    /// @param _amount Amount to be transferred back
    /// @param _receiverAddress address where ether has to be sent
    function transferEther(address _receiverAddress, uint256 _amount) public onlyAuthorizedToGovern {
        _receiverAddress.transfer(_amount);
    }

    /// @dev Transfer token to someone    
    /// @param _amount Amount to be transferred back
    /// @param _receiverAddress address where tokens have to be sent
    /// @param _token address of token to transfer
    function transferToken(address _token, address _receiverAddress, uint256 _amount) public onlyAuthorizedToGovern {
        GBTStandardToken token = GBTStandardToken(_token);
        token.transfer(_receiverAddress, _amount);
    }

}