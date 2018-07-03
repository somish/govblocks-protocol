var GBTStandardToken = artifacts.require("./GBTStandardToken.sol");
module.exports = function(deployer) {
  deployer.deploy(GBTStandardToken);
};
