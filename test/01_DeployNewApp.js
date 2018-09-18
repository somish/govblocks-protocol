const GovBlocksMaster = artifacts.require('GovBlocksMaster');
const SampleAddress = 0x0000000000000000000000000000000000000001;
let gbm;

contract('new dApp', function() {
  it('should deploy new dApp', async () => {
    gbm = await GovBlocksMaster.deployed();
    const rc = await gbm.addGovBlocksUser(
      '0x42',
      SampleAddress,
      SampleAddress,
      'yo'
    );
    console.log('Gas used in deploying dApp: ', rc.receipt.gasUsed);
  });
});
