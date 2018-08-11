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
import "./GovernanceData.sol";
import "./ProposalCategory.sol";
import "./MemberRoles.sol";
import "./Upgradeable.sol";
import "./Master.sol";
import "./imports/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./imports/openzeppelin-solidity/contracts/math/Math.sol";
import "./Pool.sol";
import "./GBTStandardToken.sol";
import "./VotingType.sol";
import "./EventCaller.sol";


contract Governance is Upgradeable {

    using SafeMath for uint;
    address internal poolAddress;
    GBTStandardToken internal govBlocksToken;
    MemberRoles internal memberRole;
    ProposalCategory internal proposalCategory;
    GovernanceData internal governanceDat;
    Pool internal pool;
    EventCaller internal eventCaller;
    address internal dAppToken;

    modifier onlyProposalOwner(uint _proposalId) {
        require(msg.sender == governanceDat.getProposalOwner(_proposalId));
        _;
    }

    modifier checkProposalValidity(uint _proposalId) {
        require(governanceDat.getProposalStatus(_proposalId) < 2);
        _;
    }

    /// @dev updates all dependency addresses to latest ones from Master
    function updateDependencyAddresses() public {
        dAppToken = master.dAppToken();
        governanceDat = GovernanceData(master.getLatestAddress("GD"));
        memberRole = MemberRoles(master.getLatestAddress("MR"));
        proposalCategory = ProposalCategory(master.getLatestAddress("PC"));
        poolAddress = master.getLatestAddress("PL");
        pool = Pool(poolAddress);
        govBlocksToken = GBTStandardToken(master.getLatestAddress("GS"));
        eventCaller = EventCaller(master.getEventCallerAddress());
    }

    /// @dev Creates a new proposal
    /// @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
    /// @param _votingTypeId Voting type id that depicts which voting procedure to follow for this proposal
    /// @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
    function createProposal(
        string _proposalTitle, 
        string _proposalSD, 
        string _proposalDescHash, 
        uint _votingTypeId, 
        uint _categoryId
    ) 
        public 
    {
        uint category = proposalCategory.getCategoryIdBySubId(_categoryId);
        require(proposalCategory.allowedToCreateProposal(msg.sender, category));
        address votingAddress = governanceDat.getVotingTypeAddress(_votingTypeId);
        uint _proposalId = governanceDat.getProposalLength();
        governanceDat.setSolutionAdded(_proposalId, address(0), "address(0)");
        governanceDat.callProposalEvent(
            msg.sender, 
            _proposalId, 
            now, 
            _proposalTitle, 
            _proposalSD, 
            _proposalDescHash
        );
        if (_categoryId > 0) {
            if (proposalCategory.isCategoryExternal(category))
                governanceDat.addNewProposal(_proposalId, msg.sender, _categoryId, votingAddress, address(govBlocksToken));
            else
                governanceDat.addNewProposal(_proposalId, msg.sender, _categoryId, votingAddress, dAppToken);            
            uint incentive=proposalCategory.getCatIncentive(category);
            governanceDat.setProposalIncentive(_proposalId, incentive);
        } else
            governanceDat.createProposal1(msg.sender, votingAddress);
    }

    /// @dev Creates a new proposal
    /// @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
    /// @param _votingTypeId Voting type id that depicts which voting procedure to follow for this proposal
    /// @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
    /// @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
    function createProposalwithSolution(
        string _proposalTitle, 
        string _proposalSD, 
        string _proposalDescHash, 
        uint _votingTypeId, 
        uint _categoryId, 
        string _solutionHash, 
        bytes _action
    ) 
        external
    {
        uint _proposalId = governanceDat.getProposalLength();
        createProposal(_proposalTitle, _proposalSD, _proposalDescHash, _votingTypeId, _categoryId);
        proposalSubmission(
            _proposalId, 
            _categoryId, 
            _solutionHash, 
            _action
        );
    }

    /// @dev Submit proposal with solution
    /// @param _proposalId Proposal id
    /// @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
    function submitProposalWithSolution(
        uint _proposalId, 
        string _solutionHash, 
        bytes _action
    ) 
        public 
        onlyProposalOwner(_proposalId) 
    {
        uint category = governanceDat.getProposalCategory(_proposalId);
        proposalSubmission(
            _proposalId, 
            category, 
            _solutionHash, 
            _action
        );
    }

    function validateStake(uint _subCat, address _token) public view returns(bool) {
        uint minStake;
        uint tokenholdingTime;
        (minStake, tokenholdingTime) = proposalCategory.getRequiredStake(_subCat);
        if(minStake == 0)
            return true;
        GBTStandardToken tokenInstance = GBTStandardToken(_token);
        tokenholdingTime += now;
        uint lockedTokens = tokenInstance.tokensLockedAtTime(msg.sender, "GOV", tokenholdingTime);
        if(lockedTokens > minStake)
            return true;
    }

    /// @dev Categorizes proposal to proceed further. Categories shows the proposal objective.
    /// @param _dappIncentive It is the company's incentive to distribute to end members
    function categorizeProposal(
        uint _proposalId, 
        uint _categoryId, 
        uint _dappIncentive
    ) 
        public 
        checkProposalValidity(_proposalId) 
    {
        require(memberRole.checkRoleIdByAddress(msg.sender, 2) || msg.sender == governanceDat.getProposalOwner(_proposalId));
        require(_dappIncentive <= govBlocksToken.balanceOf(poolAddress));
        uint category = proposalCategory.getCategoryIdBySubId(_categoryId);
        require(proposalCategory.allowedToCreateProposal(msg.sender, category));
        governanceDat.setProposalIncentive(_proposalId, _dappIncentive);
        address tokenAddress;
        if (proposalCategory.isCategoryExternal(category))
            tokenAddress = address(govBlocksToken);
        else
            tokenAddress = dAppToken;
        require (validateStake(_categoryId, tokenAddress));
        governanceDat.setProposalCategory(_proposalId, _categoryId, tokenAddress);
    }

    /// @dev Proposal is open for voting.
    function openProposalForVoting(
        uint _proposalId, 
        uint _categoryId
    ) 
        public 
        onlyProposalOwner(_proposalId) 
        checkProposalValidity(_proposalId) 
    {
        uint category = proposalCategory.getCategoryIdBySubId(_categoryId);
        uint currVotingStatus = governanceDat.getProposalCurrentVotingId(_proposalId);
        require(category != 0 && currVotingStatus < 2);
        governanceDat.changeProposalStatus(_proposalId, 2);
        callCloseEvent(_proposalId);
    }

    /// @dev Changes pending proposal start variable
    function changePendingProposalStart() public onlyInternal {
        uint pendingPS = governanceDat.pendingProposalStart();
        for (uint j = pendingPS; j < governanceDat.getProposalLength(); j++) {
            if (governanceDat.getProposalStatus(j) > 3)
                pendingPS = SafeMath.add(pendingPS, 1);
            else
                break;
        }
        if (j != pendingPS) {
            governanceDat.changePendingProposalStart(j);
        }
    }

    /// @dev Updates proposal's major details (Called from close proposal vote)
    /// @param _proposalId Proposal id
    /// @param _currVotingStatus It is the index to fetch the role id from voting sequence array. 
    ///         i.e. Tells which role id members is going to vote
    /// @param _intermediateVerdict Intermediate verdict is set after every voting layer is passed.
    /// @param _finalVerdict Final verdict is set after final layer of voting
    function updateProposalDetails(
        uint _proposalId, 
        uint _currVotingStatus, 
        uint64 _intermediateVerdict, 
        uint64 _finalVerdict
    ) 
    public
    onlyInternal 
    {
        governanceDat.setProposalCurrentVotingId(_proposalId, _currVotingStatus);
        governanceDat.setProposalIntermediateVerdict(_proposalId, _intermediateVerdict);
        governanceDat.setProposalFinalVerdict(_proposalId, _finalVerdict);
        governanceDat.setProposalDateUpd(_proposalId);
    }

    /// @dev Calculates member reward to be claimed
    /// @param _memberAddress Member address
    /// @return rewardToClaim Rewards to be claimed
    function calculateMemberReward(address _memberAddress) public returns(uint tempFinalRewardToDistribute) {
        uint lastRewardProposalId;
        uint lastRewardSolutionProposalId;
        (lastRewardProposalId, lastRewardSolutionProposalId) = 
            governanceDat.getAllidsOfLastReward(_memberAddress);

        tempFinalRewardToDistribute = 
            calculateProposalReward(_memberAddress, lastRewardProposalId) 
            + calculateSolutionReward(_memberAddress, lastRewardSolutionProposalId);
        uint votingTypes = governanceDat.getVotingTypeLength();
        for(uint i = 0; i < votingTypes; i++) {
            VotingType votingType = VotingType(governanceDat.getVotingTypeAddress(i));
            tempFinalRewardToDistribute += votingType.claimVoteReward(_memberAddress);
        }

    }

    /// @dev Gets member details
    /// @param _memberAddress Member address
    /// @return memberReputation Member reputation that has been updated till now
    /// @return totalProposal Total number of proposals created by member so far
    /// @return totalSolution Total solution proposed by member for different proposal till now.
    /// @return totalVotes Total number of votes casted by member
    function getMemberDetails(address _memberAddress) 
        public 
        view 
        returns(
            uint memberReputation, 
            uint totalProposal, 
            uint totalSolution, 
            uint totalVotes
        ) 
    {
        memberReputation = governanceDat.getMemberReputation(_memberAddress);
        totalProposal = governanceDat.getAllProposalIdsLengthByAddress(_memberAddress);
        totalSolution = governanceDat.getAllSolutionIdsLengthByAddress(_memberAddress);
        totalVotes = governanceDat.getTotalNumberOfVotesByAddress(_memberAddress);
    }

    /// @dev It fetchs the Index of solution provided by member against a proposal
    function getSolutionIdAgainstAddressProposal(
        address _memberAddress, 
        uint _proposalId
    ) 
        public 
        view 
        returns(
            uint proposalId, 
            uint solutionId, 
            uint proposalStatus, 
            uint finalVerdict, 
            uint totalReward, 
            uint category
        ) 
    {
        uint length = governanceDat.getTotalSolutions(_proposalId);
        for (uint i = 0; i < length; i++) {
            if (_memberAddress == governanceDat.getSolutionAddedByProposalId(_proposalId, i)) {
                solutionId = i;
                proposalId = _proposalId;
                proposalStatus = governanceDat.getProposalStatus(_proposalId);
                finalVerdict = governanceDat.getProposalFinalVerdict(_proposalId);
                totalReward = governanceDat.getProposalIncentive(_proposalId);
                category = proposalCategory.getCategoryIdBySubId(governanceDat.getProposalCategory(_proposalId));
                break;
            }
        }
    }

    /// @dev Gets total votes against a proposal when given proposal id
    /// @param _proposalId Proposal id
    /// @return totalVotes total votes against a proposal
    function getAllVoteIdsLengthByProposal(uint _proposalId) public view returns(uint totalVotes) {
        // memberRole=MemberRoles(MRAddress);
        uint length = memberRole.getTotalMemberRoles();
        VotingType votingType = VotingType(governanceDat.getProposalVotingAddress(_proposalId));
        for (uint i = 0; i < length; i++) {
            totalVotes = totalVotes + votingType.getAllVoteIdsLengthByProposalRole(_proposalId, i);
        }
    }

    /// @dev Call event for closing proposal
    /// @param _proposalId Proposal id which voting needs to be closed
    function callCloseEvent(uint _proposalId) internal {
        uint subCategory = governanceDat.getProposalCategory(_proposalId);
        uint _categoryId = proposalCategory.getCategoryIdBySubId(subCategory);
        uint closingTime = proposalCategory.getClosingTimeAtIndex(_categoryId, 0) + now;
        address votingType = governanceDat.getProposalVotingAddress(_proposalId);
        eventCaller.callCloseProposalOnTimeAtAddress(_proposalId, votingType, closingTime);
    }

    /// @dev Edits the details of an existing proposal and creates new version
    /// @param _proposalId Proposal id that details needs to be updated
    /// @param _proposalDescHash Proposal description hash having long and short description of proposal.
    function updateProposalDetails1(
        uint _proposalId, 
        string _proposalTitle, 
        string _proposalSD, 
        string _proposalDescHash
    ) 
        internal 
    {
        governanceDat.storeProposalVersion(_proposalId, _proposalDescHash);
        governanceDat.setProposalDateUpd(_proposalId);
        governanceDat.changeProposalStatus(_proposalId, 1);
        governanceDat.callProposalEvent(
            governanceDat.getProposalOwner(_proposalId), 
            _proposalId, 
            now, 
            _proposalTitle, 
            _proposalSD, 
            _proposalDescHash
        );
    }

    /// @dev Calculate reward for proposal creation against member
    /// @param _memberAddress Address of member who claimed the reward
    /// @param _lastRewardProposalId Last id proposal till which the reward being distributed
    function calculateProposalReward(
        address _memberAddress, 
        uint _lastRewardProposalId
    ) 
        internal  
        returns(uint tempfinalRewardToDistribute)
    {
        uint allProposalLength = governanceDat.getProposalLength();
        uint lastIndex = 0;
        uint finalVredict;
        uint proposalStatus;
        uint calcReward;
        uint category;
        uint addProposalOwnerPoints = governanceDat.addProposalOwnerPoints();

        for (uint i = _lastRewardProposalId; i < allProposalLength; i++) {
            if (_memberAddress == governanceDat.getProposalOwner(i)) {
                (, , category, proposalStatus, finalVredict) = governanceDat.getProposalDetailsById3(i);
                if (proposalStatus < 2)
                    lastIndex = i;
                else if (proposalStatus > 2 && 
                    finalVredict > 0 && 
                    governanceDat.getProposalIncentive(i) != 0
                ) {
                    category = proposalCategory.getCategoryIdBySubId(category);
                    calcReward = proposalCategory.getRewardPercProposal(category) 
                        * governanceDat.getProposalIncentive(i)
                        / 100;

                    tempfinalRewardToDistribute = 
                        tempfinalRewardToDistribute 
                        + calcReward;

                    calculateProposalReward1(_memberAddress, i, calcReward, addProposalOwnerPoints);
                }
            }
        }

        if (lastIndex == 0)
            lastIndex = i;
        governanceDat.setLastRewardIdOfCreatedProposals(_memberAddress, lastIndex);
    }

    /// @dev Saving reward and member reputation details 
    function calculateProposalReward1(
        address _memberAddress, 
        uint i, 
        uint calcReward, 
        uint addProposalOwnerPoints
    ) 
        internal
    {
        if (calcReward > 0) {
            governanceDat.callRewardEvent(
                _memberAddress, 
                i, 
                "GBT Reward-Proposal owner", 
                calcReward
            );
        }
        
        governanceDat.setMemberReputation(
            "Reputation credit-proposal owner", 
            i, 
            _memberAddress, 
            governanceDat.getMemberReputation(_memberAddress) + addProposalOwnerPoints, 
            addProposalOwnerPoints, 
            "C"
        );

    }

    /// @dev Calculate reward for proposing solution against different proposals
    /// @param _memberAddress Address of member who claimed the reward
    /// @param _lastRewardSolutionProposalId Last id proposal(To which solutions being proposed) 
    ///         till which the reward being distributed
    function calculateSolutionReward(
        address _memberAddress, 
        uint _lastRewardSolutionProposalId
    ) 
        internal  
        returns(uint tempfinalRewardToDistribute) 
    {
        uint allProposalLength = governanceDat.getProposalLength();
        uint calcReward;
        uint lastIndex = 0;
        uint i;
        uint proposalStatus;
        uint finalVerdict;
        uint solutionId;
        uint proposalId;
        uint totalReward;
        uint category;

        for (i = _lastRewardSolutionProposalId; i < allProposalLength; i++) {
            (proposalId, solutionId, proposalStatus, finalVerdict, totalReward, category) = 
                getSolutionIdAgainstAddressProposal(_memberAddress, i);

            if (proposalId == i) {
                if (proposalStatus < 2)
                    lastIndex = i;
                if (finalVerdict > 0 && finalVerdict == solutionId)
                    tempfinalRewardToDistribute = 
                        tempfinalRewardToDistribute 
                        + calculateSolutionReward1(
                            _memberAddress, 
                            i, 
                            calcReward, 
                            totalReward, 
                            category                            
                        );
            }
        }

        if (lastIndex == 0)
            lastIndex = i;
    }

    /// @dev Saving solution reward and member reputation details
    function calculateSolutionReward1(
        address _memberAddress, 
        uint i, 
        uint calcReward, 
        uint totalReward, 
        uint category
    ) 
        internal  
        returns(uint tempfinalRewardToDistribute) 
    {
        uint addSolutionOwnerPoints = governanceDat.addSolutionOwnerPoints();
        calcReward = (proposalCategory.getRewardPercSolution(category) * totalReward) / 100;
        tempfinalRewardToDistribute = calcReward;
        if (calcReward > 0) {
            governanceDat.callRewardEvent(
                _memberAddress, 
                i, 
                "GBT Reward-Solution owner", 
                calcReward
            );
            governanceDat.setMemberReputation(
                "Reputation credit-solution owner", 
                i, 
                _memberAddress, 
                governanceDat.getMemberReputation(_memberAddress) + addSolutionOwnerPoints, 
                addSolutionOwnerPoints, 
                "C"
            );
        }
    }

    /// @dev When creating or submitting proposal with solution, This function open the proposal for voting
    function proposalSubmission( 
        uint _proposalId,  
        uint _categoryId, 
        string _solutionHash, 
        bytes _action
    ) 
        internal 
    {
        require(_categoryId > 0);
        openProposalForVoting(
            _proposalId, 
            _categoryId 
        );

        proposalSubmission1(
            _proposalId, 
            _solutionHash, 
            _action
        );
    }

    /// @dev When creating proposal with solution, it adds solution details against proposal
    function proposalSubmission1(
        uint _proposalId, 
        string _solutionHash, 
        bytes _action
    ) 
        internal  
    {
        VotingType votingType = VotingType(governanceDat.getProposalVotingAddress(_proposalId));
        // VT = VotingType(0x68D2e5342Dae099C1894ce022B6101bb6d4BBF3C);
        votingType.addSolution(
            _proposalId, 
            msg.sender, 
            _solutionHash, 
            _action
        );

        governanceDat.callProposalWithSolutionEvent(
            msg.sender, 
            _proposalId, 
            "", 
            _solutionHash, 
            now
        );
    }

}