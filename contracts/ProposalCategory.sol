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
import "./imports/govern/Governed.sol";
import "./ProposalCategoryAdder.sol";


contract ProposalCategory is Governed {
    bool public constructorCheck;
    bool public adderCheck;
    address public officialPCA;

    struct Category {
        uint memberRoleToVote;
        uint majorityVotePerc;
        uint[] allowedToCreateProposal;
        uint closingTime;
        uint tokenHoldingTime;
        uint minStake;
        uint defaultIncentive;
        address contractAddress;
        bytes2 contractName;
        uint quorumPerc;
    }

    event CategoryEvent(uint indexed categoryId,string categoryName,string actionHash);

    Category[] public allCategory;

    function callCategoryEvent(uint _categoryId, string _categoryName, string _actionHash) internal{
        emit CategoryEvent(_categoryId, _categoryName, _actionHash);
    }

    /// @dev Adds new category
    /// @param _name Category name
    /// @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
    /// @param _allowedToCreateProposal Member roles allowed to create the proposal
    /// @param _majorityVotePerc Majority Vote threshold for Each voting layer
    /// @param _closingTime Vote closing time for Each voting layer
    function addNewCategory(
        string _name, 
        uint _memberRoleToVote,
        uint _majorityVotePerc, 
        uint[] _allowedToCreateProposal,
        uint _closingTime,
        string _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint _tokenHoldingTime,
        uint[2] _incentives,
        uint _quorumPerc
    ) 
        public
        onlyAuthorizedToGovern 
    {
        allCategory.push((
            Category(
                _memberRoleToVote,
                _majorityVotePerc,
                _allowedToCreateProposal,
                _closingTime,
                _tokenHoldingTime,
                _incentives[0],
                _incentives[1],
                _contractAddress,
                _contractName,
                _quorumPerc
            ))
        );
        callCategoryEvent(allCategory.length-1, _name, _actionHash);
    }

    /// @dev Updates category details
    /// @param _categoryId Category id that needs to be updated
    /// @param _roleName Updated Role sequence to vote i.e. Updated voting layer sequence
    /// @param _majorityVote Updated Majority threshold value against each voting layer.
    /// @param _allowedToCreateProposal Member roles allowed to create the proposal
    /// @param _closingTime Updated Vote closing time against each voting layer
    function updateCategory(
        uint _categoryId, 
        string _name, 
        uint _roleName, 
        uint _majorityVote, 
        uint[] _allowedToCreateProposal,
        uint _closingTime,
        uint _tokenHoldingTime,
        string _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint[2] _incentives,
        uint _quorumPerc
    )
        public
        onlyAuthorizedToGovern
    { 
        allCategory[_categoryId].memberRoleToVote = _roleName;
        allCategory[_categoryId].majorityVotePerc = _majorityVote;
        allCategory[_categoryId].closingTime = _closingTime;
        allCategory[_categoryId].allowedToCreateProposal = _allowedToCreateProposal; 
        allCategory[_categoryId].tokenHoldingTime = _tokenHoldingTime;
        allCategory[_categoryId].minStake = _incentives[0];
        allCategory[_categoryId].defaultIncentive = _incentives[1];
        allCategory[_categoryId].contractAddress = _contractAddress;
        allCategory[_categoryId].contractName = _contractName;
        allCategory[_categoryId].quorumPerc =  _quorumPerc;
        callCategoryEvent(_categoryId, _name, _actionHash);
    }

    /// @dev gets category details
    function getCategoryDetails(uint _categoryId) public view returns(uint, uint, uint, uint[], uint, uint, uint) {
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

    function getCategoryActionDetails(uint _categoryId) public view returns(uint, address, bytes2, uint){
        return(
            _categoryId,
            allCategory[_categoryId].contractAddress,
            allCategory[_categoryId].contractName,
            allCategory[_categoryId].defaultIncentive
        );
    }

    function getCategoryQuorumPercent(uint _categoryId) public view returns(uint, uint){
        return(
            _categoryId,
            allCategory[_categoryId].quorumPerc
        );
    }
    
    function isCategoryExternal(uint _category) public view returns(bool ext) {
        return _isCategoryExternal(_category);
    }

   /// @dev Gets Total number of categories added till now
    function getCategoryLength() public view returns(uint) {
        return allCategory.length;
    }

    function addInitialCategories(
        string _name, 
        uint _roleName, 
        uint _majorityVote, 
        uint[] _allowedToCreateProposal,
        uint _closingTime,
        string _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint _tokenHoldingTime,
        uint[] _incentives,
        uint _quorumPerc
    ) 
        public 
    {
        require(allCategory.length <= 18);
        require(msg.sender == officialPCA || officialPCA == address(0));
        // allSubIdByCategory[_mainCategoryId].push(allSubCategory.length);
        allCategory.push(Category(
                _roleName,
                _majorityVote,
                _allowedToCreateProposal,
                _closingTime,
                _tokenHoldingTime,
                _incentives[0],
                _incentives[1],
                _contractAddress,
                _contractName,
                _quorumPerc
            )
        );
        callCategoryEvent(allCategory.length-1 , _name, _actionHash);
    }

    /// @dev Initiates Default settings for Proposal Category contract (Adding default categories)
    function proposalCategoryInitiate(bytes32 _dAppName) public {
        require(!constructorCheck);
        dappName = _dAppName;

        if (_getCodeSize(0x31475F356a415FE6cB19E450FF8E49C9B6eF9819) > 0)        //kovan testnet
            officialPCA = 0x31475F356a415FE6cB19E450FF8E49C9B6eF9819;

        constructorCheck = true;
    }

    ///@dev just to follow the interface
    function updateDependencyAddresses() public pure { //solhint-disable-line
    }

    /// @dev just to adhere to GovBlockss' Upgradeable interface
    function changeMasterAddress(address _masterAddress) public pure { //solhint-disable-line
    }

    function _getCodeSize(address _addr) internal view returns(uint _size) {
        assembly { //solhint-disable-line
            _size := extcodesize(_addr)
        }
    }

    function _isCategoryExternal(uint _category) internal view returns(bool ext) {
        for (uint i = 0; i < allCategory[_category].allowedToCreateProposal.length; i++) {
            if (allCategory[_category].allowedToCreateProposal[i] == 0)
                ext = true;
        }        
    }
}