const GovBlocksMaster = artifacts.require('GovBlocksMaster');
const MemberRoles = artifacts.require('MemberRoles');
const Master = artifacts.require('Master');
const ProposalCategoryAdder = artifacts.require('ProposalCategoryAdder');
const dAppName = '0x41';

async function getAddress(name) {
  const gbm = await GovBlocksMaster.deployed();
  if (name == 'GBM') return gbm.address;
  if (name == 'GBT') return await gbm.gbtAddress();
  if (name == 'EC') return await gbm.eventCaller();
  const ms = await gbm.getDappMasterAddress(dAppName);
  if (name == 'MS') return ms;
  const master = await Master.at(ms);
  return await master.getLatestAddress(name);
}

async function initializeContracts() {
  const gbm = await GovBlocksMaster.deployed();
  const ms = await gbm.getDappMasterAddress(dAppName);
  const master = await Master.at(ms);
  const pc = await master.getLatestAddress('PC');
  const pca = await ProposalCategoryAdder.deployed();
  const mr = await master.getLatestAddress('MR');
  const mri = await MemberRoles.at(mr);
  try {
    await pca.addCat(pc);
    await pca.addSubCat(pc);
    await mri.addInitialMemberRoles();
  } catch (exception) {
    console.log(exception);
  }
}

module.exports = { getAddress, initializeContracts };
