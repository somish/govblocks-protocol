const ProposalCategory = artifacts.require('ProposalCategory');
const GovernanceData = artifacts.require('GovernanceData');
const catchRevert = require('../helpers/exceptions.js').catchRevert;
let pc;
let gd;
const sampleAddress = '0x0000000000000000000000000000000000000001';
const nullAddress = '0x0000000000000000000000000000000000000000';

contract('Proposal Category', function([owner, taker]) {
  before(function() {
    ProposalCategory.deployed().then(function(instance) {
      pc = instance;
      return GovernanceData.deployed();
    }).then(function(instance) {
      gd = instance;
    });
  });

  it('Should be initialized', async function() {
    this.timeout(100000);
    await catchRevert(pc.proposalCategoryInitiate('0x41'));
    const g1 = await pc.allSubCategory(0);
    assert.equal(g1[6].toNumber(), 604800);
    const g2 = await pc.getCategoryDetails(0);
    assert.equal(g2[1][0].toNumber(), 1);
    const g3 = await pc.updateDependencyAddresses(); // Just for the interface, shouldn't throw.
    const g4 = await pc.changeMasterAddress(); // Just for the interface, shouldn't throw.
    const g5 = await pc.getContractName(0);
    assert.equal(g5.toString(), '0x4558');
    const g6 = await pc.getContractAddress(0);
    assert.equal(g6, nullAddress);
    const g7 = await pc.getSubCategoryIdAtIndex(0, 0);
    assert.equal(g7.toNumber(), 0);
    const g8 = await pc.getAllSubIdsByCategory(0);
    assert.equal(g8[0].toNumber(), 0);
    const g9 = await pc.getMRAllowed(0);
    assert.equal(g9[0].toNumber(), 0);
    const g10 = await pc.getAllSubIdsLengthByCategory(0);
    assert.equal(g10.toNumber(), 1);
    const g11 = await pc.getRoleMajorityVotelength(0);
    assert.equal(g11[1].toNumber(), 1);
    const g12 = await pc.getCategoryIncentive(0);
    assert.equal(g12[1].toNumber(), 0);
    await pc.addInitialSubC('Yo', 'yo', 1, sampleAddress, '0x4164', [1, 1, 1], [1, 1, 1]);
    const g14 = await pc.getMinStake(9);
    assert.isAbove(g14.toNumber(), 1);
    const g15 = await pc.getRoleMajorityVoteAtIndex(4, 0);
    assert.equal(g15.toNumber(), 50);
  });

  it('Should add a proposal category', async function() {
    this.timeout(100000);
    let c1 = await pc.getCategoryLength();
    // will throw once owner's permissions are revoked
    await pc.addNewCategory('Yo', [1], [1], [1], [1]);
    await catchRevert(pc.addNewCategory('Yo', [1, 2], [1], [1], [1]));
    let c2 = await pc.getCategoryLength();
    assert.isAbove(c2.toNumber(), c1.toNumber(), 'category not added');
  });

  it('Should update a proposal category', async function() {
    this.timeout(100000);
    let c1 = await pc.getCategoryLength();
    c1 = c1.toNumber() - 1;
    let cat1 = await pc.getCategoryName(c1);
    // will throw once owner's permissions are revoked
    await pc.updateCategory(c1, 'YoYo', [1], [1], [1], [1]);
    await catchRevert(pc.updateCategory(c1, 'YoYo', [1, 1], [1], [1], [1]));
    let cat2 = await pc.getCategoryName(c1);
    assert.notEqual(cat1[1], cat2[2], 'category not updated');
  });

  it('Should add a proposal sub category', async function() {
    this.timeout(100000);
    let c1 = await pc.getSubCategoryLength();
    // will throw once owner's permissions are revoked
    await pc.addNewSubCategory('Yo', 'yo', 1, sampleAddress, '0x4164', [1, 1, 1], [1, 1, 1]);
    let c2 = await pc.getSubCategoryLength();
    assert.isAbove(c2.toNumber(), c1.toNumber(), 'Sub category not added');
  });

  it('Should update a proposal category', async function() {
    this.timeout(100000);
    let c1 = await pc.getCategoryLength();
    c1 = c1.toNumber() - 1;
    let cat1 = await pc.getSubCategoryName(c1);
    // will throw once owner's permissions are revoked
    await pc.updateSubCategory('YoYo', 'yo', 1, sampleAddress, '0x4141', [1, 1, 1], [1, 1, 1]);
    let cat2 = await pc.getSubCategoryName(c1);
    assert.notEqual(cat1, cat2, 'Sub category not updated');
  });
});
