const GovBlocksMaster = artifacts.require('GovBlocksMaster');
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
    address = await getAddress('GBM', false);
    gbm = await GovBlocksMaster.at(address);
  });
});
