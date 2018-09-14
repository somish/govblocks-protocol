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
import "./Governance.sol";
import "./MemberRoles.sol";
import "./Upgradeable.sol";
import "./GBTStandardToken.sol";
import "./ProposalCategory.sol";
import "./Pool.sol";
import "./imports/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./EventCaller.sol";
import "./imports/govern/Governed.sol";


contract SimpleVoting is Upgradeable {
    using SafeMath for uint;
    GovernanceData public governanceDat;
    MemberRoles public memberRole;
    Governance public governance;
    ProposalCategory public proposalCategory;
    bool public constructorCheck;
    Pool public pool;
    EventCaller public eventCaller;
    GovernChecker public governChecker;
    bytes32 public votingTypeName;

    struct ProposalVote {
        address voter;
        uint64 solutionChosen;
        uint32 proposalId;
        uint voteValue;
    }

    mapping(address => mapping(uint => uint)) internal addressProposalVote;
    mapping(uint => mapping(uint => uint[])) internal proposalRoleVote;
    mapping(address => uint[]) internal allVotesByMember;
    mapping(uint => bool) public rewardClaimed;
    

    ProposalVote[] internal allVotes;

    modifier onlySelf {
        require(msg.sender == address(this));
        _;
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
        if (msg.sender == _memberAddress) {
            require(validateStake(_proposalId, _memberAddress));
        } else
            require(master.isInternal(msg.sender));
        require(!alreadyAdded(_proposalId, _memberAddress));
        governanceDat.setSolutionAdded(_proposalId, _memberAddress, _action);
        uint solutionId = governanceDat.getTotalSolutions(_proposalId);
        governanceDat.callSolutionEvent(_proposalId, _memberAddress, solutionId - 1, _solutionHash, now); //solhint-disable-line

    }

    /// @dev Casts vote
    /// @param _proposalId Proposal id
    /// @param _solutionChosen solution chosen while voting. _solutionChosen[0] is the chosen solution
    function proposalVoting(uint32 _proposalId, uint64[] _solutionChosen) external {
        _addVote(_proposalId, _solutionChosen[0], msg.sender);
    } 

    function initialVote(uint32 _proposalId, address _voter) external onlyInternal {
        _addVote(_proposalId, 1, _voter);
    }

    /// @dev Initiates simple voting contract
    function simpleVotingInitiate() public {
        require(!constructorCheck);
        votingTypeName = "Simple Voting";
        allVotes.push(ProposalVote(address(0), 0, 0, 1));
        rewardClaimed[0] = true;
        constructorCheck = true;
    }

    /// @dev updates dependancies
    function updateDependencyAddresses() public {
        if (!constructorCheck)
            simpleVotingInitiate();
        governanceDat = GovernanceData(master.getLatestAddress("GD"));
        memberRole = MemberRoles(master.getLatestAddress("MR"));
        proposalCategory = ProposalCategory(master.getLatestAddress("PC"));
        governance = Governance(master.getLatestAddress("GV"));
        pool = Pool(master.getLatestAddress("PL"));
        eventCaller = EventCaller(master.getEventCallerAddress());
        governChecker = GovernChecker(master.getGovernCheckerAddress());
    }

    function claimVoteReward(address _memberAddress, uint[] _proposals) 
        public onlyInternal returns(uint pendingGBTReward, uint pendingDAppReward) 
    {
        uint voteId;
        uint solutionChosen;
        uint proposalStatus;
        uint finalVredict;
        uint voteValue;
        uint totalReward;
        uint subCategory;
        uint calcReward;
        uint i = _proposals.length;

        //0th element is skipped always as sometimes we actually need length of _proposals be 0. 
        for (i--; i > 0; i--) {
            voteId = addressProposalVote[_memberAddress][_proposals[i]];

            require(!rewardClaimed[voteId]);

            rewardClaimed[voteId] = true;
            (solutionChosen, proposalStatus, finalVredict, voteValue, totalReward, subCategory) = 
                getVoteDetailsForReward(voteId, _proposals[i]);
            require(proposalStatus > 2);
            if (finalVredict > 0 && solutionChosen == finalVredict) {
                calcReward = (proposalCategory.getRewardPercVote(subCategory) * voteValue * totalReward) 
                    / (100 * governanceDat.getProposalTotalVoteValue(_proposals[i]));
                
            } else if (!governanceDat.punishVoters() && finalVredict > 0) {
                calcReward = (proposalCategory.getRewardPercVote(subCategory) * voteValue * totalReward) 
                    / (100 * governanceDat.getProposalTotalVoteValue(_proposals[i]));
                
            }
            if (proposalCategory.isSubCategoryExternal(subCategory))    
                pendingGBTReward = calcReward;
            else
                pendingDAppReward = calcReward;
        }
        
    }

    function getPendingReward(address _memberAddress, uint _lastRewardVoteId) 
        public view returns(uint pendingGBTReward, uint pendingDAppReward) 
    {
        uint i;
        uint totalVotes = allVotesByMember[_memberAddress].length;
        uint voteId;
        uint proposalId;
        uint tempGBTReward;
        uint tempDAppReward;
        for (i = _lastRewardVoteId; i < totalVotes; i++) {
            voteId = allVotesByMember[_memberAddress][i];
            if (!rewardClaimed[voteId]) {
                proposalId = allVotes[voteId].proposalId;
                (tempGBTReward, tempDAppReward) = calculatePendingVoteReward(_memberAddress, i, proposalId);
                pendingGBTReward += tempGBTReward;
                pendingDAppReward += tempDAppReward;
            }
        }
    }

    /// @dev Checks if the solution is already added by a member against specific proposal
    /// @param _proposalId Proposal id
    /// @param _memberAddress Member address
    function alreadyAdded(uint _proposalId, address _memberAddress) public view returns(bool) {
        for (uint i = 1; i < governanceDat.getTotalSolutions(_proposalId); i++) {
            if (governanceDat.getSolutionAddedByProposalId(_proposalId, i) == _memberAddress)
                return true;
        }
    }

    /// @dev gets dApp name 
    function dAppName() public view returns (bytes32) {
        return master.dAppName();
    }

    function getAllVoteIdsByAddress(address _memberAddress) public view returns(uint[]) {
        return allVotesByMember[_memberAddress];
    }

    function getTotalNumberOfVotesByAddress(address _memberAddress) public view returns(uint) {
        return allVotesByMember[_memberAddress].length;
    }

    /// @dev Gets vote details by id such as Vote value, Address of the voter and Solution id for which he has voted.
    function getVoteDetailById(uint _voteId) 
        public 
        view 
        returns(
            address, 
            uint64[], 
            uint,
            uint32
        ) 
    {
        uint64[] memory solutionChosen = new uint64[](1);
        solutionChosen[0] = allVotes[_voteId].solutionChosen;
        return (
            allVotes[_voteId].voter, 
            solutionChosen, 
            allVotes[_voteId].voteValue, 
            allVotes[_voteId].proposalId
        );
    }

    /// @dev Returns the solution index that was being voted
    function getSolutionByVoteId(uint _voteId) public view returns(uint64[]) {
        uint64[] memory solutionChosen = new uint64[](1);
        solutionChosen[0] = allVotes[_voteId].solutionChosen;
        return (solutionChosen);
    }

    /// @dev Gets Solution id against which vote had been casted
    /// @param _solutionChosenId To get solution id at particular index 
    ///     from solutionChosen array i.e. 0 is passed In case of Simple Voting Type.
    function getSolutionByVoteIdAndIndex(uint _voteId, uint _solutionChosenId) 
        public 
        view 
        returns(uint) 
    {
        require(_solutionChosenId == 0);
        
        return (allVotes[_voteId].solutionChosen);
    }

    /// @dev Gets Vote id Against proposal when passing proposal id and member addresse
    function getVoteIdAgainstMember(address _memberAddress, uint _proposalId) 
        public 
        view 
        returns(uint voteId) 
    {
        voteId = addressProposalVote[_memberAddress][_proposalId];
    }

    /// @dev Gets voter address
    function getVoterAddress(uint _voteId) public view returns(address _voterAddress) {
        return (allVotes[_voteId].voter);
    }

    /// @dev Gets All the Role specific vote ids against proposal 
    /// @param _roleId Role id which number of votes to be fetched.
    /// @return totalVotes Total votes casted by this particular role id.
    function getAllVoteIdsByProposalRole(uint _proposalId, uint _roleId) public view returns(uint[] totalVotes) {
        return proposalRoleVote[_proposalId][_roleId];
    }

    /// @dev Gets Total number of votes of specific role against proposal
    function getAllVoteIdsLengthByProposalRole(uint _proposalId, uint _roleId) public view returns(uint length) {
        return proposalRoleVote[_proposalId][_roleId].length;
    }

    /// @dev Gets vote value against Vote id
    function getVoteValue(uint _voteId) public view returns(uint) {
        return (allVotes[_voteId].voteValue);
    }

    /// @dev Gets total number of votes 
    function allVotesTotal() public view returns(uint) {
        return allVotes.length;
    }

    /// @dev Closes Proposal Voting after All voting layers done with voting or Time out happens.
    function closeProposalVote(uint _proposalId) public {
        uint category = proposalCategory.getCategoryIdBySubId(governanceDat.getProposalSubCategory(_proposalId));
        uint currentVotingId = governanceDat.getProposalCurrentVotingId(_proposalId);
        uint _mrSequenceId = proposalCategory.getRoleSequencAtIndex(category, currentVotingId);
        uint64 max;
        uint totalVoteValue;
        uint i;
        uint voteId;
        uint voteValue;
        

        require(checkForClosing(_proposalId, _mrSequenceId, category, currentVotingId) == 1);
        uint voteLen = proposalRoleVote[_proposalId][_mrSequenceId].length;
        uint[] memory finalVoteValue = new uint[](governanceDat.getTotalSolutions(_proposalId));
        for (i = 0; i < voteLen; i++) {
            voteId = proposalRoleVote[_proposalId][_mrSequenceId][i];
            voteValue = allVotes[voteId].voteValue;
            totalVoteValue = totalVoteValue + voteValue;
            finalVoteValue[allVotes[voteId].solutionChosen] = 
                finalVoteValue[allVotes[voteId].solutionChosen].add(voteValue);
        }

        totalVoteValue = totalVoteValue + governanceDat.getProposalTotalVoteValue(_proposalId);
        governanceDat.setProposalTotalVoteValue(_proposalId, totalVoteValue);

        for (i = 0; i < finalVoteValue.length; i++) {
            if (finalVoteValue[max] < finalVoteValue[i]) {
                max = uint64(i);
            }
        }

        if (checkForThreshold(_proposalId, _mrSequenceId)) {
            closeProposalVote1(finalVoteValue[max], totalVoteValue, category, _proposalId, max);
        } else {
            uint64 interVerdict = governanceDat.getProposalIntermediateVerdict(_proposalId);
            governanceDat.updateProposalDetails(_proposalId, currentVotingId, max, interVerdict);
            if (governanceDat.getProposalCurrentVotingId(_proposalId) + 1 
                < proposalCategory.getRoleSequencLength(category)
            )
                governanceDat.changeProposalStatus(_proposalId, 7);
            else
                governanceDat.changeProposalStatus(_proposalId, 6);
        }
    }

    /// @dev ads an authorized address to goovernChecker
    function addAuthorized(address _newVotingAddress) public onlySelf {
        governChecker.addAuthorized(master.dAppName(), _newVotingAddress);
    }

    /// @dev ads a voting type
    function addVotingType(address _newVotingAddress, bytes2 _name) public onlySelf {
        governChecker.addAuthorized(master.dAppName(), _newVotingAddress);
        master.addNewContract(_name, _newVotingAddress);
        governanceDat.setVotingTypeDetails(_name, _newVotingAddress);
    }

    /// @dev transfers authority and funds to new addresses
    function upgrade() public onlySelf {
        address newSV = master.getLatestAddress("SV");
        if (newSV != address(this)) {
            governChecker.updateAuthorized(master.dAppName(), newSV);
            governanceDat.editVotingTypeDetails(0, newSV);
        }
        pool.transferAssets();
    } 

    /// @dev Checks If the proposal voting time is up and it's ready to close 
    ///      i.e. Closevalue is 1 in case of closing, 0 otherwise!
    /// @param _proposalId Proposal id to which closing value is being checked
    /// @param _roleId Voting will gets close for the role id provided here.
    function checkForClosing(uint _proposalId, uint _roleId, uint _category, uint _currentVotingId) 
        public 
        view 
        returns(uint8 closeValue) 
    {
        uint dateUpdate;
        uint pStatus;
        uint _closingTime;
        uint _majorityVote;

        require(!governanceDat.proposalPaused(_proposalId));
        
        (, , dateUpdate, , pStatus) = governanceDat.getProposalDetailsById1(_proposalId);
        (, _majorityVote, _closingTime) = proposalCategory.getCategoryData3(
            _category, 
            _currentVotingId
        );
        if (pStatus == 2 && _roleId != 2 && _roleId != 0) {
            if (SafeMath.add(dateUpdate, _closingTime) <= now ||  //solhint-disable-line
                proposalRoleVote[_proposalId][_roleId].length == memberRole.getAllMemberLength(_roleId)
            )
                closeValue = 1;
        } else if (pStatus == 2) {
            if (SafeMath.add(dateUpdate, _closingTime) <= now) //solhint-disable-line
                closeValue = 1;
        } else if (pStatus > 2) {
            closeValue = 2;
        } else {
            closeValue = 0;
        }
    }

    /// @dev Does category specific tasks
    function finalActions(uint _proposalId) internal {
        uint subCategory = governanceDat.getProposalSubCategory(_proposalId); 
        if (subCategory == 11) {
            addAuthorized(governanceDat.getLatestVotingAddress());
        }
    }

    /// @dev This does the remaining functionality of closing proposal vote
    function closeProposalVote1(uint maxVoteValue, uint totalVoteValue, uint category, uint _proposalId, uint64 max) 
        internal 
    {
        uint _closingTime;
        uint _majorityVote;
        uint currentVotingId = governanceDat.getProposalCurrentVotingId(_proposalId);
        (, _majorityVote, _closingTime) = proposalCategory.getCategoryData3(category, currentVotingId);
        if (SafeMath.div(SafeMath.mul(maxVoteValue, 100), totalVoteValue) >= _majorityVote) {
            if (max > 0) {
                currentVotingId = currentVotingId + 1;
                if (currentVotingId < proposalCategory.getRoleSequencLength(category)) {
                    governanceDat.updateProposalDetails(
                        _proposalId, 
                        currentVotingId, 
                        max, 
                        0
                    );
                    eventCaller.callCloseProposalOnTime(_proposalId, _closingTime + now); //solhint-disable-line
                } else {
                    governanceDat.updateProposalDetails(_proposalId, currentVotingId - 1, max, max);
                    governanceDat.changeProposalStatus(_proposalId, 3);
                    uint subCategory = governanceDat.getProposalSubCategory(_proposalId);
                    bytes2 contractName = proposalCategory.getContractName(subCategory);
                    address actionAddress;
                    if (contractName == "EX")
                        actionAddress = proposalCategory.getContractAddress(subCategory);
                    else
                        actionAddress = master.getLatestAddress(contractName);
                    if (actionAddress.call(governanceDat.getSolutionActionByProposalId(_proposalId, max))) { //solhint-disable-line
                        eventCaller.callActionSuccess(_proposalId);
                    }
                    eventCaller.callProposalAccepted(_proposalId);
                    finalActions(_proposalId);
                }
            } else {
                governanceDat.updateProposalDetails(_proposalId, currentVotingId, max, max);
                governanceDat.changeProposalStatus(_proposalId, 4);
            }
        } else {
            governanceDat.updateProposalDetails(
                _proposalId, 
                currentVotingId, 
                max, 
                governanceDat.getProposalIntermediateVerdict(_proposalId)
            );
            governanceDat.changeProposalStatus(_proposalId, 5);
        }
    }

    /// @dev Checks if the vote count against any solution passes the threshold value or not.
    function checkForThreshold(uint _proposalId, uint _mrSequenceId) internal view returns(bool) {
        uint thresHoldValue;
        if (_mrSequenceId == 2) {
            uint totalTokens;
            address token = governanceDat.getStakeToken(_proposalId);
            GBTStandardToken tokenInstance = GBTStandardToken(token);
            for (uint i = 0; i < proposalRoleVote[_proposalId][_mrSequenceId].length; i++) {
                uint voteId = proposalRoleVote[_proposalId][_mrSequenceId][i];
                address voterAddress = allVotes[voteId].voter;
                totalTokens = totalTokens.add(tokenInstance.balanceOf(voterAddress));
            }

            thresHoldValue = totalTokens.mul(100) / tokenInstance.totalSupply();
            if (thresHoldValue > governanceDat.quorumPercentage())
                return true;
        } else if (_mrSequenceId == 0) {
            return true;
        } else {
            thresHoldValue = (getAllVoteIdsLengthByProposalRole(_proposalId, _mrSequenceId) * 100)
                / memberRole.getAllMemberLength(_mrSequenceId);
            if (thresHoldValue > governanceDat.quorumPercentage())
                return true;
        }
    }

    function calculatePendingVoteReward(address _memberAddress, uint _voteNo, uint _proposalId) 
        internal
        view
        returns (uint pendingGBTReward, uint pendingDAppReward) 
    {
        uint solutionChosen;
        uint proposalStatus;
        uint finalVredict;
        uint voteValue;
        uint totalReward;
        uint subCategory;
        uint calcReward;

        (solutionChosen, proposalStatus, finalVredict, voteValue, totalReward, subCategory) = 
            getVoteDetailsToCalculateReward(_memberAddress, _voteNo);

        if (finalVredict > 0 && solutionChosen == finalVredict && totalReward != 0) {
            calcReward = (proposalCategory.getRewardPercVote(subCategory) * voteValue * totalReward) 
                / (100 * governanceDat.getProposalTotalVoteValue(_proposalId));

        } else if (!governanceDat.punishVoters() && finalVredict > 0 && totalReward != 0) {
            calcReward = (proposalCategory.getRewardPercVote(subCategory) * voteValue * totalReward) 
                / (100 * governanceDat.getProposalTotalVoteValue(_proposalId));
        }
        if (proposalCategory.isSubCategoryExternal(subCategory))    
            pendingGBTReward = calcReward;
        else
            pendingDAppReward = calcReward;
    }

    /// @dev Gets vote id details when giving member address and proposal id
    function getVoteDetailsToCalculateReward(
        address _memberAddress, 
        uint _voteNo
    ) 
        internal 
        view 
        returns(
            uint solutionChosen, 
            uint proposalStatus, 
            uint finalVerdict, 
            uint voteValue, 
            uint totalReward, 
            uint subCategory
        ) 
    {
        uint voteId = allVotesByMember[_memberAddress][_voteNo];
        uint proposalId = allVotes[voteId].proposalId;
        voteValue = allVotes[voteId].voteValue;
        solutionChosen = allVotes[voteId].solutionChosen;
        proposalStatus = governanceDat.getProposalStatus(proposalId);
        finalVerdict = governanceDat.getProposalFinalVerdict(proposalId);
        totalReward = governanceDat.getProposalIncentive(proposalId);
        subCategory = governanceDat.getProposalSubCategory(proposalId);
    }

    /// @dev Gets vote id details for reward
    function getVoteDetailsForReward(uint _voteId, uint _proposalId) 
        internal 
        view 
        returns(
            uint solutionChosen, 
            uint proposalStatus, 
            uint finalVerdict, 
            uint voteValue, 
            uint totalReward, 
            uint subCategory
        ) 
    {
        voteValue = allVotes[_voteId].voteValue;
        solutionChosen = allVotes[_voteId].solutionChosen;
        proposalStatus = governanceDat.getProposalStatus(_proposalId);
        finalVerdict = governanceDat.getProposalFinalVerdict(_proposalId);
        totalReward = governanceDat.getProposalIncentive(_proposalId);
        subCategory = governanceDat.getProposalSubCategory(_proposalId);
    }

    function _getLockedBalance(address _token, address _of, uint _time) 
        internal view returns(uint lockedTokens) 
    {
        GBTStandardToken tokenInstance = GBTStandardToken(_token);
        _time += now; //solhint-disable-line
        lockedTokens = tokenInstance.tokensLockedAtTime(_of, "GOV", _time);
    }

    function _addVote(uint32 _proposalId, uint64 _solution, address _voter) internal {
        //Variables are reused to save gas. We know that this reduces code readability but proposalVoting is
        //where gas usage should be optimized as much as possible. voters should not feel burdened while voting.
        require(addressProposalVote[_voter][_proposalId] == 0);

        require(validateStake(_proposalId, _voter));

        uint categoryThenMRSequence;
        uint intermediateVerdict;
        uint currentVotingIdThenVoteValue;

        (categoryThenMRSequence, currentVotingIdThenVoteValue, intermediateVerdict) 
            = governanceDat.getProposalDetailsForSV(_proposalId);

        categoryThenMRSequence = 
            proposalCategory.getMRSequenceBySubCat(categoryThenMRSequence, currentVotingIdThenVoteValue);
        //categoryThenMRSequence is now MemberRoleSequence

        require(memberRole.checkRoleIdByAddress(_voter, categoryThenMRSequence));

        if (currentVotingIdThenVoteValue == 0)
            require(_solution <= governanceDat.getTotalSolutions(_proposalId));
        else
            require(_solution == intermediateVerdict || _solution == 0);

        currentVotingIdThenVoteValue = calculateVoteValue(_proposalId, _voter);
        //currentVotingIdThenVoteValue is now VoteValue

        proposalRoleVote[_proposalId][categoryThenMRSequence].push(allVotes.length);
        allVotesByMember[_voter].push(allVotes.length);
        addressProposalVote[_voter][_proposalId] = allVotes.length;
        governanceDat.callVoteEvent(_voter, _proposalId, now, allVotes.length); //solhint-disable-line
        allVotes.push(ProposalVote(_voter, _solution, _proposalId, currentVotingIdThenVoteValue));

        if (proposalRoleVote[_proposalId][categoryThenMRSequence].length
            == memberRole.getAllMemberLength(categoryThenMRSequence) 
            && categoryThenMRSequence != 2
            && categoryThenMRSequence != 0
        ) {
            eventCaller.callVoteCast(_proposalId);
        }
    }

    /// @dev validates that the voter has enough tokens locked for voting
    function validateStake(uint32 _proposalId, address _of) internal view returns(bool success) {
        address token;
        uint subCat;
        uint minStake;
        uint tokenHoldingTime;
        (token, subCat) = governanceDat.getTokenAndSubCat(_proposalId);
        (minStake, tokenHoldingTime) = proposalCategory.getRequiredStake(subCat);

        if (minStake == 0)
            return true; 
        
        if (_getLockedBalance(token, _of, tokenHoldingTime) >= minStake)
            return true;
    }

    /// @dev validates that the voter has enough tokens locked for voting and returns vote value
    ///     Seperate function from validateStake to save gas.
    function calculateVoteValue(uint32 _proposalId, address _of) 
        internal view returns(uint voteValue) 
    {
        address token;
        uint subCat;
        uint tokenHoldingTime;
        uint stakeWeight;
        uint bonusStake;
        uint reputationWeight;
        uint bonusReputation;
        uint memberReputation;
        uint balance;

        (stakeWeight, bonusStake, reputationWeight, bonusReputation, memberReputation, token, subCat) 
            = governanceDat.getMemberReputationSV(_of, _proposalId);
        tokenHoldingTime = proposalCategory.getTokenHoldingTime(subCat);
        
        balance = _getLockedBalance(token, _of, tokenHoldingTime);
    
        balance = SafeMath.div(balance, GBTStandardToken(token).decimals());
        stakeWeight = SafeMath.mul(SafeMath.add(log(balance), bonusStake), stakeWeight);
        reputationWeight = SafeMath.mul(SafeMath.add(log(memberReputation), bonusReputation), reputationWeight);
        voteValue = SafeMath.add(stakeWeight, reputationWeight);
    }

    /* solhint-disable */
    ///@dev calculates log2. Taken from stackoverflow.
    function log(uint x) internal pure returns (uint y) {
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
    /* solhint-enable */
}
