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

import "./GovernanceData.sol";
import "./Master.sol";
import "github.com/oraclize/ethereum-api/oraclizeAPI_0.4.sol";
import "./SimpleVoting.sol";
import "./GBTStandardToken.sol";
import "./GBTController.sol";

contract Pool is usingOraclize
{
    using SafeMath for uint;
    address GDAddress;
    address masterAddress;
    address GBTOwner;
    address SVAddress;
    address GBTControllerAddress;
    address GBTStandardTokenAddress;
    GBTController GBTC;
    SimpleVoting SV;
    GBTStandardToken GBTS;
    GovernanceData GD;
    Master M1;
    // uint public tokenPrice;

    mapping(bytes32=>apiId) public allAPIid;
    bytes32[] public allAPIcall;

    struct apiId
    {
        bytes8 type_of;
        bytes4 currency;
        uint id;
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
     
    function changeAllContractsAddress(address _GDContractAddress,address _SVContractAddress) onlyInternal
    {
        GDAddress = _GDContractAddress;
        SVAddress = _SVContractAddress;
    }

    function changeGBTtokenAddress(address _GBTSContractAddress)
    {
        GBTStandardTokenAddress = _GBTSContractAddress;
    }

    function changeGBTControllerAddress(address _GBTCAddress)
    {
        GBTControllerAddress = _GBTCAddress;
    }
    
    /// @dev User can buy the GBTToken equivalent to the amount paid by the user.
    function buyToken(address _memberAddress) payable 
    {
        GBTC=GBTController(GBTControllerAddress);
        GBTC.buyTokenGBT(_memberAddress,msg.value);
    }

    function closeProposalOraclise(uint _proposalId , uint24 _closingTime) onlyInternal
    {
        bytes32 myid2 = oraclize_query(_closingTime,"","",4000000);
        saveApiDetails(myid2,"PRO",_proposalId);
        addInAllApiCall(myid2);
    }

    function saveApiDetails(bytes32 myid,bytes8 _typeof,uint id) internal
    {
        allAPIid[myid] = apiId(_typeof,"",id,uint64(now),uint64(now));
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

    function getApiCallDetails(bytes32 myid)constant returns(bytes8 _typeof,bytes4 curr,uint id,uint64 dateAdd,uint64 dateUpd)
    {
        return(allAPIid[myid].type_of,allAPIid[myid].currency,allAPIid[myid].id,allAPIid[myid].dateAdd,allAPIid[myid].dateUpd);
    }

    function getApiIdTypeOf(bytes32 myid)constant returns(bytes16 _typeof)
    {
        _typeof=allAPIid[myid].type_of;
    }

    function getIdOfApiId(bytes32 myid)constant returns(uint id1)
    {
        id1 = allAPIid[myid].id;
    }

    function delegateCallBack(bytes32 myid, string res) public
    {
        if(getApiIdTypeOf(myid) =="PRO")
        {
            GD=GovernanceData(GDAddress);
            uint proposalId = getIdOfApiId(myid);
            address votingTypeAddress;
            (,,,,,votingTypeAddress) = GD.getProposalDetailsById2(proposalId);
            SV=SimpleVoting(votingTypeAddress);
            SV.closeProposalVote(proposalId,msg.sender); 
        }  
    }

    function __callback(bytes32 myid, string res) 
    {
        M1=Master(masterAddress);
        if(msg.sender != oraclize_cbAddress() && M1.isOwner(msg.sender)!=1) throw;
        delegateCallBack(myid,res);
    }

}