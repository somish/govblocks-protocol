const Governance = artifacts.require('Governance');
const GovernanceData = artifacts.require('GovernanceData');
const catchRevert = require('../helpers/exceptions.js').catchRevert;
const encode = require('../helpers/encoder.js').encode;
const Pool = artifacts.require('Pool');
const SimpleVoting = artifacts.require('SimpleVoting');
const Master = artifacts.require('Master');
const GBTStandardToken = artifacts.require('GBTStandardToken');
const MemberRoles = artifacts.require('MemberRoles');
const amount = 500000000000000;

let gbt;
let sv;
let pl;
let gd;
let gv;
let ms;
let mr;

const BigNumber = web3.BigNumber;
require('chai')
  .use(require('chai-bignumber')(BigNumber))
  .should();

contract('Governance', ([owner, notOwner]) => {
  before(() => {
    Governance.deployed()
      .then(instance => {
        gv = instance;
        return GovernanceData.deployed();
      })
      .then(instance => {
        gd = instance;
        return Pool.deployed();
      })
      .then(instance => {
        pl = instance;
        return SimpleVoting.deployed();
      })
      .then(instance => {
        sv = instance;
        return GBTStandardToken.deployed();
      })
      .then(instance => {
        gbt = instance;
        return Master.deployed();
      })
      .then(instance => {
        ms = instance;
        return MemberRoles.deployed();
      })
      .then(instance => {
        mr = instance;
      });
  });

  it('Should create an uncategorized proposal', async function() {
    this.timeout(100000);
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
    await gbt.lock('GOV', amount, 54685456133563456);
    await gv.createProposal(
      'Add new member',
      'Add new member',
      'Addnewmember',
      0,
      0
    );
    p2 = await gd.getAllProposalIdsLengthByAddress(owner);
    assert.equal(p1.toNumber() + 1, p2.toNumber(), 'Proposal not created');
  });

  it('Should categorize the proposal', async function() {
    this.timeout(100000);
    p = await gd.getAllProposalIdsLengthByAddress(owner);
    p = p.toNumber();
    await catchRevert(gv.openProposalForVoting(p));
    await catchRevert(gv.categorizeProposal(p, 9));
    await gbt.transfer(pl.address, amount);
    await catchRevert(gv.categorizeProposal(p, 9, { from: notOwner }));
    await mr.updateMemberRole(notOwner, 1, true, 356800000054);
    await catchRevert(gv.categorizeProposal(p, 9, { from: notOwner }));
    await mr.updateMemberRole(notOwner, 1, false, 356800000054);
    await gv.categorizeProposal(p, 9);
    const category = await gd.getProposalCategory(p);
    assert.equal(category.toNumber(), 9, 'Category not set properly');
  });

  it('Should submit proposal with solution', async function() {
    this.timeout(100000);
    const actionHash = encode(
      'addNewMemberRole(bytes32,string,address,bool)',
      '0x41647669736f727920426f617265000000000000000000000000000000000000',
      'New member role',
      owner,
      false
    );
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
    await catchRevert(
      gv.submitProposalWithSolution(p1.toNumber(), 'Addnewmember', actionHash, {
        from: notOwner
      })
    );
    await gv.submitProposalWithSolution(
      p1.toNumber(),
      'Addnewmember',
      actionHash
    );
    await catchRevert(
      gv.submitProposalWithSolution(p1.toNumber(), 'Addnewmember', actionHash)
    );
    let remainingTime = await gv.getMaxCategoryTokenHoldTime(1);
    await assert.isAtLeast(
      remainingTime.toNumber(),
      1,
      'Remaining time not set'
    );
    remainingTime = await gv.getRemainingClosingTime(p1.toNumber(), 0);
    await assert.isAtLeast(
      remainingTime.toNumber(),
      1,
      'Remaining time not set'
    );
    const g2 = await gv.getSolutionIdAgainstAddressProposal(owner, 0);
    assert.equal(g2[0].toNumber(), 0);
    const pr = await pl.getPendingReward(owner);
    await pl.claimReward(owner);
  });

  it('Should vote in favour of the proposal', async function() {
    this.timeout(100000);
    p = await gd.getAllProposalIdsLengthByAddress(owner);
    p = p.toNumber();
    const g3 = await gv.getAllVoteIdsLengthByProposal(p);
    await sv.proposalVoting(p, [1]);
    const g4 = await gv.getAllVoteIdsLengthByProposal(p);
    assert.equal(g4.toNumber(), g3.toNumber() + 1);
  });

  it('Should close the proposal', async function() {
    this.timeout(100000);
    p = await gd.getAllProposalIdsLengthByAddress(owner);
    p = p.toNumber();
    await sv.closeProposalVote(p);
    await catchRevert(sv.closeProposalVote(p));
  });

  it('Should check getters', async function() {
    this.timeout(100000);
    const g4 = await gv.master();
    assert.equal(g4, ms.address);
  });

  it('Should create proposals with dApp token', async () => {
    await gd.setDAppTokenSupportsLocking(true);
    const prop1 = await gd.getAllProposalIdsLengthByAddress(owner);
    await gv.createProposal(
      'Add new member',
      'Add new member',
      'Addnewmember',
      0,
      9
    );
    await gv.createProposal(
      'Add new member',
      'Add new member',
      'Addnewmember',
      0,
      0,
      { from: notOwner }
    );
    await gv.createProposal(
      'Add new member',
      'Add new member',
      'Addnewmember',
      0,
      0
    );
    const prop2 = await gd.getAllProposalIdsLengthByAddress(owner);
    assert.equal(
      prop2.toNumber(),
      prop1.toNumber() + 2,
      'Proposals not created'
    );
  });

  it('Should not allow unauthorized people to create proposals', async () => {
    await catchRevert(
      gv.createProposal(
        'Add new member',
        'Add new member',
        'Addnewmember',
        0,
        10,
        { from: notOwner }
      )
    );
    await catchRevert(
      gv.createProposal(
        'Add new member',
        'Add new member',
        'Addnewmember',
        0,
        9,
        { from: notOwner }
      )
    );
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
    await catchRevert(
      gv.categorizeProposal(p1.toNumber(), 9, { from: notOwner })
    );
    await catchRevert(
      gv.categorizeProposal(p1.toNumber(), 10, { from: notOwner })
    );
  });

  it('Should allow authorized people to categorize multiple times', async () => {
    await mr.updateMemberRole(notOwner, 1, true, 356800000054);
    await gbt.transfer(notOwner, amount);
    await gbt.lock('GOV', amount, 54685456133563456, { from: notOwner });
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
    await gv.categorizeProposal(p1.toNumber(), 9, { from: notOwner });
    await gv.categorizeProposal(p1.toNumber(), 4);
    const category = await gd.getProposalCategory(p1.toNumber());
    assert.equal(category.toNumber(), 4, 'Category not set properly');
  });

  it('Should claim rewards', async () => {
    const b1 = await gbt.balanceOf(owner);
    const g1 = await gv.getMemberDetails(owner);
    let pr = await pl.getPendingReward(owner);
    assert.equal(pr[0].toNumber(), 0);
    assert.isAtLeast(pr[1].toNumber(), 100000);
    pr = await pl.getPendingReward(notOwner);
    assert.equal(pr[0].toNumber(), 0);
    assert.isAtLeast(pr[1].toNumber(), 0);
    await pl.claimReward(owner);
    await pl.claimReward(notOwner);
    const b2 = await gbt.balanceOf(owner);
    const g2 = await gv.getMemberDetails(owner);
    b2.should.be.bignumber.above(b1);
    g2[0].should.be.bignumber.above(g1[0]);
    const pr2 = await pl.getPendingReward(owner);
    pr2[0].should.be.bignumber.eq(0);
    pr2[1].should.be.bignumber.eq(0);
  });
});
