pragma solidity ^0.4.24;

contract GovernChecker {
    function authorized(bytes32 _dAppName) public constant returns(address);
}

contract Governed {

    GovernChecker internal governChecker;

    bytes32 internal dAppName;

    modifier onlyAuthorizedToGovern() {
        require(governChecker.authorized(dAppName) == msg.sender);
        _;
    }

    function Governed (bytes32 _dAppName) {
        setGovernChecker();
        dAppName = _dAppName;
    } 

    function setGovernChecker() public {
        if (getCodeSize(0x2e3413b48992f6fee938a3111a710803073d5d7a) > 0)    //kovan testnet
            governChecker = GovernChecker(0x2e3413b48992f6fee938a3111a710803073d5d7a);
    }

    function getCodeSize(address _addr) constant internal returns(uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }
}