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
        (, , , , mrAllowed, , ) = proposalCategory.category(category);
        for (uint i = 0; i < mrAllowed.length; i++) {
            if (mrAllowed[i] == 0 || memberRole.checkRole(msg.sender, mrAllowed[i]))
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

        uint _proposalId = governanceDat.getProposalLength();

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
        
        governanceDat.addNewProposal(msg.sender);
    }

    /// @dev Categorizes proposal to proceed further. Categories shows the proposal objective.
    function categorizeProposal(
        uint _proposalId, 
        uint _categoryId
    ) 
        public
        checkProposalValidity(_proposalId)
    {

        require(
            governanceDat.getTotalSolutions(_proposalId) < 2,
            "Categorization not possible, since solutions had already been submitted"
        );

        uint dafaultIncentive;
        (, , , dafaultIncentive) = proposalCategory.categoryAction(_categoryId);


        if (!memberRole.checkRole(msg.sender, 1)) {
            require(allowedToCreateProposal(_categoryId), "User not authorized to categorize this proposal"); 
            require(validateStake(_categoryId, dAppLocker), "Lock more tokens");
        }

        require(
            dafaultIncentive <= GBTStandardToken(dAppLocker).balanceOf(poolAddress),
            "Less token balance in pool for incentive distribution"
        );

        governanceDat.setProposalCategory_Incentive(_proposalId, _categoryId, dafaultIncentive);
        governanceDat.changeProposalStatus(_proposalId, uint8(ProposalStatus.AwaitingSolution));
    }

    /// @dev Initiates add solution 
    /// @param _memberAddress Address of member who is adding the solution
    /// @param _solutionHash Solution hash having required data against adding solution
    function addSolution(
        uint32 _proposalId,
        address _memberAddress, 
        string _solutionHash, 
        bytes _action
    ) 
        external 
    {
        require(
            governanceDat.getProposalStatus(_proposalId) >= uint(Governance.ProposalStatus.AwaitingSolution),
            "Proposal should be open for solution submission"
        );
        require(validateStake(_proposalId, msg.sender), "Lock more tokens");

        _addSolution( _proposalId, _memberAddress, _action, _solutionHash);
    }

    function _addSolution(uint _proposalId, address _memberAddress, bytes _action, string _solutionHash)
        internal
    {
        require(!alreadyAdded(_proposalId, _memberAddress), "User already added a solution for this proposal");
        governanceDat.setSolutionAdded(_proposalId, _memberAddress, _action, _solutionHash);
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
        proposalSubmission(_proposalId, msg.sender, _solutionHash, _action);
    }


    /// @dev Creates a new proposal with solution and votes for the solution
    /// @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
    /// @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
    /// @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
    function createProposalwithSolution(
        string _proposalTitle, 
        string _proposalSD, 
        string _proposalDescHash,
        uint _categoryId, 
        string _solutionHash, 
        bytes _action
    ) 
        external
    {
        require(allowedToCreateProposal(_categoryId), "User not authorized to create proposal under this category");
        uint proposalId = governanceDat.getProposalLength();

        createProposal(_proposalTitle, _proposalSD, _proposalDescHash, _categoryId);

        categorizeProposal(proposalId, _categoryId);
        
        proposalSubmission(
            _proposalId,
            msg.sender,
            _solutionHash, 
            _action
        );

        _addVote(uint32(proposalId), 1, msg.sender);
    }





    /// @dev checks if the msg.sender has enough tokens locked for creating a proposal or solution
    function validateStake(uint _categoryId, address _token) public view returns(bool) {
        uint minStake;
        uint tokenholdingTime;
        (, , , , , , minStake) = proposalCategory.category(_categoryId);
        tokenholdingTime = governanceDat.getTokenHoldingTime();
        if (minStake == 0)
            return true;
        GBTStandardToken tokenInstance = GBTStandardToken(_token);
        tokenholdingTime = SafeMath.add(tokenholdingTime, now); // solhint-disable-line
        uint lockedTokens = tokenInstance.tokensLockedAtTime(msg.sender, "GOV", tokenholdingTime);
        if (lockedTokens >= minStake)
            return true;
    }

    /// @dev Opens proposal for voting
    function openProposalForVoting(uint _proposalId) 
        public onlyProposalOwner(_proposalId) checkProposalValidity(_proposalId) 
    {
        uint category = governanceDat.getProposalCategory(_proposalId);

        require(category != 0, "Proposal category should be greater than 0");

        require(
            governanceDat.getTotalSolutions(_proposalId) > 1,
            "Proposal should contain atleast two solutions before it is open for voting"
        );
        governanceDat.changeProposalStatus(_proposalId, uint8(ProposalStatus.VotingStarted));
        uint closingTime;
        (, , , , , closingTime, ) = proposalCategory.category(category);
        closingTime = SafeMath.add(closingTime, now); // solhint-disable-line
        address votingType = governanceDat.getLatestVotingAddress();
        eventCaller.callCloseProposalOnTimeAtAddress(_proposalId, votingType, closingTime);
    }

    function _addVote(uint32 _proposalId, uint64 _solution, address _voter) internal {
        //Variables are reused to save gas. We know that this reduces code readability but proposalVoting is
        //where gas usage should be optimized as much as possible. voters should not feel burdened while voting.
        require(addressProposalVote[_voter][_proposalId] == 0);

        require(governanceDat.getProposalStatus(_proposalId) == uint(Governance.ProposalStatus.VotingStarted));

        require(validateStake(_proposalId, _voter));

        uint categoryThenMRSequence;
        uint voteValue;

        (categoryThenMRSequence) 
            = governanceDat.getProposalCategory(_proposalId);

        (, categoryThenMRSequence, , , , , ) = proposalCategory.category(categoryThenMRSequence);
        //categoryThenMRSequence is now MemberRoleSequence

        require(memberRole.checkRole(_voter, categoryThenMRSequence));
        require(_solution <= governanceDat.getTotalSolutions(_proposalId));

        voteValue = calculateVoteValue(_proposalId, _voter);

        proposalRoleVote[_proposalId].push(allVotes.length);
        allVotesByMember[_voter].push(allVotes.length);
        addressProposalVote[_voter][_proposalId] = allVotes.length;
        governanceDat.callVoteEvent(_voter, _proposalId, now, allVotes.length); //solhint-disable-line
        allVotes.push(ProposalVote(_voter, _solution, _proposalId, voteValue));

        if (proposalRoleVote[_proposalId].length
            == memberRole.numberOfMembers(categoryThenMRSequence) 
            && categoryThenMRSequence != 2
            && categoryThenMRSequence != 0
        ) {
            eventCaller.callVoteCast(_proposalId);
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
        address _ownerAddress,
        string _solutionHash,
        bytes _action
    ) 
        internal
    {

        governanceDat.changeProposalStatus(_proposalId, uint8(ProposalStatus.AwaitingSolution));

        _addSolution(
            _proposalId,
            _ownerAddress,
            _solutionHash,
            _action
        );

        openProposalForVoting(
            _proposalId
        );
    }

}