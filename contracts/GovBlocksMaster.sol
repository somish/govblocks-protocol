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
    function changedAppAuthorizedGB(bytes32 dAppName, address _memberAddress) public {
        require(msg.sender == govBlocksDapps[dAppName].authGBAddress);
        govBlocksDapps[dAppName].authGBAddress = _memberAddress;
    }

    /// @dev Checks for authorized address for dApp
    /// @param dAppName dApp Name
    /// @param _memberAddress Member's address to be checked against dApp authorized address
    function isAuthorizedGBOwner(bytes32 dAppName, address _memberAddress) public constant returns(bool) {
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
    function addGovBlocksUser(bytes32 _gbUserName, address _dappTokenAddress, string _dappDescriptionHash) public {
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
    function changeDappMasterAddress(bytes32 _gbUserName, address _newMasterAddress) public {
        require(msg.sender == govBlocksDapps[_gbUserName].authGBAddress);
        govBlocksDapps[_gbUserName].masterAddress = _newMasterAddress;
        govBlocksDappByAddress[_newMasterAddress] = _gbUserName;
    }

    /// @dev Changes dApp token address
    /// @param _gbUserName  dApp name
    /// @param _dappTokenAddress dApp new token address
    function changeDappTokenAddress(bytes32 _gbUserName, address _dappTokenAddress) public {
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

    /// @dev Sets dApp user information such as Email id, name etc.
    function setDappUser(string _hash) public {
        govBlocksUser[msg.sender] = _hash;
    }

    /// @dev Gets byte code and abi hash
    /// @param byteCode Byte code hash 
    /// @param abiHash Application binary interface hash
    function getByteCodeAndAbi() public constant returns(string byteCode, string abiHash) {
        return (byteCodeHash, contractsAbiHash);
    }

    /// @dev Get Address of member that is authorized for a dApp.
    function getDappAuthorizedAddress(bytes32 _gbUserName) public constant returns(address) {
        return govBlocksDapps[_gbUserName].authGBAddress;
    }

    /// @dev Gets dApp details
    /// @param _gbUserName dApp name
    /// @return GbUserName dApp name
    /// @return masterContractAddress Master contract address of dApp
    /// @return allContractsbyteCodeHash All contracts byte code hash
    /// @return allCcontractsAbiHash All contracts abi hash
    /// @return versionNo Current Verson number of dApp
    function getGovBlocksUserDetails(bytes32 _gbUserName) public constant returns(bytes32 GbUserName, address masterContractAddress, string allContractsbyteCodeHash, string allCcontractsAbiHash, uint versionNo) {
        address master = govBlocksDapps[_gbUserName].masterAddress;
        if (master == 0x00)
            return (GbUserName, 0x00, "", "", 0);
        else
            MS = Master(master);
        versionNo = MS.versionLength();
        return (_gbUserName, govBlocksDapps[_gbUserName].masterAddress, byteCodeHash, contractsAbiHash, versionNo);
    }

    /// @dev Gets dApp details such as master contract address and dApp name
    function getGovBlocksUserDetailsByIndex(uint _index) public constant returns(uint index, bytes32 GbUserName, address MasterContractAddress) {
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
    function getGovBlocksUserDetails1(bytes32 _gbUserName) public constant returns(bytes32 GbUserName, address masterContractAddress, address dappTokenAddress, string allContractsbyteCodeHash, string allCcontractsAbiHash, uint versionNo) {
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
    function getGovBlocksUserDetails2(address _Address) public constant returns(bytes32 dappName, address masterContractAddress, address dappTokenAddress) {
        dappName = govBlocksDappByAddress[_Address];
        return (dappName, govBlocksDapps[dappName].masterAddress, govBlocksDapps[dappName].tokenAddress);
    }

    /// @dev Gets dApp description hash
    /// @param _gbUserName dApp name
    function getDappDescHash(bytes32 _gbUserName) public constant returns(string) {
        return govBlocksDapps[_gbUserName].dappDescHash;
    }

    /// @dev Gets Total number of dApp that has been integrated with GovBlocks so far.
    function getAllDappLength() public constant returns(uint) {
        return (allGovBlocksUsers.length);
    }

    /// @dev Gets dApps users by index
    function getAllDappById(uint _gbIndex) public constant returns(bytes32 _gbUserName) {
        return (allGovBlocksUsers[_gbIndex]);
    }

    /// @dev Gets all dApps users
    function getAllDappArray() public constant returns(bytes32[]) {
        return (allGovBlocksUsers);
    }

    /// @dev Gets dApp username
    function getDappUser() public constant returns(string) {
        return (govBlocksUser[msg.sender]);
    }

    /// @dev Gets dApp master address of dApp (username=govBlocksUser)
    function getDappMasterAddress(bytes32 _gbUserName) public constant returns(address masterAddress) {
        return (govBlocksDapps[_gbUserName].masterAddress);
    }

    /// @dev Gets dApp token address of dApp (username=govBlocksUser)
    function getDappTokenAddress(bytes32 _gbUserName) public constant returns(address tokenAddres) {
        return (govBlocksDapps[_gbUserName].tokenAddress);
    }

    /// @dev Gets dApp username by address
    function getDappNameByAddress(address _contractAddress) public constant returns(bytes32) {
        return govBlocksDappByAddress[_contractAddress];
    }

    /// @dev Gets GBT standard token address 
    function getGBTAddress() public constant returns(address) {
        return GBTAddress;
    }


    /// @dev Gets contract address of specific contracts
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
}