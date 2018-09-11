const GovernCheckerContract = artifacts.require('GovernCheckerContract');
const catchRevert = require('../helpers/exceptions.js').catchRevert;
let gc;

contract('GovernCheckerContract', function([first, second, third, foruth]) {
  before(function() {
    GovernCheckerContract.deployed().then(function(instance) {
      gc = instance;
    });
  });

  it('should initalize authorized', async function() {
    this.timeout(100000);
    await gc.initializeAuthorized('0x41', first);
    await catchRevert(gc.initializeAuthorized('0x41', second));
    let authorizedAddressNumber = await gc.authorizedAddressNumber(
      '0x41',
      first
    );
    assert.equal(
      authorizedAddressNumber.toNumber(),
      1,
      'authorized not initialized properly'
    );
  });

  it('should add authorized', async function() {
    this.timeout(100000);
    await catchRevert(gc.addAuthorized('0x41', second, { from: second }));
    await gc.addAuthorized('0x41', second);
    let authAddress = await gc.authorized('0x41', 1);
    assert.equal(authAddress, second, 'authorized not added properly');
    await gc.addAuthorized('0x41', second);
  });

  it('should update authorized', async function() {
    this.timeout(100000);
    await catchRevert(gc.updateAuthorized('0x41', gc.address, { from: third }));
    await gc.updateAuthorized('0x41', gc.address);
    let authorizedAddressNumber = await gc.authorizedAddressNumber(
      '0x41',
      first
    );
    assert.equal(
      authorizedAddressNumber.toNumber(),
      0,
      'authorized not removed properly'
    );
  });

  it('should add gbm', async function() {
    this.timeout(100000);
    await gc.updateGBMAdress(first);
    await catchRevert(gc.initializeAuthorized('0x42', first));
    assert.equal(await gc.govBlockMaster(), first, 'gbm not added properly');
    await catchRevert(gc.updateGBMAdress(second, { from: second }));
  });
});
