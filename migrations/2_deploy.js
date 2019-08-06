const MemberRoles = artifacts.require('MemberRoles');
const GovBlocksMaster = artifacts.require('GovBlocksMaster');
const Master = artifacts.require('Master');
const GBTStandardToken = artifacts.require('GBTStandardToken');
const Governance = artifacts.require('Governance');
const ProposalCategory = artifacts.require('ProposalCategory');
const EventCaller = artifacts.require('EventCaller');

module.exports = function(deployer) {
  deployer.then(async () => {
    ec = await deployer.deploy(EventCaller);
    gbt = await deployer.deploy(GBTStandardToken);
    await deployer.deploy(GovBlocksMaster, ec.address);
    gv = await deployer.deploy(Governance);
    mr = await deployer.deploy(MemberRoles);
    pc = await deployer.deploy(ProposalCategory);
    let implementations = [mr.address, pc.address, gv.address];
    ms = await deployer.deploy(Master);
    await ms.initMaster(
      mr.address,
      true,
      gbt.address,
      gbt.address,
      implementations
    );
  });
};
