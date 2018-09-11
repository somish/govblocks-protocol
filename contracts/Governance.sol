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
    address internal dAppTokenProxy;

    modifier onlyProposalOwner(uint _proposalId) {
        require(msg.sender == governanceDat.getProposalOwner(_proposalId));
        _;
    }

    modifier checkProposalValidity(uint _proposalId) {
        require(governanceDat.getProposalStatus(_proposalId) < 2);
        _;
    }

    /// @dev Creates a new proposal
    /// @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
    /// @param _votingTypeId Voting type id that depicts which voting procedure to follow for this proposal
    /// @param _subCategoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
    /// @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
    function createProposalwithSolution(
        string _proposalTitle, 
        string _proposalSD, 
        string _proposalDescHash, 
        uint _votingTypeId, 
        uint _subCategoryId, 
        string _solutionHash, 
        bytes _action
    ) 
        external
    {
        uint _proposalId = governanceDat.getProposalLength();
        createProposal(_proposalTitle, _proposalSD, _proposalDescHash, _votingTypeId, _subCategoryId);
        proposalSubmission(
            _proposalId, 
            _solutionHash, 
            _action
        );
    }

    /// @dev Creates a new proposal with solution and votes for the solution
    /// @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
    /// @param _votingTypeId Voting type id that depicts which voting procedure to follow for this proposal
    /// @param _subCategoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
    /// @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
    function createProposalwithVote(
        string _proposalTitle, 
        string _proposalSD, 
        string _proposalDescHash, 
        uint _votingTypeId, 
        uint _subCategoryId, 
        string _solutionHash, 
        bytes _action
    ) 
        external
    {
        uint _proposalId = governanceDat.getProposalLength();
        createProposal(_proposalTitle, _proposalSD, _proposalDescHash, _votingTypeId, _subCategoryId);
        proposalSubmission(
            _proposalId, 
            _solutionHash, 
            _action
        );
        VotingType votingType = VotingType(governanceDat.getProposalVotingAddress(_proposalId));
        votingType.initialVote(uint32(_proposalId), msg.sender);
    }

    /// @dev updates all dependency addresses to latest ones from Master
    function updateDependencyAddresses() public {
        dAppToken = master.dAppToken();
        dAppTokenProxy = master.dAppTokenProxy();
        governanceDat = GovernanceData(master.getLatestAddress("GD"));
        memberRole = MemberRoles(master.getLatestAddress("MR"));
        proposalCategory = ProposalCategory(master.getLatestAddress("PC"));
        poolAddress = master.getLatestAddress("PL");
        pool = Pool(poolAddress);
        govBlocksToken = GBTStandardToken(master.getLatestAddress("GS"));
        eventCaller = EventCaller(master.getEventCallerAddress());
    }

    /// @dev checks if the msg.sender is allowed to create a proposal under certain category
    function allowedToCreateProposal(uint category) public view returns(bool check) {
        uint[] memory mrAllowed = proposalCategory.getMRAllowed(category);
        if (mrAllowed[0] == 0) {
            check = true;
            return check;
        } else {
            for (uint i = 0; i < mrAllowed.length; i++) {
                if (memberRole.checkRoleIdByAddress(msg.sender, mrAllowed[i])) {
                    check = true;
                    break;
                }
            }
        }
    }

    /// @dev Creates a new proposal
    /// @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
    /// @param _votingTypeId Voting type id that depicts which voting procedure to follow for this proposal
    /// @param _subCategoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
    function createProposal(
        string _proposalTitle, 
        string _proposalSD, 
        string _proposalDescHash, 
        uint _votingTypeId, 
        uint _subCategoryId
    ) 
        public 
    {
        uint category = proposalCategory.getCategoryIdBySubId(_subCategoryId);

        require(allowedToCreateProposal(category));
        address votingAddress = governanceDat.getVotingTypeAddress(_votingTypeId);
        uint _proposalId = governanceDat.getProposalLength();
        /* solhint-disable */
        governanceDat.callProposalEvent(
            msg.sender, 
            _proposalId, 
            now, 
            _proposalTitle, 
            _proposalSD, 
            _proposalDescHash
        );
        /* solhint-enable */
        address token;
        if (_subCategoryId > 0) {
            /* solhint-disable */
            if (proposalCategory.isCategoryExternal(category))
                token = address(govBlocksToken);
            else if (!governanceDat.dAppTokenSupportsLocking())
                token = dAppTokenProxy;
            else
                token = dAppToken;
            /* solhint-enable */
            require(validateStake(_subCategoryId, token));
            governanceDat.addNewProposal(msg.sender, _subCategoryId, votingAddress, token);            
            uint incentive = proposalCategory.getSubCatIncentive(_subCategoryId);
            governanceDat.setProposalIncentive(_proposalId, incentive); 
        } else
            governanceDat.createProposal(msg.sender, votingAddress);
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
        proposalSubmission(
            _proposalId, 
            _solutionHash, 
            _action
        );
    }

    /// @dev checks if the msg.sender has enough tokens locked for creating a proposal or solution
    function validateStake(uint _subCat, address _token) public view returns(bool) {
        uint minStake;
        uint tokenholdingTime;
        (minStake, tokenholdingTime) = proposalCategory.getRequiredStake(_subCat);
        if (minStake == 0)
            return true;
        GBTStandardToken tokenInstance = GBTStandardToken(_token);
        tokenholdingTime += now; // solhint-disable-line
        uint lockedTokens = tokenInstance.tokensLockedAtTime(msg.sender, "GOV", tokenholdingTime);
        if (lockedTokens >= minStake)
            return true;
    }

    /// @dev Categorizes proposal to proceed further. Categories shows the proposal objective.
    function categorizeProposal(
        uint _proposalId, 
        uint _subCategoryId
    ) 
        public 
        checkProposalValidity(_proposalId) 
    {
        uint dappIncentive = proposalCategory.getSubCatIncentive(_subCategoryId);
        require(memberRole.checkRoleIdByAddress(msg.sender, 1) 
            || msg.sender == governanceDat.getProposalOwner(_proposalId)
        );
        
        uint category = proposalCategory.getCategoryIdBySubId(_subCategoryId);
        address tokenAddress;

        /* solhint-disable */
        if (proposalCategory.isCategoryExternal(category))
            tokenAddress = address(govBlocksToken);
        else if (!governanceDat.dAppTokenSupportsLocking())
            tokenAddress = dAppTokenProxy;
        else
            tokenAddress = dAppToken;
        /* solhint-enable */

        require(dappIncentive <= GBTStandardToken(tokenAddress).balanceOf(poolAddress));
        require(allowedToCreateProposal(category));

        governanceDat.setProposalIncentive(_proposalId, dappIncentive);
        
        require(validateStake(_subCategoryId, tokenAddress));
        governanceDat.setProposalSubCategory(_proposalId, _subCategoryId, tokenAddress);
    }

    /// @dev Opens proposal for voting
    function openProposalForVoting(
        uint _proposalId
    ) 
        public 
        onlyProposalOwner(_proposalId) 
        checkProposalValidity(_proposalId) 
    {
        uint category = proposalCategory.getCategoryIdBySubId(governanceDat.getProposalSubCategory(_proposalId));
        require(category != 0);
        governanceDat.changeProposalStatus(_proposalId, 2);
        callCloseEvent(_proposalId);
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
    function calculateMemberReward(address _memberAddress) 
        public 
        onlyInternal 
        returns(uint pendingGBTReward, uint pendingDAppReward) 
    {
        uint lastRewardProposalId = governanceDat.lastRewardDetails(_memberAddress);

        (pendingGBTReward, pendingDAppReward) = calculateProposalReward(_memberAddress, lastRewardProposalId); 
        uint tempGBTReward;
        uint tempDAppRward;
        (tempGBTReward, tempDAppRward) = calculateSolutionReward(_memberAddress, lastRewardProposalId);
        pendingGBTReward += tempGBTReward;
        pendingDAppReward += tempDAppRward;
        uint votingTypes = governanceDat.getVotingTypeLength();
        for (uint i = 0; i < votingTypes; i++) {
            VotingType votingType = VotingType(governanceDat.getVotingTypeAddress(i));
            (tempGBTReward, tempDAppRward) = votingType.claimVoteReward(_memberAddress);
            pendingGBTReward += tempGBTReward;
            pendingDAppReward += tempDAppRward;
        }
    }

    /// @dev Gets remaining vote closing time against proposal 
    /// i.e. Calculated closing time from current voting index to the last layer.
    /// @param _proposalId Proposal Id
    /// @param _index Current voting status id works as index here in voting layer sequence. 
    /// @return totalTime Total time that left for proposal closing.
    function getRemainingClosingTime(uint _proposalId, uint _index) 
        public 
        view 
        returns(uint totalTime) 
    {
        uint pClosingTime;
        uint subc = governanceDat.getProposalSubCategory(_proposalId);
        uint categoryId = proposalCategory.getCategoryIdBySubId(subc);
        uint ctLength = proposalCategory.getCloseTimeLength(categoryId);
        for (uint i = _index; i < ctLength; i++) {
            pClosingTime = pClosingTime + proposalCategory.getClosingTimeAtIndex(categoryId, i);
        }

        totalTime = pClosingTime 
            + proposalCategory.getTokenHoldingTime(subc)
            + governanceDat.getProposalDateUpd(_proposalId)
            - now; // solhint-disable-line
    }

    /// @dev Gets Total vote closing time against sub category i.e. 
    /// Calculated Closing time from first voting layer where current voting index is 0.
    /// @param _subCategoryId Category id
    /// @return totalTime Total time before the voting gets closed
    function getMaxCategoryTokenHoldTime(uint _subCategoryId) public view returns(uint totalTime) {
        uint categoryId = proposalCategory.getCategoryIdBySubId(_subCategoryId);
        uint ctLength = proposalCategory.getCloseTimeLength(categoryId);
        for (uint i = 0; i < ctLength; i++) {
            totalTime = totalTime + proposalCategory.getClosingTimeAtIndex(categoryId, i);
        }
        totalTime = totalTime + proposalCategory.getTokenHoldingTime(_subCategoryId);
        return totalTime;
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
            uint subCategory
        ) 
    {
        uint length = governanceDat.getTotalSolutions(_proposalId);
        proposalId = _proposalId;
        for (uint i = 1; i < length; i++) {
            if (_memberAddress == governanceDat.getSolutionAddedByProposalId(_proposalId, i)) {
                proposalId = _proposalId;
                solutionId = i;
                proposalStatus = governanceDat.getProposalStatus(_proposalId);
                finalVerdict = governanceDat.getProposalFinalVerdict(_proposalId);
                totalReward = governanceDat.getProposalIncentive(_proposalId);
                subCategory = governanceDat.getProposalSubCategory(_proposalId);
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
        uint subCategory = governanceDat.getProposalSubCategory(_proposalId);
        uint categoryId = proposalCategory.getCategoryIdBySubId(subCategory);
        uint closingTime = proposalCategory.getClosingTimeAtIndex(categoryId, 0) + now; // solhint-disable-line
        address votingType = governanceDat.getProposalVotingAddress(_proposalId);
        eventCaller.callCloseProposalOnTimeAtAddress(_proposalId, votingType, closingTime);
    }

    /// @dev Calculate reward for proposal creation against member
    /// @param _memberAddress Address of member who claimed the reward
    /// @param _lastRewardProposalId Last id proposal till which the reward being distributed
    function calculateProposalReward(
        address _memberAddress, 
        uint _lastRewardProposalId
    ) 
        internal
        returns(uint pendingGBTReward, uint pendingDAppReward)
    {
        uint allProposalLength = governanceDat.getProposalLength();
        uint lastIndex = 0;
        uint finalVredict;
        uint proposalStatus;
        uint calcReward;
        uint subCategory;
        bool rewardClaimed;
        uint i;

        for (i = _lastRewardProposalId; i < allProposalLength; i++) {
            if (_memberAddress == governanceDat.getProposalOwner(i)) {
                (rewardClaimed, subCategory, proposalStatus, finalVredict) = 
                    governanceDat.getProposalDetailsById3(i, _memberAddress);
                if (proposalStatus <= 2 && lastIndex == 0) 
                    lastIndex = i;
                if (proposalStatus > 2 && finalVredict > 0 && !rewardClaimed) {
                    calcReward = proposalCategory.getRewardPercProposal(subCategory).mul(
                            governanceDat.getProposalIncentive(i)
                        );
                    calcReward = calcReward.div(100);
                    if (proposalCategory.isSubCategoryExternal(subCategory))    
                        pendingGBTReward += calcReward;
                    else
                        pendingDAppReward += calcReward;

                    calculateProposalReward1(_memberAddress, i, calcReward);
                }
            }
        }

        if (lastIndex == 0)
            lastIndex = i - 1;
        governanceDat.setLastRewardIdOfSolutionProposals(_memberAddress, lastIndex);
    }

    /// @dev Saving reward and member reputation details 
    function calculateProposalReward1(
        address _memberAddress, 
        uint i, 
        uint calcReward
    ) 
        internal
    {
        if (calcReward > 0) {
            governanceDat.callRewardEvent(
                _memberAddress, 
                i, 
                "Reward-Proposal owner", 
                calcReward
            );
        }
        uint addProposalOwnerPoints = governanceDat.addProposalOwnerPoints();
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
        returns(uint pendingGBTReward, uint pendingDAppReward) 
    {
        uint allProposalLength = governanceDat.getProposalLength();
        uint calcReward;
        uint lastIndex = 0;
        uint i;
        uint proposalStatus;
        uint finalVerdict;
        uint solutionId;
        uint totalReward;
        uint subCategory;
        
        for (i = _lastRewardSolutionProposalId; i < allProposalLength; i++) {
            (i, solutionId, proposalStatus, finalVerdict, totalReward, subCategory) = 
                getSolutionIdAgainstAddressProposal(_memberAddress, i);
            if (proposalStatus <= 2 && lastIndex == 0)
                lastIndex = i;
            if (finalVerdict > 0 && finalVerdict == solutionId 
                && !governanceDat.getRewardClaimed(i, _memberAddress)
            ) {
                governanceDat.setRewardClaimed(i, _memberAddress);
                calcReward = (proposalCategory.getRewardPercSolution(subCategory) * totalReward) / 100;
                if (proposalCategory.isSubCategoryExternal(subCategory))    
                    pendingGBTReward += calcReward;
                else
                    pendingDAppReward += calcReward;
                calculateSolutionReward1(_memberAddress, i, calcReward);
            }
        }

        if (lastIndex == 0)
            lastIndex = i - 1;
    }

    /// @dev Saving solution reward and member reputation details
    function calculateSolutionReward1(
        address _memberAddress, 
        uint i, 
        uint calcReward
    ) 
        internal  
    {
        
        if (calcReward > 0) {
            governanceDat.callRewardEvent(
                _memberAddress, 
                i, 
                "Reward-Solution owner", 
                calcReward
            );
        }
        uint addSolutionOwnerPoints = governanceDat.addSolutionOwnerPoints();
        governanceDat.setMemberReputation(
                "Reputation credit-solution owner", 
                i, 
                _memberAddress, 
                governanceDat.getMemberReputation(_memberAddress) + addSolutionOwnerPoints, 
                addSolutionOwnerPoints, 
                "C"
            );
    }

    /// @dev When creating or submitting proposal with solution, This function open the proposal for voting
    function proposalSubmission( 
        uint _proposalId,  
        string _solutionHash, 
        bytes _action
    ) 
        internal 
    {
        openProposalForVoting(
            _proposalId
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
        votingType.addSolution(
            uint32(_proposalId), 
            msg.sender, 
            _solutionHash, 
            _action
        );
        /* solhint-disable */
        governanceDat.callProposalWithSolutionEvent(
            msg.sender, 
            _proposalId, 
            "", 
            _solutionHash, 
            now
        );
        /* solhint-enable */
    }

}