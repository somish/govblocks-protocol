const Governance = artifacts.require('Governance');
const GovernanceData = artifacts.require('GovernanceData');
const catchRevert = require('../helpers/exceptions.js').catchRevert;
const increaseTime = require('../helpers/increaseTime.js').increaseTime;
const encode = require('../helpers/encoder.js').encode;
const Pool = artifacts.require('Pool');
const SimpleVoting = artifacts.require('SimpleVoting');
const Master = artifacts.require('Master');
const GBTStandardToken = artifacts.require('GBTStandardToken');
const ProposalCategory = artifacts.require('ProposalCategory');
const MemberRoles = artifacts.require('MemberRoles');
const TokenProxy = artifacts.require('TokenProxy');
const amount = 500000000000000;
const sampleAddress = 0x0000000000000000000000000000000000000001;

let gbt;
let sv;
let pl;
let gd;
let gv;
let ms;
let mr;
let tp;
let pc;
let propId;
let pid;

const BigNumber = web3.BigNumber;
require('chai')
  .use(require('chai-bignumber')(BigNumber))
  .should();

contract('Governance', ([owner, notOwner, noStake]) => {
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
        return TokenProxy.new(gbt.address);
      })
      .then(instance => {
        tp = instance;
        return ProposalCategory.deployed();
      })
      .then(instance => {
        pc = instance;
      });
  });

  it('Should create an uncategorized proposal', async function() {
    this.timeout(100000);
    p1 = await gd.getProposalLength();
    await gbt.lock('GOV', amount, 54685456133563456);
    await gv.createProposal(
      'Add new member',
      'Add new member',
      'Addnewmember',
      0,
      0
    );
    await gv.createProposal(
      'Add new member',
      'Add new member',
      'Addnewmember',
      0,
      0,
      { from: notOwner }
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
    await catchRevert(
      gv.createProposal(
        'Add new member',
        'Add new member',
        'Addnewmember',
        0,
        10
      )
    );
    p2 = await gd.getProposalLength();
    assert.equal(p1.toNumber() + 2, p2.toNumber(), 'Proposal not created');
  });

  it('Should categorize the proposal', async function() {
    this.timeout(100000);
    p = await gd.getProposalLength();
    p = p.toNumber() - 1;
    await catchRevert(gv.openProposalForVoting(p));
    await catchRevert(gv.categorizeProposal(p, 15, { from: notOwner }));
    await catchRevert(gv.categorizeProposal(p, 1, { from: notOwner }));
    await catchRevert(gv.categorizeProposal(p, 19, { from: notOwner }));
    await catchRevert(gv.categorizeProposal(p, 19));
    await gbt.transfer(pl.address, amount);
    await gv.categorizeProposal(p, 19);
    await mr.updateMemberRole(notOwner, 1, true, 356800000054);
    const category = await gd.getProposalSubCategory(p);
    assert.equal(category.toNumber(), 19, 'Category not set properly');
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
    pid = (await gd.getProposalLength()).toNumber() - 1;
    await catchRevert(
      gv.submitProposalWithSolution(pid, 'Addnewmember', actionHash)
    );
    await gv.submitProposalWithSolution(pid, 'Addnewmember', actionHash, {
      from: notOwner
    });
    pid;
    await catchRevert(
      gv.submitProposalWithSolution(p1.toNumber(), 'Addnewmember', actionHash)
    );
    const remainingTime = await gv.getRemainingClosingTime(p1.toNumber(), 0);
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

  it('Should check getters', async function() {
    this.timeout(100000);
    const g4 = await gv.master();
    assert.equal(g4, ms.address);
  });

  it('Should create proposals with dApp token', async () => {
    const prop1 = await gd.getAllProposalIdsLengthByAddress(owner);
    await gv.createProposal(
      'Add new member',
      'Add new member',
      'Addnewmember',
      0,
      15
    );
    propId = (await gd.getProposalLength()).toNumber() - 1;
    await gd.setDAppTokenSupportsLocking(true);
    await gv.createProposal(
      'Add new member',
      'Add new member',
      'Addnewmember',
      0,
      20
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
      prop1.toNumber() + 3,
      'Proposals not created'
    );
  });

  it('Should not allow unauthorized people to submit solutions', async () => {
    const initSol = await gd.getTotalSolutions(propId);
    await catchRevert(
      sv.addSolution(propId, noStake, '0x0', '0x0', { from: noStake })
    );
    await catchRevert(
      sv.addSolution(propId, noStake, '0x0', '0x0', { from: notOwner })
    );
    const finalSol = await gd.getTotalSolutions(propId);
    assert.equal(initSol.toNumber(), finalSol.toNumber());
  });

  it('Should allow authorized people to submit solution', async () => {
    const initSol = await gd.getTotalSolutions(propId);
    await sv.addSolution(propId, owner, '0x0', '0x0');
    const finalSol = await gd.getTotalSolutions(propId);
    assert.equal(finalSol.toNumber(), initSol.toNumber() + 1);
  });

  it('Should not allow voting before proposal is open for voting', async () => {
    await catchRevert(sv.proposalVoting(propId, [1]));
  });

  it('Should open proposal for voting', async () => {
    await gv.openProposalForVoting(propId);
    const pStatus = await gd.getProposalStatus(propId);
    assert.equal(pStatus.toNumber(), 2);
  });

  it('Should not allow unauthorized people to vote', async () => {
    await catchRevert(sv.proposalVoting(propId, [1], { from: noStake }));
    await mr.updateMemberRole(noStake, 1, true, 356800000054);
    await catchRevert(sv.proposalVoting(propId, [1], { from: noStake }));
    await mr.updateMemberRole(noStake, 1, false, 356800000054);
  });

  it('Should not allow voting for non existent solution', async () => {
    await catchRevert(sv.proposalVoting(propId, [5]));
  });

  it('Should allow voting', async () => {
    await sv.proposalVoting(propId, [1]);
  });

  it('Should not allow unauthorized people to create proposals', async () => {
    await catchRevert(
      gv.createProposal(
        'Add new member',
        'Add new member',
        'Addnewmember',
        0,
        10,
        { from: noStake }
      )
    );
    await catchRevert(
      gv.createProposal(
        'Add new member',
        'Add new member',
        'Addnewmember',
        0,
        9,
        { from: noStake }
      )
    );
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
    await catchRevert(
      gv.categorizeProposal(p1.toNumber(), 9, { from: noStake })
    );
    await catchRevert(
      gv.categorizeProposal(p1.toNumber(), 10, { from: noStake })
    );
  });

  it('Should allow authorized people to categorize multiple times', async () => {
    await mr.updateMemberRole(notOwner, 1, true, 356800000054);
    await gbt.transfer(notOwner, amount);
    await gbt.lock('GOV', amount, 54685456133563456, { from: notOwner });
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
    await gv.categorizeProposal(p1.toNumber(), 20, { from: notOwner });
    await gv.categorizeProposal(p1.toNumber(), 4);
    const category = await gd.getProposalSubCategory(p1.toNumber());
    assert.equal(category.toNumber(), 4, 'Category not set properly');
  });

  it('Should vote in favour of the proposal', async function() {
    this.timeout(100000);
    const g3 = await gv.getAllVoteIdsLengthByProposal(pid);
    await sv.initialVote(pid, owner);
    const g4 = await gv.getAllVoteIdsLengthByProposal(pid);
    assert.equal(g4.toNumber(), g3.toNumber() + 1);
  });

  it('Should close the proposal', async function() {
    this.timeout(100000);
    await mr.updateMemberRole(notOwner, 1, false, 356800000054);
    await catchRevert(sv.initialVote(pid, notOwner));
    await sv.closeProposalVote(pid);
    await catchRevert(sv.closeProposalVote(pid));
  });

  it('Should claim rewards', async () => {
    const b1 = await gbt.balanceOf(owner);
    const g1 = await gv.getMemberDetails(notOwner);
    let pr = await pl.getPendingReward(owner);
    assert.equal(pr[0].toNumber(), 40000);
    assert.equal(pr[1].toNumber(), 0);
    pr = await pl.getPendingReward(notOwner);
    assert.equal(pr[0].toNumber(), 60000);
    assert.equal(pr[1].toNumber(), 0);
    await pl.claimReward(owner);
    await pl.claimReward(notOwner);
    const b2 = await gbt.balanceOf(owner);
    const g2 = await gv.getMemberDetails(notOwner);
    b2.should.be.bignumber.above(b1);
    g2[0].should.be.bignumber.above(g1[0]);
    const pr2 = await pl.getPendingReward(owner);
    pr2[0].should.be.bignumber.eq(0);
    pr2[1].should.be.bignumber.eq(0);
  });

  it('Should close proposal', async () => {
    await sv.closeProposalVote(propId);
    await catchRevert(sv.closeProposalVote(propId));
  });

  it('Should allow claiming reward for preious proposals', async () => {
    const b1 = await gbt.balanceOf(owner);
    const pr = await pl.getPendingReward(owner);
    assert.equal(pr[0].toNumber(), 0);
    assert.equal(pr[1].toNumber(), 100000);
    await pl.claimReward(owner);
    const b2 = await gbt.balanceOf(owner);
    b2.should.be.bignumber.above(b1);
  });

  it('Should add a new category with token holder as voters', async function() {
    this.timeout(100000);
    let c1 = await pc.getCategoryLength();
    await pc.addNewCategory(
      'New Category',
      [1, 2],
      [50, 50],
      [0],
      [1000, 1000]
    );
    await pc.addNewCategory('New Category', [2], [50], [0], [1000]);
    let c2 = await pc.getCategoryLength();
    assert.equal(c2.toNumber(), c1.toNumber() + 2, 'category not added');
  });

  it('Should add a new proposal sub category', async function() {
    this.timeout(100000);
    let c1 = await pc.getSubCategoryLength();
    let cat = await pc.getCategoryLength();
    await pc.addNewSubCategory(
      'New Sub Category',
      'New Sub Category',
      cat.toNumber() - 2,
      sampleAddress,
      '0x4164',
      [0, 0, 100000],
      [40, 40, 20]
    );
    await pc.addNewSubCategory(
      'New Sub Category',
      'New Sub Category',
      cat.toNumber() - 1,
      sampleAddress,
      '0x4164',
      [0, 0, 100000],
      [40, 40, 20]
    );
    let c2 = await pc.getSubCategoryLength();
    assert.equal(c2.toNumber(), c1.toNumber() + 2, 'Sub category not added');
  });

  it('Should create proposal with solution for token holders', async function() {
    this.timeout(100000);
    propId = (await gd.getProposalLength()).toNumber();
    const c = await pc.getSubCategoryLength();
    await gv.createProposalwithSolution(
      'Add new member',
      'Add new member',
      'Addnewmember',
      0,
      c.toNumber() - 1,
      'Add new member',
      '0x5465'
    );
    pid = (await gd.getProposalLength()).toNumber();
    assert.equal(pid, propId + 1, 'Proposal not created');
    await gv.createProposalwithSolution(
      'Add new member',
      'Add new member',
      'Addnewmember',
      0,
      c.toNumber() - 1,
      'Add new member',
      '0x5465'
    );
    await gv.createProposalwithSolution(
      'Add new member',
      'Add new member',
      'Addnewmember',
      0,
      c.toNumber() - 2,
      'Add new member',
      '0x5465'
    );
  });

  it('Should not allow non token holders to vote', async function() {
    await catchRevert(sv.proposalVoting(propId, [0], { from: noStake }));
  });

  it('Should allow token holders to vote', async function() {
    await gbt.transfer(noStake, 100000);
    await sv.proposalVoting(propId, [0], { from: noStake });
    await sv.proposalVoting(propId + 1, [1], { from: noStake });
    await catchRevert(sv.proposalVoting(propId, [0], { from: noStake }));
  });

  it('Should not close proposal when time is not reached', async function() {
    await catchRevert(sv.closeProposalVote(propId));
  });

  it('Should allow more token holders to vote', async function() {
    await sv.proposalVoting(propId, [1]);
    await catchRevert(sv.proposalVoting(propId, [1]));
  });

  it('Should let first layer vote in Multi-Layer voting', async function() {
    await sv.proposalVoting(propId + 2, [1]);
    await catchRevert(sv.proposalVoting(propId + 2, [1]));
  });

  it('Should close proposal when time is reached', async function() {
    await increaseTime(2000);
    await sv.closeProposalVote(propId);
    await sv.closeProposalVote(propId + 1);
    await sv.closeProposalVote(propId + 2);
    await catchRevert(sv.closeProposalVote(propId));
  });

  it('Should let second layer vote in Multi-Layer voting', async function() {
    await sv.proposalVoting(propId + 2, [0], { from: noStake });
    await catchRevert(sv.proposalVoting(propId + 2, [1], { from: noStake }));
  });

  it('Should close second layer voting when time is reached', async function() {
    await catchRevert(sv.closeProposalVote(propId + 2));
    await increaseTime(2000);
    await sv.closeProposalVote(propId + 2);
  });

  it('Should give reward to all voters if punishVoters is false', async function() {
    await gd.setPunishVoters(true);
    const pr = await pl.getPendingReward(noStake);
    assert.equal(pr[0].toNumber(), 0);
    assert.equal(pr[1].toNumber(), 0);
    // const pro = await pl.getPendingReward(owner);
    await gd.setPunishVoters(false);
    const pr2 = await pl.getPendingReward(noStake);
    assert.isAbove(pr2[0].toNumber(), 0);
    assert.equal(pr2[1].toNumber(), 0);
    // const pro2 = await pl.getPendingReward(owner);
    // assert.isBelow(pro2[0].toNumber(), pro[0].toNumber());
    await pl.claimReward(owner);
    await pl.claimReward(noStake);
    const pr3 = await pl.getPendingReward(noStake);
    assert.equal(pr3[0].toNumber(), 0);
    assert.equal(pr3[1].toNumber(), 0);
  });
});
