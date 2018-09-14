const catchRevert = require('../helpers/exceptions.js').catchRevert;
const getAddress = require('../helpers/getAddress.js').getAddress;
const initializeContracts = require('../helpers/getAddress.js')
  .initializeContracts;
const sampleAddress = '0x0000000000000000000000000000000000000001';
const MemberRoles = artifacts.require('MemberRoles');
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
let ec;
let gd;
let mr;
let pc;
let sv;
let gv;
let pl;
let add = [];
let ms;

contract('Master', function([owner, notOwner]) {
  it('Should fetch addresses from master', async function() {
    await initializeContracts();
    address = await getAddress('GV');
    gv = await Governance.at(address);
    address = await getAddress('GD');
    gd = await GovernanceData.at(address);
    address = await getAddress('SV');
    sv = await SimpleVoting.at(address);
    address = await getAddress('MR');
    mr = await MemberRoles.at(address);
    address = await getAddress('GBT');
    gbt = await GBTStandardToken.at(address);
    address = await getAddress('PC');
    pc = await ProposalCategory.at(address);
    address = await getAddress('PL');
    pl = await Pool.at(address);
    address = await getAddress('MS');
    ms = await Master.at(address);
    address = await getAddress('EC');
    ec = await EventCaller.at(address);
    address = await getAddress('GBM');
    gbm = await GovBlocksMaster.at(address);
    add.push(gd.address);
    add.push(mr.address);
    add.push(pc.address);
    add.push(sv.address);
    add.push(gv.address);
    add.push(pl.address);
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
    await ms.addNewVersion(add);
    await catchRevert(ms.addNewVersion(add, { from: notOwner }));
    const g6 = await ms.getLatestAddress('SV');
    const g7 = await ms.getEventCallerAddress();
    assert.equal(g6, sv.address, 'SV address incorrect');
    assert.equal(g7, ec.address, 'EventCaller address incorrect');
  });

  it('Should not allow non-gbm address to change gbt address', async function() {
    this.timeout(100000);
    await catchRevert(ms.changeGBTSAddress());
  });

  it('Should add new contract', async function() {
    this.timeout(100000);
    // Will throw once owner's permissions are removed. will need to create proposal then.
    await ms.addNewContract('QP', sampleAddress);
    const QPproxy = await ms.getLatestAddress('QP');
    await catchRevert(ms.addNewContract('yo', owner, { from: notOwner }));
  });
});
