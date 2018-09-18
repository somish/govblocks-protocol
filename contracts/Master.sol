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

import "./Upgradeable.sol";
import "./GovBlocksMaster.sol";
import "./imports/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./imports/proxy/OwnedUpgradeabilityProxy.sol";
import "./GovernanceData.sol";
import "./imports/govern/Governed.sol";
import "./ProposalCategory.sol";
import "./MemberRoles.sol";


contract Master is Ownable {

    uint[] public versionDates;
    bytes32 public dAppName;
    bytes2[] public allContractNames;

    mapping(address => bool) public contractsActive;
    mapping(bytes2 => address) public contractsAddress;

    address public dAppLocker;
    address public gbt;
    address public dAppToken;

    GovBlocksMaster public gbm;
    Governed internal govern;
    
    // Owner is just for testing, will be removed before launch.
    modifier authorizedOnly() {
        require(owner == msg.sender || contractsAddress["SV"] == msg.sender);
        _;
    }

    modifier govBlocksMasterOnly() {
        require(owner == msg.sender || msg.sender == address(gbm));
        _;
    }

    function initMaster(address _ownerAddress, bytes32 _gbUserName, address[] _implementations) external {
        require(address(gbm) == address(0));

        _addContractNames();
        require(allContractNames.length == _implementations.length);
        
        contractsActive[address(this)] = true;
        gbm = GovBlocksMaster(msg.sender);
        gbt = gbm.gbtAddress();
        dAppToken = gbm.getDappTokenAddress(_gbUserName);
        dAppLocker = gbm.getDappTokenProxyAddress(_gbUserName);
        dAppName = _gbUserName;
        owner = _ownerAddress;
        versionDates.push(now); //solhint-disable-line

        for (uint i = 0; i < allContractNames.length; i++) {
            _generateProxy(allContractNames[i], _implementations[i]);
        }

        govern = new Governed();
        GovernChecker governChecker = GovernChecker(govern.governChecker());
        if (address(governChecker) != address(0)) {
            if (governChecker.authorizedAddressNumber(_gbUserName, contractsAddress["SV"]) == 0)
                governChecker.initializeAuthorized(_gbUserName, contractsAddress["SV"]);
        }

        _changeMasterAddress(address(this));
        _changeAllAddress();

        ProposalCategory pc = ProposalCategory(contractsAddress["PC"]);
        pc.proposalCategoryInitiate(_gbUserName);

        MemberRoles mr = MemberRoles(contractsAddress["MR"]);
        mr.memberRolesInitiate(_gbUserName, dAppToken, _ownerAddress);
    }

    /// @dev Creates a new version of contract addresses
    /// @param _contractAddresses Array of contract implementations
    function addNewVersion(address[] _contractAddresses) external authorizedOnly {
        for (uint i = 0; i < allContractNames.length; i++) {
            _replaceImplementation(allContractNames[i], _contractAddresses[i]);
        }

        versionDates.push(now); //solhint-disable-line
    }

    /// @dev adds a new contract type to master
    function addNewContract(bytes2 _contractName, address _contractAddress) external authorizedOnly {
        allContractNames.push(_contractName);
        _generateProxy(_contractName, _contractAddress);
        _changeMasterAddress(address(this));
        _changeAllAddress();
    }

    /// @dev upgrades a single contract
    function upgradeContractImplementation(bytes2 _contractsName, address _contractsAddress) 
        external authorizedOnly 
    {
        _replaceImplementation(_contractsName, _contractsAddress);
        versionDates.push(now);  //solhint-disable-line
    }

    /// @dev upgrades a single contract
    function upgradeContractProxy(bytes2 _contractsName, address _contractsAddress) 
        external authorizedOnly 
    {
        contractsActive[contractsAddress[_contractsName]] = false;
        _generateProxy(_contractsName, _contractsAddress);
        _changeMasterAddress(address(this));
        _changeAllAddress();
    }

    /// @dev sets dAppTokenProxy address
    /// @param _locker address where tokens are locked
    function setDAppLocker(address _locker) external authorizedOnly {
        dAppLocker = _locker;
        _changeAllAddress();
    }

    /// @dev changeGBTSAddress. Refreshes all addresses including GBT.
    function changeGBTSAddress() external govBlocksMasterOnly {
        gbt = gbm.gbtAddress();
        _changeAllAddress();
    }

    /// @dev Changes Master contract address
    /// To be called only when proxy is being changed
    /// To update implementation, use voting to call upgradeTo of the proxy.
    function changeMasterAddress(address _masterAddress) external authorizedOnly {
        _changeMasterAddress(_masterAddress);
    }

    /// @dev Changes GovBlocks Master address
    /// @param _gbmNewAddress New GovBlocks master address
    function changeGBMAddress(address _gbmNewAddress) external govBlocksMasterOnly {
        gbm = GovBlocksMaster(_gbmNewAddress);
    }

    /// @dev Gets current version amd its master address
    /// @return versionNo Current version number that is active
    function getCurrentVersion() public view returns(uint versionNo) {
        return versionDates.length;
    }

    /// @dev Checks if the address is authorized to make changes.
    ///     owner allowed for debugging only, will be removed before launch.
    function isAuth() public view returns(bool check) {
        if (owner == msg.sender || contractsAddress["SV"] == msg.sender)
            check = true;
    }

    /// @dev Checks if the caller address is either one of its active contract address or owner.
    /// @param _address  address to be checked for internal
    /// @return check returns true if the condition meets
    function isInternal(address _address) public view returns(bool check) {
        if (contractsActive[_address] || owner == _address)
            check = true;
    }

    /// @dev Gets latest version name and address
    function getVersionData() public view returns(uint, bytes2[], address[]) {
        address[] memory contractAddresses = new address[](allContractNames.length);

        for (uint i = 0; i < allContractNames.length; i++)
            contractAddresses[i] = contractsAddress[allContractNames[i]];

        return(versionDates.length, allContractNames, contractAddresses);
    }

    /// @dev Gets latest contract address
    /// @param _contractName Contract name to fetch
    function getLatestAddress(bytes2 _contractName) public view returns(address) {
        return contractsAddress[_contractName];
    }

    function getEventCallerAddress() public view returns(address) {
        return gbm.eventCaller();
    }

    function getGovernCheckerAddress() public view returns(address) {
        return govern.governChecker();
    }

    /// @dev Save the initials of all the contracts
    function _addContractNames() internal {
        allContractNames.push("GD");
        allContractNames.push("MR");
        allContractNames.push("PC");
        allContractNames.push("SV");
        allContractNames.push("GV");
        allContractNames.push("PL");
    }

    /// @dev Sets the older versions of contract addresses as inactive and the latest one as active.
    function _changeAllAddress() internal {
        for (uint i = 0; i < allContractNames.length; i++) {
            Upgradeable up = Upgradeable(contractsAddress[allContractNames[i]]);
            up.updateDependencyAddresses();
        }
    }

    /// @dev Changes Master contract address
    function _changeMasterAddress(address _masterAddress) internal {
        for (uint i = 0; i < allContractNames.length; i++) {
            Upgradeable up = Upgradeable(contractsAddress[allContractNames[i]]);
            up.changeMasterAddress(_masterAddress);
        }
    }

    function _replaceImplementation(bytes2 _contractsName, address _contractsAddress) internal {
        OwnedUpgradeabilityProxy tempInstance 
                = OwnedUpgradeabilityProxy(contractsAddress[_contractsName]);
        tempInstance.upgradeTo(_contractsAddress);
    }

    function _generateProxy(bytes2 _contractName, address _contractAddress) internal {
        OwnedUpgradeabilityProxy tempInstance = new OwnedUpgradeabilityProxy(_contractAddress);
        contractsAddress[_contractName] = address(tempInstance);
        contractsActive[address(tempInstance)] = true;
    }
}