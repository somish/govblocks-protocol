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

pragma solidity ^ 0.4.8;
import "./governanceData.sol";
import "./ProposalCategory.sol";
import "./memberRoles.sol";
import "./Upgradeable.sol";
import "./Master.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./Pool.sol";
import "./GBTStandardToken.sol";
import "./VotingType.sol";

contract Governance is Upgradeable{

    using SafeMath for uint;
    address P1Address;
    address masterAddress;
    GBTStandardToken GBTS;
    Master MS;
    memberRoles MR;
    ProposalCategory PC;
    governanceData GD;
    Pool P1;
    VotingType VT;

    modifier onlyInternal {
        MS = Master(masterAddress);
        require(MS.isInternal(msg.sender));
        _;
    }

    modifier onlyOwner {
        MS = Master(masterAddress);
        require(MS.isOwner(msg.sender));
        _;
    }

    modifier onlyMaster {
        require(msg.sender == masterAddress);
        _;
    }

    modifier onlyProposalOwner(uint _proposalId) {
        require(msg.sender == GD.getProposalOwner(_proposalId));
        _;
    }

    modifier checkProposalValidity(uint _proposalId) {
        require(GD.getProposalStatus(_proposalId) < 2);
        _;
    }

    modifier validateStake(uint8 _categoryId, uint _proposalStake) {
        uint _Stake = _proposalStake / (10 ** GBTS.decimals());
        uint category = PC.getCategoryId_bySubId(_categoryId);
        require(_Stake <= PC.getMaxStake(category) && _Stake >= PC.getMinStake(category));
        _;
    }


    /// @dev updates all dependency addresses to latest ones from Master
    function updateDependencyAddresses() onlyInternal {
        MS = Master(masterAddress);
        GD = governanceData(MS.getLatestAddress("GD"));
        MR = memberRoles(MS.getLatestAddress("MR"));
        PC = ProposalCategory(MS.getLatestAddress("PC"));
        P1Address = MS.getLatestAddress("PL");
        P1 = Pool(P1Address);
    }

    /// @dev Changes GBT standard token address
    /// @param _GBTSAddress New GBT standard token address
    function changeGBTSAddress(address _GBTSAddress) onlyMaster {
        GBTS = GBTStandardToken(_GBTSAddress);
    }

    /// @dev Changes master address
    /// @param _MasterAddress New master address
    function changeMasterAddress(address _MasterAddress) {
        if (masterAddress == 0x000)
            masterAddress = _MasterAddress;
        else {
            MS = Master(masterAddress);
            require(MS.isInternal(msg.sender));
            masterAddress = _MasterAddress;
        }
    }

    /// @dev Creates a new proposal
    /// @param _proposalDescHash Proposal description hash
    /// @param _votingTypeId Voting type id
    /// @param _categoryId Category id
    /// @param _dateAdd Date the proposal was added
    function createProposal(string _proposalTitle, string _proposalSD, string _proposalDescHash, uint _votingTypeId, uint8 _categoryId, uint _dateAdd) public {
        address votingAddress = GD.getVotingTypeAddress(_votingTypeId);
        uint8 category = PC.getCategoryId_bySubId(_categoryId);
        uint _proposalId = GD.getProposalLength();
        GD.callProposalEvent(msg.sender, _proposalId, now, _proposalTitle, _proposalSD, _proposalDescHash);
        if (_categoryId > 0) {
            GD.addNewProposal(_proposalId, msg.sender, _categoryId, votingAddress, _dateAdd);
            uint incentive=PC.getCatIncentive(category);
            GD.setProposalIncentive(_proposalId,incentive );
        } else
            GD.createProposal1(_proposalId, msg.sender, votingAddress, now);
    }

    /// @dev Creates a new proposal (Stake in ether)
    /// @param _proposalDescHash Proposal description hash
    /// @param _votingTypeId Voting type id
    /// @param _categoryId Category id
    /// @param _solutionHash Solution hash
    // function createProposalwithSolution_inEther(string _proposalTitle, string _proposalSD, string _proposalDescHash, uint _votingTypeId, uint8 _categoryId, string _solutionHash, uint _validityUpto, uint8 _v, bytes32 _r, bytes32 _s, bytes32 _lockTokenTxHash) payable {
    //     uint tokenAmount = GBTS.buyToken.value(msg.value)();
    //     createProposalwithSolution(_proposalTitle, _proposalSD, _proposalDescHash, _votingTypeId, _categoryId, tokenAmount, _solutionHash, _validityUpto, _v, _r, _s, _lockTokenTxHash);
    // }

    /// @dev Creates a new proposal
    /// @param _proposalDescHash Proposal description hash
    /// @param _votingTypeId Voting type id
    /// @param _categoryId Category id
    /// @param _proposalSolutionStake Proposal solution stake
    /// @param _solutionHash Solution hash
    function createProposalwithSolution(string _proposalTitle, string _proposalSD, string _proposalDescHash, uint _votingTypeId, uint8 _categoryId, uint _proposalSolutionStake, string _solutionHash, uint _validityUpto, uint8 _v, bytes32 _r, bytes32 _s, bytes32 _lockTokenTxHash) public {
        uint proposalDateAdd = now;
        uint _proposalId = GD.getProposalLength();
        address VTAddress = GD.getVotingTypeAddress(_votingTypeId);
        createProposal(_proposalTitle, _proposalSD, _proposalDescHash, _votingTypeId, _categoryId, proposalDateAdd);
        proposalSubmission(proposalDateAdd, _proposalId, VTAddress, _categoryId, _proposalSolutionStake, _solutionHash, _validityUpto, _v, _r, _s, _lockTokenTxHash);
    }

    /// @dev Submit proposal with solution (Stake in ether)
    /// @param _proposalId Proposal id
    /// @param _solutionHash Solution hash
    // function submitProposalWithSolution_inEther(uint _proposalId, string _solutionHash, uint _validityUpto, uint8 _v, bytes32 _r, bytes32 _s, bytes32 _lockTokenTxHash) payable {
    //     uint tokenAmount = GBTS.buyToken.value(msg.value)();
    //     submitProposalWithSolution(_proposalId, tokenAmount, _solutionHash, _validityUpto, _v, _r, _s, _lockTokenTxHash);
    // }

    /// @dev Submit proposal with solution
    /// @param _proposalId Proposal id
    /// @param _proposalSolutionStake Proposal solution stake
    /// @param _solutionHash Solution hash
    function submitProposalWithSolution(uint _proposalId, uint _proposalSolutionStake, string _solutionHash, uint _validityUpto, uint8 _v, bytes32 _r, bytes32 _s, bytes32 _lockTokenTxHash) public onlyProposalOwner(_proposalId) {
        uint proposalDateAdd = GD.getProposalDateUpd(_proposalId);
        address VTAddress = GD.getProposalVotingType(_proposalId);
        proposalSubmission(proposalDateAdd, _proposalId, VTAddress, 0, _proposalSolutionStake, _solutionHash, _validityUpto, _v, _r, _s, _lockTokenTxHash);
    }

    /// @dev Categorizes proposal to proceed further. _reward is the company's incentive to distribute to end members
    /// @param _proposalId Proposal id
    /// @param _categoryId Category id
    /// @param _dappIncentive It is the company's incentive to distribute to end members
    function categorizeProposal(uint _proposalId, uint8 _categoryId, uint _dappIncentive) public checkProposalValidity(_proposalId) {
        require(MR.checkRoleId_byAddress(msg.sender, MR.getAuthorizedMemberId()));
        require(_dappIncentive <= GBTS.balanceOf(P1Address));

        GD.setProposalIncentive(_proposalId, _dappIncentive);
        GD.setProposalCategory(_proposalId, _categoryId);
    }

    /// @dev Submit proposal for voting while giving stake in Ether.
    /// @param  _proposalId Proposal id
    /// @param  _categoryId Proposal category id
    // function openProposalForVoting_inEther(uint _proposalId, uint8 _categoryId, uint _validityUpto, uint8 _v, bytes32 _r, bytes32 _s, bytes32 _lockTokenTxHash) payable {
    //     uint tokenAmount = GBTS.buyToken.value(msg.value)();
    //     openProposalForVoting(_proposalId, _categoryId, tokenAmount, _validityUpto, _v, _r, _s, _lockTokenTxHash);
    // }

    /// @dev Proposal's complexity level and reward are added
    /// @param  _proposalId Proposal id
    /// @param  _categoryId Proposal category id
    /// @param  _proposalStake Token amount
    function openProposalForVoting(uint _proposalId, uint8 _categoryId, uint _proposalStake, uint _validityUpto, uint8 _v, bytes32 _r, bytes32 _s, bytes32 _lockTokenTxHash) public validateStake(_categoryId, _proposalStake) onlyProposalOwner(_proposalId) checkProposalValidity(_proposalId) {
        uint8 category = PC.getCategoryId_bySubId(_categoryId);
        require(category != 0);
        openProposalForVoting2(_proposalId, category, _proposalStake, _validityUpto, _v, _r, _s, _lockTokenTxHash);

    }

    function openProposalForVoting2(uint _proposalId, uint8 _categoryId, uint _proposalStake, uint validityUpto, uint8 _v, bytes32 _r, bytes32 _s, bytes32 _lockTokenTxHash) internal {
        uint depositPerc = GD.depositPercProposal();
        uint _currVotingStatus = GD.getProposalCurrentVotingId(_proposalId);
        uint proposalDepositPerc=GD.depositPercProposal();
        uint depositAmount = SafeMath.div(SafeMath.mul(_proposalStake,proposalDepositPerc), 100);

        if (_proposalStake != 0) {
            require(validityUpto > PC.getRemainingClosingTime(_proposalId, _categoryId, _currVotingStatus));
            if (depositPerc != 0 && depositPerc != 100) {
                uint stake= SafeMath.sub(_proposalStake, depositAmount);
                GBTS.lockToken(msg.sender,stake, validityUpto, _v, _r, _s, _lockTokenTxHash);
                GD.setDepositTokens(msg.sender, _proposalId, 'P', depositAmount);
            } else if (depositPerc == 100)
                GD.setDepositTokens(msg.sender, _proposalId, 'P', _proposalStake);
            else
                GBTS.lockToken(msg.sender, _proposalStake, validityUpto, _v, _r, _s, _lockTokenTxHash);
        }

        GD.changeProposalStatus(_proposalId, 2);
        callOraclize(_proposalId);
        GD.callProposalStakeEvent(msg.sender, _proposalId, now, _proposalStake);
    }

    /// @dev Call oraclize for closing proposal
    /// @param _proposalId Proposal id
    function callOraclize(uint _proposalId) internal {
        uint _categoryId = PC.getCategoryId_bySubId(GD.getProposalCategory(_proposalId));
        uint closingTime = SafeMath.add(PC.getClosingTimeAtIndex(_categoryId, 0), GD.getProposalDateUpd(_proposalId));
        P1.closeProposalOraclise(_proposalId, closingTime);
        GD.callOraclizeCallEvent(_proposalId, GD.getProposalDateUpd(_proposalId), closingTime);
    }

    /// @dev Edits a proposal and only owner of a proposal can edit it
    /// @param _proposalId Proposal id
    /// @param _proposalDescHash Proposal description hash
    // function editProposal(uint _proposalId, string _proposalTitle, string _proposalSD, string _proposalDescHash) public onlyProposalOwner(_proposalId) {
    //     updateProposalDetails1(_proposalId, _proposalTitle, _proposalSD, _proposalDescHash);
    //     uint _categoryId = PC.getCategoryId_bySubId(GD.getProposalCategory(_proposalId));
    //     if (_categoryId > 0)
    //         GD.setProposalCategory(_proposalId, 0);
    // }

    /// @dev Edits the details of an existing proposal and creates new version
    /// @param _proposalId Proposal id
    /// @param _proposalDescHash Proposal description hash
    function updateProposalDetails1(uint _proposalId, string _proposalTitle, string _proposalSD, string _proposalDescHash) internal {
        GD.storeProposalVersion(_proposalId, _proposalDescHash);
        GD.setProposalDateUpd(_proposalId);
        GD.changeProposalStatus(_proposalId, 1);
        GD.callProposalEvent(GD.getProposalOwner(_proposalId), _proposalId, now, _proposalTitle, _proposalSD, _proposalDescHash);
    }

    /*/// @dev Checks proposal for vote closing
    /// @param _proposalId Proposal id
    /// @param _roleId Role id
    function checkProposalVoteClosing(uint _proposalId, uint32 _roleId) onlyInternal constant returns(uint8 closeValue) {
        closeValue = checkForClosing(_proposalId, _roleId);
    }*/

    /// @dev Checks proposal for vote closing
    /// @param _proposalId Proposal id
    /// @param _roleId Role id
    function checkForClosing(uint _proposalId, uint32 _roleId)  constant returns(uint8 closeValue) {
        uint dateUpdate;
        uint pStatus;
        uint _closingTime;
        uint _majorityVote;
        (, , dateUpdate, , pStatus) = GD.getProposalDetailsById1(_proposalId);
        uint _categoryId = PC.getCategoryId_bySubId(GD.getProposalCategory(_proposalId));
        (, _closingTime, _majorityVote) = PC.getCategoryData3(_categoryId, GD.getProposalCurrentVotingId(_proposalId));

        if (pStatus == 2 && _roleId != 2) {
            if (SafeMath.add(dateUpdate, _closingTime) <= now || GD.getAllVoteIdsLength_byProposalRole(_proposalId, _roleId) == MR.getAllMemberLength(_roleId))
                closeValue = 1;
        } else if (pStatus == 2) {
            if (SafeMath.add(dateUpdate, _closingTime) <= now)
                closeValue = 1;
        } else if (pStatus > 2) {
            closeValue = 2;
        } else {
            closeValue = 0;
        }
    }

    /// @dev Checks role for vote closing
    /// @param _proposalId Proposal id
    /// @param _roleId Role id
    function checkRoleVoteClosing(uint _proposalId, uint32 _roleId) onlyInternal {
        if (checkForClosing(_proposalId, _roleId) == 1){
            P1.closeProposalOraclise(_proposalId, 0);
            GD.callOraclizeCallEvent(_proposalId, GD.getProposalDateUpd(_proposalId), 0);
        }
    }

    /// @dev Changes pending proposal start variable
    function changePendingProposalStart() onlyInternal {
        uint pendingPS = GD.pendingProposalStart();
        for (uint j = pendingPS; j < GD.getProposalLength(); j++) {
            if (GD.getProposalStatus(j) > 3)
                pendingPS = SafeMath.add(pendingPS, 1);
            else
                break;
        }
        if (j != pendingPS) {
            GD.changePendingProposalStart(j);
        }
    }

    /// @dev Updates proposal's major details (Called from close proposal vote)
    /// @param _proposalId Proposal id
    /// @param _currVotingStatus Current voting status
    /// @param _intermediateVerdict Intermediate verdict
    /// @param _finalVerdict Final verdict
    function updateProposalDetails(uint _proposalId, uint8 _currVotingStatus, uint8 _intermediateVerdict, uint8 _finalVerdict) onlyInternal {
        GD.setProposalCurrentVotingId(_proposalId, _currVotingStatus);
        GD.setProposalIntermediateVerdict(_proposalId, _intermediateVerdict);
        GD.setProposalFinalVerdict(_proposalId, _finalVerdict);
        GD.setProposalDateUpd(_proposalId);
    }

    /// @dev Updating proposal details after reward being distributed
    /// @param _proposalId Proposal id
    /// @param _totalRewardToDistribute Total reward to be distributed
    /// @param _totalVoteValue Total vote value not favourable to the solution to the proposal 
    function setProposalDetails(uint _proposalId, uint _totalRewardToDistribute, uint _totalVoteValue) onlyInternal {
        GD.setProposalTotalReward(_proposalId, _totalRewardToDistribute);
        GD.setProposalTotalVoteValue(_proposalId, _totalVoteValue);
    }

    function calculateProposalReward(address _memberAddress, uint _lastRewardProposalId) internal constant returns(uint tempfinalRewardToDistribute) {
        uint allProposalLength = GD.getProposalLength();
        uint lastIndex = 0;
        uint category;
        uint finalVredict;
        uint proposalStatus;
        uint calcReward;
        uint32 addProposalOwnerPoints;
        (addProposalOwnerPoints, , , , , ) = GD.getMemberReputationPoints();

        for (uint i = _lastRewardProposalId; i < allProposalLength; i++) {
            if (_memberAddress == GD.getProposalOwner(i)) {
                (, , category, proposalStatus, finalVredict) = GD.getProposalDetailsById3(i);
                if (proposalStatus < 2)
                    lastIndex = i;
                else if (proposalStatus > 2 && finalVredict > 0 && GD.getReturnedTokensFlag(_memberAddress, i, 'P') == 0) {
                    calcReward = (PC.getRewardPercProposal(category) * GD.getProposalTotalReward(i)) / 100;
                    tempfinalRewardToDistribute = tempfinalRewardToDistribute + calcReward + GD.getDepositedTokens(_memberAddress, i, 'P');
                    calculateProposalReward1(_memberAddress, i, calcReward, addProposalOwnerPoints);
                }
            }
        }

        if (lastIndex == 0)
            lastIndex = i;
        GD.setLastRewardId_ofCreatedProposals(_memberAddress, lastIndex);
    }

    function calculateProposalReward1(address _memberAddress, uint i, uint calcReward, uint32 addProposalOwnerPoints) internal {
        GD.callRewardEvent(_memberAddress, i, "GBT Reward for being Proposal owner - Accepted ", calcReward);
        GD.setMemberReputation("Reputation credit for proposal owner - Accepted", i, _memberAddress, SafeMath.add32(GD.getMemberReputation(_memberAddress), addProposalOwnerPoints), addProposalOwnerPoints, "C");
        GD.setReturnedTokensFlag(_memberAddress, i, 'P', 1);
    }

    function calculateSolutionReward(address _memberAddress, uint _lastRewardSolutionProposalId) internal constant returns(uint tempfinalRewardToDistribute) {
        uint allProposalLength = GD.getProposalLength();
        uint calcReward;
        uint lastIndex = 0;
        uint i;
        uint proposalStatus;
        uint finalVerdict;
        uint solutionId;
        uint proposalId;
        uint totalReward;
        uint category;
        uint addSolutionOwnerPoints;
        (addSolutionOwnerPoints, , , , , ) = GD.getMemberReputationPoints();

        for (i = _lastRewardSolutionProposalId; i < allProposalLength; i++) {
            (proposalId, solutionId, proposalStatus, finalVerdict, totalReward, category) = getSolutionId_againstAddressProposal(_memberAddress, i);
            if (proposalId == i) {
                if (proposalStatus < 2)
                    lastIndex = i;
                if (finalVerdict > 0 && finalVerdict == solutionId)
                    tempfinalRewardToDistribute = tempfinalRewardToDistribute + calculateSolutionReward1(_memberAddress, i, calcReward, totalReward, category, proposalId);
            }
        }

        if (lastIndex == 0)
            lastIndex = i;
        GD.setLastRewardId_ofSolutionProposals(_memberAddress, lastIndex);
    }

    function calculateSolutionReward1(address _memberAddress, uint i, uint calcReward, uint totalReward, uint category, uint proposalId) internal constant returns(uint tempfinalRewardToDistribute) {
        if (GD.getReturnedTokensFlag(_memberAddress, proposalId, 'S') == 0) {
            uint32 addSolutionOwnerPoints;
            (addSolutionOwnerPoints, , , , , ) = GD.getMemberReputationPoints();
            calcReward = (PC.getRewardPercSolution(category) * totalReward) / 100;
            tempfinalRewardToDistribute = calcReward + GD.getDepositedTokens(_memberAddress, i, 'S');
            GD.callRewardEvent(_memberAddress, i, "GBT Reward earned for being Solution owner - Final Solution by majority voting", calcReward);
            GD.setMemberReputation("Reputation credit for solution owner - Final Solution selected by majority voting", i, _memberAddress, SafeMath.add32(GD.getMemberReputation(_memberAddress), addSolutionOwnerPoints), addSolutionOwnerPoints, "C");
            GD.setReturnedTokensFlag(_memberAddress, i, 'S', 1);
        }
    }
    
    function calculateVoteReward(address _memberAddress, uint _lastRewardVoteId) internal constant returns(uint tempfinalRewardToDistribute) {
        uint allProposalLength = GD.getProposalLength();
        uint calcReward;
        uint lastIndex = 0;
        uint i;
        uint solutionChosen;
        uint proposalStatus;
        uint finalVredict;
        uint voteValue;
        uint totalReward;
        uint category;

        for (i = _lastRewardVoteId; i < allProposalLength; i++) {
            (solutionChosen, proposalStatus, finalVredict, voteValue, totalReward, category, ) = getVoteDetails_toCalculateReward(_memberAddress, i);
            uint returnedTokensFlag = GD.getReturnedTokensFlag(_memberAddress, i, 'V');
            if (proposalStatus < 2)
                lastIndex = i;

            if (finalVredict > 0 && solutionChosen == finalVredict && returnedTokensFlag == 0) {
                calcReward = (PC.getRewardPercVote(category) * totalReward * voteValue) / (100 * GD.getProposalTotalReward(i));
                tempfinalRewardToDistribute = tempfinalRewardToDistribute + calcReward + GD.getDepositedTokens(_memberAddress, i, 'V');
                GD.callRewardEvent(_memberAddress, i, "GBT Reward earned for voting in favour of final Solution", calcReward);
                GD.setReturnedTokensFlag(_memberAddress, i, 'V', 1);
            }
        }
        if (lastIndex == 0)
            lastIndex = i;
        GD.setLastRewardId_ofVotes(_memberAddress, lastIndex);
    }


    /// @dev Gets vote details to calculate reward
    /// @param _memberAddress Member address
    /// @param _proposalId Proposal id
    /// @return solutionChosen Solution chosen
    /// @return proposalStatus Proposal status
    /// @return finalVerdict Final verdict of the solution
    /// @return voteValue Vote value
    /// @return totalReward Total reward
    /// @return category Category 
    /// @return totalVoteValueProposal Total vote value of proposal
    function getVoteDetails_toCalculateReward(address _memberAddress, uint _proposalId) internal constant returns(uint solutionChosen, uint proposalStatus, uint finalVerdict, uint voteValue, uint totalReward, uint category, uint totalVoteValueProposal) {
        uint voteId = GD.getVoteId_againstMember(_memberAddress, _proposalId);
        solutionChosen = GD.getSolutionByVoteIdAndIndex(voteId, 0);
        proposalStatus = GD.getProposalStatus(_proposalId);
        finalVerdict = GD.getProposalFinalVerdict(_proposalId);
        voteValue = GD.getVoteValue(voteId);
        totalReward = GD.getProposalTotalReward(_proposalId);
        category = PC.getCategoryId_bySubId(GD.getProposalCategory(_proposalId));
        totalVoteValueProposal = GD.getProposalTotalVoteValue(_proposalId);
    }

    // VERSION 2.0 USER DETAILS :

    /// @dev Calculates member reward to be claimed
    /// @param _memberAddress Member address
    /// @return rewardToClaim Rewards to be claimed
    function calculateMemberReward(address _memberAddress) constant returns(uint tempFinalRewardToDistribute) {
        uint lastRewardProposalId;
        uint lastRewardSolutionProposalId;
        uint lastRewardVoteId;
        (lastRewardProposalId, lastRewardSolutionProposalId, lastRewardVoteId) = GD.getAllidsOfLastReward(_memberAddress);

        tempFinalRewardToDistribute = calculateProposalReward(_memberAddress, lastRewardProposalId) + calculateSolutionReward(_memberAddress, lastRewardSolutionProposalId) + calculateVoteReward(_memberAddress, lastRewardVoteId);
    }

    /// @dev Gets member details
    /// @param _memberAddress Member address
    /// @return memberReputation Member reputation
    /// @return totalProposal Total number of proposals
    /// @return totalSolution Total solution
    /// @return totalVotes Total number of votes
    function getMemberDetails(address _memberAddress) constant returns(uint memberReputation, uint totalProposal, uint totalSolution, uint totalVotes) {
        memberReputation = GD.getMemberReputation(_memberAddress);
        totalProposal = getAllProposalIdsLength_byAddress(_memberAddress);
        totalSolution = GD.getAllSolutionIdsLength_byAddress(_memberAddress);
        totalVotes = getAllVoteIdsLength_byAddress(_memberAddress);
    }

    /// @dev Gets total number of vote casted of a member
    /// @param _memberAddress Member address
    /// @return totalVoteCasted Total number of vote casted
    function getAllVoteids_byAddress(address _memberAddress) constant returns(uint[] totalVoteCasted) {
        uint length = GD.getProposalLength();
        uint j = 0;
        uint totalVoteCount = getAllVoteIdsLength_byAddress(_memberAddress);
        totalVoteCasted = new uint[](totalVoteCount);
        for (uint i = 0; i < length; i++) {
            uint voteId = GD.getVoteId_againstMember(_memberAddress, i);
            if (voteId != 0) {
                totalVoteCasted[j] = voteId;
                j++;
            }
        }
    }

    /// @dev Gets all vote ids length casted by member
    /// @param _memberAddress Member address
    /// @return totalVoteCount Total vote count
    function getAllVoteIdsLength_byAddress(address _memberAddress) constant returns(uint totalVoteCount) {
        uint length = GD.getProposalLength();
        for (uint i = 0; i < length; i++) {
            uint voteId = GD.getVoteId_againstMember(_memberAddress, i);
            if (voteId != 0)
                totalVoteCount++;
        }
    }

    /// @dev Gets all proposal ids created by a member
    /// @param _memberAddress Member address 
    /// @return totalProposalCreated Arrays of total proposals created by a member
    // function getAllProposalIds_byAddress(address _memberAddress) constant returns(uint[] totalProposalCreated) {
    //     uint length = GD.getProposalLength();
    //     uint8 j;
    //     uint proposalLength = getAllProposalIdsLength_byAddress(_memberAddress);
    //     totalProposalCreated = new uint[](proposalLength);
    //     for (uint i = 0; i < length; i++) {
    //         if (_memberAddress == GD.getProposalOwner(i)) {
    //             totalProposalCreated[j] = i;
    //             j++;
    //         }
    //     }
    // }

    /// @dev Gets length of all created proposals by member
    /// @param _memberAddress Member address
    /// @return totalProposalCount Total proposal count
    function getAllProposalIdsLength_byAddress(address _memberAddress) constant returns(uint totalProposalCount) {
        uint length = GD.getProposalLength();
        for (uint i = 0; i < length; i++) {
            if (_memberAddress == GD.getProposalOwner(i))
                totalProposalCount++;
        }
    }

    /// @dev Gets solutionId id against proposal of a member
    /// @param _memberAddress Member address
    /// @param _proposalId Proposal id
    /// @return proposalId Proposal id
    /// @return solutionId Solution id
    /// @return proposalStatus Proposal status
    /// @return finalVerdict Final verdict
    /// @return totalReward Total reward 
    /// @return category Category
    function getSolutionId_againstAddressProposal(address _memberAddress, uint _proposalId) constant returns(uint proposalId, uint solutionId, uint proposalStatus, uint finalVerdict, uint totalReward, uint category) {
        uint length = GD.getTotalSolutions(_proposalId);
        for (uint i = 0; i < length; i++) {
            if (_memberAddress == GD.getSolutionAddedByProposalId(_proposalId, i)) {
                solutionId = i;
                proposalId = _proposalId;
                proposalStatus = GD.getProposalStatus(_proposalId);
                finalVerdict = GD.getProposalFinalVerdict(_proposalId);
                totalReward = GD.getProposalTotalReward(_proposalId);
                category = PC.getCategoryId_bySubId(GD.getProposalCategory(_proposalId));
                break;
            }
        }
    }


    /// @dev Gets total votes against a proposal when given proposal id
    /// @param _proposalId Proposal id
    /// @return totalVotes total votes against a proposal
    function getAllVoteIdsLength_byProposal(uint _proposalId) constant returns(uint totalVotes) {
        // MR=memberRoles(MRAddress);
        uint length = MR.getTotalMemberRoles();
        for (uint i = 0; i < length; i++) {
            totalVotes = totalVotes + GD.getAllVoteIdsLength_byProposalRole(_proposalId, i);
        }
    }

    function proposalSubmission(uint proposalDateAdd, uint _proposalId, address _VTAddress, uint8 _categoryId, uint _proposalSolutionStake, string _solutionHash, uint _validityUpto, uint8 _v, bytes32 _r, bytes32 _s, bytes32 _lockTokenTxHash) internal {
        require(_categoryId > 0);
        VT = VotingType(_VTAddress);
        openProposalForVoting(_proposalId, _categoryId, _proposalSolutionStake, _validityUpto, _v, _r, _s, _lockTokenTxHash);
        proposalSubmission1(_proposalId, proposalDateAdd, _solutionHash, _validityUpto, _v, _r, _s, _lockTokenTxHash, _proposalSolutionStake);
    }

    function proposalSubmission1(uint _proposalId, uint proposalDateAdd, string _solutionHash, uint _validityUpto, uint8 _v, bytes32 _r, bytes32 _s, bytes32 _lockTokenTxHash, uint _proposalSolutionStake) internal {
        VT.addSolution(_proposalId, msg.sender, 0, _solutionHash, proposalDateAdd, _validityUpto, _v, _r, _s, _lockTokenTxHash);
        GD.callProposalWithSolutionEvent(msg.sender, _proposalId, "", _solutionHash, proposalDateAdd, _proposalSolutionStake);
    }

}