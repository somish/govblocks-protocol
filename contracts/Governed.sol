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

pragma solidity ^0.4.24;

contract GovernChecker {
    function authorized(bytes32 _dAppName) public view returns(address);
    function initializeAuthorized(bytes32 _dAppName, address authorizedAddress) public;
    function updateGBMAdress(address _govBlockMaster) public;
}

contract Governed {

    GovernChecker internal governChecker;

    bytes32 internal dAppName;

    modifier onlyAuthorizedToGovern() {
        require(governChecker.authorized(dAppName) == msg.sender);
        _;
    }

    // @dev You need to enter your dApp name here.
    constructor() {
        setGovernChecker();
        dAppName = "GOVBLOCKS";
    } 

    function setGovernChecker() public {
        if (getCodeSize(0xb176c4c479837d2b8f830418c6201a4f5fdbe902) > 0)        //kovan testnet
            governChecker = GovernChecker(0xb176c4c479837d2b8f830418c6201a4f5fdbe902);
        else if (getCodeSize(0xc1851dec0b56f7551631fe7699bad677a6130609) > 0)   //RSK testnet
            governChecker = GovernChecker(0xc1851dec0b56f7551631fe7699bad677a6130609);
        else if (getCodeSize(0x67995f25f04d61614d05607044c276727dea9cf0) > 0)   //Rinkeyby testnet
            governChecker = GovernChecker(0x67995f25f04d61614d05607044c276727dea9cf0);
        else if (getCodeSize(0xb5fe0857770d85302585564b04c81a5be96022c8) > 0)   //Ropsten testnet
            governChecker = GovernChecker(0xb5fe0857770d85302585564b04c81a5be96022c8);

    }

    function getCodeSize(address _addr) internal view returns(uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    function getGovernCheckerAddress() public view returns(address) {
        return address(governChecker);
    }
}