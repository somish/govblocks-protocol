const catchRevert = require('../helpers/exceptions.js').catchRevert;
const getAddress = require('../helpers/getAddress.js').getAddress;
const initializeContracts = require('../helpers/getAddress.js')
  .initializeContracts;
const encode = require('../helpers/encoder.js').encode;
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
let gv;

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
    address = await getAddress('GV', false);
    gv = await Governance.at(address);
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
    let temp = await GBTStandardToken.new();
    //proposal
      let actionHash = encode(
        'setDAppLocker(address)',
        temp.address
      );
      let p1 = await gv.getProposalLength();
      await gv.createProposalwithSolution(
        'setDAppLocker',
        'Change dApp token proxy',
        'setDAppLocker',
        5,
        'setDAppLocker',
        actionHash
      );
      await gv.closeProposal(p1.toNumber());
    //proposal closed 
    const tp = await ms.dAppLocker();
    assert.equal(tp, temp.address, 'Token Proxy not set');
  });

  it('Should add new version', async function() {
    temp = await MemberRoles.new();
    add.push(temp.address);
    temp = await ProposalCategory.new();
    add.push(temp.address);
    temp = await Governance.new();
    add.push(temp.address);
    temp = await Governance.new();
    add.push(temp.address);
    this.timeout(100000);
    //proposal
      let actionHash = encode(
        'addNewVersion(address[])',
        add
      );
      let p1 = await gv.getProposalLength();
      await gv.createProposalwithSolution(
        'addNewVersion',
        'addNewVersion',
        'addNewVersion',
        8,
        'addNewVersion',
        actionHash
      );
      await gv.closeProposal(p1.toNumber());
    //proposal closed 
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
    //proposal 
      let actionHash = encode(
        'addNewContract(bytes2,address)',
        'QP',
        newContract.address
      );
      let p1 = await gv.getProposalLength();
      await gv.createProposalwithSolution(
        'addNewContract',
        'Add new contractAddress',
        'addNewContract',
        9,
        'addNewContract',
        actionHash
      );
      await gv.closeProposal(p1.toNumber());
    //proposal closed 
    const QPproxy = await ms.getLatestAddress('QP');
    await catchRevert(ms.addNewContract('yo', owner, { from: notOwner }));
  });

  it('Should update implementation', async function() {
    const poolProxyAddress = await ms.contractAddress('QP');
    const poolProxy = await OwnedUpgradeabilityProxy.at(poolProxyAddress);
    const newPool = await Governance.new();
    //proposal 
      let actionHash = encode(
        'upgradeContractImplementation(bytes2,address)',
        'QP',
        newPool.address
      );
      let p1 = await gv.getProposalLength();
      await gv.createProposalwithSolution(
        'upgradeContractImplementation',
        'upgradeContractImplementation',
        'upgradeContractImplementation',
        10,
        'upgradeContractImplementation',
        actionHash
      );
      await gv.closeProposal(p1.toNumber());
    //proposal closed 
    const newPoolAddress = await poolProxy.implementation();
    assert.equal(newPoolAddress, newPool.address);
  });

  it('Should update proxy', async function() {
    const poolProxyAddress = await ms.contractAddress('QP');
    const poolProxy = await OwnedUpgradeabilityProxy.at(poolProxyAddress);
    const poolAddress = await poolProxy.implementation();
    //proposal
      let actionHash = encode(
        'upgradeContractProxy(bytes2,address)',
        'QP',
        poolAddress
      );
      let p1 = await gv.getProposalLength();
      await gv.createProposalwithSolution(
        'upgradeContractProxy',
        'upgradeContractProxy',
        'upgradeContractProxy',
        11,
        'upgradeContractProxy',
        actionHash
      );
      await gv.closeProposal(p1.toNumber());
    //proposal closed 
    const pool = await Governance.at(poolProxyAddress);
    await pool.transferAssets();
    await pool.transferAssets();
    await gbt.transfer(poolProxyAddress, 10000);
    await pool.sendTransaction({ value: 1000000000 });
    await pool.transferAssets();
    const newPoolProxyAddress = await ms.contractAddress('QP');
    const newPoolProxy = await OwnedUpgradeabilityProxy.at(newPoolProxyAddress);
    const newPoolAddress = await newPoolProxy.implementation();
    assert.equal(newPoolAddress, poolAddress);
    assert.notEqual(poolProxyAddress, newPoolProxyAddress);
  });

  it('Should change master address', async function() {
    const newMaster = await Master.new();
    //proposal
      let actionHash = encode(
        'upgradeContractImplementation(bytes2,address)',
        'MS',
        newMaster.address
      );
      let p1 = await gv.getProposalLength();
      await gv.createProposalwithSolution(
        'upgradeContractImplementation',
        'upgradeContractImplementation',
        'upgradeContractImplementation',
        10,
        'upgradeContractImplementation',
        actionHash
      );
      await gv.closeProposal(p1.toNumber());
    //proposal closed 
    assert.equal(await gv.master(), newMaster.address);
    await catchRevert(gv.changeMasterAddress(newMaster.address));
  });

  it('Should not get initiazlized with incorrect params', async function() {
    const m = await Master.new();
    await catchRevert(m.initMaster(owner, false, sampleAddress, sampleAddress, sampleAddress, [owner]));
  });
});