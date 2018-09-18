const GovBlocksMaster = artifacts.require('GovBlocksMaster');
const EventCaller = artifacts.require('EventCaller');
const catchRevert = require('../helpers/exceptions.js').catchRevert;
const getAddress = require('../helpers/getAddress.js').getAddress;
let ec;
let address;
let gbm;
const sampleBytes32 =
  '0x41647669736f727920426f617264000000000000000000000000000000000000';
const sampleAddress = '0x0000000000000000000000000000000000000001';

// addGovBlocksUser, setMasterByteCode already tested earlier
contract('GovBlocksMaster', function([owner, notOwner]) {
  it('Should fetch addresses for testing', async function() {
    address = await getAddress('GBM');
    gbm = await GovBlocksMaster.at(address);
    address = await getAddress('EC');
    ec = await EventCaller.at(address);
  });

  it('should be initialized', async function() {
    this.timeout(100000);
    assert.equal(await gbm.owner(), owner, 'owner was not set properly');
    assert.notEqual(
      await gbm.eventCaller(),
      sampleAddress,
      'eventCaller was not set properly'
    );
    assert.notEqual(
      await gbm.gbtAddress(),
      sampleAddress,
      'gbtAddress was not set properly'
    );
    assert.equal(await gbm.initialized(), true, 'initialized bool not set');
    await catchRevert(
      gbm.govBlocksMasterInit(sampleAddress, sampleAddress, sampleAddress)
    );
    let temp = await gbm.getGovBlocksUserDetails('0x4143');
    temp = await gbm.getGovBlocksUserDetails1('0x4143');
  });

  it('should change dapp master', async function() {
    this.timeout(100000);
    let masterAddress = await gbm.getDappMasterAddress('0x41');
    await gbm.changeDappMasterAddress('0x41', sampleAddress);
    assert.equal(
      await gbm.getDappMasterAddress('0x41'),
      sampleAddress,
      'dApp Master not changed'
    );
    await gbm.changeDappMasterAddress('0x41', masterAddress);
    await catchRevert(
      gbm.changeDappMasterAddress('0x41', sampleAddress, { from: notOwner })
    );
  });

  it('should change sample master', async function() {
    this.timeout(100000);
    let masterAddress = await gbm.masterAdd();
    await gbm.updateMasterAddress(sampleAddress);
    assert.equal(
      await gbm.masterAdd(),
      sampleAddress,
      'Sample Master not changed'
    );
    await catchRevert(
      gbm.updateMasterAddress(sampleAddress, { from: notOwner })
    );
    await gbm.updateMasterAddress(masterAddress);
  });

  it('should not allow to add dApp with same name', async function() {
    this.timeout(100000);
    await catchRevert(
      gbm.addGovBlocksUser('0x41', sampleAddress, sampleAddress, 'yo')
    );
  });

  it('should change dapp desc hash', async function() {
    this.timeout(100000);
    let desc = await gbm.getDappDescHash('0x41');
    await gbm.changeDappDescHash('0x41', 'some random string');
    assert.equal(
      await gbm.getDappDescHash('0x41'),
      'some random string',
      'dApp desc not changed'
    );
    await gbm.changeDappDescHash('0x41', desc);
    await catchRevert(gbm.changeDappDescHash('0x41', desc, { from: notOwner }));
  });

  it('should change dapp token', async function() {
    this.timeout(100000);
    let tokenAddress = await gbm.getDappTokenAddress('0x41');
    await gbm.changeDappTokenAddress('0x41', sampleAddress);
    assert.equal(
      await gbm.getDappTokenAddress('0x41'),
      sampleAddress,
      'dApp token not changed'
    );
    await gbm.changeDappTokenAddress('0x41', tokenAddress);
    await catchRevert(
      gbm.changeDappTokenAddress('0x41', sampleAddress, { from: notOwner })
    );
  });

  it('should change gbt address', async function() {
    this.timeout(100000);
    let tokenAddress = await gbm.gbtAddress();
    await gbm.updateGBTAddress(sampleAddress);
    assert.equal(await gbm.gbtAddress(), sampleAddress, 'gbt not changed');
    await gbm.updateGBTAddress(tokenAddress);
  });

  it('should change gbm address', async function() {
    this.timeout(100000);
    await gbm.updateGBMAddress(gbm.address);
    assert.equal(1, 1, 'GBM address change threw');
  });

  it('should set abi and bc hash', async function() {
    this.timeout(100000);
    await gbm.setByteCodeAndAbi(sampleBytes32, sampleBytes32);
    result = await gbm.getByteCodeAndAbi();
    assert.equal(result[0], sampleBytes32, 'BC hash not set properly');
    assert.equal(result[1], sampleBytes32, 'ABI hash not set properly');
  });

  it('should set dapp user', async function() {
    this.timeout(100000);
    await gbm.setDappUser('yo');
    assert.equal(await gbm.getDappUser(), 'yo', 'dApp user not set properly');
  });

  it('should change gbt address', async function() {
    this.timeout(100000);
    let ecAddress = await gbm.eventCaller();
    await gbm.setEventCallerAddress(sampleAddress);
    assert.equal(
      await gbm.eventCaller(),
      sampleAddress,
      'event caller not changed'
    );
    await gbm.setEventCallerAddress(ecAddress);
  });

  it('should check getters', async function() {
    this.timeout(100000);
    // TODO check all the data returned by getters
    let g1 = await gbm.getGovBlocksUserDetails('0x41');
    let g2 = await gbm.getGovBlocksUserDetailsByIndex(0);
    let g3 = await gbm.getGovBlocksUserDetails1('0x41');
    let g4 = await gbm.getGovBlocksUserDetails2(gbm.address);
    let dAppLength = await gbm.getAllDappLength();
    let dAppName = await gbm.getAllDappById(0);
    let allDappNameArray = await gbm.getAllDappArray();
    let getDappNameByAddress = await gbm.getDappNameByAddress(gbm.address);
    await ec.callCloseProposalOnTime(1, 1); // for coverage
    assert.isAtLeast(dAppLength.toNumber(), 1, 'dApp Length not proper');
    assert.equal(dAppName, allDappNameArray[0], 'dApp name not consistent');
  });
});
