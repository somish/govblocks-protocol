const catchRevert = require('../helpers/exceptions.js').catchRevert;
const getAddress = require('../helpers/getAddress.js').getAddress;
const initializeContracts = require('../helpers/getAddress.js')
  .initializeContracts;
const sampleAddress = '0x0000000000000000000000000000000000000001';
const MemberRoles = artifacts.require('MemberRoles');
const OwnedUpgradeabilityProxy = artifacts.require('OwnedUpgradeabilityProxy');
const GovBlocksMaster = artifacts.require('GovBlocksMaster');
const Master = artifacts.require('Master');
const Governance = artifacts.require('Governance');
const ProposalCategory = artifacts.require('ProposalCategory');
const EventCaller = artifacts.require('EventCaller');
const GBTStandardToken = artifacts.require('GBTStandardToken');
let gbm;
let temp;
let pc;
let add = [];
let ms;

contract('Master', function([owner, notOwner]) {
  it('Should fetch addresses from master', async function() {
    let punishVoters = false
    await initializeContracts(punishVoters);
    address = await getAddress('GBT', false);
    gbt = await GBTStandardToken.at(address);
    address = await getAddress('MS', false);
    ms = await Master.at(address);
    address = await getAddress('EC', false);
    ec = await EventCaller.at(address);
    address = await getAddress('PC', false);
    pc = await Master.at(address);
    address = await getAddress('GBM', false);
    gbm = await GovBlocksMaster.at(address);
  });

  it('Should check getters', async function() {
    this.timeout(100000);
    const g1 = await ms.versionDates(0);
    const g4 = await ms.getCurrentVersion();
    const g5 = await ms.getVersionData();
    assert.isAbove(g1.toNumber(), 1, 'Master version date not set');
    assert.equal(g4.toNumber(), 1, 'Incorrect Master Version');
    assert.equal(g5[0].toNumber(), 1, 'Incorrect Master Version');
    assert.equal(
      await ms.isInternal(notOwner),
      false,
      'Internal check failing'
    );
    await catchRevert(ms.initMaster(owner, false, sampleAddress, sampleAddress, sampleAddress, [owner]));
  });

  it('Should set dAppTokenProxy', async function() {
    this.timeout(100000);
    await ms.setDAppLocker(sampleAddress);
    const tp = await ms.dAppLocker();
    assert.equal(tp, sampleAddress, 'Token Proxy not set');
  });

  it('Should add new version', async function() {
    this.timeout(100000);
    temp = await MemberRoles.new();
    add.push(temp.address);
    temp = await ProposalCategory.new();
    add.push(temp.address);
    temp = await Governance.new();
    add.push(temp.address);
    temp = await Governance.new();
    add.push(temp.address);

    await ms.addNewVersion(add);
    await catchRevert(ms.addNewVersion(add, { from: notOwner }));
    const g6 = await ms.getLatestAddress('PC');
    assert.equal(g6, pc.address, 'PC proxy address incorrect');
    g7 = await OwnedUpgradeabilityProxy.at(g6);
    assert.equal(
      await g7.implementation(),
      add[1],
      'PC implementation address incorrect'
    );
  });

  it('Should not allow non-gbm address to change gbt address', async function() {
    this.timeout(100000);
  });

  it('Should add new contract', async function() {
    this.timeout(100000);
    // Will throw once owner's permissions are removed. will need to create proposal then.
    const newContract = await Governance.new();
    await ms.addNewContract('QP', newContract.address);
    const QPproxy = await ms.getLatestAddress('QP');
    await catchRevert(ms.addNewContract('yo', owner, { from: notOwner }));
  });

  it('Should update implementation', async function() {
    const poolProxyAddress = await ms.contractAddress('GV');
    const poolProxy = await OwnedUpgradeabilityProxy.at(poolProxyAddress);
    const newPool = await Governance.new();
    await ms.upgradeContractImplementation('GV', newPool.address);
    const newPoolAddress = await poolProxy.implementation();
    assert.equal(newPoolAddress, newPool.address);
  });

  it('Should update proxy', async function() {
    const poolProxyAddress = await ms.contractAddress('GV');
    const poolProxy = await OwnedUpgradeabilityProxy.at(poolProxyAddress);
    const poolAddress = await poolProxy.implementation();
    await ms.upgradeContractProxy('GV', poolAddress);
    const pool = await Governance.at(poolProxyAddress);
    await pool.transferAssets();
    await pool.transferAssets();
    await gbt.transfer(poolProxyAddress, 10000);
    await pool.sendTransaction({ value: 1000000000 });
    await pool.transferAssets();
    const newPoolProxyAddress = await ms.contractAddress('GV');
    const newPoolProxy = await OwnedUpgradeabilityProxy.at(newPoolProxyAddress);
    const newPoolAddress = await newPoolProxy.implementation();
    assert.equal(newPoolAddress, poolAddress);
    assert.notEqual(poolProxyAddress, newPoolProxyAddress);
  });

  it('Should change master address', async function() {
    const poolProxyAddress = await ms.contractAddress('GV');
    const pool = await Governance.at(poolProxyAddress);
    const newMaster = await Master.new();
    await ms.upgradeContractImplementation('MS',newMaster.address);
    assert.equal(await pool.master(), newMaster.address);
    await catchRevert(pool.changeMasterAddress(newMaster.address));
  });

  it('Should not get initiazlized with incorrect params', async function() {
    const m = await Master.new();
    await catchRevert(m.initMaster(owner, false, sampleAddress, sampleAddress, sampleAddress, [owner]));
  });
});