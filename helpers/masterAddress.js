var masterAddress;

function setMasterAddress(address) {
  masterAddress = address;
}

function getMasterAddress(address) {
	return masterAddress;
}

module.exports = { getMasterAddress, setMasterAddress };