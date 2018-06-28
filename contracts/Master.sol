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

import "./Upgradeable.sol";
import "./GBTStandardToken.sol";
import "./GovBlocksMaster.sol";
import "./Ownable.sol";

contract Master is Ownable, Upgradeable {

    struct changeVersion {
        uint date_implement;
        uint16 versionNo;
    }

    uint16 public versionLength;
    bytes32 public DappName;
    bytes2[] allContractNames;
    changeVersion[] public contractChangeDate;
    mapping(address => bool) public contracts_active;
    mapping(uint16 => mapping(bytes2 => address)) public allContractVersions;

    GovBlocksMaster GBM;
    Upgradeable up;
    bool constructorCheck;
    address public GBMAddress;

    /// @dev Constructor function for master
    /// @param _GovBlocksMasterAddress GovBlocks master address
    /// @param _gbUserName dApp Name which is integrating GovBlocks.
    function Master(address _GovBlocksMasterAddress, bytes32 _gbUserName) {
        contracts_active[address(this)] = true;
        versionLength = 0;
        GBMAddress = _GovBlocksMasterAddress;
        DappName = _gbUserName;
        owner = msg.sender;
        addContractNames();
    }

    modifier onlyOwner {
        require(isOwner(msg.sender) == true);
        _;
    }

    modifier onlyAuthorizedGB {
        GBM = GovBlocksMaster(GBMAddress);
        require(GBM.isAuthorizedGBOwner(DappName, msg.sender) == true);
        _;
    }

    modifier onlyInternal {
        require(contracts_active[msg.sender] == true || owner == msg.sender);
        _;
    }

    /// @dev Returns true if the caller address is GovBlocksMaster Address.
    function isGBM(address _GBMaddress) constant returns(bool check) {
        require(_GBMaddress == GBMAddress);
    }

    /// @dev Checks for authorized Member for Dapp and returns true if the address is authorized in dApp.
    /// @param _memberaddress Address to be checked
    function isAuthGB(address _memberaddress) constant returns(bool check) {
        GBM = GovBlocksMaster(GBMAddress);
        require(GBM.isAuthorizedGBOwner(DappName, _memberaddress) == true);
        check = true;
    }

    /// @dev Checks if the caller address is either one of its active contract address or owner.
    /// @param _address  address to be checked for internal
    /// @return check returns true if the condition meets
    function isInternal(address _address) constant returns(bool check) {
        if (contracts_active[_address] == true || owner == _address)
            check = true;
    }

    /// @dev Checks if the caller address is owner
    /// @param _ownerAddress member address to be checked for owner
    /// @return check returns true if the address is owner address
    function isOwner(address _ownerAddress) constant returns(bool check) {
        if (owner == _ownerAddress)
            check = true;
    }

    /// @dev Sets owner 
    /// @param _memberaddress Contract address to be set as owner
    function setOwner(address _memberaddress) onlyOwner {
        owner = _memberaddress;
    }

    /// @dev Save the initials of all the contracts
    function addContractNames() internal {
        allContractNames.push("MS");
        allContractNames.push("GD");
        allContractNames.push("MR");
        allContractNames.push("PC");
        allContractNames.push("SV");
    //    allContractNames.push("VT");
        allContractNames.push("GV");
        allContractNames.push("PL");
        allContractNames.push("GS");
    }

    /// @dev Creates a new version of contract addresses
    /// @param _contractAddresses Array of nine contract addresses which will be generated
    function addNewVersion(address[6] _contractAddresses) onlyAuthorizedGB {
        GBM = GovBlocksMaster(GBMAddress);
        addContractDetails(versionLength, "MS", address(this));
        addContractDetails(versionLength, "GD", _contractAddresses[0]);
        addContractDetails(versionLength, "MR", _contractAddresses[1]);
        addContractDetails(versionLength, "PC", _contractAddresses[2]);
        addContractDetails(versionLength, "SV", _contractAddresses[3]);
        //addContractDetails(versionLength, "VT", _contractAddresses[4]);
        addContractDetails(versionLength, "GV", _contractAddresses[4]);
        addContractDetails(versionLength, "PL", _contractAddresses[5]);
        addContractDetails(versionLength, "GS", GBM.getGBTAddress());
        setVersionLength(versionLength + 1);
    }

    /// @dev Adds contract's name  and its address in a given version
    /// @param _versionNo Version number of the contracts
    /// @param _contractName Contract name
    /// @param _contractAddress Contract addresse
    function addContractDetails(uint16 _versionNo, bytes2 _contractName, address _contractAddress) internal {
        allContractVersions[_versionNo][_contractName] = _contractAddress;
    }

    /// @dev Switches to the recent version of contracts
    function switchToRecentVersion() public {
        require(isValidateOwner());
        addInContractChangeDate();
        changeAllAddress();
    }

    /// @dev Stores the date when version of contracts get switched
    function addInContractChangeDate() internal {
        contractChangeDate.push(changeVersion(now, versionLength - 1));
    }

    /// @dev Sets the older versions of contract addresses as inactive and the latest one as active.
    function changeAllAddress() internal {
        for (uint8 i = 0; i < allContractNames.length - 1; i++) {
            addRemoveAddress(versionLength - 1, allContractNames[i]);
            up = Upgradeable(allContractVersions[versionLength - 1][allContractNames[i]]);
            up.changeMasterAddress(address(this));
            up.updateDependencyAddresses();
        }
        addRemoveAddress(versionLength - 1, allContractNames[allContractNames.length - 1]);
    }

    /// @dev just for the interface
    function updateDependencyAddresses() public onlyInternal {
    }

    /// @dev just for the interface
    function changeGBTSAddress(address _GBTSAddress) public onlyInternal {
    }

    /// @dev Changes Master contract address
    function changeMasterAddress(address _MasterAddress) public onlyInternal {
        Master MS = Master(_MasterAddress);
        require(MS.versionLength() > 0);
        addContractDetails(versionLength - 1, "MS", _MasterAddress);
        for (uint8 i = 1; i < allContractNames.length - 1; i++) {
            up = Upgradeable(allContractVersions[versionLength - 1][allContractNames[i]]);
            up.changeMasterAddress(_MasterAddress);
        }
        //GBM=GovBlocksMaster(GBMAddress);
        //GBM.changeDappMasterAddress(DappName,_MasterAddress);  Requires Auth Address
    }

    /// @dev Deactivates address of a contract from last version
    /// @param _version Version of the new contracts
    /// @param _contractName Contract name
    function addRemoveAddress(uint16 _version, bytes2 _contractName) internal {
        uint16 version_old = 0;
        if (_version > 0)
            version_old = _version - 1;
        contracts_active[allContractVersions[version_old][_contractName]] = false;
        contracts_active[allContractVersions[_version][_contractName]] = true;
    }


    /// @dev Changes GBT standard token address in GD, SV, SVT and governance contracts
    /// @param _tokenAddress Address of the GBT token
    function changeGBTAddress(address _tokenAddress) public {
        require(isValidateOwner());
        for (uint8 i = 1; i < allContractNames.length - 1; i++) {
            up = Upgradeable(allContractVersions[versionLength - 1][allContractNames[i]]);
            up.changeGBTSAddress(_tokenAddress);
        }
    }

    /// @dev Checks the authenticity of changing address or switching to recent version 
    function isValidateOwner() constant returns(bool) {
        GBM = GovBlocksMaster(GBMAddress);
        uint16 version = versionLength - 1;
        if ((version == 0 && msg.sender == owner) || msg.sender == GBMAddress || GBM.isAuthorizedGBOwner(DappName, msg.sender) == true)
            return true;
    }

    /// @dev Changes GovBlocks Master address
    /// @param _GBMnewAddress New GovBlocks master address
    function changeGBMAddress(address _GBMnewAddress) public {
        require(msg.sender == GBMAddress);
        GBMAddress == _GBMnewAddress;
    }


    /// @dev Sets the length of version
    /// @param _length Length of the version
    function setVersionLength(uint16 _length) internal {
        versionLength = _length;
    }

    /// @dev Gets current version amd its master address
    /// @return versionNo Current version number that is active
    /// @return MSAddress Master contract address
    function getCurrentVersion() constant returns(uint16 versionNo, address MSAddress) {
        versionNo = versionLength - 1;
        MSAddress = allContractVersions[versionNo]['MS'];
    }

    /// @dev Gets latest version name and address
    /// @param _versionNo Version number that data we want to fetch
    /// @return versionNo Version number
    /// @return contractsName Latest version's contract names
    /// @return contractsAddress Latest version's contract addresses
    function getLatestVersionData(uint16 _versionNo) constant returns(uint16 versionNo, bytes2[] contractsName, address[] contractsAddress) {
        versionNo = _versionNo;
        contractsName = new bytes2[](allContractNames.length);
        contractsAddress = new address[](allContractNames.length);

        for (uint8 i = 0; i < allContractNames.length; i++) {
            contractsName[i] = allContractNames[i];
            contractsAddress[i] = allContractVersions[versionNo][allContractNames[i]];
        }
    }

    /// @dev Gets latest contract address
    /// @param _contractName Contract name to fetch
    function getLatestAddress(bytes2 _contractName) public constant returns(address contractAddress){
        contractAddress = allContractVersions[versionLength - 1][_contractName];
    }
}