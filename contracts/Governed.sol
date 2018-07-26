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
    constructor(bytes32 _dAppName) public {
        setGovernChecker();
        dAppName = _dAppName;
    } 

    function setGovernChecker() public {
        if (getCodeSize(0x42b7429819648B55d6eed353a74842F2e5827262) > 0)        //kovan testnet
            governChecker = GovernChecker(0x42b7429819648B55d6eed353a74842F2e5827262);
        else if (getCodeSize(0xC1851deC0b56f7551631Fe7699bAd677A6130609) > 0)   //RSK testnet
            governChecker = GovernChecker(0xC1851deC0b56f7551631Fe7699bAd677A6130609);
        else if (getCodeSize(0x67995F25f04d61614d05607044c276727DEA9Cf0) > 0)   //Rinkeyby testnet
            governChecker = GovernChecker(0x67995F25f04d61614d05607044c276727DEA9Cf0);
        else if (getCodeSize(0xb5fE0857770D85302585564b04C81a5Be96022C8) > 0)   //Ropsten testnet
            governChecker = GovernChecker(0xb5fE0857770D85302585564b04C81a5Be96022C8);
        else if (getCodeSize(0x962d110554E0b20E18E5c3680018b49A58EF0bBB) > 0)   //Private testnet
            governChecker = GovernChecker(0x962d110554E0b20E18E5c3680018b49A58EF0bBB);
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