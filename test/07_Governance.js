const Governance = artifacts.require('Governance');
const GovernanceData = artifacts.require('GovernanceData');
const catchRevert = require('../helpers/exceptions.js').catchRevert;
const encode = require('../helpers/encoder.js').encode;
const Pool = artifacts.require('Pool');
const SimpleVoting = artifacts.require('SimpleVoting');
const Master = artifacts.require('Master');
const GBTStandardToken = artifacts.require('GBTStandardToken');
let gbt;
let sv;
let pl;
let gd;
let gv;
let ms;

contract('Governance', ([owner, notOwner]) => {
  before(() => {
    Governance.deployed().then((instance) => {
      gv = instance;
      return GovernanceData.deployed();
    }).then((instance) => {
      gd = instance;
      return Pool.deployed();
    }).then((instance) => {
      pl = instance;
      return SimpleVoting.deployed();
    }).then((instance) => {
      sv = instance;
      return GBTStandardToken.deployed();
    }).then((instance) => {
      gbt = instance;
      return Master.deployed();
    }).then((instance) => {
      ms = instance;
    });
  });

  it('Should create an uncategorized proposal', async function() {
    this.timeout(100000);
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
    const amount = 50000000000000;
    await gbt.lock('GOV', amount, 5468545613353456);
    await gbt.transfer(pl.address, amount);
    await gv.createProposal('Add new member', 'Add new member', 'Addnewmember', 0, 0);
    p2 = await gd.getAllProposalIdsLengthByAddress(owner);
    assert.equal(p1.toNumber() + 1, p2.toNumber(), 'Proposal not created');
  });

  it('Should categorize the proposal', async function() {
    this.timeout(100000);
    p = await gd.getAllProposalIdsLengthByAddress(owner);
    p = p.toNumber() - 1;
    await catchRevert(gv.openProposalForVoting(p));
    await gv.categorizeProposal(p, 9);
    const category = await gd.getProposalCategory(p);
    assert.equal(category.toNumber(), 9, 'Category not set properly');
  });

  it('Should submit proposal with solution', async function() {
    this.timeout(100000);
    const actionHash = encode('addNewMemberRole(bytes32,string,address,bool)', '0x41647669736f727920426f617265000000000000000000000000000000000000', 'New member role', owner, false);
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
    await catchRevert(gv.submitProposalWithSolution(p1.toNumber() - 1, 'Addnewmember', actionHash, {from: notOwner}));
    await gv.submitProposalWithSolution(p1.toNumber() - 1, 'Addnewmember', actionHash);
    await catchRevert(gv.submitProposalWithSolution(p1.toNumber() - 1, 'Addnewmember', actionHash));
    let remainingTime = await gv.getMaxCategoryTokenHoldTime(1);
    await assert.isAtLeast(remainingTime.toNumber(), 1, 'Remaining time not set');
    remainingTime = await gv.getRemainingClosingTime(p1.toNumber() - 1, 0);
    await assert.isAtLeast(remainingTime.toNumber(), 1, 'Remaining time not set');
    const g2 = await gv.getSolutionIdAgainstAddressProposal(owner, 0);
    assert.equal(g2[0].toNumber(), 0);
    const pr = await pl.getPendingReward(owner);
    await pl.claimReward(owner);
  });

  it('Should vote in favour of the proposal', async function() {
    this.timeout(100000);
    p = await gd.getAllProposalIdsLengthByAddress(owner);
    p = p.toNumber() - 1;
    const g3 = await gv.getAllVoteIdsLengthByProposal(p);
    await sv.proposalVoting(p, [1]);
    const g4 = await gv.getAllVoteIdsLengthByProposal(p);
    assert.equal(g4.toNumber(), g3.toNumber() + 1);
  });

  it('Should close the proposal', async function() {
    this.timeout(100000);
    p = await gd.getAllProposalIdsLengthByAddress(owner);
    p = p.toNumber() - 1;
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
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
    await gv.createProposal('Add new member', 'Add new member', 'Addnewmember', 0, 9);
    await gv.createProposal('Add new member', 'Add new member', 'Addnewmember', 0, 0);
    await gv.categorizeProposal(p1.toNumber(), 9);
    p2 = await gd.getAllProposalIdsLengthByAddress(owner);
    assert.equal(p1.toNumber() + 2, p2.toNumber(), 'Proposal not created');
    const pr = await pl.getPendingReward(owner);
    await pl.claimReward(owner);
    const g1 = await gv.getMemberDetails(owner);
    assert.isAbove(g1[0].toNumber(), 1);
  });

  it('Should not allow unauthorized people to create proposals', async () => {
    await catchRevert(gv.createProposal('Add new member', 'Add new member', 'Addnewmember', 0, 10, {from: notOwner}));
    await catchRevert(gv.createProposal('Add new member', 'Add new member', 'Addnewmember', 0, 8, {from: notOwner}));
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
    await catchRevert(gv.categorizeProposal(p1.toNumber() - 1, 4, {from: notOwner}));
    await gv.categorizeProposal(p1.toNumber() - 1, 4);
  });
});
