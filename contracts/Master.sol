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
import "./imports/govern/Governed.sol";
import "./Governance.sol";
import "./MemberRoles.sol";


contract Master is Ownable, Governed {

    uint[] public versionDates;
    bytes2[] public allContractNames;

    mapping(address => bool) public contractsActive;
    mapping(bytes2 => address) public contractAddress;

    address public dAppLocker;
    address public dAppToken;
    address public eventCaller;

    Governed internal govern;
    
    function initMaster(
        address _ownerAddress,
        bool _punishVoters,
        address _token,
        address _lockableToken,
        address _eventCaller,
        address[] _implementations
    ) external {
        _addContractNames();
        masterAddress = address(this);
        require(allContractNames.length == _implementations.length);
        contractsActive[address(this)] = true;
        dAppToken = _token;
        dAppLocker = _lockableToken;
        owner = _ownerAddress;
        eventCaller = _eventCaller;
        versionDates.push(now); //solhint-disable-line

        for (uint i = 0; i < allContractNames.length; i++) {
            _generateProxy(allContractNames[i], _implementations[i]);
        }

        _changeMasterAddress(address(this));
        _changeAllAddress();

        MemberRoles mr = MemberRoles(contractAddress["MR"]);
        mr.memberRolesInitiate(dAppToken, _ownerAddress);

        Governance gv = Governance(contractAddress["GV"]);
        gv.initiateGovernance(_punishVoters);
    }

    /// @dev Creates a new version of contract addresses
    /// @param _contractAddresses Array of contract implementations
    function addNewVersion(address[] _contractAddresses) external onlyAuthorizedToGovern {
        for (uint i = 0; i < allContractNames.length; i++) {
            _replaceImplementation(allContractNames[i], _contractAddresses[i]);
        }

        versionDates.push(now); //solhint-disable-line
    }

    /// @dev adds a new contract type to master
    function addNewContract(bytes2 _contractName, address _contractAddress) external onlyAuthorizedToGovern {
        allContractNames.push(_contractName);
        _generateProxy(_contractName, _contractAddress);
        _changeMasterAddress(address(this));
        _changeAllAddress();
    }

    /// @dev upgrades a single contract
    function upgradeContractImplementation(bytes2 _contractsName, address _contractAddress) 
        external onlyAuthorizedToGovern
    {
        if (_contractsName == "MS") {
            _changeMasterAddress(_contractAddress);
        } else {
            _replaceImplementation(_contractsName, _contractAddress);
        }
        versionDates.push(now);  //solhint-disable-line
    }

    /// @dev upgrades a single contract
    function upgradeContractProxy(bytes2 _contractsName, address _contractAddress) 
        external onlyAuthorizedToGovern 
    {
        contractsActive[contractAddress[_contractsName]] = false;
        _generateProxy(_contractsName, _contractAddress);
        _changeMasterAddress(address(this));
        _changeAllAddress();
    }

    /// @dev sets dAppTokenProxy address
    /// @param _locker address where tokens are locked
    function setDAppLocker(address _locker) external onlyAuthorizedToGovern {
        dAppLocker = _locker;
        _changeAllAddress();
    }
    
    /// @dev Gets current version amd its master address
    /// @return versionNo Current version number that is active
    function getCurrentVersion() public view returns(uint versionNo) {
        return versionDates.length;
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
            contractAddresses[i] = contractAddress[allContractNames[i]];

        return(versionDates.length, allContractNames, contractAddresses);
    }

    /// @dev Gets latest contract address
    /// @param _contractName Contract name to fetch
    function getLatestAddress(bytes2 _contractName) public view returns(address) {
        return contractAddress[_contractName];
    }

    /// @dev Save the initials of all the contracts
    function _addContractNames() internal {
        allContractNames.push("MR");
        allContractNames.push("PC");
        allContractNames.push("GV");
    }

    /// @dev Sets the older versions of contract addresses as inactive and the latest one as active.
    function _changeAllAddress() internal {
        for (uint i = 0; i < allContractNames.length; i++) {
            Upgradeable up = Upgradeable(contractAddress[allContractNames[i]]);
            up.updateDependencyAddresses();
        }
    }

    /// @dev Changes Master contract address
    function _changeMasterAddress(address _masterAddress) internal {
        for (uint i = 0; i < allContractNames.length; i++) {
            Upgradeable up = Upgradeable(contractAddress[allContractNames[i]]);
            up.changeMasterAddress(_masterAddress);
        }
    }

    function _replaceImplementation(bytes2 _contractsName, address _contractAddress) internal {
        OwnedUpgradeabilityProxy tempInstance 
                = OwnedUpgradeabilityProxy(contractAddress[_contractsName]);
        tempInstance.upgradeTo(_contractAddress);
    }

    function _generateProxy(bytes2 _contractName, address _contractAddress) internal {
        OwnedUpgradeabilityProxy tempInstance = new OwnedUpgradeabilityProxy(_contractAddress);
        contractAddress[_contractName] = address(tempInstance);
        contractsActive[address(tempInstance)] = true;
    }
}