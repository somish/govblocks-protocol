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

pragma solidity ^ 0.4.8;
import "./Master.sol";
import "./memberRoles.sol";
import "./ProposalCategory.sol";
import "./governanceData.sol";

contract GovBlocksMaster {
    Master MS;
    memberRoles MR;
    ProposalCategory PC;
    governanceData GD;
    address public owner;
    address GBTAddress;

    struct GBDapps {
        address masterAddress;
        address tokenAddress;
        address authGBAddress;
        string dappDescHash;
    }

    mapping(address => bytes32) govBlocksDappByAddress;
    mapping(bytes32 => GBDapps) govBlocksDapps;
    mapping(address => string) govBlocksUser;

    bytes32[] allGovBlocksUsers;
    string byteCodeHash;
    string contractsAbiHash;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /// @dev Initializes GovBlocks master
    /// @param _GBTAddress GBT standard token address
    function GovBlocksMasterInit(address _GBTAddress) {
        require(owner == 0x00);
        owner = msg.sender;
        GBTAddress = _GBTAddress;
        //   updateGBMAddress(address(this));  
    }

    /// @dev Changes Member address authorized to dApp
    /// @param dAppName dApp name
    /// @param _memberAddress Address of the member that needs to be assigned the dApp authority
    function changedAppAuthorizedGB(bytes32 dAppName, address _memberAddress) {
        require(msg.sender == govBlocksDapps[dAppName].authGBAddress);
        govBlocksDapps[dAppName].authGBAddress = _memberAddress;
    }

    /// @dev Checks for authorized address for dApp
    /// @param dAppName dApp Name
    /// @param _memberAddress Member's address to be checked against dApp authorized address
    function isAuthorizedGBOwner(bytes32 dAppName, address _memberAddress) constant returns(bool) {
        if (govBlocksDapps[dAppName].authGBAddress == _memberAddress)
            return true;
    }

    /// @dev Transfers ownership to new owner (of GBT contract address)
    /// @param _newOwner Address of new owner
    function transferOwnership(address _newOwner) onlyOwner {
        owner = _newOwner;
    }

    /// @dev Updates GBt standard token address
    /// @param _GBTContractAddress New GBT standard token contract address
    function updateGBTAddress(address _GBTContractAddress) onlyOwner {
        GBTAddress = _GBTContractAddress;
        for (uint i = 0; i < allGovBlocksUsers.length; i++) {
            address masterAddress = govBlocksDapps[allGovBlocksUsers[i]].masterAddress;
            MS = Master(masterAddress);
            if (MS.versionLength() > 0)
                MS.changeGBTAddress(_GBTContractAddress);
        }
    }

    /// @dev Updates GovBlocks master address
    /// @param _newGBMAddress New GovBlocks master address
    function updateGBMAddress(address _newGBMAddress) internal {
        for (uint i = 0; i < allGovBlocksUsers.length; i++) {
            address masterAddress = govBlocksDapps[allGovBlocksUsers[i]].masterAddress;
            MS = Master(masterAddress);
            if (MS.versionLength() > 0)
                MS.changeGBMAddress(_newGBMAddress);
        }
    }

    /// @dev Adds GovBlocks user
    /// @param _gbUserName dApp name
    /// @param _dappTokenAddress dApp token address
    /// @param _dappDescriptionHash dApp description hash having dApp or token logo information
    function addGovBlocksUser(bytes32 _gbUserName, address _dappTokenAddress, string _dappDescriptionHash) {
        require(govBlocksDapps[_gbUserName].masterAddress == 0x00);
        address _newMasterAddress = new Master(address(this), _gbUserName);
        allGovBlocksUsers.push(_gbUserName);
        govBlocksDapps[_gbUserName].masterAddress = _newMasterAddress;
        govBlocksDapps[_gbUserName].tokenAddress = _dappTokenAddress;
        govBlocksDapps[_gbUserName].dappDescHash = _dappDescriptionHash;
        govBlocksDappByAddress[_newMasterAddress] = _gbUserName;
        govBlocksDappByAddress[_dappTokenAddress] = _gbUserName;
        govBlocksDapps[_gbUserName].authGBAddress = owner;
        MS = Master(_newMasterAddress);
        MS.setOwner(msg.sender);
    }

    /// @dev Changes dApp master address
    /// @param _gbUserName dApp name
    /// @param _newMasterAddress dApp new master address
    function changeDappMasterAddress(bytes32 _gbUserName, address _newMasterAddress) {
        require(msg.sender == govBlocksDapps[_gbUserName].authGBAddress);
        govBlocksDapps[_gbUserName].masterAddress = _newMasterAddress;
        govBlocksDappByAddress[_newMasterAddress] = _gbUserName;
    }

    /// @dev Changes dApp token address
    /// @param _gbUserName  dApp name
    /// @param _dappTokenAddress dApp new token address
    function changeDappTokenAddress(bytes32 _gbUserName, address _dappTokenAddress) {
        require(msg.sender == govBlocksDapps[_gbUserName].authGBAddress);
        govBlocksDapps[_gbUserName].tokenAddress = _dappTokenAddress;
        govBlocksDappByAddress[_dappTokenAddress] = _gbUserName;
    }

    /// @dev Sets byte code and abi hash that will help in generating new set of contracts for every dApp
    /// @param _byteCodeHash Byte code hash of all contracts    
    /// @param _abiHash Abi hash of all contracts
    function setByteCodeAndAbi(string _byteCodeHash, string _abiHash) onlyOwner {
        byteCodeHash = _byteCodeHash;
        contractsAbiHash = _abiHash;
    }

    /// @def Sets dApp user information such as Email id, name etc.
    function setDappUser(string _hash) {
        govBlocksUser[msg.sender] = _hash;
    }

    /// @dev Gets byte code and abi hash
    /// @param byteCode Byte code hash 
    /// @param abiHash Application binary interface hash
    function getByteCodeAndAbi() constant returns(string byteCode, string abiHash) {
        return (byteCodeHash, contractsAbiHash);
    }

    /// @def Get Address of member that is authorized for a dApp.
    function getDappAuthorizedAddress(bytes32 _gbUserName) constant returns(address) {
        return govBlocksDapps[_gbUserName].authGBAddress;
    }

    /// @dev Gets dApp details
    /// @param _gbUserName dApp name
    /// @return GbUserName dApp name
    /// @return masterContractAddress Master contract address of dApp
    /// @return allContractsbyteCodeHash All contracts byte code hash
    /// @return allCcontractsAbiHash All contracts abi hash
    /// @return versionNo Current Verson number of dApp
    function getGovBlocksUserDetails(bytes32 _gbUserName) constant returns(bytes32 GbUserName, address masterContractAddress, string allContractsbyteCodeHash, string allCcontractsAbiHash, uint versionNo) {
        address master = govBlocksDapps[_gbUserName].masterAddress;
        if (master == 0x00)
            return (GbUserName, 0x00, "", "", 0);
        else
            MS = Master(master);
        versionNo = MS.versionLength();
        return (_gbUserName, govBlocksDapps[_gbUserName].masterAddress, byteCodeHash, contractsAbiHash, versionNo);
    }

    /// @dev Gets dApp details such as master contract address and dApp name
    function getGovBlocksUserDetailsByIndex(uint _index) constant returns(uint index, bytes32 GbUserName, address MasterContractAddress) {
        return (_index, allGovBlocksUsers[_index], govBlocksDapps[allGovBlocksUsers[_index]].masterAddress);
    }

    /// @dev Gets dApp details (another function)
    /// @param _gbUserName dApp name whose details need to be fetched
    /// @return GbUserName dApp name 
    /// @return masterContractAddress Master contract address
    /// @return dappTokenAddress dApp token address
    /// @return allContractsbyteCodeHash All contracts byte code hash
    /// @return allCcontractsAbiHash All contract abi hash
    /// @return versionNo Version number
    function getGovBlocksUserDetails1(bytes32 _gbUserName) constant returns(bytes32 GbUserName, address masterContractAddress, address dappTokenAddress, string allContractsbyteCodeHash, string allCcontractsAbiHash, uint versionNo) {
        address master = govBlocksDapps[_gbUserName].masterAddress;
        if (master == 0x00)
            return (GbUserName, 0x00, 0x00, "", "", 0);
        else
            MS = Master(master);
        versionNo = MS.versionLength();
        return (_gbUserName, govBlocksDapps[_gbUserName].masterAddress, govBlocksDapps[_gbUserName].tokenAddress, byteCodeHash, contractsAbiHash, versionNo);
    }

    /// @dev Gets dApp details by passing either of contract address i.e. Token or Master contract address
    /// @param _Address Contract address is passed
    /// @return dappName dApp name
    /// @return masterContractAddress Master contract address of dApp
    /// @return dappTokenAddress dApp's token address
    function getGovBlocksUserDetails2(address _Address) constant returns(bytes32 dappName, address masterContractAddress, address dappTokenAddress) {
        dappName = govBlocksDappByAddress[_Address];
        return (dappName, govBlocksDapps[dappName].masterAddress, govBlocksDapps[dappName].tokenAddress);
    }

    /// @dev Gets dApp description hash
    /// @param _gbUserName dApp name
    function getDappDescHash(bytes32 _gbUserName) constant returns(string) {
        return govBlocksDapps[_gbUserName].dappDescHash;
    }

    /// @def Gets Total number of dApp that has been integrated with GovBlocks so far.
    function getAllDappLength() constant returns(uint) {
        return (allGovBlocksUsers.length);
    }

    /// @dev Gets dApps users by index
    function getAllDappById(uint _gbIndex) constant returns(bytes32 _gbUserName) {
        return (allGovBlocksUsers[_gbIndex]);
    }

    /// @dev Gets all dApps users
    function getAllDappArray() constant returns(bytes32[]) {
        return (allGovBlocksUsers);
    }

    /// @dev Gets dApp username
    function getDappUser() constant returns(string) {
        return (govBlocksUser[msg.sender]);
    }

    /// @dev Gets dApp master address of dApp (username=govBlocksUser)
    function getDappMasterAddress(bytes32 _gbUserName) constant returns(address masterAddress) {
        return (govBlocksDapps[_gbUserName].masterAddress);
    }

    /// @dev Gets dApp token address of dApp (username=govBlocksUser)
    function getDappTokenAddress(bytes32 _gbUserName) constant returns(address tokenAddres) {
        return (govBlocksDapps[_gbUserName].tokenAddress);
    }

    /// @dev Gets dApp username by address
    function getDappNameByAddress(address _contractAddress) constant returns(bytes32) {
        return govBlocksDappByAddress[_contractAddress];
    }

    /// @dev Gets GBT standard token address 
    function getGBTAddress() constant returns(address) {
        return GBTAddress;
    }


    /// @def Gets contract address of specific contracts
    /// @param _gbUserName dApp name
    /// @param _typeOf Contract name initials which address is to be fetched
    function getContractInstance_byDapp(bytes32 _gbUserName, bytes2 _typeOf) internal constant returns(address contractAddress) {
        require(isAuthorizedGBOwner(_gbUserName, msg.sender) == true);
        address master = govBlocksDapps[_gbUserName].masterAddress;
        MS = Master(master);
        uint16 versionNo = MS.versionLength() - 1;
        contractAddress = MS.allContractVersions(versionNo, _typeOf);
        return contractAddress;
    }


    // ACTION AFTER PROPOSAL PASS ACCEPTANCE FUNCTIONALITY


    /// @dev Adds new member roles in dApp existing member roles
    /// @param _gbUserName dApp name
    /// @param _newRoleName Role name to add in dApp
    /// @param _roleDescription Description hash of this particular Role
    function addNewMemberRoleGB(bytes32 _gbUserName, bytes32 _newRoleName, string _roleDescription, address _canAddMembers) {
        address MRAddress = getContractInstance_byDapp(_gbUserName, "MR");
        MR = memberRoles(MRAddress);
        MR.addNewMemberRole(_newRoleName, _roleDescription, _canAddMembers);
    }

    /// @dev Update existing Role data in dApp i.e. Assign/Remove any member from given role
    /// @param _gbUserName dApp name
    /// @param _memberAddress Address of who needs to be added/remove from specific role
    /// @param _memberRoleId Role id that details needs to be updated.
    /// @param _typeOf typeOf is set to be True if we want to assign this role to member, False otherwise!
    function updateMemberRoleGB(bytes32 _gbUserName, address _memberAddress, uint32 _memberRoleId, bool _typeOf) {
        address MRAddress = getContractInstance_byDapp(_gbUserName, "MR");
        MR = memberRoles(MRAddress);
        MR.updateMemberRole(_memberAddress, _memberRoleId, _typeOf);
    }

    /// @dev Adds new category in dApp existing categories
    /// @param _gbUserName dApp name
    /// @param _descHash dApp description hash
    function addNewCategoryGB(bytes32 _gbUserName, string _descHash, uint8[] _memberRoleSequence, uint8[] _memberRoleMajorityVote, uint32[] _closingTime, uint64[] _stakeAndIncentive, uint8[] _rewardPercentage) {
        address PCAddress = getContractInstance_byDapp(_gbUserName, "PC");
        PC = ProposalCategory(PCAddress);
        PC.addNewCategory(_descHash, _memberRoleSequence, _memberRoleMajorityVote, _closingTime, _stakeAndIncentive, _rewardPercentage);
    }

    /// @dev Updates category in dApp
    /// @param _gbUserName dApp name
    /// @param _categoryId Category id that details needs to be updated 
    /// @param _categoryData Category description hash having all the details 
    /// @param _roleName Voting Layer sequence in which the voting has to be performed.
    /// @param _majorityVote Majority Vote threshhold for Each voting layer
    /// @param _closingTime Vote closing time for Each voting layer
    /// @param _stakeAndIncentive array of minstake maxstake and incentive required against each category
    /// @param _rewardPercentage array of reward percentages for Proposal, Solution and Voting.
    function updateCategoryGB(bytes32 _gbUserName, uint _categoryId, string _categoryData, uint8[] _roleName, uint8[] _majorityVote, uint32[] _closingTime, uint64[] _stakeAndIncentive, uint8[] _rewardPercentage) {
        address PCAddress = getContractInstance_byDapp(_gbUserName, "PC");
        PC = ProposalCategory(PCAddress);
        PC.updateCategory(_categoryId, _categoryData, _roleName, _majorityVote, _closingTime, _stakeAndIncentive, _rewardPercentage);
    }

    /// @dev Adds new sub category in GovBlocks
    /// @param _gbUserName dApp name
    /// @param _categoryName Name of the category
    /// @param _actionHash Automated Action hash has Contract Address and function name i.e. Functionality that needs to be performed after proposal acceptance.
    /// @param _mainCategoryId Id of main category
    function addNewSubCategoryGB(bytes32 _gbUserName, string _categoryName, string _actionHash, uint8 _mainCategoryId) {
        address PCAddress = getContractInstance_byDapp(_gbUserName, "PC");
        PC = ProposalCategory(PCAddress);
        PC.addNewSubCategory(_categoryName, _actionHash, _mainCategoryId);
    }

    /// @dev Updates category in dApp
    /// @param _gbUserName dApp name
    /// @param _subCategoryId Id of subcategory that needs to be updated
    /// @param _actionHash Updated Automated Action hash i.e. Either contract address or function name is changed.
    function updateSubCategoryGB(bytes32 _gbUserName, uint8 _subCategoryId, string _actionHash) {
        address PCAddress = getContractInstance_byDapp(_gbUserName, "PC");
        PC = ProposalCategory(PCAddress);
        PC.updateSubCategory(_subCategoryId, _actionHash);
    }

    /// @dev Configures global parameters against dApp i.e. Voting or Reputation parameters
    /// @param _gbUserName dApp name
    /// @param _typeOf Passing intials of the parameter name which value needs to be updated
    /// @param _value New value that needs to be updated    
    function configureGlobalParameters(bytes32 _gbUserName, bytes4 _typeOf, uint32 _value) {
        address GDAddress = getContractInstance_byDapp(_gbUserName, "GD");
        GD = governanceData(GDAddress);

        if (_typeOf == "APO") {
            GD.changeProposalOwnerAdd(_value);
        } else if (_typeOf == "AOO") {
            GD.changeSolutionOwnerAdd(_value);
        } else if (_typeOf == "AVM") {
            GD.changeMemberAdd(_value);
        } else if (_typeOf == "SPO") {
            GD.changeProposalOwnerSub(_value);
        } else if (_typeOf == "SOO") {
            GD.changeSolutionOwnerSub(_value);
        } else if (_typeOf == "SVM") {
            GD.changeMemberSub(_value);
        } else if (_typeOf == "GBTS") {
            GD.changeGBTStakeValue(_value);
        } else if (_typeOf == "MSF") {
            GD.changeMembershipScalingFator(_value);
        } else if (_typeOf == "SW") {
            GD.changeScalingWeight(_value);
        } else if (_typeOf == "QP") {
            GD.changeQuorumPercentage(_value);
        }
    }
}