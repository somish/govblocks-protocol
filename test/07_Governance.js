const Governance = artifacts.require('Governance');
const GovernanceData = artifacts.require('GovernanceData');
const catchRevert = require('../helpers/exceptions.js').catchRevert;
const encode = require('../helpers/encoder.js').encode;
const Pool = artifacts.require('Pool');
const SimpleVoting = artifacts.require('SimpleVoting');
const GBTStandardToken = artifacts.require('GBTStandardToken');
let gbt;
let sv;
let pl;
let gd;
let gv;

contract('Governance', function([owner, notOwner]) {

  before(function() {
    Governance.deployed().then(function(instance) {
      gv = instance;
      return GovernanceData.deployed();
    }).then(function(instance) {
      gd = instance;
      return Pool.deployed();
    }).then(function(instance) {
      pl = instance;
      return SimpleVoting.deployed();
    }).then(function(instance) {
      sv = instance;
      return GBTStandardToken.deployed();
    }).then(function(instance) {
      gbt = instance;
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
    await gv.categorizeProposal(p, 8);
    let category = await gd.getProposalCategory(p);
    assert.equal(category.toNumber(), 8, 'Category not set properly');
  });

  it('Should submit proposal with solution', async function() {
    this.timeout(100000);
    let actionHash = encode('addNewMemberRole(bytes32,string,address,bool)', '0x41647669736f727920426f617265000000000000000000000000000000000000', 'New member role', owner, false);
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
    await catchRevert(gv.submitProposalWithSolution(p1.toNumber() - 1, 'Addnewmember', actionHash, {from: notOwner}));
    await gv.submitProposalWithSolution(p1.toNumber() - 1, 'Addnewmember', actionHash);
    await catchRevert(gv.submitProposalWithSolution(p1.toNumber() - 1, 'Addnewmember', actionHash));
    let remainingTime = await gv.getMaxCategoryTokenHoldTime(1);
    await assert.isAtLeast(remainingTime.toNumber(), 1, 'Remaining time not set');
    remainingTime = await gv.getRemainingClosingTime(p1.toNumber() - 1, 0);
    await assert.isAtLeast(remainingTime.toNumber(), 1, 'Remaining time not set');
    await pl.claimReward(owner);
  });

  it('Should vote in favour of the proposal', async function() {
    this.timeout(100000);
    p = await gd.getAllProposalIdsLengthByAddress(owner);
    p = p.toNumber() - 1;
    await sv.proposalVoting(p, [1]);
    await catchRevert(sv.proposalVoting(p, [1]));
  });

  it('Should close the proposal', async function() {
    this.timeout(100000);
    p = await gd.getAllProposalIdsLengthByAddress(owner);
    p = p.toNumber() - 1;
    await sv.closeProposalVote(p);
    await catchRevert(sv.closeProposalVote(p));
    await pl.claimReward(owner);
  });
  
  it('Should check getters', async function() {
    this.timeout(100000);
    let g1 = await gv.getMemberDetails(owner);
    let g2 = await gv.getSolutionIdAgainstAddressProposal(owner, 0);
    let g3 = await gv.getAllVoteIdsLengthByProposal(0);
    let g4 = await gv.master();
    // TODO verify the data returned
  });

  it('Should create proposals with dApp token', async function() {
    await gd.setDAppTokenSupportsLocking(true);
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
    await gv.createProposal('Add new member', 'Add new member', 'Addnewmember', 0, 0);
    p2 = await gd.getAllProposalIdsLengthByAddress(owner);
    assert.equal(p1.toNumber() + 1, p2.toNumber(), 'Proposal not created');
  });

  it('Should not allow unauthorized people to create proposals', async function() {
    await catchRevert(gv.createProposal('Add new member', 'Add new member', 'Addnewmember', 0, 10, {from: notOwner}));
    await catchRevert(gv.createProposal('Add new member', 'Add new member', 'Addnewmember', 0, 8, {from: notOwner}));
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
    await catchRevert(gv.categorizeProposal(p1.toNumber() - 1, 4, {from: notOwner}));
    await gv.categorizeProposal(p1.toNumber() - 1, 4);
  });
});