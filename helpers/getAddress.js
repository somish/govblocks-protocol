const GovBlocksMaster = artifacts.require('GovBlocksMaster');
const GBTStandardToken = artifacts.require('GBTStandardToken');
const MemberRoles = artifacts.require('MemberRoles');
const Master = artifacts.require('Master');
const getMasterAddress = require('./masterAddress.js').getMasterAddress;
const dAppName = '0x41';

async function getAddress(name, punishVoters) {
  const gbm = await GovBlocksMaster.deployed();
  const gbt = await GBTStandardToken.deployed();
  if (name == 'GBM') return gbm.address;
  if (name == 'GBT') return gbt.address;
  if (name == 'EC') return await gbm.eventCaller();
  const ms = getMasterAddress(punishVoters);
  if (name == 'MS') return ms;
  const master = await Master.at(ms);
  return await master.getLatestAddress(name);
}

async function initializeContracts(punishVoters) {
  const gbm = await GovBlocksMaster.deployed();
  const ms = getMasterAddress(punishVoters);
  const master = await Master.at(ms);
  const pc = await master.getLatestAddress('PC');
  const mr = await master.getLatestAddress('MR');
  const mri = await MemberRoles.at(mr);
}

module.exports = { getAddress, initializeContracts };
