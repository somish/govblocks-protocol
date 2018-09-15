pragma solidity 0.4.24;

import './UpgradeabilityProxy.sol';
import '../govern/GovernCheckerContract.sol';

/**
 * @title GovernedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with authorization control functionalities
 *      of a network wide govern checker
 */
contract GovernedUpgradeabilityProxy is UpgradeabilityProxy {

    // Storage position of the governChecker Address and dAppName
    bytes32 private constant governCheckerPosition = keccak256("org.govblocks.govern.checker");
    bytes32 private constant dAppNamePosition = keccak256("org.govblocks.dApp.name");

    /**
    * @dev the constructor sets the governChecker, dAppName and implementation
    */
    constructor(bytes32 _dAppName, address _implementation) public {
        /* solhint-disable */
        if (_getCodeSize(0xF0AF942909632711694B02357B03fe967e18e32c) > 0)          //kovan testnet
            _setGovernCheckerUnique(0xF0AF942909632711694B02357B03fe967e18e32c);
        else if (_getCodeSize(0xdF6c6a73BCf71E8CAa6A2c131bCf98f10eBb5162) > 0)     //RSK testnet
            _setGovernCheckerUnique(0xdF6c6a73BCf71E8CAa6A2c131bCf98f10eBb5162);
        else if (_getCodeSize(0x67995F25f04d61614d05607044c276727DEA9Cf0) > 0)     //Rinkeyby testnet
            _setGovernCheckerUnique(0x67995F25f04d61614d05607044c276727DEA9Cf0);
        else if (_getCodeSize(0xb5fE0857770D85302585564b04C81a5Be96022C8) > 0)     //Ropsten testnet
            _setGovernCheckerUnique(0xb5fE0857770D85302585564b04C81a5Be96022C8);
        else if (_getCodeSize(0x962d110554E0b20E18E5c3680018b49A58EF0bBB) > 0)     //Private testnet
            _setGovernCheckerUnique(0x962d110554E0b20E18E5c3680018b49A58EF0bBB);
        else
            _setGovernCheckerUnique(address(0));
        /* solhint-enable */
        _setDAppNameUnique(_dAppName);
        _upgradeTo(_implementation);
    }

    /**
    * @dev Throws if called by any account other than the authorized.
    */
    modifier onlyAuthorizedToGovern() {
        GovernCheckerContract gc = GovernCheckerContract(governChecker());
        if (address(gc) != address(0))
            require(gc.authorizedAddressNumber(dAppName(), msg.sender) > 0);
        _;
    }
    
    /**
    * @dev checks if an address is authorized to govern
    */
    function isAuthorizedToGovern(address _toCheck) public view returns(bool) {
        GovernCheckerContract gc = GovernCheckerContract(governChecker());
        if (address(gc) == address(0) || gc.authorizedAddressNumber(dAppName(), _toCheck) > 0)
            return true;
    }

    /**
     * @dev Tells the address of the governChecker
     * @return the address of the governChecker
     */
    function governChecker() public view returns (address governCheckerAddress) {
        bytes32 position = governCheckerPosition;
        //solhint-disable-next-line
        assembly {
            governCheckerAddress := sload(position)
        }
    }

    /**
     * @dev Tells the dAppName
     * @return the dAppName
     */
    function dAppName() public view returns (bytes32 dappName) {
        bytes32 position = dAppNamePosition;
        //solhint-disable-next-line
        assembly {
            dappName := sload(position)
        }
    }

    /**
     * @dev Allows to upgrade the current version of the proxy.
     * @param _implementation representing the address of the new implementation to be set.
     */
    function upgradeTo(address _implementation) public onlyAuthorizedToGovern {
        _upgradeTo(_implementation);
    }

    /**
     * @dev Allows the authorized address to upgrade the current version of the proxy and call the
     * new implementation to initialize whatever is needed through a low level call.
     * @param _implementation representing the address of the new implementation to be set.
     * @param _data represents the msg.data to bet sent in the low level call. This parameter may include the function
     * signature of the implementation to be called with the needed payload
     */
    function upgradeToAndCall(address _implementation, bytes _data) payable public onlyAuthorizedToGovern {
        _upgradeTo(_implementation);
        require(address(this).call.value(msg.value)(_data));
    }

    /**
     * @dev Sets the address of the governChecker
     */
    function _setGovernCheckerUnique(address _governChecker) internal {
        //solhint-disable-next-line
        bytes32 position = governCheckerPosition;
        assembly {
            sstore(position, _governChecker)
        }
    }

    /**
     * @dev Sets the dAppName
     */
    function _setDAppNameUnique(bytes32 _dAppName) internal {
        //solhint-disable-next-line
        bytes32 position = dAppNamePosition;
        assembly {
            sstore(position, _dAppName)
        }
    }

    /// @dev returns the code size at an address, used to confirm that a contract exisits at an address.
    function _getCodeSize(address _addr) internal view returns(uint _size) {
        //solhint-disable-next-line
        assembly {
            _size := extcodesize(_addr)
        }
    }
}
