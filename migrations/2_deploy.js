const MemberRoles = artifacts.require('MemberRoles');
const GovBlocksMaster = artifacts.require('GovBlocksMaster');
const Master = artifacts.require('Master');
const GBTStandardToken = artifacts.require('GBTStandardToken');
const Governance = artifacts.require('Governance');
const ProposalCategory = artifacts.require('ProposalCategory');
const EventCaller = artifacts.require('EventCaller');
const GovernCheckerContract = artifacts.require('GovernCheckerContract');

module.exports = function(deployer) {
  deployer.deploy(EventCaller);
  deployer.deploy(GBTStandardToken);
  deployer.deploy(EventCaller);
  deployer.deploy(GovBlocksMaster);
  deployer.deploy(Governance);
  deployer.deploy(ProposalCategory);
  deployer.deploy(MemberRoles);
  deployer.deploy(Master);
  deployer.deploy(GovernCheckerContract);
};