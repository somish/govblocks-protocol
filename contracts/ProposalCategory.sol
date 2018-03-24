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
import "./Ownable.sol";
import "./Master.sol";
import "./memberRoles.sol";
import "./governanceData.sol";
// import "./zeppelin-solidity/contracts/ownership/Ownable.sol";

contract ProposalCategory
{
    uint8 public constructorCheck;
    mapping(uint=>string) allCategoryData;
    string[] allCategory;

    // struct category{
    //     string categoryName;
    //     string functionName;
    //     address contractAt;
    //     uint8 paramInt;
    //     uint8 paramBytes32;
    //     uint8 paramAddress;
    //     uint8[] memberRoleSequence;
    //     uint[] memberRoleMajorityVote;
    //     uint24[] closingTime;
    //     uint8 minStake;
    //     uint8 maxStake;
    //     uint defaultIncentive;
    // }

    // struct categoryParams
    // {
    //     bytes32[] parameterName;
    //     string parameterDescHash;
    // }

    // category[] public allCategory;

    // categoryParams[] uintParam;
    // categoryParams[] bytesParam;
    // categoryParams[] addressParam;

    // mapping(uint=>uint8) parametersAdded;
    memberRoles MR;
    Master M1;
    address MRAddress;
    address masterAddress;
    address GDAddress;
    governanceData GD;
    address GBMAddress;

    modifier onlyInternal {
        M1=Master(masterAddress);
        require(M1.isInternal(msg.sender) == 1);
        _; 
    }
    
     modifier onlyOwner {
        M1=Master(masterAddress);
        require(M1.isOwner(msg.sender) == 1);
        _; 
    }

    /// @dev Change master's contract address
    function changeMasterAddress(address _masterContractAddress) 
    {
        if(masterAddress == 0x000)
            masterAddress = _masterContractAddress;
        else
        {
            M1=Master(masterAddress);
            require(M1.isInternal(msg.sender) == 1);
                masterAddress = _masterContractAddress;
        }
    }

    function changeAllContractsAddress(address _MRContractAddress,address _GDContractAddress)
    {
        // MRAddress = _MRContractAddress;
        // GDAddress = _GDContractAddress;
    }

    function ProposalCategoryInitiate(address _GBMAddress)
    {
        require(constructorCheck == 0);
        GBMAddress = _GBMAddress;
        addNewCategory("QmcEP2ELejTFsaLCeiukMNS9HSg6mxitFubHEuuLDSLbYt");
        addNewCategory("QmWCvo6vbFg3s8pcoYYRVArJ8kHYu9yDUnitChYPMcphJx");
        addNewCategory("QmVUzcTpWxWZpHg9xVgcpykYR9nDL8wHwv8FbWHBTk1dZG");
        addNewCategory("QmPNSRyY1GGCgrNHWfT4h2Swixv8GrjpfyhFre6gArsmAL");
        addNewCategory("QmTrnWVi9W6cQ5VqoznrXHbVKPNzjPugrumVPjQtT3ykTn");
        addNewCategory("QmXHkn8tPWMPy7xQfaZCBx1VgnApm17FjBnJ7r4RZqq2mA");
        addNewCategory("QmbhoJt8fQD2SUssoyVzmtZNie8L6R5XG5yH76txFVYMc6");

        // require(uintParam.length == 0 && bytesParam.length == 0 && addressParam.length == 0);
        // parametersAdded[0] = 1;
        // uintParam.push(categoryParams(new bytes32[](0),""));
        // bytesParam.push(categoryParams(new bytes32[](0),""));
        // addressParam.push(categoryParams(new bytes32[](0),""));
        // addCategory(_MRAddress);
        constructorCheck =1;
    }

    function getCategoryLength()constant returns(uint)
    {
        return allCategory.length;
    }

    function getCategoryData1(uint _categoryId) constant returns(string)
    {
        return allCategory[_categoryId];
    }

    /// @dev Adds a new category and Category Function Parameter names..
    function addNewCategory(string _categoryData) 
    {
        // M1=Master(masterAddress);
        // require(msg.sender == GBMAddress || M1.isAuthGB(msg.sender) == 1);
            allCategory.push(_categoryData);
    }
    
    function updateCategory(uint _categoryId,string _categoryData) 
    {
        // M1=Master(masterAddress);
        // require(msg.sender == GBMAddress || M1.isAuthGB(msg.sender) == 1);
            allCategory[_categoryId] = _categoryData;
    }

    // function addCategory(address _mraddress) internal
    // {
    //     allCategory.push(category("Uncategorized","",0x00,0,0,0,new uint8[](0),new uint[](0),new uint24[](0),0,0,0));
    //     allCategory.push(category("Add new member role","addNewMemberRole(bytes32,string)",_mraddress,0,1,0,new uint8[](0),new uint[](0),new uint24[](0),1,10,2));
    //     allCategory.push(category("Update member role","updateMemberRole(address,uint256,uint8)",_mraddress,2,0,1,new uint8[](0),new uint[](0),new uint24[](0),1,10,2))
    //     allCategory.push(category("Update member role","addNewCategoryAfterProposalPass(address,uint256,uint8)",_mraddress,2,0,1,new uint8[](0),new uint[](0),new uint24[](0),1,10,2))
        
    //     setClosingTime(1,300);
    //     setRoleSequence(1,1);
    //     setMajorityVote(1,50);
    // }

    // function getCategoryData1(uint _categoryId) constant returns(uint category,bytes32[] roleName,uint[] majorityVote,uint24[] closingTime,string categoryName,bool functionValue)
    // {
    //     MR=memberRoles(MRAddress);
    //     category = _categoryId;
    //     roleName=new bytes32[]( allCategory[_categoryId].memberRoleSequence.length);
    //     for(uint8 i=0; i < allCategory[_categoryId].memberRoleSequence.length; i++)
    //     {
    //         bytes32 name;
    //         (,name) = MR.getMemberRoleNameById(allCategory[_categoryId].memberRoleSequence[i]);
    //         roleName[i] = name;
    //     }
        
    //     majorityVote = allCategory[_categoryId].memberRoleMajorityVote;
    //     closingTime =  allCategory[_categoryId].closingTime;
    //     categoryName = allCategory[_categoryId].categoryName;
    //     if(allCategory[_categoryId].contractAt != 0x00)
    //       functionValue = true;   
    // }

    // function getMinStake(uint _categoryId)constant returns(uint8) 
    // {
    //     return allCategory[_categoryId].minStake;
    // }

    // function getMaxStake(uint _categoryId) constant returns(uint8)
    // {
    //     return allCategory[_categoryId].maxStake;
    // }

    // function getCategoryName(uint8 _categoryId)constant returns(string)
    // {
    //     return allCategory[_categoryId].categoryName;
    // }
    
    // /// @dev Get the integer parameterName when given Category Id and parameterIndex
    // function getCategoryParamNameUint(uint _categoryId,uint _index)constant returns(bytes32)
    // {
    //     return uintParam[_categoryId].parameterName[_index];
    // }

    // /// @dev Get the Bytes parameterName when given Category Id and parameterIndex
    // function getCategoryParamNameBytes(uint _categoryId,uint _index)constant returns(bytes32)
    // {
    //     return bytesParam[_categoryId].parameterName[_index];
    // }

    // /// @dev Get the Address parameterName when given Category Id and parameterIndex
    // function getCategoryParamNameAddress(uint _categoryId,uint _index)constant returns(bytes32)
    // {
    //     return addressParam[_categoryId].parameterName[_index];
    // }

    // /// @dev Get the Address parameterName when given Category Id and parameterIndex
    // function getCategoryParamHashUint(uint _categoryId)constant returns(uint Category,string hash)
    // {
    //     Category = _categoryId;
    //     return (Category,uintParam[_categoryId].parameterDescHash);
    // }

    /// @dev Get the Address parameterName when given Category Id and parameterIndex
    // function getCategoryParamHashBytes(uint _categoryId)constant returns(uint Category,string hash)
    // {
    //     Category = _categoryId;
    //     return (Category,bytesParam[_categoryId].parameterDescHash);
    // }

    // /// @dev Get the Address parameterName when given Category Id and parameterIndex
    // function getCategoryParamHashAddress(uint _categoryId)constant returns(uint Category,string hash)
    // {
    //     Category = _categoryId;
    //     return (Category,addressParam[_categoryId].parameterDescHash);
    // }

    // /// @dev Gets the total number of categories.
    // function getCategoriesLength() constant returns (uint length)
    // {
    //     length = allCategory.length;
    // }

    // /// @dev Gets category details by category id.
    // function getCategoryDetails(uint _categoryId) public constant returns (uint cateId,string categoryName,string functionName,address contractAt,uint8 paramInt,uint8 paramBytes32,uint8 paramAddress,uint8[] memberRoleSequence,uint[] memberRoleMajorityVote)
    // {    
    //     cateId = _categoryId;
    //     categoryName = allCategory[_categoryId].categoryName;
    //     functionName = allCategory[_categoryId].functionName;
    //     contractAt = allCategory[_categoryId].contractAt;
    //     paramInt = allCategory[_categoryId].paramInt;
    //     paramBytes32 = allCategory[_categoryId].paramBytes32;
    //     paramAddress = allCategory[_categoryId].paramAddress;
    //     memberRoleSequence = allCategory[_categoryId].memberRoleSequence;
    //     memberRoleMajorityVote = allCategory[_categoryId].memberRoleMajorityVote;
    // } 
    
    // /// @dev Get majority vote value for each voting level.
    // function getRoleMajorityVote(uint _categoryId,uint _index) constant returns(uint majorityVote)
    // {
    //     return allCategory[_categoryId].memberRoleMajorityVote[_index];
    // }
    
    // function getRoleMajorityVotelength(uint _categoryId) constant returns(uint index,uint majorityVoteLength)
    // {
    //     index = _categoryId;
    //     majorityVoteLength= allCategory[_categoryId].memberRoleMajorityVote.length;
    // }

    // function getClosingTimeLength(uint _categoryId) constant returns(uint index,uint closingTimeLength)
    // {
    //     index = _categoryId;
    //     closingTimeLength = allCategory[_categoryId].closingTime.length;
    // }

    // function getClosingTimeByIndex(uint _categoryId,uint _index) constant returns(uint24 closeTime)
    // {
    //     return allCategory[_categoryId].closingTime[_index];
    // }

    // /// @dev Get the length of voting levels against given proposal.
    // function getRoleSequencLength(uint _categoryId) constant returns(uint roleLength)
    // {
    //     roleLength = allCategory[_categoryId].memberRoleSequence.length;
    // }
    // /// @dev Get the next Roleid to cast vote against proposal, according to the sequence defined.
    // function getRoleSequencAtIndex(uint _categoryId,uint _index) constant returns(uint roleId)
    // {
    //     return allCategory[_categoryId].memberRoleSequence[_index];
    // }

    // /// @dev Adds a new category and Category Function Parameter names..
    // function addNewCategory(string _categoryName,string _functionName,address _contractAt,uint8 _paramInt,uint8 _paramBytes32,uint8 _paramAddress,uint8[] _memberRoleSequence,uint[] _memberRoleMajorityVote,uint24[] _closingTime,uint8 _minStake,uint8 _maxStake) onlyOwner
    // {
    //     GD=governanceData(GDAddress);
    //     require(_memberRoleSequence.length == _memberRoleMajorityVote.length && _memberRoleSequence.length == _closingTime.length);
    //     require(_minStake <= _maxStake);
    //     allCategory.push(category(_categoryName,_functionName,_contractAt,_paramInt,_paramBytes32,_paramAddress,_memberRoleSequence,_memberRoleMajorityVote,_closingTime,_minStake,_maxStake,0));
    // }

    /// @dev Saving descriptions against various parameters required for category.
    // function addCategoryParamsNameAndDesc(uint _categoryId,bytes32[] _uintParamName,bytes32[] _bytesParamName,bytes32[] _addressParamName,string _uintParameterDescHash,string _bytesParameterDescHash,string _addressParameterDescHash) onlyOwner
    // {
    //     require(parametersAdded[_categoryId] == 0);
    //     uintParam.push(categoryParams(_uintParamName,_uintParameterDescHash));
    //     bytesParam.push(categoryParams(_bytesParamName,_bytesParameterDescHash));
    //     addressParam.push(categoryParams(_addressParamName,_addressParameterDescHash));
    //     parametersAdded[_categoryId] = 1;
    // }

    /// @dev Updates a category details
    // function updateCategory(uint _categoryId,string _functionName,address _contractAt,uint8 _paramInt,uint8 _paramBytes32,uint8 _paramAddress,uint8[] _memberRoleSequence,uint[] _memberRoleMajorityVote,uint24[] _closingTime,uint8 _minStake,uint8 _maxStake) onlyOwner
    // {
    //     require(_memberRoleSequence.length == _memberRoleMajorityVote.length && _memberRoleSequence.length == _closingTime.length);
    //     allCategory[_categoryId].functionName = _functionName;
    //     allCategory[_categoryId].contractAt = _contractAt;
    //     allCategory[_categoryId].paramInt = _paramInt;
    //     allCategory[_categoryId].paramBytes32 = _paramBytes32; 
    //     allCategory[_categoryId].paramAddress = _paramAddress;
    //     allCategory[_categoryId].minStake = _minStake;
    //     allCategory[_categoryId].maxStake = _maxStake;

    //     allCategory[_categoryId].memberRoleSequence=new uint8[](_memberRoleSequence.length);
    //     allCategory[_categoryId].memberRoleMajorityVote=new uint[](_memberRoleMajorityVote.length);
    //     allCategory[_categoryId].closingTime = new uint24[](_closingTime.length);

    //     for(uint i=0; i<_memberRoleSequence.length; i++)
    //     {
    //         allCategory[_categoryId].memberRoleSequence[i] =_memberRoleSequence[i];
    //         allCategory[_categoryId].memberRoleMajorityVote[i] = _memberRoleMajorityVote[i];
    //         allCategory[_categoryId].closingTime[i] = _closingTime[i];
    //     }
    // }

    // /// @dev function to be called after proposal pass
    // function actionAfterProposalPass(uint _proposalId,uint _categoryId) public
    // {
    //     address contractAt;
    //     (,,,contractAt,,,,,) = getCategoryDetails(_categoryId);
    //     contractAt.call(bytes4(sha3(allCategory[_categoryId].functionName)),_proposalId);
    // }

    // function getCatgoryData2(uint _categoryId) constant returns(uint category,bytes32[] intParameter,bytes32[] bytesParameter,bytes32[] addressParameter,string intDesc, string bytesDesc, string addressDesc)
    // {
    //     category = _categoryId;
    //     return (category,uintParam[_categoryId].parameterName,bytesParam[_categoryId].parameterName,addressParam[_categoryId].parameterName,uintParam[_categoryId].parameterDescHash,bytesParam[_categoryId].parameterDescHash,addressParam[_categoryId].parameterDescHash);
    // }

    // function getCategoryIncentive(uint _categoryId)constant returns(uint category,uint incentive)
    // {
    //     category = _categoryId;
    //     incentive = allCategory[_categoryId].defaultIncentive;
    // }

    // function setClosingTime(uint _categoryId,uint24 _time)
    // {
    //     allCategory[_categoryId].closingTime.push(_time);
    // }

    // function setRoleSequence(uint _categoryId,uint8 _roleSequence)
    // {
    //     allCategory[_categoryId].memberRoleSequence.push(_roleSequence);
    // }

    // function setMajorityVote(uint _categoryId,uint _majorityVote)
    // {
    //     allCategory[_categoryId].memberRoleMajorityVote.push(_majorityVote);
    // }

}