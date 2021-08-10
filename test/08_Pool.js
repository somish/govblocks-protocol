const GBTStandardToken = artifacts.require('GBTStandardToken');
const Governance = artifacts.require('Governance');
const Master = artifacts.require('Master');
const catchRevert = require('../helpers/exceptions.js').catchRevert;
const encode = require('../helpers/encoder.js').encode;
const getAddress = require('../helpers/getAddress.js').getAddress;
let pl;
let gbts;
let dAppToken;
let ms;

// getPendingReward and claim reward tested already
contract('Pool', function([owner, taker]) {
  it('Should fetch addresses from master', async function() {
    address = await getAddress('GV', false);
    pl = await Governance.at(address);
    address = await getAddress('MS', false);
    ms = await Master.at(address);
    address = await ms.dAppLocker();
    dAppToken = await GBTStandardToken.at(address);
  });

  it('Should transfer ether', async function() {
    this.timeout(100000);
    await pl.send(10000000000000);
    let b1 = await web3.eth.getBalance(pl.address);
    //proposal to add member to AB
    let actionHash = encode('transferEther(address,uint256)', owner, 1000);
    let p1 = await pl.getProposalLength();
    await pl.createProposalwithSolution(
      'transfer',
      'transfer',
      'transfer',
      6,
      'transfer',
      actionHash
    );
    await pl.closeProposal(p1.toNumber());
    //proposal closed
    // await pl.transferEther(owner, 10);
    let b2 = await web3.eth.getBalance(pl.address);
    assert.isBelow(b2.toNumber(), b1.toNumber(), 'Balance not reduced');
  });

  it('Should transfer token', async function() {
    this.timeout(100000);
    let tokenAddress = await ms.dAppToken();
    gbts = await GBTStandardToken.at(tokenAddress);
    await gbts.transfer(pl.address, 100000);
    await pl.updateDependencyAddresses();
    let b1 = await gbts.balanceOf(pl.address);
    //proposal to add member to AB
    let actionHash = encode(
      'transferToken(address,address,uint256)',
      tokenAddress,
      owner,
      1000
    );
    let p1 = await pl.getProposalLength();
    await pl.createProposalwithSolution(
      'transfer',
      'transfer',
      'transfer',
      7,
      'transfer',
      actionHash
    );
    await pl.closeProposal(p1.toNumber());
    //proposal closed
    // await pl.transferToken(tokenAddress, owner, 1000);
    let b2 = await gbts.balanceOf(pl.address);
    assert.isBelow(b2.toNumber(), b1.toNumber(), 'Balance not reduced');
  });
});
