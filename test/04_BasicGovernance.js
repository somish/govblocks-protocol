const Governance = artifacts.require('Governance');
const GovernanceData = artifacts.require('GovernanceData');
const MemberRoles = artifacts.require('MemberRoles');
const SimpleVoting = artifacts.require('SimpleVoting');
const catchRevert = require('../helpers/exceptions.js').catchRevert;
const encode = require('../helpers/encoder.js').encode;
const GBTStandardToken = artifacts.require('GBTStandardToken');
const Pool = artifacts.require('Pool');

let gv;
let gd;
let mr;
let sv;
let pl;
let mrLength;
let gbt;

contract('Proposal, solution and voting', function([owner]) {

  before(function() {
    Governance.deployed().then(function(instance) {
      gv = instance;
      return GovernanceData.deployed();
    }).then(function(instance) {
      gd = instance;
      return SimpleVoting.deployed();
    }).then(function(instance) {
      sv = instance;
      return MemberRoles.deployed();
    }).then(function(instance) {
      mr = instance;
      return GBTStandardToken.deployed();
    }).then(function(instance) {
      gbt = instance;
      return Pool.deployed();
    }).then(function(instance) {
      pl = instance;
    });
  });
  
  it('Should create a proposal with solution to add new member role', async function() {
    this.timeout(100000);
    let actionHash = encode('addNewMemberRole(bytes32,string,address,bool)', '0x41647669736f727920426f617265000000000000000000000000000000000000', 'New member role', owner, false);
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
    mrLength = await mr.getTotalMemberRoles();
    let amount = 50000000000000000000;
    await gbt.lock('GOV', amount, 5468545613353456);
    await gv.createProposalwithSolution('Add new member', 'Add new member', 'Addnewmember', 0, 1, 'Add new member', actionHash);
    p2 = await gd.getAllProposalIdsLengthByAddress(owner);
    assert.equal(p1.toNumber() + 1, p2.toNumber(), 'Proposal not created');
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
  });

  it('Should have added new member role', async function() {
    this.timeout(100000);
    mrLength2 = await mr.getTotalMemberRoles();
    assert.equal(mrLength.toNumber() + 1, mrLength2.toNumber(), 'Member Role Not Added');
  });

  it('Should create an uncategorized proposal', async function() {
    this.timeout(100000);
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
    mrLength = await mr.getTotalMemberRoles();
    await gv.createProposal('Add new member', 'Add new member', 'Addnewmember', 0, 0);
    p2 = await gd.getAllProposalIdsLengthByAddress(owner);
    assert.equal(p1.toNumber() + 1, p2.toNumber(), 'Proposal not created');
  });

  it('Should categorize the proposal and then open it for voting', async function() {
    this.timeout(100000);
    p = await gd.getAllProposalIdsLengthByAddress(owner);
    p = p.toNumber() - 1;
    await gv.categorizeProposal(p, 1, 0);
    await gv.openProposalForVoting(p);
    await catchRevert(gv.openProposalForVoting(p));
  });

  it('Should submit a solution', async function() {
    this.timeout(100000);
    let actionHash = encode('addNewMemberRole(bytes32,string,address,bool)', '0x41647669736f727920426f617265000000000000000000000000000000000000', 'New member role', owner, false);
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
    await sv.addSolution(p1.toNumber() - 1, owner, 'Addnewmember', actionHash);
    await catchRevert(sv.addSolution(p1.toNumber() - 1, owner, 'Addnewmember', actionHash));
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
  });

  it('Should have added new member role', async function() {
    this.timeout(100000);
    mrLength2 = await mr.getTotalMemberRoles();
    assert.equal(mrLength.toNumber() + 1, mrLength2.toNumber(), 'Member Role Not Added');
  });

  it('Should show zero pending reward when only rep is to be earned', async function() {
    this.timeout(100000);
    let reward = await pl.getPendingReward(owner);
    assert.equal(reward[0].toNumber(), 0, 'Incorrect Reward');
  });

  it('Should claim pending reward/reputation', async function() {
    this.timeout(100000);
    let rep1 = await gd.getMemberReputation(owner);
    await pl.claimReward(owner);
    let rep2 = await gd.getMemberReputation(owner);
    assert.isAtLeast(rep2.toNumber(), rep1.toNumber(), 'Incorrect Reward');
  });
});