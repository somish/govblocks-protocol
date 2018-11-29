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
import "./interfaces/IProposalCategory.sol";
import "./imports/govern/Governed.sol";
import "./ProposalCategoryAdder.sol";


contract ProposalCategory is IProposalCategory, Governed {

    bool public constructorCheck;
    bool public adderCheck;
    address public officialPCA;

    struct Category {
        uint memberRoleToVote;
        uint majorityVotePerc;
        uint quorumPerc;
        uint[] allowedToCreateProposal;
        uint closingTime;
        uint tokenHoldingTime;
        uint minStake;
    }

    struct CategoryAction {
        uint defaultIncentive;
        address contractAddress;
        bytes2 contractName;        
    }

    event CategoryEvent(uint indexed categoryId, string categoryName, string actionHash);

    Category[] internal allCategory;
    mapping (uint => CategoryAction) internal categoryActionData;
    
    /// @dev Adds new category
    /// @param _name Category name
    /// @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
    /// @param _majorityVotePerc Majority Vote threshold for Each voting layer
    /// @param _quorumPerc minimum threshold percentage required in voting to calculate result
    /// @param _allowedToCreateProposal Member roles allowed to create the proposal
    /// @param _closingTime Vote closing time for Each voting layer
    /// @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
    /// @param _contractAddress address of contract to call after proposal is accepted
    /// @param _contractName name of contract to be called after proposal is accepted
    /// @param _tokenHoldingTime minimum time that user need to lock tokens to create proposal under this category
    /// @param _incentives rewards to distributed after proposal is accepted
    function addCategory(
        string _name, 
        uint _memberRoleToVote,
        uint _majorityVotePerc, 
        uint _quorumPerc,
        uint[] _allowedToCreateProposal,
        uint _closingTime,
        string _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint _tokenHoldingTime,
        uint[] _incentives
    ) 
        public
        onlyAuthorizedToGovern 
    {
        categoryActionData[allCategory.length].defaultIncentive = _incentives[1];        
        categoryActionData[allCategory.length].contractName = _contractName;
        categoryActionData[allCategory.length].contractAddress = _contractAddress;        
        allCategory.push((
            Category(
                _memberRoleToVote,
                _majorityVotePerc,
                _quorumPerc,
                _allowedToCreateProposal,
                _closingTime,
                _tokenHoldingTime,
                _incentives[0]
            ))
        );

        emit CategoryEvent(allCategory.length-1, _name, _actionHash);
    }

    /// @dev Updates category details
    /// @param _categoryId Category id that needs to be updated
    /// @param _name Category name
    /// @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
    /// @param _allowedToCreateProposal Member roles allowed to create the proposal
    /// @param _majorityVotePerc Majority Vote threshold for Each voting layer
    /// @param _quorumPerc minimum threshold percentage required in voting to calculate result
    /// @param _closingTime Vote closing time for Each voting layer
    /// @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
    /// @param _contractAddress address of contract to call after proposal is accepted
    /// @param _contractName name of contract to be called after proposal is accepted
    /// @param _tokenHoldingTime minimum time that user need to lock tokens to create proposal under this category
    /// @param _incentives rewards to distributed after proposal is accepted
    function updateCategory(
        uint _categoryId, 
        string _name, 
        uint _memberRoleToVote, 
        uint _majorityVotePerc, 
        uint _quorumPerc,
        uint[] _allowedToCreateProposal,
        uint _closingTime,
        uint _tokenHoldingTime,
        string _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint[] _incentives
    )
        public
        onlyAuthorizedToGovern
    { 
        allCategory[_categoryId].memberRoleToVote = _memberRoleToVote;
        allCategory[_categoryId].majorityVotePerc = _majorityVotePerc;
        allCategory[_categoryId].closingTime = _closingTime;
        allCategory[_categoryId].allowedToCreateProposal = _allowedToCreateProposal;
        allCategory[_categoryId].tokenHoldingTime = _tokenHoldingTime;
        allCategory[_categoryId].minStake = _incentives[0];
        allCategory[_categoryId].quorumPerc = _quorumPerc;

        categoryActionData[_categoryId].defaultIncentive = _incentives[1];
        categoryActionData[_categoryId].contractName = _contractName;
        categoryActionData[_categoryId].contractAddress = _contractAddress;
        emit CategoryEvent(_categoryId, _name, _actionHash);
    }

    /// @dev gets category details
    function category(uint _categoryId) public view returns(uint, uint, uint, uint[], uint, uint, uint) {
        return(
            _categoryId,
            allCategory[_categoryId].memberRoleToVote,
            allCategory[_categoryId].majorityVotePerc,
            allCategory[_categoryId].allowedToCreateProposal,
            allCategory[_categoryId].closingTime,
            allCategory[_categoryId].tokenHoldingTime,
            allCategory[_categoryId].minStake
        );
    }

    function categoryQuorum(uint _categoryId) public view returns(uint, uint) {
        return (_categoryId, allCategory[_categoryId].quorumPerc);
    }

    function categoryAction(uint _categoryId) public view returns(uint, address, bytes2, uint) {
        return(
            _categoryId,
            categoryActionData[_categoryId].contractAddress,
            categoryActionData[_categoryId].contractName,
            categoryActionData[_categoryId].defaultIncentive
        );
    }

   /// @dev Gets Total number of categories added till now
    function totalCategories() public view returns(uint) {
        return allCategory.length;
    }

    function addInitialCategories(
        string _name,
        uint _memberRoleToVote,
        uint _majorityVotePerc, 
        uint _quorumPerc,
        uint[] _allowedToCreateProposal,
        uint _closingTime,
        string _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint _tokenHoldingTime,
        uint[] _incentives
    ) 
        public 
    {
        require(allCategory.length < 18);
        require(msg.sender == officialPCA || officialPCA == address(0));
        // allSubIdByCategory[_mainCategoryId].push(allSubCategory.length);
        addCategory(
                _name,
                _memberRoleToVote,
                _majorityVotePerc,
                _quorumPerc,
                _allowedToCreateProposal,
                _closingTime,
                _actionHash,
                _contractAddress,
                _contractName,
                _tokenHoldingTime,
                _incentives
            );
    }

    /// @dev Initiates Default settings for Proposal Category contract (Adding default categories)
    function proposalCategoryInitiate(bytes32 _dAppName) public {
        require(!constructorCheck);
        dappName = _dAppName;

        if (_getCodeSize(0xe57f3ffb5febc1c1a3b880ed5692e1ead1493d9c) > 0)        //kovan testnet
            officialPCA = 0xe57f3ffb5febc1c1a3b880ed5692e1ead1493d9c;

        constructorCheck = true;
    }

    function _getCodeSize(address _addr) internal view returns(uint _size) {
        assembly { //solhint-disable-line
            _size := extcodesize(_addr)
        }
    }

}