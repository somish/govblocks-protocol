const Governance = artifacts.require('Governance');
const MemberRoles = artifacts.require('MemberRoles');
const catchRevert = require('../helpers/exceptions.js').catchRevert;
const encode = require('../helpers/encoder.js').encode;
const getProposalIds = require('../helpers/reward.js').getProposalIds;
const getAddress = require('../helpers/getAddress.js').getAddress;
const initializeContracts = require('../helpers/getAddress.js')
  .initializeContracts;
const GBTStandardToken = artifacts.require('GBTStandardToken');
const ProposalCategory = artifacts.require('ProposalCategory');
const sampleAddress = 0x0000000000000000000000000000000000000001;
const amount = 500000000000000;

let gv;
let mr;
let sv;
let pl;
let pc;
let mrLength;
let gbt;

const BigNumber = web3.BigNumber;
require('chai')
  .use(require('chai-bignumber')(BigNumber))
  .should();

const e18 = new BigNumber(1e18);

contract('Proposal, solution and voting', function([
  owner,
  ab,
  member,
  nonMember
]) {
  it('Should fetch addresses from master', async function() {
    let punishVoters = false;
    await initializeContracts(punishVoters);
    punishVoters = true;
    await initializeContracts(punishVoters);
    address = await getAddress('GV', false);
    gv = await Governance.at(address);
    address = await getAddress('MR', false);
    mr = await MemberRoles.at(address);
    address = await getAddress('GBT', false);
    gbt = await GBTStandardToken.at(address);
    address = await getAddress('PC', false);
    pc = await ProposalCategory.at(address);
    address = await getAddress('GV', false);
    pl = await Governance.at(address);
  });

  it('Should create a proposal with solution to add new member role', async function() {
    this.timeout(100000);
    let actionHash = encode(
      'addRole(bytes32,string,address)',
      '0x41647669736f727920426f617265000000000000000000000000000000000000',
      'New member role',
      owner
    );
    p1 = await gv.getProposalLength();
    mrLength = await mr.totalRoles();
    let amount = 50000000000000000000;
    await gbt.lock('GOV', amount, 5468545613353456);
    await gv.createProposalwithSolution(
      'Add new member',
      'Add new member',
      'Addnewmember',
      1,
      'Add new member',
      actionHash
    );
    p2 = await gv.getProposalLength();
    assert.equal(p1.toNumber() + 1, p2.toNumber(), 'Proposal not created');
  });

  it('Should close the proposal', async function() {
    this.timeout(100000);
    p = await gv.getProposalLength();
    p = p.toNumber() - 1;
    await gv.closeProposal(p);
    await catchRevert(gv.closeProposal(p));
    mrLength2 = await mr.totalRoles();
    assert.equal(
      mrLength.toNumber() + 1,
      mrLength2.toNumber(),
      'Member Role Not Added'
    );
  });

  it('Should have added new member role', async function() {
    this.timeout(100000);
    mrLength2 = await mr.totalRoles();
    assert.equal(
      mrLength.toNumber() + 1,
      mrLength2.toNumber(),
      'Member Role Not Added'
    );
  });

  it('Should create an uncategorized proposal', async function() {
    this.timeout(100000);
    mrLength = await mr.totalRoles();
    await gv.createProposal(
      'Add new member',
      'Add new member',
      'Addnewmember',
      0
    );
    p1 = await gv.getProposalLength();
    await gv.categorizeProposal(p1.toNumber() - 1, 1, 0);
    await gv.createProposal(
      'Add new member',
      'Add new member',
      'Addnewmember',
      0
    );
    p2 = await gv.getProposalLength();
    assert.equal(p1.toNumber() + 1, p2.toNumber(), 'Proposal not created');
  });

  it('Should not add solution before proposal is open for solution submission', async function() {
    this.timeout(100000);
    let actionHash = encode(
      'addRole(bytes32,string,address)',
      '0x41647669736f727920426f617265000000000000000000000000000000000000',
      'New member role',
      owner
    );
    p = await gv.getProposalLength();
    p = p.toNumber() - 1;
    await catchRevert(gv.addSolution(p, 'Addnewmember', actionHash));
  });

  it('Should not open the proposal for voting when it is not categorized', async function() {
    await catchRevert(gv.openProposalForVoting(p));
  });

  it('Should categorize the proposal and then open it for solution submission', async function() {
    this.timeout(100000);
    p = await gv.getProposalLength();
    p = p.toNumber() - 1;
    await gv.categorizeProposal(p, 1, 0);
  });

  it('Should not open the proposal for voting till there are atleast two solutions', async function() {
    this.timeout(100000);
    p = await gv.getProposalLength();
    p = p.toNumber() - 1;
    await catchRevert(gv.openProposalForVoting(p));
  });

  it('Should submit a solution', async function() {
    this.timeout(100000);
    let actionHash = encode(
      'addRole(bytes32,string,address)',
      '0x41647669736f727920426f617265000000000000000000000000000000000000',
      'New member role',
      owner
    );
    p1 = await gv.getProposalLength();
    p1 = p1.toNumber() - 1;
    await gv.submitProposalWithSolution(p1, 'Addnewmember', actionHash);
    await catchRevert(
      gv.submitProposalWithSolution(p1, 'Addnewmember', actionHash)
    );
  });

  it('Should vote in favour of the proposal', async function() {
    this.timeout(100000);
    p = await gv.getProposalLength();
    p = p.toNumber() - 1;
    await gv.submitVote(p, [1]);
    await catchRevert(gv.submitVote(p, [1]));
  });

  it('Should close the proposal', async function() {
    this.timeout(100000);
    p = await gv.getProposalLength();
    p = p.toNumber() - 1;
    await gv.closeProposal(p);
    await catchRevert(gv.closeProposal(p));
  });

  it('Should have added new member role', async function() {
    this.timeout(100000);
    mrLength2 = await mr.totalRoles();
    assert.equal(
      mrLength.toNumber() + 1,
      mrLength2.toNumber(),
      'Member Role Not Added'
    );
  });

  it('Should show zero pending reward when only rep is to be earned', async function() {
    this.timeout(100000);
    let reward = await gv.getPendingReward(owner);
    assert.equal(reward.toNumber(), 0, 'Incorrect Reward');
  });

  it('Should add another person to member role', async function() {
    this.timeout(100000);
    //proposal to add member to AB
    let actionHash = encode('updateRole(address,uint,bool)', ab, 1, true);
    let p1 = await gv.getProposalLength();
    await gv.createProposalwithSolution(
      'Add new member',
      'Add new member',
      'Addnewmember',
      2,
      'Add new member',
      actionHash
    );
    await gv.closeProposal(p1.toNumber());
    //proposal closed
    await mr.updateRole(member, 3, true);
    assert.equal(
      await mr.checkRole(member, 3),
      true,
      'user not added to member'
    );
  });

  it('Should get proper proposal status', async function() {
    this.timeout(100000);
    p = await gv.getProposalLength();
    p = p.toNumber();
    await gv.createProposalwithSolution(
      'Add new member',
      'Add new member',
      'Addnewmember',
      5,
      'Add new member',
      '0x0'
    );
    await gv.submitVote(p, [0], { from: ab });
    await gv.closeProposal(p);
    //proposal to add member to AB
    let actionHash = encode('updateRole(address,uint,bool)', member, 1, true);
    let p1 = await gv.getProposalLength();
    await gv.createProposalwithSolution(
      'Add new member',
      'Add new member',
      'Addnewmember',
      2,
      'Add new member',
      actionHash
    );
    await gv.submitVote(p1.toNumber(), [1], { from: ab });
    await gv.closeProposal(p1.toNumber());
    //proposal closed
    p = await gv.getProposalLength();
    p = p.toNumber();
    await gv.createProposal(
      'Add new member',
      'Add new member',
      'Addnewmember',
      5
    );
    await gv.addSolution(p, 'Add new member', '0x0');
    await gv.addSolution(p, '0x0', '0x0', { from: ab });
    await gv.openProposalForVoting(p);
    await catchRevert(gv.addSolution(p, '0x0', '0x0', { from: member }));
    await gv.submitVote(p, [1]);
    await gv.submitVote(p, [2], { from: ab });
    await gv.submitVote(p, [0], { from: member });
    await gv.closeProposal(p);
    //proposal to remove member from AB
    actionHash = encode('updateRole(address,uint,bool)', member, 1, false);
    p1 = await gv.getProposalLength();
    await gv.createProposalwithSolution(
      'Add new member',
      'Add new member',
      'Addnewmember',
      2,
      'Add new member',
      actionHash
    );
    await gv.submitVote(p1.toNumber(), [1], { from: ab });
    await gv.submitVote(p1.toNumber(), [1], { from: member });
    await gv.closeProposal(p1.toNumber());
    //proposal closed
    await gbt.transfer(pl.address, e18.mul(20));
    //proposal to remove member from AB
    actionHash = encode('updateRole(address,uint,bool)', ab, 1, false);
    p1 = await gv.getProposalLength();
    await gv.createProposalwithSolution(
      'Add new member',
      'Add new member',
      'Addnewmember',
      2,
      'Add new member',
      actionHash
    );
    await gv.submitVote(p1.toNumber(), [1], { from: ab });
    await gv.closeProposal(p1.toNumber());
    //proposal closed
    p = await gv.getProposalLength();
    p = p.toNumber();
    await gv.createProposal(
      'Add new member',
      'Add new member',
      'Addnewmember',
      14
    );
    await gv.submitProposalWithSolution(p, '0x0', '0x0');
    await catchRevert(gv.categorizeProposal(p, 1, 0));
    await gv.submitVote(p, [0]);
    await gv.closeProposal(p);
    const ps = await gv.getStatusOfProposals();
    assert.equal(ps[0].toNumber(), 11);
    assert.equal(ps[1].toNumber(), 1);
    assert.equal(ps[2].toNumber(), 1);
    assert.equal(ps[3].toNumber(), 0);
    assert.equal(ps[4].toNumber(), 8);
    assert.equal(ps[5].toNumber(), 1);
  });
});
