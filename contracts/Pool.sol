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

import "./Master.sol";
import "./SafeMath.sol";
import "./GBTStandardToken.sol";
import "./Upgradeable.sol";
import "./usingOraclize.sol";
// import "./oraclizeAPI_0.4.sol";


contract Pool is usingOraclize, Upgradeable {
    event CloseProposal(uint256 indexed proposalId, uint256 closingTime, string url);
    event ApiResult(address indexed sender, string msg, bytes32 myid);
    using SafeMath for uint;

    struct ApiId {
        bytes8 typeOf;
        uint proposalId;
        uint64 dateAdd;
        uint64 dateUpd;
    }

    mapping(bytes32 => ApiId) public allAPIid;
    bytes32[] public allAPIcall;
    address public masterAddress;
    Master private master;
    GBTStandardToken private gbt;

    function () public payable {}

    /// @dev Changes master address
    /// @param _add New master address
    function changeMasterAddress(address _add) public {
        if (masterAddress == 0x000)
            masterAddress = _add;
        else {
            master = Master(masterAddress);
            require(master.isInternal(msg.sender));
            masterAddress = _add;
        }

    }

    modifier onlyInternal {
        master = Master(masterAddress);
        require(master.isInternal(msg.sender) == true);
        _;
    }

    modifier onlyOwner {
        master = Master(masterAddress);
        require(master.isOwner(msg.sender) == true);
        _;
    }

    modifier onlyMaster {
        require(msg.sender == masterAddress);
        _;
    }

    /// @dev Changes GBT standard token address
    /// @param _gbtAddress New GBT standard token address
    function changeGBTSAddress(address _gbtAddress) public onlyMaster {
        gbt = GBTStandardToken(_gbtAddress);
    }

    /// @dev just to adhere to the interface
    function updateDependencyAddresses() public {
        master = Master(masterAddress);
        gbt = GBTStandardToken(master.getLatestAddress("GS"));
    }

    /// @dev converts pool ETH to GBT
    /// @param _gbt number of GBT to buy
    function buyPoolGBT(uint _gbt) {
        uint _wei = SafeMath.mul(_gbt, gbt.tokenPrice());
        gbt.buyToken.value(_wei)();
    }

    /// @dev Closes Proposal voting using oraclize once the time is over.
    /// @param _proposalId Proposal id
    /// @param _closingTime Remaining Closing time of proposal
    function closeProposalOraclise(uint _proposalId, uint _closingTime) public {
        uint index = getApiCallLength();
        bytes32 myid2;
        master = Master(masterAddress);

        if (_closingTime == 0)
            myid2 = 
                oraclize_query(
                    "URL", 
                    strConcat(
                        "http://a1.govblocks.io/closeProposalVoting.js/42/", 
                        bytes32ToString(master.dAppName()), 
                        "/", 
                        uint2str(index)
                    )
                );
        else
            myid2 = 
                oraclize_query(
                    _closingTime, 
                    "URL", 
                    strConcat(
                        "http://a1.govblocks.io/closeProposalVoting.js/42/", 
                        bytes32ToString(master.dAppName()), 
                        "/", 
                        uint2str(index)
                    )
                );

        uint closeTime = now + _closingTime;
        CloseProposal(
            _proposalId, 
            closeTime, 
            strConcat(
                "http://a1.govblocks.io/closeProposalVoting.js/42/", 
                bytes32ToString(master.dAppName()), 
                "/", 
                uint2str(index)
            )
        );
        saveApiDetails(myid2, "PRO", _proposalId);
        addInAllApiCall(myid2);
    }

    /// @dev Get total length of oraclize call being triggered using this function  "closeProposalOraclise"
    function getApiCallLength() public constant returns(uint len) {
        return allAPIcall.length;
    }

    /// @dev Gets api call of index
    /// @param index Index to call
    /// @return myid Id with respect to index
    function getApiCallIndex(uint index) public constant returns(bytes32 myid) {
        myid = allAPIcall[index];
    }

    /// @dev Gets api call details of given id
    /// @param myid Id of api response
    /// @return _typeof Type of proposal
    /// @return id Id of api
    /// @return dateAdd Date proposal was added 
    /// @return dateUpd Date proposal was updated
    function getApiCallDetails(bytes32 myid) 
        public 
        constant 
        returns(bytes8 _typeof, uint id, uint64 dateAdd, uint64 dateUpd) 
    {
        return (allAPIid[myid].typeOf, allAPIid[myid].proposalId, allAPIid[myid].dateAdd, allAPIid[myid].dateUpd);
    }

    /// @dev Gets type of proposal wrt api id
    /// @param myid Id of api
    /// @return _typeof Type of proposal
    function getApiIdTypeOf(bytes32 myid) public constant returns(bytes16 _typeof) {
        _typeof = allAPIid[myid].typeOf;
    }

    /// @dev Gets proposal id of api id
    /// @param myid Api id
    /// @return id1 Proposal id
    function getProposalIdOfApiId(bytes32 myid) public constant returns(uint id1) {
        id1 = allAPIid[myid].proposalId;
    }

    /// @dev Callback function of Oraclize
    /// @param myid Api id
    /// @param res Result string
    function __callback(bytes32 myid, string res) public {
        master = Master(masterAddress);
        require(msg.sender != oraclize_cbAddress() && master.isOwner(msg.sender));
        allAPIid[myid].dateUpd = uint64(now);
    }

    /// @dev Transfer Ether back to Pool    
    /// @param amount Amount to be transferred back
    function transferBackEther(uint256 amount) public onlyOwner {
        msg.sender.transfer(amount);
    }

    /// @dev Byte32 to string
    /// @param x Byte32 to be converted to string
    /// @return bytesStringTrimmed Resultant string 
    function bytes32ToString(bytes32 x) public constant returns(string) {
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

    /// @dev Gets proposal index by proposal id
    /// @return myIndexId Api index of corresponding proposal id
    function getMyIndexByProposalId(uint _proposalId) public constant returns(uint myIndexId) {
        uint length = getApiCallLength();
        for (uint i = 0; i < length; i++) {
            bytes32 myid = getApiCallIndex(i);
            uint propId = getProposalIdOfApiId(myid);
            if (_proposalId == propId)
                myIndexId = i;
        }
    }

    /// @dev Saves api details
    /// @param myid Proposal id
    /// @param _typeof typeOf differ in case we have different stages of process. i.e. here default typeOf is "PRO"
    /// @param id This is index of the oraclize call.
    function saveApiDetails(bytes32 myid, bytes8 _typeof, uint id) internal {
        allAPIid[myid] = ApiId(_typeof, id, uint64(now), uint64(now));
    }

    /// @dev Adds api response hash returned in all api call
    function addInAllApiCall(bytes32 myid) internal {
        allAPIcall.push(myid);
    }

}