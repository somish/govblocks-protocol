const Pool = artifacts.require('Pool');
const GBTStandardToken = artifacts.require('GBTStandardToken');
const Master = artifacts.require('Master');
let pl;
let gbts;
let ms;

// getPendingReward and claim reward tested already
contract('Pool', function([owner, taker]) {

  before(function() {
    Pool.deployed().then(function(instance) {
      pl = instance;
      return Master.deployed();
    }).then(function(instance) {
      ms = instance;
    });
  });

  it('Should buy gbt from ether', async function() {
    this.timeout(100000);
    await pl.transferAssets();
    await pl.send(10000000000000);
    let b1 = await web3.eth.getBalance(pl.address);
    // will throw once owner's permission are taken away
    await pl.buyPoolGBT(1000000000000);
    let b2 = await web3.eth.getBalance(pl.address);
    assert.isBelow(b2.toNumber(), b1.toNumber(), 'Balance not reduced');
  });

  it('Should transfer ether', async function() {
    this.timeout(100000);
    let b1 = await web3.eth.getBalance(pl.address);
    // will throw once owner's permission are taken away
    await pl.transferEther(owner, 10);
    let b2 = await web3.eth.getBalance(pl.address);
    assert.isBelow(b2.toNumber(), b1.toNumber(), 'Balance not reduced');
  });

  it('Should transfer token', async function() {
    this.timeout(100000);
    let tokenAddress = await ms.getLatestAddress('GS');
    gbts = await GBTStandardToken.at(tokenAddress);
    await pl.updateDependencyAddresses();
    let b1 = await gbts.balanceOf(pl.address);
    await pl.transferToken(tokenAddress, owner, 1000);
    let b2 = await gbts.balanceOf(pl.address);
    assert.isBelow(b2.toNumber(), b1.toNumber(), 'Balance not reduced');
  });
});