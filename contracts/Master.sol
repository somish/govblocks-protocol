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
import "./GBTStandardToken.sol";
import "./GovBlocksMaster.sol";
import "./imports/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./GovernanceData.sol";
import "./Governed.sol";


contract Master is Ownable {

    uint[] public versionDates;
    bytes32 public dAppName;
    bytes2[] internal allContractNames;
    mapping(address => bool) public contractsActive;
    mapping(uint => mapping(bytes2 => address)) internal allContractVersions;
    address public dAppTokenProxy;

    GovBlocksMaster internal gbm;
    Upgradeable internal up;
    Governed internal govern;
    address public dAppToken;
    
    function initMaster(address _ownerAddress, bytes32 _gbUserName) public {
        require(address(gbm) == address(0));
        contractsActive[address(this)] = true;
        gbm = GovBlocksMaster(msg.sender);
        dAppName = _gbUserName;
        owner = _ownerAddress;
        versionDates.push(now); //solhint-disable-line
        addContractNames();
    }

    /// @dev Checks if the address is authorized to make changes.
    ///     owner allowed for debugging only, will be removed before launch.
    function isAuth() public view returns(bool check) {
        if (versionDates.length < 2) {
            if (owner == msg.sender)
                check = true;
        } else {
            if (getLatestAddress("SV") == msg.sender || owner == msg.sender)
                check = true;
        }
    }

    /// @dev Checks if the caller address is either one of its active contract address or owner.
    /// @param _address  address to be checked for internal
    /// @return check returns true if the condition meets
    function isInternal(address _address) public view returns(bool check) {
        if (contractsActive[_address] || owner == _address)
            check = true;
    }

    /// @dev returns gbm address
    function gbmAddress() public view returns(address) {
        return address(gbm);
    }

    /// @dev Creates a new version of contract addresses
    /// @param _contractAddresses Array of contract addresses which will be generated
    function addNewVersion(address[] _contractAddresses) public {
        require(isAuth());
        address gbt = gbm.gbtAddress();
        if (versionDates.length < 2) {
            govern = new Governed();
            GovernChecker governChecker = GovernChecker(govern.governChecker());
            if (getCodeSize(address(governChecker)) > 0) {
                if (governChecker.authorizedAddressNumber(dAppName, _contractAddresses[3]) == 0)
                    governChecker.initializeAuthorized(dAppName, _contractAddresses[3]);
            }
            dAppToken = gbm.getDappTokenAddress(dAppName);
            dAppTokenProxy = gbt;
        }

        for (uint i = 0; i < allContractNames.length - 2; i++) {
            allContractVersions[versionDates.length][allContractNames[i+1]] = _contractAddresses[i];
        }

        allContractVersions[versionDates.length]["GS"] = gbt;

        versionDates.push(now); //solhint-disable-line

        changeMasterAddress(address(this));
        changeAllAddress();
    }

    /// @dev sets dAppTokenProxy address
    function setDAppTokenProxy(address _dAppTokenProxy) public {
        require(isAuth());
        dAppTokenProxy = _dAppTokenProxy;
    }

    /// @dev changeGBTSAddress
    function changeGBTSAddress(address _gbtAddress) public {
        require(msg.sender == address(gbm));
        contractsActive[allContractVersions[versionDates.length - 1]["GS"]] = false;
        allContractVersions[versionDates.length - 1]["GS"] = _gbtAddress;
        contractsActive[_gbtAddress] = true;
        changeAllAddress();
    }

    /// @dev Changes Master contract address
    function changeMasterAddress(address _masterAddress) public {
        if (_masterAddress != address(this)) {
            require(isAuth());
        }
        allContractVersions[versionDates.length - 1]["MS"] = _masterAddress;
        for (uint i = 1; i < allContractNames.length - 1; i++) {
            up = Upgradeable(allContractVersions[versionDates.length - 1][allContractNames[i]]);
            up.changeMasterAddress();
        }
        contractsActive[address(this)] = false;
        contractsActive[_masterAddress] = true;
    }

    /// @dev Changes GovBlocks Master address
    /// @param _gbmNewAddress New GovBlocks master address
    function changeGBMAddress(address _gbmNewAddress) public {
        require(msg.sender == address(gbm));
        gbm = GovBlocksMaster(_gbmNewAddress);
    }

    /// @dev Gets current version amd its master address
    /// @return versionNo Current version number that is active
    function getCurrentVersion() public view returns(uint versionNo) {
        return versionDates.length - 1;
    }

    /// @dev Gets latest version name and address
    /// @param _versionNo Version number that data we want to fetch
    /// @return versionNo Version number
    /// @return contractsName Latest version's contract names
    /// @return contractsAddress Latest version's contract addresses
    function getVersionData(uint _versionNo) 
        public 
        view 
        returns(uint versionNo, bytes2[] contractsName, address[] contractsAddress) 
    {
        versionNo = _versionNo;
        contractsName = new bytes2[](allContractNames.length);
        contractsAddress = new address[](allContractNames.length);

        for (uint i = 0; i < allContractNames.length; i++) {
            contractsName[i] = allContractNames[i];
            contractsAddress[i] = allContractVersions[versionNo][allContractNames[i]];
        }
    }

    /// @dev Gets latest contract address
    /// @param _contractName Contract name to fetch
    function getLatestAddress(bytes2 _contractName) public view returns(address contractAddress) {
        contractAddress =
            allContractVersions[versionDates.length - 1][_contractName];
    }

    /// @dev Configures global parameters i.e. Voting or Reputation parameters
    /// @param _typeOf Passing intials of the parameter name which value needs to be updated
    /// @param _value New value that needs to be updated    
    // solhint-disable-next-line
    function configureGlobalParameters(bytes4 _typeOf, uint32 _value) public {
        require(isAuth());
        GovernanceData governanceDat = GovernanceData(getLatestAddress("GD"));
                    
        if (_typeOf == "APO") {
            governanceDat.changeProposalOwnerAdd(_value);
        } else if (_typeOf == "AOO") {
            governanceDat.changeSolutionOwnerAdd(_value);
        } else if (_typeOf == "RW") {
            governanceDat.changeReputationWeight(_value);
        } else if (_typeOf == "SW") {
            governanceDat.changeStakeWeight(_value);
        } else if (_typeOf == "BR") {
            governanceDat.changeBonusReputation(_value);
        } else if (_typeOf == "BS") {
            governanceDat.changeBonusStake(_value);
        } else if (_typeOf == "QP") {
            governanceDat.changeQuorumPercentage(_value);
        }
    }

    /// @dev adds a new contract type to master
    function addNewContract(bytes2 _contractName, address _contractAddress) public {
        require(isAuth());
        allContractNames.push(allContractNames[allContractNames.length - 1]);
        allContractNames[allContractNames.length - 2] = _contractName;
        contractsActive[_contractAddress] = true;
        allContractVersions[versionDates.length - 1][_contractName] = _contractAddress;
    }

    function getEventCallerAddress() public view returns(address) {
        return gbm.eventCaller();
    }

    function getGovernCheckerAddress() public view returns(address) {
        return govern.governChecker();
    }

    /// @dev Save the initials of all the contracts
    function addContractNames() internal {
        allContractNames.push("MS");
        allContractNames.push("GD");
        allContractNames.push("MR");
        allContractNames.push("PC");
        allContractNames.push("SV");
        allContractNames.push("GV");
        allContractNames.push("PL");
        allContractNames.push("GS");
    }

    function getCodeSize(address _addr) internal view returns(uint _size) {
        assembly { //solhint-disable-line
            _size := extcodesize(_addr)
        }
    }

    /// @dev Sets the older versions of contract addresses as inactive and the latest one as active.
    function changeAllAddress() internal {
        uint i;
        if (versionDates.length < 3) {
            for (i = 1; i < allContractNames.length - 1; i++) {
                contractsActive[allContractVersions[versionDates.length - 1][allContractNames[i]]] = true;
                up = Upgradeable(allContractVersions[versionDates.length - 1][allContractNames[i]]);
                up.updateDependencyAddresses();
            }
        } else {
            for (i = 1; i < allContractNames.length - 1; i++) {
                contractsActive[allContractVersions[versionDates.length - 2][allContractNames[i]]] = false;
                contractsActive[allContractVersions[versionDates.length - 1][allContractNames[i]]] = true;
                up = Upgradeable(allContractVersions[versionDates.length - 1][allContractNames[i]]);
                up.updateDependencyAddresses();
            }
        }
    }
}