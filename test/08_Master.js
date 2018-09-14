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
const GovernanceData = artifacts.require('GovernanceData');
const Pool = artifacts.require('Pool');
const ProposalCategory = artifacts.require('ProposalCategory');
const SimpleVoting = artifacts.require('SimpleVoting');
const EventCaller = artifacts.require('EventCaller');
const GBTStandardToken = artifacts.require('GBTStandardToken');
let gbm;
let temp;
let sv;
let add = [];
let ms;

contract('Master', function([owner, notOwner]) {
  it('Should fetch addresses from master', async function() {
    await initializeContracts();
    address = await getAddress('SV');
    sv = await SimpleVoting.at(address);
    address = await getAddress('GBT');
    gbt = await GBTStandardToken.at(address);
    address = await getAddress('MS');
    ms = await Master.at(address);
    address = await getAddress('EC');
    ec = await EventCaller.at(address);
    address = await getAddress('GBM');
    gbm = await GovBlocksMaster.at(address);
  });

  it('Should check getters', async function() {
    this.timeout(100000);
    const g1 = await ms.versionDates(0);
    const g2 = await ms.dAppName();
    const g3 = await ms.gbm();
    const g4 = await ms.getCurrentVersion();
    const g5 = await ms.getVersionData();
    const g8 = await ms.getGovernCheckerAddress(); // Varies based on the network
    assert.isAbove(g1.toNumber(), 1, 'Master version date not set');
    assert.equal(
      g2,
      '0x4100000000000000000000000000000000000000000000000000000000000000',
      'Master name not set'
    );
    assert.equal(g3, gbm.address, 'gbm address incorrect');
    assert.equal(g4.toNumber(), 0, 'Incorrect Master Version');
    assert.equal(g5[0].toNumber(), 0, 'Incorrect Master Version');
    assert.equal(
      await ms.isInternal(notOwner),
      false,
      'Internal check failing'
    );
    await catchRevert(ms.initMaster(owner, '0x41', [owner]));
  });

  it('Should set dAppTokenProxy', async function() {
    this.timeout(100000);
    await ms.setDAppLocker(sampleAddress);
    const tp = await ms.dAppLocker();
    assert.equal(tp, sampleAddress, 'Token Proxy not set');
  });

  it('Should add new version', async function() {
    this.timeout(100000);
    temp = await GovernanceData.new();
    add.push(temp.address);
    temp = await MemberRoles.new();
    add.push(temp.address);
    temp = await ProposalCategory.new();
    add.push(temp.address);
    const svad = await SimpleVoting.new();
    add.push(svad.address);
    temp = await Governance.new();
    add.push(temp.address);
    temp = await Pool.new();
    add.push(temp.address);

    await ms.addNewVersion(add);
    await catchRevert(ms.addNewVersion(add, { from: notOwner }));
    const g6 = await ms.getLatestAddress('SV');
    assert.equal(g6, sv.address, 'SV proxy address incorrect');
    g7 = await OwnedUpgradeabilityProxy.at(g6);
    assert.equal(
      await g7.implementation(),
      svad.address,
      'SV implementation address incorrect'
    );
  });

  it('Should not allow non-gbm address to change gbt address', async function() {
    this.timeout(100000);
    await catchRevert(ms.changeGBTSAddress({ from: notOwner }));
    await catchRevert(ms.changeGBMAddress(ms.address, { from: notOwner }));
  });

  it('Should add new contract', async function() {
    this.timeout(100000);
    // Will throw once owner's permissions are removed. will need to create proposal then.
    const newContract = await Pool.new();
    await ms.addNewContract('QP', newContract.address);
    const QPproxy = await ms.getLatestAddress('QP');
    await catchRevert(ms.addNewContract('yo', owner, { from: notOwner }));
  });

  it('Should update implementation', async function() {
    const poolProxyAddress = await ms.contractsAddress('PL');
    const poolProxy = await OwnedUpgradeabilityProxy.at(poolProxyAddress);
    const newPool = await Pool.new();
    await ms.upgradeContractImplementation('PL', newPool.address);
    const newPoolAddress = await poolProxy.implementation();
    assert.equal(newPoolAddress, newPool.address);
  });

  it('Should update proxy', async function() {
    const poolProxyAddress = await ms.contractsAddress('PL');
    const poolProxy = await OwnedUpgradeabilityProxy.at(poolProxyAddress);
    const poolAddress = await poolProxy.implementation();
    await ms.upgradeContractProxy('PL', poolAddress);
    const pool = await Pool.at(poolProxyAddress);
    await pool.transferAssets();
    await pool.transferAssets();
    await gbt.transfer(poolProxyAddress, 10000);
    await pool.sendTransaction({ value: 1000000000 });
    await pool.transferAssets();
    const newPoolProxyAddress = await ms.contractsAddress('PL');
    const newPoolProxy = await OwnedUpgradeabilityProxy.at(newPoolProxyAddress);
    const newPoolAddress = await newPoolProxy.implementation();
    assert.equal(newPoolAddress, poolAddress);
    assert.notEqual(poolProxyAddress, newPoolProxyAddress);
  });

  it('Should check authorization correctly', async function() {
    assert.equal(await ms.isAuth(), true);
    assert.equal(await ms.isAuth({ from: notOwner }), false);
  });

  it('Should change master address', async function() {
    const poolProxyAddress = await ms.contractsAddress('PL');
    const pool = await Pool.at(poolProxyAddress);
    const newMaster = await Master.new();
    await ms.changeMasterAddress(newMaster.address);
    assert.equal(await pool.master(), newMaster.address);
    await catchRevert(pool.changeMasterAddress(newMaster.address));
  });
});
