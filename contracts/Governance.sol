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
    address public poolAddress;
    GBTStandardToken public govBlocksToken;
    MemberRoles public memberRole;
    ProposalCategory public proposalCategory;
    GovernanceData public governanceDat;
    Pool public pool;
    EventCaller public eventCaller;
    address public dAppLocker;

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
        uint proposalId = governanceDat.getProposalLength();
        _createProposalwithSolution(
            _proposalTitle, 
            _proposalSD, 
            _proposalDescHash, 
            _votingTypeId, 
            _subCategoryId,
            _solutionHash,
            _action,
            proposalId
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
        uint proposalId = governanceDat.getProposalLength();
        _createProposalwithSolution(
            _proposalTitle, 
            _proposalSD, 
            _proposalDescHash, 
            _votingTypeId, 
            _subCategoryId,
            _solutionHash,
            _action,
            proposalId
        );
        VotingType votingType = VotingType(governanceDat.getProposalVotingAddress(proposalId));
        votingType.initialVote(uint32(proposalId), msg.sender);
    }

    /// @dev updates all dependency addresses to latest ones from Master
    function updateDependencyAddresses() public {
        dAppLocker = master.dAppLocker();
        governanceDat = GovernanceData(master.getLatestAddress("GD"));
        memberRole = MemberRoles(master.getLatestAddress("MR"));
        proposalCategory = ProposalCategory(master.getLatestAddress("PC"));
        poolAddress = master.getLatestAddress("PL");
        pool = Pool(poolAddress);
        govBlocksToken = GBTStandardToken(master.gbt());
        eventCaller = EventCaller(master.getEventCallerAddress());
    }

    /// @dev checks if the msg.sender is allowed to create a proposal under certain category
    function allowedToCreateProposal(uint category) public view returns(bool check) {
        if (category == 0)
            return true;
        uint[] memory mrAllowed = proposalCategory.getMRAllowed(category);
        for (uint i = 0; i < mrAllowed.length; i++) {
            if (mrAllowed[i] == 0 || memberRole.checkRoleIdByAddress(msg.sender, mrAllowed[i]))
                return true;
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
            else
                token = dAppLocker;
            /* solhint-enable */
            require(validateStake(_subCategoryId, token));
            governanceDat.addNewProposal(msg.sender, _subCategoryId, votingAddress, token);            
            uint incentive = proposalCategory.getSubCatIncentive(_subCategoryId);
            require(incentive <= GBTStandardToken(token).balanceOf(poolAddress));
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
        
        uint category = proposalCategory.getCategoryIdBySubId(_subCategoryId);
        address tokenAddress;

        /* solhint-disable */
        if (proposalCategory.isCategoryExternal(category))
            tokenAddress = address(govBlocksToken);
        else
            tokenAddress = dAppLocker;
        /* solhint-enable */

        if (!memberRole.checkRoleIdByAddress(msg.sender, 1)) {
            require(msg.sender == governanceDat.getProposalOwner(_proposalId));
            require(allowedToCreateProposal(category));
            require(validateStake(_subCategoryId, tokenAddress));
        }

        require(dappIncentive <= GBTStandardToken(tokenAddress).balanceOf(poolAddress));

        governanceDat.setProposalIncentive(_proposalId, dappIncentive);
        governanceDat.setProposalSubCategory(_proposalId, _subCategoryId, tokenAddress);
    }

    /// @dev Opens proposal for voting
    function openProposalForVoting(uint _proposalId) 
        public onlyProposalOwner(_proposalId) checkProposalValidity(_proposalId) 
    {
        uint category = proposalCategory.getCategoryIdBySubId(governanceDat.getProposalSubCategory(_proposalId));
        require(category != 0);
        governanceDat.changeProposalStatus(_proposalId, 2);
        uint closingTime = proposalCategory.getClosingTimeAtIndex(category, 0) + now; // solhint-disable-line
        address votingType = governanceDat.getProposalVotingAddress(_proposalId);
        eventCaller.callCloseProposalOnTimeAtAddress(_proposalId, votingType, closingTime);
    }

    /// @dev calculates reward to distribute for a user
    /// @param _memberAddress Member address
    /// @param _proposals proposal ids to calculate reward for
    function calculateMemberReward(address _memberAddress, uint[] _proposals) 
        public 
        onlyInternal 
        returns(uint totalGBTReward, uint totalDAppReward, uint reputation) 
    {
        uint i = _proposals.length;
        
        uint finalVerdictThenRewardPerc;
        uint proposalStatusThenRewardPercent;
        uint solutionIdThenRep;
        uint subCategory;
        uint totalReward;
        bool rewardClaimedThenIsExternal;
        //0th element is skipped always as sometimes we actually need length of _proposals be 0. 
        for (i--; i > 0; i--) {
            //solhint-disable-next-line
            (rewardClaimedThenIsExternal, subCategory, proposalStatusThenRewardPercent, finalVerdictThenRewardPerc, solutionIdThenRep, totalReward) =
                governanceDat.getProposalDetailsForReward(_proposals[i], _memberAddress);           
            totalReward = totalReward / 100;

            require(!rewardClaimedThenIsExternal && proposalStatusThenRewardPercent > 2);

            if (finalVerdictThenRewardPerc > 0) {

                rewardClaimedThenIsExternal = proposalCategory.isSubCategoryExternal(subCategory);
                (finalVerdictThenRewardPerc, solutionIdThenRep) = _getReward(
                        _memberAddress, 
                        _proposals[i], 
                        finalVerdictThenRewardPerc, 
                        solutionIdThenRep, 
                        subCategory
                    );

                if (finalVerdictThenRewardPerc > 0) {
                    if (rewardClaimedThenIsExternal)    
                        totalGBTReward += finalVerdictThenRewardPerc.mul(totalReward);
                    else
                        totalDAppReward += finalVerdictThenRewardPerc.mul(totalReward);
                }

                reputation += solutionIdThenRep;
            } 
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

    /// @dev Creates a new proposal
    /// @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
    /// @param _votingTypeId Voting type id that depicts which voting procedure to follow for this proposal
    /// @param _subCategoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
    /// @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
    function _createProposalwithSolution(
        string _proposalTitle, 
        string _proposalSD, 
        string _proposalDescHash, 
        uint _votingTypeId, 
        uint _subCategoryId, 
        string _solutionHash, 
        bytes _action,
        uint _proposalId
    ) 
        internal
    {
        createProposal(_proposalTitle, _proposalSD, _proposalDescHash, _votingTypeId, _subCategoryId);
        proposalSubmission(
            _proposalId, 
            _solutionHash, 
            _action
        );
    }

    /// @dev gets rewardPercent and reputation to award a user for a proposal 
    function _getReward(
        address _memberAddress, 
        uint _proposal, 
        uint _finalVerdict, 
        uint _solutionId, 
        uint _subCategory
    ) internal returns (uint rewardPercent, uint reputation) {
        governanceDat.setRewardClaimed(_proposal, _memberAddress);
        if (_memberAddress == governanceDat.getProposalOwner(_proposal)) {
            rewardPercent += proposalCategory.getRewardPercProposal(_subCategory);
            reputation += governanceDat.addProposalOwnerPoints();
        }
        if (_finalVerdict == _solutionId) {  
            rewardPercent += proposalCategory.getRewardPercSolution(_subCategory);                  
            reputation += governanceDat.addSolutionOwnerPoints();
        }
    }

}