var GBTStandardToken = artifacts.require("./GBTStandardToken.sol");
var GovBlocksMaster = artifacts.require("./GovBlocksMaster.sol");
var Governance = artifacts.require("./Governance.sol");
var GovernanceData = artifacts.require("./GovernanceData.sol");
var MemberRoles = artifacts.require("./MemberRoles.sol");
var Pool = artifacts.require("./Pool.sol");
var ProposalCategory = artifacts.require("./ProposalCategory.sol");
var SimpleVoting = artifacts.require("./SimpleVoting.sol");

module.exports = function(deployer) {
  deployer.deploy(GBTStandardToken);
  deployer.deploy(GovBlocksMaster);
  deployer.deploy(Governance);
  deployer.deploy(GovernanceData);
  deployer.deploy(MemberRoles);
  deployer.deploy(Pool);
  deployer.deploy(ProposalCategory);
  deployer.deploy(SimpleVoting);
};
