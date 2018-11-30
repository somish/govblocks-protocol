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
  });

  it('Should be initialized', async function() {
    this.timeout(100000);
    console.log(await pc.totalCategories());
    await catchRevert(
      pc.addInitialCategories(
        'YoYo',
        1,
        0,
        [1],
        0,
        '',
        nullAddress,
        'EX',
        0,
        [0, 0],
        25
      )
    );
    // await catchRevert(pc.proposalCategoryInitiate('0x41'));
    const g3 = await pc.updateDependencyAddresses(); // Just for the interface, shouldn't throw.
    const g4 = await pc.changeMasterAddress(pc.address); // Just for the interface, shouldn't throw.
    // const g1 = await pc.allSubCategory(0);
    // assert.equal(g1[6].toNumber(), 0);
    const g2 = await pc.category(1);
    assert.equal(g2[1].toNumber(), 1);
    const g5 = await pc.categoryAction(1);
    assert.equal(g5[2].toString(), '0x4d52');
    const g6 = await pc.categoryQuorum(2);
    assert.equal(g6[1].toNumber(), 25);
    // const g7 = await pc.getSubCategoryIdAtIndex(0, 0);
    // assert.equal(g7.toNumber(), 0);
    // const g8 = await pc.getAllSubIdsByCategory(0);
    // assert.equal(g8[0].toNumber(), 0);
    const g10 = await pc.totalCategories();
    assert.equal(g10.toNumber(), 18);
  });

  it('Should not add initial category after initialization', async function() {
    this.timeout(100000);
    await catchRevert(
      pc.addInitialCategories(
        'Not specified',
        1,
        0,
        [1],
        0,
        '',
        nullAddress,
        'EX',
        0,
        [0, 1],
        25
      )
    );
  });

  it('Should add a proposal category', async function() {
    this.timeout(100000);
    let c1 = await pc.getCategoryLength();
    // will throw once owner's permissions are revoked
    await pc.addNewCategory(
      'Yo',
      1,
      1,
      [1],
      1,
      '',
      nullAddress,
      'EX',
      0,
      [0, 0],
      0
    );
    const c2 = await pc.getCategoryLength();
    assert.isAbove(c2.toNumber(), c1.toNumber(), 'category not added');
  });

  it('Should update a proposal category', async function() {
    this.timeout(100000);
    let c1 = await pc.getCategoryLength();
    c1 = c1.toNumber() - 1;
    const cat1 = await pc.getCategoryQuorumPercent(c1);
    // will throw once owner's permissions are revoked
    await pc.updateCategory(
      c1,
      'YoYo',
      1,
      1,
      [1],
      0,
      1,
      '',
      nullAddress,
      'EX',
      [0, 0],
      20
    );
    let cat2 = await pc.getCategoryQuorumPercent(c1);
    assert.notEqual(cat1, cat2[1], 'category not updated');
  });
});
