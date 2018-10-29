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
import "./Master.sol";
import "./imports/govern/Governed.sol";
import "./imports/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./imports/proxy/GovernedUpgradeabilityProxy.sol";


contract GovBlocksMaster is Ownable {
    address public eventCaller;
    address public gbtAddress;
    address public masterAdd;
    address[] public implementations;
    bool public initialized;
    GovernChecker internal governChecker;

    struct GBDapps {
        address masterAddress;
        address tokenAddress;
        address proxyAddress;
        string dappDescHash;
    }

    mapping(address => bytes32) internal govBlocksDappByAddress;
    mapping(bytes32 => GBDapps) internal govBlocksDapps;
    mapping(address => string) internal govBlocksUser;
    bytes32[] internal allGovBlocksUsers;
    string internal byteCodeHash;
    string internal contractsAbiHash;

    /// @dev Updates GBt standard token address
    /// @param _gbtContractAddress New GBT standard token contract address
    function updateGBTAddress(address _gbtContractAddress) external onlyOwner {
        gbtAddress = _gbtContractAddress;
        for (uint i = 0; i < allGovBlocksUsers.length; i++) {
            address masterAddress = govBlocksDapps[allGovBlocksUsers[i]].masterAddress;
            Master master = Master(masterAddress);
            /* solhint-disable */
            if (address(master).call(bytes4(keccak256("changeGBTSAddress()")))) {
                //just to silence the compiler warning
            }
            /* solhint-enable */     
        }
    }

    /// @dev Updates GovBlocks master address
    /// @param _newGBMAddress New GovBlocks master address
    function updateGBMAddress(address _newGBMAddress) external onlyOwner {
        for (uint i = 0; i < allGovBlocksUsers.length; i++) {
            address masterAddress = govBlocksDapps[allGovBlocksUsers[i]].masterAddress;
            Master master = Master(masterAddress);
            /* solhint-disable */
            if (address(master).call(bytes4(keccak256("changeGBMAddress(address)")), _newGBMAddress)) {
                //just to silence the compiler warning
            }
            /* solhint-enable */   
        }
        if (address(governChecker) != address(0))
            governChecker.updateGBMAdress(_newGBMAddress);
    }

    function updateMasterAddress(address _newMaster) external onlyOwner {
        masterAdd = _newMaster;
    }

    /// @dev Adds GovBlocks user
    /// @param _gbUserName dApp name
    /// @param _dappTokenAddress dApp token address
    /// @param _dappDescriptionHash dApp description hash having dApp or token logo information
    function addGovBlocksUser(
        bytes32 _gbUserName, 
        address _dappTokenAddress, 
        address _tokenProxy, 
        string _dappDescriptionHash
    ) external {
        require(govBlocksDapps[_gbUserName].masterAddress == address(0));
        govBlocksDapps[_gbUserName].tokenAddress = _dappTokenAddress;
        govBlocksDapps[_gbUserName].proxyAddress = _tokenProxy;
        GovernedUpgradeabilityProxy tempInstance = new GovernedUpgradeabilityProxy(_gbUserName, masterAdd);
        allGovBlocksUsers.push(_gbUserName);
        govBlocksDapps[_gbUserName].masterAddress = address(tempInstance);
        govBlocksDapps[_gbUserName].dappDescHash = _dappDescriptionHash;
        govBlocksDappByAddress[address(tempInstance)] = _gbUserName;
        govBlocksDappByAddress[_dappTokenAddress] = _gbUserName;
        Master ms = Master(address(tempInstance));
        ms.initMaster(msg.sender, _gbUserName, implementations);
    }

    /// @dev Changes dApp master address
    /// @param _gbUserName dApp name
    /// @param _newMasterAddress dApp new master address
    function changeDappMasterAddress(bytes32 _gbUserName, address _newMasterAddress) external {
        if (address(governChecker) != address(0))          // Owner for debugging only, will be removed before launch
            require(governChecker.authorizedAddressNumber(_gbUserName, msg.sender) > 0 || owner == msg.sender);
        else
            require(owner == msg.sender);
        govBlocksDapps[_gbUserName].masterAddress = _newMasterAddress;                   
        govBlocksDappByAddress[_newMasterAddress] = _gbUserName;
    }

    /// @dev Changes dApp desc hash
    /// @param _gbUserName dApp name
    /// @param _descHash dApp new desc hash
    function changeDappDescHash(bytes32 _gbUserName, string _descHash) external {
        if (address(governChecker) != address(0))          // Owner for debugging only, will be removed before launch
            require(governChecker.authorizedAddressNumber(_gbUserName, msg.sender) > 0 || owner == msg.sender);
        else
            require(owner == msg.sender);
        govBlocksDapps[_gbUserName].dappDescHash = _descHash;                   
    }

    /// @dev Changes dApp token address
    /// @param _gbUserName  dApp name
    /// @param _dappTokenAddress dApp new token address
    function changeDappTokenAddress(bytes32 _gbUserName, address _dappTokenAddress) external {
        if (address(governChecker) != address(0))          // Owner for debugging only, will be removed before launch
            require(governChecker.authorizedAddressNumber(_gbUserName, msg.sender) > 0 || owner == msg.sender);
        else
            require(owner == msg.sender);
        govBlocksDapps[_gbUserName].tokenAddress = _dappTokenAddress;                        
        govBlocksDappByAddress[_dappTokenAddress] = _gbUserName;
    }

    /// @dev Sets byte code and abi hash that will help in generating new set of contracts for every dApp
    /// @param _byteCodeHash Byte code hash of all contracts    
    /// @param _abiHash Abi hash of all contracts
    function setByteCodeAndAbi(string _byteCodeHash, string _abiHash) external onlyOwner {
        byteCodeHash = _byteCodeHash;
        contractsAbiHash = _abiHash;
    }

    function setImplementations(address[] _implementations) external onlyOwner {
        implementations = _implementations;
    }

    /// @dev Sets dApp user information such as Email id, name etc.
    function setDappUser(string _hash) external {
        govBlocksUser[msg.sender] = _hash;
    }

    /// @dev Sets global event caller address
    function setEventCallerAddress(address _eventCaller) external onlyOwner {
        eventCaller = _eventCaller;
    }

    /// @dev Initializes GovBlocks master
    /// @param _gbtAddress GBT standard token address
    function govBlocksMasterInit(address _gbtAddress, address _eventCaller, address _master) public {
        require(!initialized);
        require(owner != address(0));
        
        gbtAddress = _gbtAddress;
        eventCaller = _eventCaller;
        masterAdd = _master;
        Governed govern = new Governed();
        governChecker = GovernChecker(govern.governChecker());
        if (address(governChecker) != address(0))
            governChecker.updateGBMAdress(address(this));
        initialized = true;
    }

    /// @dev Gets byte code and abi hash
    function getByteCodeAndAbi() public view returns(string, string) {
        return (byteCodeHash, contractsAbiHash);
    }
    
    /// @dev Gets dApp details
    /// @param _gbUserName dApp name
    /// @return gbUserName dApp name
    /// @return masterContractAddress Master contract address of dApp
    /// @return allContractsbyteCodeHash All contracts byte code hash
    /// @return allCcontractsAbiHash All contracts abi hash
    /// @return versionNo Current Verson number of dApp
    function getGovBlocksUserDetails(bytes32 _gbUserName) 
        public 
        view 
        returns(
            bytes32 gbUserName, 
            address masterContractAddress, 
            string allContractsbyteCodeHash, 
            string allCcontractsAbiHash, 
            uint versionNo
        ) 
    {
        address masterAddress = govBlocksDapps[_gbUserName].masterAddress;
        if (masterAddress == address(0))
            return (_gbUserName, address(0), "", "", 0);
        Master master = Master(masterAddress);
        versionNo = master.getCurrentVersion();
        return (_gbUserName, govBlocksDapps[_gbUserName].masterAddress, byteCodeHash, contractsAbiHash, versionNo);
    }

    /// @dev Gets dApp details such as master contract address and dApp name
    function getGovBlocksUserDetailsByIndex(uint _index) 
        public 
        view 
        returns(uint index, bytes32 gbUserName, address masterContractAddress) 
    {
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
    function getGovBlocksUserDetails1(bytes32 _gbUserName) 
        public 
        view 
        returns(
            bytes32 gbUserName, 
            address masterContractAddress, 
            address dappTokenAddress, 
            string allContractsbyteCodeHash, 
            string allCcontractsAbiHash, 
            uint versionNo
        ) 
    {
        address masterAddress = govBlocksDapps[_gbUserName].masterAddress;
        if (masterAddress == address(0))
            return (_gbUserName, address(0), address(0), "", "", 0);
            
        Master master = Master(masterAddress);
        versionNo = master.getCurrentVersion();
        return (
            _gbUserName, 
            govBlocksDapps[_gbUserName].masterAddress, 
            govBlocksDapps[_gbUserName].tokenAddress, 
            byteCodeHash, 
            contractsAbiHash, 
            versionNo
        );
    }

    /// @dev Gets dApp details by passing either of contract address i.e. Token or Master contract address
    /// @param _address Contract address is passed
    /// @return dappName dApp name
    /// @return masterContractAddress Master contract address of dApp
    /// @return dappTokenAddress dApp's token address
    function getGovBlocksUserDetails2(address _address) 
        public 
        view 
        returns(bytes32 dappName, address masterContractAddress, address dappTokenAddress) 
    {
        dappName = govBlocksDappByAddress[_address];
        return (dappName, govBlocksDapps[dappName].masterAddress, govBlocksDapps[dappName].tokenAddress);
    }

    /// @dev Gets dApp description hash
    /// @param _gbUserName dApp name
    function getDappDescHash(bytes32 _gbUserName) public view returns(string) {
        return govBlocksDapps[_gbUserName].dappDescHash;
    }

    /// @dev Gets Total number of dApp that has been integrated with GovBlocks so far.
    function getAllDappLength() public view returns(uint) {
        return (allGovBlocksUsers.length);
    }

    /// @dev Gets dApps users by index
    function getAllDappById(uint _gbIndex) public view returns(bytes32 _gbUserName) {
        return (allGovBlocksUsers[_gbIndex]);
    }

    /// @dev Gets all dApps users
    function getAllDappArray() public view returns(bytes32[]) {
        return (allGovBlocksUsers);
    }

    /// @dev Gets dApp username
    function getDappUser() public view returns(string) {
        return (govBlocksUser[msg.sender]);
    }

    /// @dev Gets dApp master address of dApp (username=govBlocksUser)
    function getDappMasterAddress(bytes32 _gbUserName) public view returns(address masterAddress) {
        return (govBlocksDapps[_gbUserName].masterAddress);
    }

    /// @dev Gets dApp token address of dApp (username=govBlocksUser)
    function getDappTokenAddress(bytes32 _gbUserName) public view returns(address tokenAddres) {
        return (govBlocksDapps[_gbUserName].tokenAddress);
    }

    /// @dev Gets dApp token address of dApp (username=govBlocksUser)
    function getDappTokenProxyAddress(bytes32 _gbUserName) public view returns(address tokenAddres) {
        return (govBlocksDapps[_gbUserName].proxyAddress);
    }

    /// @dev Gets dApp username by address
    function getDappNameByAddress(address _contractAddress) public view returns(bytes32) {
        return govBlocksDappByAddress[_contractAddress];
    }
}