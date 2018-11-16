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
    enum ProposalStatus { 
        Draft,
        AwaitingSolution,
        VotingStarted,
        Accepted,
        Rejected,
        Majority_Not_Reached_But_Accepted,
        Denied,
        Threshold_Not_Reached_But_Accepted_By_PrevVoting 
    }
    
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
        require(governanceDat.getProposalStatus(_proposalId) < uint(ProposalStatus.VotingStarted));
        _;
    }

    /// @dev Creates a new proposal with solution and votes for the solution
    /// @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
    /// @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
    /// @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
    function createProposalwithVote(
        string _proposalTitle, 
        string _proposalSD, 
        string _proposalDescHash,
        uint _categoryId, 
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
            _categoryId,
            _solutionHash,
            _action,
            proposalId
        );
        VotingType votingType = VotingType(governanceDat.getLatestVotingAddress());
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
        uint[] memory mrAllowed;
        (,,,mrAllowed,,,) = proposalCategory.getCategoryDetails(category);
        for (uint i = 0; i < mrAllowed.length; i++) {
            if (mrAllowed[i] == 0 || memberRole.checkRoleIdByAddress(msg.sender, mrAllowed[i]))
                return true;
        }  
    }

    /// @dev Creates a new proposal
    /// @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
    /// @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
    function createProposal(
        string _proposalTitle, 
        string _proposalSD, 
        string _proposalDescHash, 
        uint _categoryId
    ) 
        public 
    {
        // uint category = proposalCategory.getCategoryIdBySubId(_subCategoryId);

        require(allowedToCreateProposal(_categoryId));
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
        eventCaller.callProposalCreated(
            _proposalId,
            _categoryId,
            master.dAppName(),
            _proposalDescHash
        );
        /* solhint-enable */
        address token;
        if (_categoryId > 0) {
            /* solhint-disable */
            if (proposalCategory.isCategoryExternal(_categoryId))
                token = address(govBlocksToken);
            else
                token = dAppLocker;
            /* solhint-enable */
            require(validateStake(_categoryId, token));
            governanceDat.addNewProposal(msg.sender, _categoryId, token);
            uint incentive;
            (,,incentive) = proposalCategory.getCategoryActionDetails(_categoryId);
            require(incentive <= GBTStandardToken(token).balanceOf(poolAddress));
            governanceDat.setProposalIncentive(_proposalId, incentive); 
            governanceDat.changeProposalStatus(_proposalId, uint8(ProposalStatus.AwaitingSolution));
        } else
            governanceDat.createProposal(msg.sender);
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
        submitSolution(
            _proposalId, 
            _solutionHash, 
            _action
        );

        openProposalForVoting(
            _proposalId
        );
    }

    /// @dev checks if the msg.sender has enough tokens locked for creating a proposal or solution
    function validateStake(uint _categoryId, address _token) public view returns(bool) {
        uint minStake;
        uint tokenholdingTime;
        (,,,,, tokenholdingTime, minStake) = proposalCategory.getCategoryDetails(_categoryId);
        if (minStake == 0)
            return true;
        GBTStandardToken tokenInstance = GBTStandardToken(_token);
        tokenholdingTime = SafeMath.add(tokenholdingTime, now); // solhint-disable-line
        uint lockedTokens = tokenInstance.tokensLockedAtTime(msg.sender, "GOV", tokenholdingTime);
        if (lockedTokens >= minStake)
            return true;
    }

    /// @dev Categorizes proposal to proceed further. Categories shows the proposal objective.
    function categorizeProposal(
        uint _proposalId, 
        uint _categoryId
    ) 
        checkProposalValidity(_proposalId)
        public  
    {

        require(governanceDat.getTotalSolutions(_proposalId) < 2 , "Categorization not possible, since solutions had already been submitted");

        uint dappIncentive;
        (,, dappIncentive) = proposalCategory.getCategoryActionDetails(_categoryId);
        
        // uint category = proposalCategory.getCategoryIdBySubId(_subCategoryId);
        address tokenAddress;

        /* solhint-disable */
        if (proposalCategory.isCategoryExternal(_categoryId))
            tokenAddress = address(govBlocksToken);
        else
            tokenAddress = dAppLocker;
        /* solhint-enable */

        if (!memberRole.checkRoleIdByAddress(msg.sender, 1)) {
            require(msg.sender == governanceDat.getProposalOwner(_proposalId));
            require(allowedToCreateProposal(_categoryId)); 
            require(validateStake(_categoryId, tokenAddress));
        }

        require(dappIncentive <= GBTStandardToken(tokenAddress).balanceOf(poolAddress) , "Less token balance in pool for incentive distribution");

        governanceDat.setProposalIncentive(_proposalId, dappIncentive);
        governanceDat.setProposalCategory(_proposalId, _categoryId, tokenAddress);
        governanceDat.changeProposalStatus(_proposalId, uint8(ProposalStatus.AwaitingSolution));
    }

    /// @dev Opens proposal for voting
    function openProposalForVoting(uint _proposalId) 
        internal onlyProposalOwner(_proposalId) checkProposalValidity(_proposalId) 
    {
        uint category = governanceDat.getProposalCategory(_proposalId);

        require (category!=0 , "Proposal category should be greater than 0");

        require(governanceDat.getTotalSolutions(_proposalId) > 1 , "Proposal should contain atleast two solutions before it is open for voting");
        governanceDat.changeProposalStatus(_proposalId, uint8(ProposalStatus.VotingStarted));
        uint closingTime;
        (,,,,closingTime,,) = proposalCategory.getCategoryDetails(category);
        closingTime = SafeMath.add(closingTime, now); // solhint-disable-line
        address votingType = governanceDat.getLatestVotingAddress();
        eventCaller.callCloseProposalOnTimeAtAddress(_proposalId, votingType, closingTime);
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
            uint totalProposal, 
            uint totalSolution, 
            uint totalVotes
        ) 
    {
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
            if (_memberAddress == governanceDat.getSolutionOwnerByProposalIdAndIndex(_proposalId, i)) {
                proposalId = _proposalId;
                solutionId = i;
                proposalStatus = governanceDat.getProposalStatus(_proposalId);
                finalVerdict = governanceDat.getProposalFinalVerdict(_proposalId);
                totalReward = governanceDat.getProposalIncentive(_proposalId);
                subCategory = governanceDat.getProposalCategory(_proposalId);
                break;
            }
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

        governanceDat.changeProposalStatus(_proposalId, uint8(ProposalStatus.AwaitingSolution));

        submitSolution(
            _proposalId, 
            _solutionHash, 
            _action
        );

        openProposalForVoting(
            _proposalId
        );
    }

    /// @dev When creating proposal with solution, it adds solution details against proposal
    function submitSolution(
        uint _proposalId, 
        string _solutionHash, 
        bytes _action
    ) 
        internal  
    {
        VotingType votingType = VotingType(governanceDat.getLatestVotingAddress());
        votingType.addSolution(
            uint32(_proposalId), 
            msg.sender, 
            _solutionHash, 
            _action
        );
    }

    /// @dev Creates a new proposal
    /// @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
    /// @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
    /// @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
    function _createProposalwithSolution(
        string _proposalTitle, 
        string _proposalSD, 
        string _proposalDescHash,
        uint _categoryId, 
        string _solutionHash, 
        bytes _action,
        uint _proposalId
    ) 
        internal
    {
        createProposal(_proposalTitle, _proposalSD, _proposalDescHash, _categoryId);

        proposalSubmission(
            _proposalId, 
            _solutionHash, 
            _action
        );
    }

}