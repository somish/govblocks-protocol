var masterAddress;
var masterAddress1;

function setMasterAddress(address,punishVoters) {
	if(punishVoters)
  		masterAddress1 = address;
  	else
  		masterAddress = address
}

function getMasterAddress(punishVoters) {
	if(punishVoters)
		return masterAddress1;
	else
		return masterAddress;
}

module.exports = { getMasterAddress, setMasterAddress };