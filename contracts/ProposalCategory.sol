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
// import "./Ownable.sol";
import "./zeppelin-solidity/contracts/ownership/Ownable.sol";

contract ProposalCategory is Ownable
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

    struct categoryParams
    {
        bytes32[] parameterName;
        string parameterDescHash;
    }

    category[] public allCategory;

    categoryParams[] uintParam;
    categoryParams[] bytesParam;
    categoryParams[] addressParam;

    /// @dev Get the integer parameterName when given Category Id and parameterIndex
    function getCategoryParamNameUint(uint _categoryId,uint _index)constant returns(bytes32)
    {
        return uintParam[_categoryId].parameterName[_index];
    }

    /// @dev Get the Bytes parameterName when given Category Id and parameterIndex
    function getCategoryParamNameBytes(uint _categoryId,uint _index)constant returns(bytes32)
    {
        return bytesParam[_categoryId].parameterName[_index];
    }

    /// @dev Get the Address parameterName when given Category Id and parameterIndex
    function getCategoryParamNameAddress(uint _categoryId,uint _index)constant returns(bytes32)
    {
        return addressParam[_categoryId].parameterName[_index];
    }

    /// @dev Get the Address parameterName when given Category Id and parameterIndex
    function getCategoryParamHashUint(uint _categoryId)constant returns(string)
    {
        return uintParam[_categoryId].parameterDescHash;
    }

    /// @dev Get the Address parameterName when given Category Id and parameterIndex
    function getCategoryParamHashBytes(uint _categoryId)constant returns(string)
    {
        return bytesParam[_categoryId].parameterDescHash;
    }

    /// @dev Get the Address parameterName when given Category Id and parameterIndex
    function getCategoryParamHashAddress(uint _categoryId)constant returns(string)
    {
        return addressParam[_categoryId].parameterDescHash;
    }

    /// @dev Get category parameter details when giving category id and Index.
    function getCategoryParameterDetails(uint _categoryId,uint _index) constant returns(bytes32 paramInt,bytes32 paramBytes,bytes32 paramAddress, string uintHash,string bytesHash,string addressHash)
    {
        paramInt = uintParam[_categoryId].parameterName[_index];
        paramBytes = bytesParam[_categoryId].parameterName[_index];
        paramAddress = addressParam[_categoryId].parameterName[_index];
        uintHash = uintParam[_categoryId].parameterDescHash;
        bytesHash = bytesParam[_categoryId].parameterDescHash;
        addressHash = addressParam[_categoryId].parameterDescHash;
    }

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
    /// @dev Adds a new category and Category Function Parameter names..
    function addNewCategory(string _categoryName,string _functionName,address _contractAt,uint8 _paramInt,uint8 _paramBytes32,uint8 _paramAddress,uint8[] _memberRoleSequence,uint[] _memberRoleMajorityVote) onlyOwner
    {
        require(_memberRoleSequence.length == _memberRoleMajorityVote.length);
        allCategory.push(category(_categoryName,_functionName,_contractAt,_paramInt,_paramBytes32,_paramAddress,_memberRoleSequence,_memberRoleMajorityVote));
    }
    /// @dev Saving descriptions against various parameters required for category.
    function addCategoryParamsNameAndDesc(uint _categoryId,bytes32[] _uintParamName,bytes32[] _bytesParamName,bytes32[] _addressParamName,string _uintParameterDescHash,string _bytesParameterDescHash,string _addressParameterDescHash) onlyOwner
    {
        uintParam.push(categoryParams(_uintParamName,_uintParameterDescHash));
        bytesParam.push(categoryParams(_bytesParamName,_bytesParameterDescHash));
        addressParam.push(categoryParams(_addressParamName,_addressParameterDescHash));
    }
    /// @dev Change the category parameters name against category.
    function changeCategoryParametersName(uint _categoryId,bytes32[] _uintParamName,bytes32[] _bytesParamName,bytes32[] _addressParamName) onlyOwner
    {   
        uintParam[_categoryId].parameterName=new bytes32[](_uintParamName.length); 
        bytesParam[_categoryId].parameterName=new bytes32[](_bytesParamName.length); 
        addressParam[_categoryId].parameterName=new bytes32[](_addressParamName.length); 
        
        for(uint i=0; i<_uintParamName.length; i++)
        {
            uintParam[_categoryId].parameterName[i]=_uintParamName[i]; 
        }
            
        for(i=0; i<_uintParamName.length; i++)
        {
            bytesParam[_categoryId].parameterName[i]=_bytesParamName[i];
        }
        
        for(i=0; i<_uintParamName.length; i++)
        {
            addressParam[_categoryId].parameterName[i]=_addressParamName[i];
        }
    }

    /// @dev Updates a category details
    function updateCategory(uint _categoryId,string _functionName,address _contractAt,uint8 _paramInt,uint8 _paramBytes32,uint8 _paramAddress,uint8[] _memberRoleSequence,uint[] _memberRoleMajorityVote) onlyOwner
    {
        require(_memberRoleSequence.length == _memberRoleMajorityVote.length);
        allCategory[_categoryId].functionName = _functionName;
        allCategory[_categoryId].contractAt = _contractAt;
        allCategory[_categoryId].paramInt = _paramInt;
        allCategory[_categoryId].paramBytes32 = _paramBytes32; 
        allCategory[_categoryId].paramAddress = _paramAddress;

        allCategory[_categoryId].memberRoleSequence=new uint8[](_memberRoleSequence.length);
        allCategory[_categoryId].memberRoleMajorityVote=new uint[](_memberRoleMajorityVote.length);

        for(uint i=0; i<_memberRoleSequence.length; i++)
        {
            allCategory[_categoryId].memberRoleSequence[i] =_memberRoleSequence[i];
            allCategory[_categoryId].memberRoleMajorityVote[i] = _memberRoleMajorityVote[i];
        }
    }
    /// @dev function to be called after proposal pass
    function actionAfterProposalPass(uint _proposalId,uint _categoryId) public
    {
        address contractAt;
        (,,contractAt,,,,,) = getCategoryDetails(_categoryId);
        contractAt.call(bytes4(sha3(allCategory[_categoryId].functionName)),_proposalId);
    }

}