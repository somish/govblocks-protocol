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
import "./imports/openzeppelin-solidity/contracts/ownership/Ownable.sol";


contract GovBlocksMaster is Ownable {
    address public eventCaller;
    address[] public implementations;

    event OnBoarded (
        string indexed dappName,
        address masterAddress
    );


    /// @dev Adds GovBlocks dApp
    /// @param _gbDAppName dApp name
    /// @param _dappTokenAddress dApp token address
    function addGovBlocksDapp(
        bytes32 _gbDAppName, 
        address _dappTokenAddress, 
        address _tokenProxy
    ) external {
        Master ms = new Master();
        ms.initMaster(msg.sender, _dappTokenAddress, _tokenProxy, eventCaller, implementations);
        OnBoarded(_gbDAppName, address(ms));
    }  

    function setImplementations(address[] _implementations) external onlyOwner {
        implementations = _implementations;
    }

    /// @dev Sets global event caller address
    function setEventCallerAddress(address _eventCaller) external onlyOwner {
        eventCaller = _eventCaller;
    }

    /// @dev Initializes GovBlocks master
    function GovBlocksMaster(address _eventCaller) public {        
        eventCaller = _eventCaller;
    }

   
}