const ProposalCategory = artifacts.require('ProposalCategory');
const catchRevert = require('../helpers/exceptions.js').catchRevert;
let pc;
const getAddress = require('../helpers/getAddress.js').getAddress;
const initializeContracts = require('../helpers/getAddress.js')
  .initializeContracts;
const sampleAddress = '0x0000000000000000000000000000000000000001';
const nullAddress = '0x0000000000000000000000000000000000000000';

contract('Proposal Category', function() {
  it('Should fetch addresses from master', async function() {
    await initializeContracts();
    address = await getAddress('PC');
    pc = await ProposalCategory.at(address);
    await catchRevert( pc.proposalCategoryInitiate(0x4d52));
  });

  it('Should be initialized', async function() {
    this.timeout(100000);
    const g1 = await pc.totalCategories();
    const g2 = await pc.category(1);
    assert.equal(g2[1].toNumber(), 1);
    const g3 = await pc.updateDependencyAddresses(); // Just for the interface, shouldn't throw.
    const g4 = await pc.changeMasterAddress(pc.address); // Just for the interface, shouldn't throw.
    const g5 = await pc.categoryAction(1);
    assert.equal(g5[2].toString(), '0x4d52');
    const g6 = await pc.totalCategories();
    assert.equal(g6.toNumber(), 17);
  });

  it('Should add a proposal category', async function() {
    this.timeout(100000);
    let c1 = await pc.totalCategories();
    // will throw once owner's permissions are revoked
    await pc.addCategory(
      'Yo',
      1,
      1,
      0,
      [1],
      1,
      '',
      nullAddress,
      'EX',
      [0, 0]
    );
    const c2 = await pc.totalCategories();
    assert.isAbove(c2.toNumber(), c1.toNumber(), 'category not added');
  });

  it('Should update a proposal category', async function() {
    this.timeout(100000);
    let c1 = await pc.totalCategories();
    c1 = c1.toNumber() - 1;
    const cat1 = await pc.category(c1);
    // will throw once owner's permissions are revoked
    await pc.updateCategory(
      c1,
      'YoYo',
      3,
      1,
      20,
      [1],
      1,
      '',
      nullAddress,
      'EX',
      [0, 0]
    );
    let cat2 = await pc.category(c1);
    assert.notEqual(cat1[1], cat2[1], 'category not updated');
  });
});