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
    string constant dAppNotRegistered = "DApp not registered in GovBlocks network";

    struct GBDapps {
        address masterAddress;
        address tokenAddress;
        address proxyAddress;
        string dappDescHash;
    }

    mapping(address => bytes32) internal govBlocksDappByAddress;
    mapping(bytes32 => GBDapps) internal govBlocksDapps;
    bytes32[] internal allGovBlocksDapps;
    string internal byteCodeHash;
    string internal contractsAbiHash;

    /// @dev Updates GBt standard token address
    /// @param _gbtContractAddress New GBT standard token contract address
    function updateGBTAddress(address _gbtContractAddress) external onlyOwner {
        gbtAddress = _gbtContractAddress;
        for (uint i = 0; i < allGovBlocksDapps.length; i++) {
            address masterAddress = govBlocksDapps[allGovBlocksDapps[i]].masterAddress;
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
        for (uint i = 0; i < allGovBlocksDapps.length; i++) {
            address masterAddress = govBlocksDapps[allGovBlocksDapps[i]].masterAddress;
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

    /// @dev Adds GovBlocks dApp
    /// @param _gbDAppName dApp name
    /// @param _dappTokenAddress dApp token address
    /// @param _dappDescriptionHash dApp description hash having dApp or token logo information
    function addGovBlocksDapp(
        bytes32 _gbDAppName, 
        address _dappTokenAddress, 
        address _tokenProxy, 
        string _dappDescriptionHash
    ) external {
        require(govBlocksDapps[_gbDAppName].masterAddress == address(0));
        govBlocksDapps[_gbDAppName].tokenAddress = _dappTokenAddress;
        govBlocksDapps[_gbDAppName].proxyAddress = _tokenProxy;
        GovernedUpgradeabilityProxy tempInstance = new GovernedUpgradeabilityProxy(_gbDAppName, masterAdd);
        allGovBlocksDapps.push(_gbDAppName);
        govBlocksDapps[_gbDAppName].masterAddress = address(tempInstance);
        govBlocksDapps[_gbDAppName].dappDescHash = _dappDescriptionHash;
        govBlocksDappByAddress[address(tempInstance)] = _gbDAppName;
        govBlocksDappByAddress[_dappTokenAddress] = _gbDAppName;
        Master ms = Master(address(tempInstance));
        ms.initMaster(msg.sender, _gbDAppName, implementations);
    }

    /// @dev Changes dApp master address
    /// @param _gbDAppName dApp name
    /// @param _newMasterAddress dApp new master address
    function changeDappMasterAddress(bytes32 _gbDAppName, address _newMasterAddress) external {
        if (address(governChecker) != address(0))          // Owner for debugging only, will be removed before launch
            require(governChecker.authorizedAddressNumber(_gbDAppName, msg.sender) > 0 || owner == msg.sender);
        else
            require(owner == msg.sender);
        govBlocksDapps[_gbDAppName].masterAddress = _newMasterAddress;                   
        govBlocksDappByAddress[_newMasterAddress] = _gbDAppName;
    }

    /// @dev Changes dApp desc hash
    /// @param _gbDAppName dApp name
    /// @param _descHash dApp new desc hash
    function changeDappDescHash(bytes32 _gbDAppName, string _descHash) external {
        if (address(governChecker) != address(0))          // Owner for debugging only, will be removed before launch
            require(governChecker.authorizedAddressNumber(_gbDAppName, msg.sender) > 0 || owner == msg.sender);
        else
            require(owner == msg.sender);
        govBlocksDapps[_gbDAppName].dappDescHash = _descHash;                   
    }

    /// @dev Changes dApp token address
    /// @param _gbDAppName  dApp name
    /// @param _dappTokenAddress dApp new token address
    function changeDappTokenAddress(bytes32 _gbDAppName, address _dappTokenAddress) external {
        if (address(governChecker) != address(0))          // Owner for debugging only, will be removed before launch
            require(governChecker.authorizedAddressNumber(_gbDAppName, msg.sender) > 0 || owner == msg.sender);
        else
            require(owner == msg.sender);
        govBlocksDapps[_gbDAppName].tokenAddress = _dappTokenAddress;                        
        govBlocksDappByAddress[_dappTokenAddress] = _gbDAppName;
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

    /// @dev Gets dApp details such as master contract address and dApp name
    function getGovBlocksDappDetailsByIndex(uint _index) 
        public 
        view 
        returns(uint index, bytes32 gbDAppName, address masterContractAddress) 
    {
        return (_index, allGovBlocksDapps[_index], govBlocksDapps[allGovBlocksDapps[_index]].masterAddress);
    }

    /// @dev Gets dApp details
    /// @param _gbDAppName dApp name whose details need to be fetched
    /// @return GbUserName dApp name 
    /// @return masterContractAddress Master contract address
    /// @return dappTokenAddress dApp token address
    /// @return allContractsbyteCodeHash All contracts byte code hash
    /// @return allCcontractsAbiHash All contract abi hash
    /// @return versionNo Version number
    function getGovBlocksDappDetails(bytes32 _gbDAppName) 
        public 
        view 
        returns(
            bytes32 gbDAppName, 
            address masterContractAddress, 
            address dappTokenAddress, 
            string allContractsbyteCodeHash, 
            string allCcontractsAbiHash, 
            uint versionNo
        ) 
    {
        address masterAddress = govBlocksDapps[_gbDAppName].masterAddress;

        require (masterAddress != address(0), dAppNotRegistered);
            
        Master master = Master(masterAddress);
        versionNo = master.getCurrentVersion();
        return (
            _gbDAppName, 
            govBlocksDapps[_gbDAppName].masterAddress, 
            govBlocksDapps[_gbDAppName].tokenAddress, 
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
    function getDappDetailsByAddress(address _address) 
        public 
        view 
        returns(bytes32 dappName, address masterContractAddress, address dappTokenAddress) 
    {
        dappName = govBlocksDappByAddress[_address];
        return (dappName, govBlocksDapps[dappName].masterAddress, govBlocksDapps[dappName].tokenAddress);
    }

    /// @dev Gets dApp description hash
    /// @param _gbDAppName dApp name
    function getDappDescHash(bytes32 _gbDAppName) public view returns(string) {
        return govBlocksDapps[_gbDAppName].dappDescHash;
    }

    /// @dev Gets Total number of dApp that has been integrated with GovBlocks so far.
    function getAllDappLength() public view returns(uint) {
        return (allGovBlocksDapps.length);
    }

    /// @dev Gets dApps users by index
    function getAllDappById(uint _gbIndex) public view returns(bytes32 _gbDAppName) {
        return (allGovBlocksDapps[_gbIndex]);
    }

    /// @dev Gets all dApps users
    function getAllDappArray() public view returns(bytes32[]) {
        return (allGovBlocksDapps);
    }

    /// @dev Gets dApp master address of dApp (username=govBlocksUser)
    function getDappMasterAddress(bytes32 _gbDAppName) public view returns(address masterAddress) {
        return (govBlocksDapps[_gbDAppName].masterAddress);
    }

    /// @dev Gets dApp token address of dApp (username=govBlocksUser)
    function getDappTokenAddress(bytes32 _gbDAppName) public view returns(address tokenAddres) {
        return (govBlocksDapps[_gbDAppName].tokenAddress);
    }

    /// @dev Gets dApp token address of dApp (username=govBlocksUser)
    function getDappTokenProxyAddress(bytes32 _gbDAppName) public view returns(address tokenAddres) {
        return (govBlocksDapps[_gbDAppName].proxyAddress);
    }

    /// @dev Gets dApp username by address
    function getDappNameByAddress(address _contractAddress) public view returns(bytes32) {
        return govBlocksDappByAddress[_contractAddress];
    }
}