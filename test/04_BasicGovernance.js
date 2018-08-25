const Governance = artifacts.require('Governance');
const GovernanceData = artifacts.require('GovernanceData');
const MemberRoles = artifacts.require('MemberRoles');
const SimpleVoting = artifacts.require('SimpleVoting');
const catchRevert = require('../helpers/exceptions.js').catchRevert;
const encode = require('../helpers/encoder.js').encode;
const GBTStandardToken = artifacts.require('GBTStandardToken');
const Pool = artifacts.require('Pool');
const ProposalCategory = artifacts.require('ProposalCategory');
const sampleAddress = 0x0000000000000000000000000000000000000001;

let gv;
let gd;
let mr;
let sv;
let pl;
let pc;
let mrLength;
let gbt;

contract('Proposal, solution and voting', function([owner, ab, member]) {
  before(function() {
    Governance.deployed()
      .then(function(instance) {
        gv = instance;
        return GovernanceData.deployed();
      })
      .then(function(instance) {
        gd = instance;
        return SimpleVoting.deployed();
      })
      .then(function(instance) {
        sv = instance;
        return MemberRoles.deployed();
      })
      .then(function(instance) {
        mr = instance;
        return GBTStandardToken.deployed();
      })
      .then(function(instance) {
        gbt = instance;
        return Pool.deployed();
      })
      .then(function(instance) {
        pl = instance;
        return ProposalCategory.deployed();
      })
      .then(function(instance) {
        pc = instance;
      });
  });

  it('Should create a proposal with solution to add new member role', async function() {
    this.timeout(100000);
    let actionHash = encode(
      'addNewMemberRole(bytes32,string,address,bool)',
      '0x41647669736f727920426f617265000000000000000000000000000000000000',
      'New member role',
      owner,
      false
    );
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
    mrLength = await mr.getTotalMemberRoles();
    let amount = 50000000000000000000;
    await gbt.lock('GOV', amount, 5468545613353456);
    await gv.createProposalwithSolution(
      'Add new member',
      'Add new member',
      'Addnewmember',
      0,
      1,
      'Add new member',
      actionHash
    );
    p2 = await gd.getAllProposalIdsLengthByAddress(owner);
    assert.equal(p1.toNumber() + 1, p2.toNumber(), 'Proposal not created');
  });

  it('Should vote in favour of the proposal', async function() {
    this.timeout(100000);
    p = await gd.getAllProposalIdsLengthByAddress(owner);
    p = p.toNumber();
    await sv.proposalVoting(p, [1]);
    await catchRevert(sv.proposalVoting(p, [1]));
  });

  it('Should close the proposal', async function() {
    this.timeout(100000);
    p = await gd.getAllProposalIdsLengthByAddress(owner);
    p = p.toNumber();
    await sv.closeProposalVote(p);
    await catchRevert(sv.closeProposalVote(p));
  });

  it('Should have added new member role', async function() {
    this.timeout(100000);
    mrLength2 = await mr.getTotalMemberRoles();
    assert.equal(
      mrLength.toNumber() + 1,
      mrLength2.toNumber(),
      'Member Role Not Added'
    );
  });

  it('Should create an uncategorized proposal', async function() {
    this.timeout(100000);
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
    mrLength = await mr.getTotalMemberRoles();
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

  it('Should categorize the proposal and then open it for voting', async function() {
    this.timeout(100000);
    p = await gd.getAllProposalIdsLengthByAddress(owner);
    p = p.toNumber();
    await gv.categorizeProposal(p, 1);
    await gv.openProposalForVoting(p);
    await catchRevert(gv.openProposalForVoting(p));
  });

  it('Should submit a solution', async function() {
    this.timeout(100000);
    let actionHash = encode(
      'addNewMemberRole(bytes32,string,address,bool)',
      '0x41647669736f727920426f617265000000000000000000000000000000000000',
      'New member role',
      owner,
      false
    );
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
    await sv.addSolution(p1.toNumber(), owner, 'Addnewmember', actionHash);
    await catchRevert(
      sv.addSolution(p1.toNumber(), owner, 'Addnewmember', actionHash)
    );
  });

  it('Should vote in favour of the proposal', async function() {
    this.timeout(100000);
    p = await gd.getAllProposalIdsLengthByAddress(owner);
    p = p.toNumber();
    await sv.proposalVoting(p, [1]);
    await catchRevert(sv.proposalVoting(p, [1]));
  });

  it('Should close the proposal', async function() {
    this.timeout(100000);
    p = await gd.getAllProposalIdsLengthByAddress(owner);
    p = p.toNumber();
    await sv.closeProposalVote(p);
    await catchRevert(sv.closeProposalVote(p));
  });

  it('Should have added new member role', async function() {
    this.timeout(100000);
    mrLength2 = await mr.getTotalMemberRoles();
    assert.equal(
      mrLength.toNumber() + 1,
      mrLength2.toNumber(),
      'Member Role Not Added'
    );
  });

  it('Should show zero pending reward when only rep is to be earned', async function() {
    this.timeout(100000);
    let reward = await pl.getPendingReward(owner);
    assert.equal(reward[0].toNumber(), 0, 'Incorrect Reward');
  });

  it('Should add another person to AB', async function() {
    this.timeout(100000);
    await mr.updateMemberRole(ab, 1, true, 54565656456);
    assert.equal(
      await mr.checkRoleIdByAddress(ab, 1),
      true,
      'user not added to AB'
    );
    await mr.updateMemberRole(member, 3, true, 54565656456);
    assert.equal(
      await mr.checkRoleIdByAddress(member, 3),
      true,
      'user not added to member'
    );
  });

  it('Should add a new category with multiple layers of voting', async function() {
    this.timeout(100000);
    let c1 = await pc.getCategoryLength();
    await pc.addNewCategory(
      'New Category',
      [1, 3],
      [1, 1],
      [0],
      [48548564156864, 645564561546]
    );
    let c2 = await pc.getCategoryLength();
    assert.isAbove(c2.toNumber(), c1.toNumber(), 'category not added');
  });

  it('Should add a new proposal sub category', async function() {
    this.timeout(100000);
    let c1 = await pc.getSubCategoryLength();
    let cat = await pc.getCategoryLength();
    await pc.addNewSubCategory(
      'New Sub Category',
      'New Sub Category',
      cat.toNumber() - 1,
      sampleAddress,
      '0x4164',
      [100, 100, 100],
      [40, 40, 20]
    );
    let c2 = await pc.getSubCategoryLength();
    assert.isAbove(c2.toNumber(), c1.toNumber(), 'Sub category not added');
  });

  it('Should create a proposal with solution', async function() {
    this.timeout(100000);
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
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
    p2 = await gd.getAllProposalIdsLengthByAddress(owner);
    assert.equal(p1.toNumber() + 1, p2.toNumber(), 'Proposal not created');
  });

  it('Should transfer and lock gbt', async function() {
    let amount = 5000000000;
    await gbt.transfer(ab, amount);
    await gbt.transfer(member, amount);
    await gbt.transfer(pl.address, amount);
    await gbt.lock('GOV', amount, 5468545613353456, { from: ab });
    await gbt.lock('GOV', amount, 5468545613353456, { from: member });
  });

  it('Should submit another solution', async function() {
    this.timeout(100000);
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
    let s1 = await gd.getTotalSolutions(p1.toNumber());
    await sv.addSolution(p1.toNumber(), ab, 'Addnewmember', '0x41', {
      from: ab
    });
    let s2 = await gd.getTotalSolutions(p1.toNumber());
    assert.equal(s1.toNumber() + 1, s2.toNumber(), 'Solution not created');
  });

  it('Should vote in favour of the second solution', async function() {
    this.timeout(100000);
    p = await gd.getAllProposalIdsLengthByAddress(owner);
    p = p.toNumber();
    await sv.proposalVoting(p, [2]);
    let vid = await sv.getVoteIdAgainstMember(owner, p);
    assert.isAtLeast(vid.toNumber(), 1, 'Vote not added');
  });

  it('Should not close the proposal before time', async function() {
    this.timeout(100000);
    p = await gd.getAllProposalIdsLengthByAddress(owner);
    p = p.toNumber();
    await catchRevert(sv.closeProposalVote(p));
  });

  it('Should vote in favour of the second solution', async function() {
    this.timeout(100000);
    p = await gd.getAllProposalIdsLengthByAddress(owner);
    p = p.toNumber();
    await sv.proposalVoting(p, [2], { from: ab });
    let vid = await sv.getVoteIdAgainstMember(ab, p);
    assert.isAtLeast(vid.toNumber(), 1, 'Vote not added');
  });

  it('Should close the proposal once all members have voted', async function() {
    this.timeout(100000);
    p = await gd.getAllProposalIdsLengthByAddress(owner);
    p = p.toNumber();
    await sv.closeProposalVote(p);
    let iv = await gd.getProposalIntermediateVerdict(p);
    assert.equal(iv.toNumber(), 2, 'Incorrect intermediate Verdict');
  });

  it('Should not allow to pick different solution than ab', async function() {
    this.timeout(100000);
    p = await gd.getAllProposalIdsLengthByAddress(owner);
    p = p.toNumber();
    await catchRevert(sv.proposalVoting(p, [1], { from: member }));
  });

  it('Should allow to vote for rejection', async function() {
    this.timeout(100000);
    p = await gd.getAllProposalIdsLengthByAddress(owner);
    p = p.toNumber();
    await sv.proposalVoting.call(p, [0], { from: member });
  });

  it('Should allow to vote for same solution as AB', async function() {
    this.timeout(100000);
    p = await gd.getAllProposalIdsLengthByAddress(owner);
    p = p.toNumber();
    await sv.proposalVoting(p, [2], { from: member });
    let vid = await sv.getVoteIdAgainstMember(member, p);
    assert.isAtLeast(vid.toNumber(), 2, 'Vote not added');
  });

  it('Should close the proposal once all members have voted', async function() {
    this.timeout(100000);
    p = await gd.getAllProposalIdsLengthByAddress(owner);
    p = p.toNumber();
    await sv.closeProposalVote(p);
    let iv = await gd.getProposalFinalVerdict(p);
    assert.equal(iv.toNumber(), 2, 'Incorrect final Verdict');
  });

  it('Should claim pending reward/reputation', async function() {
    this.timeout(100000);
    let rep1 = await gd.getMemberReputation(owner);
    let pr = await pl.getPendingReward(owner);
    assert.equal(pr[1].toNumber(), 0);
    assert.isAtLeast(pr[0].toNumber(), 40);
    pr = await pl.getPendingReward(ab);
    assert.equal(pr[1].toNumber(), 0);
    assert.isAtLeast(pr[0].toNumber(), 40);
    pr = await pl.getPendingReward(member);
    assert.equal(pr[1].toNumber(), 0);
    assert.isAtLeast(pr[0].toNumber(), 0);
    await pl.claimReward(owner);
    await pl.claimReward(ab);
    await pl.claimReward(member);
    let rep2 = await gd.getMemberReputation(owner);
    assert.isAbove(rep2.toNumber(), rep1.toNumber(), 'Incorrect Reward');
  });
});
