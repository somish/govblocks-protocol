const MemberRoles = artifacts.require('MemberRoles');
const GovBlocksMaster = artifacts.require('GovBlocksMaster');
const Master = artifacts.require('Master');
const GBTStandardToken = artifacts.require('GBTStandardToken');
const Governance = artifacts.require('Governance');
const GovernanceData = artifacts.require('GovernanceData');
const Pool = artifacts.require('Pool');
const ProposalCategory = artifacts.require('ProposalCategory');
const SimpleVoting = artifacts.require('SimpleVoting');
const EventCaller = artifacts.require('EventCaller');
const GovernCheckerContract = artifacts.require('GovernCheckerContract');
const ProposalCategoryAdder = artifacts.require('ProposalCategoryAdder');

module.exports = function(deployer) {
  deployer.deploy(EventCaller);
  deployer.deploy(GBTStandardToken);
  deployer.deploy(EventCaller);
  deployer.deploy(GovBlocksMaster);
  deployer.deploy(GovernanceData, false);
  deployer.deploy(Governance);
  deployer.deploy(Pool);
  deployer.deploy(ProposalCategory);
  deployer.deploy(SimpleVoting);
  deployer.deploy(MemberRoles);
  deployer.deploy(Master);
  deployer.deploy(GovernCheckerContract);
  deployer.deploy(ProposalCategoryAdder);
};
