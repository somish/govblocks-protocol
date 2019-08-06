const MemberRoles = artifacts.require('MemberRoles');
const GovBlocksMaster = artifacts.require('GovBlocksMaster');
const Master = artifacts.require('Master');
const GBTStandardToken = artifacts.require('GBTStandardToken');
const Governance = artifacts.require('Governance');
const ProposalCategory = artifacts.require('ProposalCategory');

module.exports = function(deployer) {
  deployer.then(async () => {
    gbt = await deployer.deploy(GBTStandardToken);
    await deployer.deploy(GovBlocksMaster);
    gv = await deployer.deploy(Governance);
    mr = await deployer.deploy(MemberRoles);
    pc = await deployer.deploy(ProposalCategory);
    ms = await deployer.deploy(Master);
  });
};
