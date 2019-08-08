const MemberRoles = artifacts.require('MemberRoles');
const MemberRolesMock = artifacts.require('MemberRolesMock');
const GovBlocksMaster = artifacts.require('GovBlocksMaster');
const Master = artifacts.require('Master');
const GBTStandardToken = artifacts.require('GBTStandardToken');
const Governance = artifacts.require('DelegatedGovernance');
const ProposalCategory = artifacts.require('ProposalCategory');

module.exports = function(deployer) {
  deployer.then(async () => {
    gbt = await deployer.deploy(GBTStandardToken);
    await deployer.deploy(GovBlocksMaster);
    gv = await deployer.deploy(Governance);
    mr = await deployer.deploy(MemberRoles);
    mrMock = await deployer.deploy(MemberRolesMock);
    pc = await deployer.deploy(ProposalCategory);
    ms = await deployer.deploy(Master);
  });
};
