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
import "./GovernanceData.sol";
import "./Governance.sol";
import "./MemberRoles.sol";
import "./Upgradeable.sol";
import "./GBTStandardToken.sol";
import "./ProposalCategory.sol";
import "./GovBlocksMaster.sol";
import "./Pool.sol";
import 'openzeppelin-solidity/contracts/math/Math.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import "./EventCaller.sol";
import "./Governed.sol";

contract SimpleVoting is Upgradeable {
    using SafeMath for uint;
    GBTStandardToken internal gbt;
    GovernanceData internal governanceDat;
    MemberRoles internal memberRole;
    Governance internal governance;
    ProposalCategory internal proposalCategory;
    Master internal master;
    address internal govAddress;
    bool public constructorCheck;
    address public masterAddress;
    GBTStandardToken internal basicToken;
    Pool internal pool;
    EventCaller internal eventCaller;
    GovernChecker internal governChecker;
    bytes32 public votingTypeName;

    modifier onlyMaster {
        require(msg.sender == masterAddress);
        _;
    }

    modifier validateStake(uint _proposalId, uint _stake) {    
        require(proposalCategory.validateStake(_proposalId, _stake));
        _;
    }

    /// @dev Initiates simple voting contract
    function simpleVotingInitiate() public {
        require(!constructorCheck);
        votingTypeName = "Simple Voting";
        constructorCheck = true;
    }

    /// @dev Changes master address
    /// @param _masterContractAddress New master contract address
    function changeMasterAddress(address _masterContractAddress) public {
        if (masterAddress == address(0))
            masterAddress = _masterContractAddress;
        else {
            master = Master(masterAddress);
            require(master.isInternal(msg.sender));
            masterAddress = _masterContractAddress;
        }
    }

    /// @dev updates dependancies
    function updateDependencyAddresses() public {
        if (!constructorCheck)
            simpleVotingInitiate();
        master = Master(masterAddress);
        governanceDat = GovernanceData(master.getLatestAddress("GD"));
        memberRole = MemberRoles(master.getLatestAddress("MR"));
        proposalCategory = ProposalCategory(master.getLatestAddress("PC"));
        govAddress = master.getLatestAddress("GV");
        governance = Governance(govAddress);
        pool = Pool(master.getLatestAddress("PL"));
        gbt = GBTStandardToken(master.getLatestAddress("GS"));
        GovBlocksMaster govBlocksMaster = GovBlocksMaster(master.gbmAddress());
        basicToken = GBTStandardToken(govBlocksMaster.getDappTokenAddress(master.dAppName()));
        eventCaller = EventCaller(govBlocksMaster.eventCaller());
        governChecker = GovernChecker(master.getGovernCheckerAddress());
    }

    /// @dev Changes GBT Standard Token address
    /// @param _gbtAddress New GBT standard token address
    function changeGBTSAddress(address _gbtAddress) public onlyMaster {
        gbt = GBTStandardToken(_gbtAddress);
    }

    /// @dev Initiates add solution 
    /// @param _memberAddress Address of member who is adding the solution
    /// @param _solutionStake Stake in GBT against adding solution
    /// @param _solutionHash Solution hash having required data against adding solution
    function addSolution(
        uint _proposalId,
        address _memberAddress, 
        uint _solutionStake, 
        string _solutionHash, 
        uint _validityUpto, 
        bytes _action
    ) 
        public 
        validateStake(_proposalId, _solutionStake) 
    {
        master = Master(masterAddress);
        require(master.isInternal(msg.sender) || msg.sender == _memberAddress);
        require(!alreadyAdded(_proposalId, _memberAddress));
        // if(msg.sender == _memberAddress) 
        //     receiveStake('S',_proposalId,_solutionStake,_validityUpto,_v,_r,_s,_lockTokenTxHash);
        addSolution1(
            _proposalId, 
            _memberAddress, 
            _solutionStake, 
            _solutionHash, 
            _validityUpto, 
            _action
        );

    }

    /// @dev Adds solution
    /// @param _proposalId Proposal id
    /// @param _solutionStake Stake put by the member when providing a solution
    /// @param _solutionHash Solution hash
    function initiateAddSolution(
        uint _proposalId, 
        uint _solutionStake, 
        string _solutionHash, 
        uint _validityUpto, 
        bytes _action
    ) 
        public 
    {
        addSolution(
            _proposalId, 
            msg.sender, 
            _solutionStake, 
            _solutionHash, 
            _validityUpto, 
            _action
        );
    }

    /// @dev Creates proposal for voting
    /// @param _proposalId Proposal id
    /// @param _solutionChosen solution chosen while voting
    /// @param _voteStake Amount payable in GBT tokens
    function proposalVoting(
        uint32 _proposalId,  
        uint64[] _solutionChosen, 
        uint _voteStake,
        uint _validityUpto
    ) 
        external
    {
        //uint64[] memory solutionChosen = _solutionChosen;
        uint8 categoryThenMRSequence;
        uint8 intermediateVerdict;
        uint32 proposalId = _proposalId;
        uint currentVotingIdThenVoteValue;
        (categoryThenMRSequence, currentVotingIdThenVoteValue, intermediateVerdict) 
            = governanceDat.getProposalDetailsForSV(msg.sender, proposalId);
        categoryThenMRSequence = proposalCategory.getMRSequenceBySubCat(categoryThenMRSequence, currentVotingIdThenVoteValue);
        require(memberRole.checkRoleIdByAddress(msg.sender, categoryThenMRSequence));
        if (currentVotingIdThenVoteValue == 0)
            require(_solutionChosen[0] <= governanceDat.getTotalSolutions(proposalId));
        else
            require(_solutionChosen[0] == intermediateVerdict || _solutionChosen[0] == 0);
        if (_voteStake != 0)
            receiveStake("V", proposalId, _voteStake, _validityUpto);
        currentVotingIdThenVoteValue = getVoteValueGivenByMember(msg.sender, _voteStake);
        governanceDat.addVote(
            msg.sender, 
            _solutionChosen, 
            _voteStake, 
            currentVotingIdThenVoteValue, 
            proposalId, 
            categoryThenMRSequence
        );
        if(governanceDat.getAllVoteIdsLengthByProposalRole(proposalId, categoryThenMRSequence) 
            == memberRole.getAllMemberLength(categoryThenMRSequence) 
            && categoryThenMRSequence != 2
            && categoryThenMRSequence != 0
        ) {
            eventCaller.callVoteCast(proposalId);
        }
    }

    /// @dev Checks if the solution is already added by a member against specific proposal
    /// @param _proposalId Proposal id
    /// @param _memberAddress Member address
    function alreadyAdded(uint _proposalId, address _memberAddress) public view returns(bool) {
        for (uint i = 0; i < governanceDat.getTotalSolutions(_proposalId); i++) {
            if (governanceDat.getSolutionAddedByProposalId(_proposalId, i) == _memberAddress)
                return true;
        }
    }

    /*/// @dev Returns true if the member passes all the checks to vote. i.e. If he is authorize to vote
    function validateMember(uint _proposalId, uint64[] _solutionChosen) public view returns(bool) {
        uint8 mrSequence;
        uint8 category;
        uint currentVotingId;
        uint intermediateVerdict;
        (category, currentVotingId, intermediateVerdict) = governanceDat.getProposalDetailsForSV(msg.sender, _proposalId);
        mrSequence = proposalCategory.getMRSequenceBySubCat(category, currentVotingId);
        require(
            memberRole.checkRoleIdByAddress(msg.sender, mrSequence) 
            && _solutionChosen.length == 1
            && !governanceDat.checkVoteIdAgainstMember(msg.sender, _proposalId)
        );

        if (currentVotingId == 0)
            require(_solutionChosen[0] <= governanceDat.getTotalSolutions(_proposalId));
        else
            require(_solutionChosen[0] == intermediateVerdict || _solutionChosen[0] == 0);

        return true;
    }
    */
    /// @dev gets dApp name 
    function dAppName() public view returns (bytes32) {
        return master.dAppName();
    }

    /// @dev checks for closing of proposal
    function checkForClosing(uint _proposalId) public view returns(uint) {
        uint8 category = proposalCategory.getCategoryIdBySubId(governanceDat.getProposalCategory(_proposalId));
        uint8 currentVotingId = governanceDat.getProposalCurrentVotingId(_proposalId);
        uint32 _mrSequenceId = proposalCategory.getRoleSequencAtIndex(category, currentVotingId);

        return governance.checkForClosing(_proposalId, _mrSequenceId);
    }

    /// @dev Sets vote value given by member
    // TODO Need to devise a new formula
    function getVoteValueGivenByMember(address _memberAddress, uint _memberStake)  
        public
        view 
        returns(uint finalVoteValue) 
    {   
        uint stakeWeight;
        uint bonusStake;
        uint reputationWeight;
        uint bonusReputation;
        uint memberReputation;
        (stakeWeight, bonusStake, reputationWeight, bonusReputation, memberReputation) 
            = governanceDat.getMemberReputationSV(_memberAddress);
        _memberStake = SafeMath.div(_memberStake, gbt.decimals());
        stakeWeight = SafeMath.mul(SafeMath.add(log(_memberStake), bonusStake), stakeWeight);
        reputationWeight = SafeMath.mul(SafeMath.add(log(memberReputation), bonusReputation), reputationWeight);
        finalVoteValue = SafeMath.add(stakeWeight, reputationWeight);
    }

    /// @dev Closes Proposal Voting after All voting layers done with voting or Time out happens.
    function closeProposalVote(uint _proposalId) public {
        uint256 totalVoteValue = 0;
        uint8 category = proposalCategory.getCategoryIdBySubId(governanceDat.getProposalCategory(_proposalId));
        uint8 currentVotingId = governanceDat.getProposalCurrentVotingId(_proposalId);
        uint8 i;
        uint8 max = 0;

        uint32 _mrSequenceId = proposalCategory.getRoleSequencAtIndex(category, currentVotingId);

        require(governance.checkForClosing(_proposalId, _mrSequenceId) == 1);
        uint[] memory finalVoteValue = new uint[](governanceDat.getTotalSolutions(_proposalId));
        for (i = 0; i < governanceDat.getAllVoteIdsLengthByProposalRole(_proposalId, _mrSequenceId); i++) {
            uint voteId = governanceDat.getVoteIdAgainstProposalRole(_proposalId, _mrSequenceId, i);
            uint solutionChosen = governanceDat.getSolutionByVoteIdAndIndex(voteId, 0);
            uint voteValue = governanceDat.getVoteValue(voteId);
            totalVoteValue = totalVoteValue + voteValue;
            finalVoteValue[solutionChosen] = finalVoteValue[solutionChosen] + voteValue;
        }

        for (i = 0; i < finalVoteValue.length; i++) {
            if (finalVoteValue[max] < finalVoteValue[i]) {
                max = i;
            }
        }

        if (checkForThreshold(_proposalId, _mrSequenceId)) {
            closeProposalVote1(finalVoteValue[max], totalVoteValue, category, _proposalId, max);
        } else {
            uint8 interVerdict = governanceDat.getProposalIntermediateVerdict(_proposalId);

            governance.updateProposalDetails(_proposalId, currentVotingId, max, interVerdict);
            if (governanceDat.getProposalCurrentVotingId(_proposalId) + 1 
                < proposalCategory.getRoleSequencLength(category)
            )
                governanceDat.changeProposalStatus(_proposalId, 7);
            else
                governanceDat.changeProposalStatus(_proposalId, 6);
            governance.changePendingProposalStart();
        }
    }

    /// @dev Gives rewards to respective members after final decision
    function giveRewardAfterFinalDecision(uint _proposalId) internal {
        uint   totalReward;
        address  ownerAddress;
        uint  depositedTokens;
        uint finalVerdict = governanceDat.getProposalFinalVerdict(_proposalId);
        if (finalVerdict == 0) {
            ownerAddress = governanceDat.getProposalOwner(_proposalId);
            depositedTokens = governanceDat.getDepositedTokens(ownerAddress, _proposalId, "P");
            totalReward = SafeMath.add(totalReward, depositedTokens);
        }    

        for (uint i = 0; i < governanceDat.getTotalSolutions(_proposalId); i++) {
            if (i != finalVerdict) {
                ownerAddress = governanceDat.getSolutionAddedByProposalId(_proposalId, i);
                depositedTokens = governanceDat.getDepositedTokens(ownerAddress, _proposalId, "S");
                totalReward = SafeMath.add(totalReward, depositedTokens);
            }    
        }
        
        giveRewardAfterFinalDecision1(_proposalId, totalReward, finalVerdict);
    }

    /// @dev This does the remaining functionality of closing proposal vote
    function closeProposalVote1(uint maxVoteValue, uint totalVoteValue, uint8 category, uint _proposalId, uint8 max) 
        internal 
    {
        uint _closingTime;
        uint _majorityVote;
        uint8 currentVotingId = governanceDat.getProposalCurrentVotingId(_proposalId);
        (, _majorityVote, _closingTime) = proposalCategory.getCategoryData3(category, currentVotingId);
        if (SafeMath.div(SafeMath.mul(maxVoteValue, 100), totalVoteValue) >= _majorityVote) {
            if (max > 0) {
                currentVotingId = currentVotingId + 1;
                if (currentVotingId < proposalCategory.getRoleSequencLength(category)) {
                    governance.updateProposalDetails(
                        _proposalId, 
                        currentVotingId, 
                        max, 
                        0
                    );
                    eventCaller.callCloseProposalOnTime(_proposalId, _closingTime + now);
                } else {
                    governance.updateProposalDetails(_proposalId, currentVotingId - 1, max, max);
                    governanceDat.changeProposalStatus(_proposalId, 3);
                    address actionAddress = 
                        proposalCategory.getContractAddress(governanceDat.getProposalCategory(_proposalId));
                    if (actionAddress.call(governanceDat.getSolutionActionByProposalId(_proposalId, max))) {
                        eventCaller.callActionSuccess(_proposalId);
                    }
                    eventCaller.callProposalAccepted(_proposalId);
                    giveRewardAfterFinalDecision(_proposalId);
                }
            } else {
                governance.updateProposalDetails(_proposalId, currentVotingId, max, max);
                governanceDat.changeProposalStatus(_proposalId, 4);
                giveRewardAfterFinalDecision(_proposalId);
                governance.changePendingProposalStart();
            }
        } else {
            governance.updateProposalDetails(
                _proposalId, 
                currentVotingId, 
                max, 
                governanceDat.getProposalIntermediateVerdict(_proposalId)
            );
            governanceDat.changeProposalStatus(_proposalId, 5);
            governance.changePendingProposalStart();
        }

    }

    /// @dev castsVote
    function castVote(uint _voteStake, uint64[] _solutionChosen, uint32 _proposalId, uint32 mrSequence) internal {
        uint finalVoteValue = getVoteValueGivenByMember(msg.sender, _voteStake);
        governanceDat.addVote(msg.sender, _solutionChosen, _voteStake, finalVoteValue, _proposalId, mrSequence);
        if(governanceDat.getAllVoteIdsLengthByProposalRole(_proposalId, mrSequence) 
            == memberRole.getAllMemberLength(mrSequence) 
            && mrSequence != 2
        ) {
            eventCaller.callVoteCast(_proposalId);
        }
    }

    /// @dev Checks if the vote count against any solution passes the threshold value or not.
    function checkForThreshold(uint _proposalId, uint32 _mrSequenceId) internal view returns(bool) {
        uint thresHoldValue;
        if (_mrSequenceId == 2) {
            uint totalTokens;

            for (uint8 i = 0; i < governanceDat.getAllVoteIdsLengthByProposalRole(_proposalId, _mrSequenceId); i++) {
                uint voteId = governanceDat.getVoteIdAgainstProposalRole(_proposalId, _mrSequenceId, i);
                address voterAddress = governanceDat.getVoterAddress(voteId);
                totalTokens = totalTokens + basicToken.balanceOf(voterAddress);
            }

            thresHoldValue = totalTokens * 100 / basicToken.totalSupply();
            if (thresHoldValue > governanceDat.quorumPercentage())
                return true;
        } else if (_mrSequenceId == 0) {
            return true;
        } else {
            thresHoldValue = (governanceDat.getAllVoteIdsLengthByProposalRole(_proposalId, _mrSequenceId) * 100)
                / memberRole.getAllMemberLength(_mrSequenceId);
            if (thresHoldValue > governanceDat.quorumPercentage())
                return true;
        }
    }
    
    /// @dev Distributing reward after final decision
    function giveRewardAfterFinalDecision1(
        uint _proposalId,
        uint totalReward,
        uint _finalVerdict
    ) 
        internal
    {
        uint8 subCategoryThenCategory = governanceDat.getProposalCategory(_proposalId); 
        if (subCategoryThenCategory == 10) {
            upgrade();
        }
        uint totalVoteValue;
        subCategoryThenCategory = proposalCategory.getCategoryIdBySubId(subCategoryThenCategory);
        uint mrLength = proposalCategory.getRoleSequencLength(subCategoryThenCategory);
        for (uint i = 0; i < mrLength; i++) {
            uint roleId = proposalCategory.getRoleSequencAtIndex(subCategoryThenCategory, i);
            uint mrVoteLength = governanceDat.getAllVoteIdsLengthByProposalRole(_proposalId, roleId);
            for (uint j = 0; j < mrVoteLength; j++) {
                uint voteId = governanceDat.getVoteIdAgainstProposalRole(_proposalId, roleId, j);
                (totalReward, totalVoteValue) = giveRewardAfterFinalDecision2(voteId, _proposalId, _finalVerdict, totalReward, totalVoteValue);
            }
        }
        totalReward = totalReward + governanceDat.getProposalIncentive(_proposalId);
        governance.setProposalDetails(_proposalId, totalReward, totalVoteValue);
    }

    /// @dev Distributing reward after final decision
    function giveRewardAfterFinalDecision2(
        uint voteId,
        uint _proposalId,
        uint _finalVerdict,
        uint _totalReward,
        uint _totalVoteValue
    ) 
        internal
        view
        returns (uint, uint)
    {
        address ownerAddress;
        uint depositedTokens;
        uint voteValue;
        bool punishVoters = governanceDat.punishVoters();
        if(governanceDat.getSolutionByVoteIdAndIndex(voteId, 0) != _finalVerdict) {
            ownerAddress = governanceDat.getVoterAddress(voteId);
            depositedTokens = governanceDat.getDepositedTokens(ownerAddress, _proposalId, "V");
            _totalReward = SafeMath.add(_totalReward, depositedTokens);
            if (!punishVoters) {
                voteValue = governanceDat.getVoteValue(voteId);
                _totalVoteValue = SafeMath.add(_totalVoteValue, voteValue);
            }
        } else {
            voteValue = governanceDat.getVoteValue(voteId);
            _totalVoteValue = SafeMath.add(_totalVoteValue, voteValue);
        } 
        return(_totalReward, _totalVoteValue);
    }

    function upgrade() internal {
        address newSV = master.getLatestAddress("GS");
        if (newSV != address(this)) {
            governChecker.updateAuthorized(master.dAppName(), newSV);
        }
        pool.transferAssets();
    } 

    /// @dev Adding member address against solution index and event call to save details of solution
    function addSolution1(
        uint _proposalId, 
        address _memberAddress, 
        uint _solutionStake, 
        string _solutionHash, 
        uint _validityUpto, 
        bytes _action
    ) 
        internal 
    {
        require(governanceDat.getProposalCategory(_proposalId) > 0);
        if (msg.sender == _memberAddress)
            receiveStake("S", _proposalId, _solutionStake, _validityUpto);
        addSolution2(_proposalId, _memberAddress, _action, _solutionHash, _solutionStake);
    }
    
    function addSolution2(
        uint _proposalId, 
        address _memberAddress, 
        bytes _action, 
        string _solutionHash, 
        uint _solutionStake
    ) 
        internal 
    {
        governanceDat.setSolutionAdded(_proposalId, _memberAddress, _action);
        uint solutionId = governanceDat.getTotalSolutions(_proposalId);
        governanceDat.callSolutionEvent(_proposalId, msg.sender, solutionId - 1, _solutionHash, _dateAdd, _solutionStake);
    }

    /// @dev Receives solution stake against solution in simple voting i.e. Deposit and lock the tokens
    function receiveStake(
        bytes2 _type, 
        uint _proposalId, 
        uint _stake, 
        uint _validityUpto
    ) 
        internal 
    {
        if (_stake != 0) {
            require(proposalCategory.validateStake(_proposalId, _stake));
            uint8 currVotingId = governanceDat.getProposalCurrentVotingId(_proposalId);
            uint depositPerc = governanceDat.depositPercVote();
            uint category = proposalCategory.getCatIdByPropId(_proposalId);
            require(_validityUpto >= proposalCategory.getRemainingClosingTime(_proposalId, category, currVotingId));
            if (depositPerc != 0) {
                uint deposit = SafeMath.div(SafeMath.mul(_stake, depositPerc), 100);
                uint depositedTokens;
                uint depositAmount;
                //require(pool.putDeposit(msg.sender, deposit));
                require(pool.putDeposit(msg.sender, deposit));
                depositedTokens = governanceDat.getDepositedTokens(msg.sender, _proposalId, _type);
                depositAmount = deposit + depositedTokens;
                governanceDat.setDepositTokens(msg.sender, _proposalId, _type, depositAmount);
            }
        }
    }

    ///@dev calculates log2
    function log(uint x) public pure returns (uint y) {
        assembly {
            let arg := x
            x := sub(x,1)
            x := or(x, div(x, 0x02))
            x := or(x, div(x, 0x04))
            x := or(x, div(x, 0x10))
            x := or(x, div(x, 0x100))
            x := or(x, div(x, 0x10000))
            x := or(x, div(x, 0x100000000))
            x := or(x, div(x, 0x10000000000000000))
            x := or(x, div(x, 0x100000000000000000000000000000000))
            x := add(x, 1)
            let m := mload(0x40)
            mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
            mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
            mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
            mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
            mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
            mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
            mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
            mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
            mstore(0x40, add(m, 0x100))
            let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
            let shift := 0x100000000000000000000000000000000000000000000000000000000000000
            let a := div(mul(x, magic), shift)
            y := div(mload(add(m,sub(255,a))), shift)
            y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
        }  
    }
}
