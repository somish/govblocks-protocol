const ProposalCategory = artifacts.require('ProposalCategory');
const GBTStandardToken = artifacts.require('GBTStandardToken');
const Governance = artifacts.require('DelegatedGovernance');
const catchRevert = require('../helpers/exceptions.js').catchRevert;
let pc;
let gv;
const encode = require('../helpers/encoder.js').encode;
const getAddress = require('../helpers/getAddress.js').getAddress;
const initializeContracts = require('../helpers/getAddress.js')
  .initializeContracts;
const sampleAddress = '0x0000000000000000000000000000000000000001';
const nullAddress = '0x0000000000000000000000000000000000000000';
let dAppToken;
contract('Proposal Category', function() {

  async function createProposal(actionHash, categoryId) {
    let p1 = await gv.getProposalLength();
    await gv.createProposalwithSolution(
        'Category',
        'Category',
        'Category',
        categoryId,
        'Category',
        actionHash
      );
    await gv.closeProposal(p1.toNumber());
  }

  it('Should fetch addresses from master', async function() {
    let punishVoters = false
    await initializeContracts(punishVoters);
    address = await getAddress('PC', false);
    pc = await ProposalCategory.at(address);
    address = await getAddress('GV', false);
    gv = await Governance.at(address);
    address = await getAddress('GBT', false);
    dAppToken = await GBTStandardToken.at(address);
  });

  it('Should be initialized', async function() {
    this.timeout(100000);
    const g1 = await pc.totalCategories();
    const g2 = await pc.category(1);
    assert.equal(g2[1].toNumber(), 1);
    const g3 = await pc.updateDependencyAddresses();
    address = await getAddress('MS', false);
    const g4 = await catchRevert(pc.changeMasterAddress(address)); 
    const g5 = await pc.categoryAction(1);
    assert.equal(g5[2].toString(), '0x4d52');
    const g6 = await pc.totalCategories();
    assert.equal(g6.toNumber(), 17);
  });

  it('Should add a proposal category', async function() {
    this.timeout(100000);
    let c1 = await pc.totalCategories();
    // will throw once owner's permissions are revoked
    await dAppToken.lock('GOV', Math.pow(10,18), 54685456133563456);
    //proposal to add category
      let actionHash = encode(
        'addCategory(string,uint,uint,uint,uint[],uint,string,address,bytes2,uint[])',
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
      await createProposal(actionHash, 3);
    const c2 = await pc.totalCategories();
    assert.isAbove(c2.toNumber(), c1.toNumber(), 'category not added');
  });

  it('Should update a proposal category', async function() {
    this.timeout(100000);
    let c1 = await pc.totalCategories();
    c1 = c1.toNumber() - 1;
    const cat1 = await pc.category(c1);
    //proposal to update category
    let actionHash = encode(
      'updateCategory(uint,string,uint,uint,uint,uint[],uint,string,address,bytes2,uint[])',
      c1,
      'YoYo',
      2,
      1,
      20,
      [1],
      1,
      '',
      nullAddress,
      'EX',
      [0, 0]
    );
    await createProposal(actionHash, 4);
    let cat2 = await pc.category(c1);
    assert.notEqual(cat1[1].toNumber(), cat2[1].toNumber(), 'category not updated');
  });

  it('Should not add a proposal category if invalid roles are passed', async function() {
    this.timeout(100000);
    let c1 = await pc.totalCategories();
    //proposal to add category
      let actionHash = encode(
        'addCategory(string,uint,uint,uint,uint[],uint,string,address,bytes2,uint[])',
        'Yo',
        1,
        1,
        0,
        [5,6], //Total existing roles 3
        1,
        '',
        nullAddress,
        'EX',
        [0, 0]
      );
      await createProposal(actionHash, 3);
    const c2 = await pc.totalCategories();
    assert.equal(c2.toNumber(), c1.toNumber(), 'category added incorrectly');
  });

  it('Should not update a proposal category if invalid roles are passed', async function() {
    this.timeout(100000);
    let c1 = await pc.totalCategories();
    c1 = c1.toNumber() - 1;
    const cat1 = await pc.category(c1);
    //proposal to update category
    let actionHash = encode(
      'updateCategory(uint,string,uint,uint,uint,uint[],uint,string,address,bytes2,uint[])',
      c1,
      'YoYo',
      7, //Total existing roles 3
      1,
      20,
      [1],
      1,
      '',
      nullAddress,
      'EX',
      [0, 0]
    );
    await createProposal(actionHash, 4);
    let cat2 = await pc.category(c1);
    assert.equal(cat1[1].toNumber(), cat2[1].toNumber(), 'category not updated');
  });
});