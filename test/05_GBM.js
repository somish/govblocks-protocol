const GovBlocksMaster = artifacts.require('GovBlocksMaster');
const EventCaller = artifacts.require('EventCaller');
const catchRevert = require('../helpers/exceptions.js').catchRevert;
const getAddress = require('../helpers/getAddress.js').getAddress;
let ec;
let address;
let gbm;
const sampleBytes32 =
  '0x41647669736f727920426f617264000000000000000000000000000000000000';
const sampleAddress = '0x0000000000000000000000000000000000000002';

// addGovBlocksUser, setMasterByteCode already tested earlier
contract('GovBlocksMaster', function([owner, notOwner]) {
  it('Should fetch addresses for testing', async function() {
    address = await getAddress('GBM',false);
    gbm = await GovBlocksMaster.at(address);
    address = await getAddress('EC',false);
    ec = await EventCaller.at(address);
  });

  it('should be initialized', async function() {
    this.timeout(100000);
    assert.equal(await gbm.owner(), owner, 'owner was not set properly');
  });

  it('should set eventCaller address', async function() {
    await catchRevert( gbm.setEventCallerAddress(sampleAddress, {from: notOwner}));
    await catchRevert( gbm.setImplementations([], {from: notOwner}));
    await gbm.setEventCallerAddress(sampleAddress);
    assert.equal(
      await gbm.eventCaller(),
      sampleAddress,
      'eventCaller was not set properly'
    );
  });

});
