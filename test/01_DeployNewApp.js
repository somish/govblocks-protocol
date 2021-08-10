const GovBlocksMaster = artifacts.require('GovBlocksMaster');
const setMasterAddress = require('../helpers/masterAddress.js')
  .setMasterAddress;
const SampleAddress = 0x0000000000000000000000000000000000000001;

let gbm;

contract('new dApp', function() {
  it('should deploy new dApp', async () => {
    gbm = await GovBlocksMaster.deployed();
    const rc = await gbm.addGovBlocksDapp(
      '0x42',
      SampleAddress,
      SampleAddress,
      true
    );
    console.log('Gas used in deploying dApp: ', rc.receipt.gasUsed);
  });
});
