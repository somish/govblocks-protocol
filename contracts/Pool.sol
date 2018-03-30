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

pragma solidity ^0.4.8;

import "./Master.sol";
// import "github.com/oraclize/ethereum-api/oraclizeAPI_0.4.sol";
import "./oraclizeAPI_0.4.sol";
import "./GBTStandardToken.sol";
import "./GBTController.sol";

contract Pool is usingOraclize
{
    event closeProposal(uint256 indexed proposalId,uint256 closingTime,string URL);

    using SafeMath for uint;
    address masterAddress;
    address GBTOwner;
    address GBTControllerAddress;
    address GBTStandardTokenAddress;
    GBTController GBTC;
    GBTStandardToken GBTS;
    Master M1;
    // uint public tokenPrice;

    mapping(bytes32=>apiId) public allAPIid;
    bytes32[] public allAPIcall;

    struct apiId
    {
        bytes8 type_of;
        uint proposalId;
        uint64 dateAdd;
        uint64 dateUpd;
    }

    event apiresult(address indexed sender,string msg,bytes32 myid);

    function changeMasterAddress(address _add)
    {
        if(masterAddress == 0x000)
            masterAddress = _add;
        else
        {
            M1=Master(masterAddress);
            if(M1.isInternal(msg.sender) == 1)
                masterAddress = _add;
            else
                throw;
        }
     
    }

    modifier onlyInternal {
        M1=Master(masterAddress);
        require(M1.isInternal(msg.sender) == 1);
        _; 
    }
    
    modifier onlyOwner {
        M1=Master(masterAddress);
        require(M1.isOwner(msg.sender) == 1);
        _; 
    }
     
    function changeGBTtokenAddress(address _GBTSContractAddress)
    {
        GBTStandardTokenAddress = _GBTSContractAddress;
    }

    function changeGBTControllerAddress(address _GBTCAddress)
    {
        GBTControllerAddress = _GBTCAddress;
    }
    
    function () payable {}

    // function buyGBT(uint _amount) 
    // {
    //     GBTC=GBTController(GBTControllerAddress);
    //     GBTC.buyTokenGBT.value(_amount)(address(this));
    // }


    function buyGBT() payable
    {
        GBTC=GBTController(GBTControllerAddress);
        GBTC.buyTokenGBT.value(msg.value)(address(this));
    }


    function transferGBTtoController(uint _amount,string _description) 
    {
        GBTC=GBTController(GBTControllerAddress);
        GBTC.receiveGBT(address(this),_amount,_description);
    }

    function closeProposalOraclise(uint _proposalId , uint24 _closingTime) 
    {
        uint index = getApilCall_length(); bytes32 myid2;
        M1=Master(masterAddress);

        if (_closingTime == 0)
            myid2 = oraclize_query("URL",strConcat("http://a1.govblocks.io/closeProposalVoting.js/42/",bytes32ToString(M1.DappName()),"/",uint2str(index)));
        else
            myid2 = oraclize_query(_closingTime,"URL",strConcat("http://a1.govblocks.io/closeProposalVoting.js/42",bytes32ToString(M1.DappName()),"/",uint2str(index)));
        
        uint closeTime = now + _closingTime;
        closeProposal(_proposalId,closeTime,strConcat("http://a1.govblocks.io/closeProposalVoting.js/42/",bytes32ToString(M1.DappName()),"/",uint2str(index)));
        saveApiDetails(myid2,"PRO",_proposalId);
        addInAllApiCall(myid2);
    }

    function saveApiDetails(bytes32 myid,bytes8 _typeof,uint id) internal
    {
        allAPIid[myid] = apiId(_typeof,id,uint64(now),uint64(now));
    }

    function addInAllApiCall(bytes32 myid) internal
    {
        allAPIcall.push(myid);
    }

    function getApiCall_Index(uint index) constant returns(bytes32 myid)
    {
        myid = allAPIcall[index];
    }

    function getApilCall_length() constant returns(uint len)
    {
        return allAPIcall.length;
    }

    function getApiCallDetails(bytes32 myid)constant returns(bytes8 _typeof,uint id,uint64 dateAdd,uint64 dateUpd)
    {
        return(allAPIid[myid].type_of,allAPIid[myid].proposalId,allAPIid[myid].dateAdd,allAPIid[myid].dateUpd);
    }

    function getApiIdTypeOf(bytes32 myid)constant returns(bytes16 _typeof)
    {
        _typeof=allAPIid[myid].type_of;
    }

    function getProposalIdOfApiId(bytes32 myid)constant returns(uint id1)
    {
        id1 = allAPIid[myid].proposalId;
    }
    
    function __callback(bytes32 myid, string res) 
    {
        M1=Master(masterAddress);
        if(msg.sender != oraclize_cbAddress() && M1.isOwner(msg.sender)!=1) throw;
        allAPIid[myid].dateUpd = uint64(now);
    }
    
    function transferBackEther(uint256 amount) onlyOwner
    {
        address _add=msg.sender;
        bool succ = _add.send(amount);  
    }

   function bytes32ToString(bytes32 x) constant returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    function getMyIndexByProposalId(uint _proposalId) constant returns(uint myIndexId)
    {
        uint length = getApilCall_length();
        for(uint i=0; i<length; i++)
        {
            bytes32 myid = getApiCall_Index(i);
            uint propId = getProposalIdOfApiId(myid);
            if(_proposalId == propId)
                myIndexId = i;
        }
    }

}