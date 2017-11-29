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
    pragma solidity ^0.4.8;
contract ProposalCategory
{
        struct category{
        string categoryName;
        string functionName;
        address contractAt;
        uint8 paramInt;
        uint8 paramBytes32;
        uint8 paramAddress;
        uint8[] memberRoleSequence;
        uint[] memberRoleMajorityVote;
    }
    category[] public allCategory;
    
      /// @dev Gets the total number of categories.
    function getCategoriesLength() constant returns (uint length)
    {
        length = allCategory.length;
    }

    /// @dev Gets category details by category id.
    function getCategoryDetails(uint _categoryId) public constant returns (string categoryName,string functionName,address contractAt,uint8 paramInt,uint8 paramBytes32,uint8 paramAddress,uint8[] memberRoleSequence,uint[] memberRoleMajorityVote)
    {    
        categoryName = allCategory[_categoryId].categoryName;
        functionName = allCategory[_categoryId].functionName;
        contractAt = allCategory[_categoryId].contractAt;
        paramInt = allCategory[_categoryId].paramInt;
        paramBytes32 = allCategory[_categoryId].paramBytes32;
        paramAddress = allCategory[_categoryId].paramAddress;
        memberRoleSequence = allCategory[_categoryId].memberRoleSequence;
        memberRoleMajorityVote = allCategory[_categoryId].memberRoleMajorityVote;
    } 
    
    /// @dev Get majority vote value for each voting level.
    function getRoleMajorityVote(uint _categoryId,uint _index) constant returns(uint majorityVote)
    {
        return allCategory[_categoryId].memberRoleMajorityVote[_index];
    }
    
    /// @dev Get the length of voting levels against given proposal.
    function getRoleSequencLength(uint _categoryId) constant returns(uint roleLength)
    {
        return allCategory[_categoryId].memberRoleSequence.length;
    }
    /// @dev Get the next Roleid to cast vote against proposal, according to the sequence defined.
    function getRoleSequencAtIndex(uint _categoryId,uint _index) constant returns(uint roleId)
    {
        return allCategory[_categoryId].memberRoleSequence[_index];
    }
    /// @dev Adds a new category.
    function addNewCategory(string _categoryName,string _functionName,address _contractAt,uint8 _paramInt,uint8 _paramBytes32,uint8 _paramAddress,uint8[] _memberRoleSequence,uint[] _memberRoleMajorityVote) public
    {
        require(_memberRoleSequence.length == _memberRoleMajorityVote.length);
        allCategory.push(category(_categoryName,_functionName,_contractAt,_paramInt,_paramBytes32,_paramAddress,_memberRoleSequence,_memberRoleMajorityVote));
    }
    /// @dev Updates a category details
    function updateCategory(uint _categoryId,string _functionName,address _contractAt,uint8 _paramInt,uint8 _paramBytes32,uint8 _paramAddress,uint8[] _memberRoleSequence,uint[] _memberRoleMajorityVote) public
    {
        require(_memberRoleSequence.length == _memberRoleMajorityVote.length);
        allCategory[_categoryId].functionName = _functionName;
        allCategory[_categoryId].contractAt = _contractAt;
        allCategory[_categoryId].paramInt = _paramInt;
        allCategory[_categoryId].paramBytes32 = _paramBytes32; 
        allCategory[_categoryId].paramAddress = _paramAddress;

        for(uint i=0; i<_memberRoleSequence.length; i++)
        {
            allCategory[_categoryId].memberRoleSequence.push(_memberRoleSequence[i]);
            allCategory[_categoryId].memberRoleMajorityVote.push(_memberRoleMajorityVote[i]);
        }
    }
    /// @dev function to be called after proposal pass
    function actionAfterProposalPass(uint _proposalId,uint _categoryId) public returns(bool)
    {
        address contractAt;
        (,,contractAt,,,,,) = getCategoryDetails(_categoryId);
        contractAt.call(bytes4(sha3(allCategory[_categoryId].functionName)),_proposalId);
    }

}