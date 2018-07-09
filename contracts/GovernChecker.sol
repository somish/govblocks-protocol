pragma solidity ^0.4.24;

contract GBM {
	function getDappMasterAddress(bytes32 _gbUserName) public constant returns(address masterAddress);
}

contract GovernChecker {

	mapping (bytes32 => address) public authorized;

	GBM internal govBlockMaster;

	/// @dev Updates GBM address, can only be called by current GBM
	function updateGBMAdress(address _govBlockMaster) public {
		require(address(_govBlockMaster) == msg.sender || address(_govBlockMaster) == address(0));
		govBlockMaster = GBM(_govBlockMaster);
	}

	/// @dev Allows dApp's master to add authorized address for initalization
	function initializeAuthorized(bytes32 _dAppName, address authorizedAddress) public {
		require(authorized[_dAppName] == address(0));
		require(govBlockMaster.getDappMasterAddress(_dAppName) == msg.sender);
		authorized[_dAppName] = authorizedAddress;
	}

	/// @dev Allows the authorized address to pass on the authorized to someone else
	function updateAuthorized(bytes32 _dAppName, address authorizedAddress) public {
		require(authorized[_dAppName] == msg.sender);
		authorized[_dAppName] = authorizedAddress;
	}
}