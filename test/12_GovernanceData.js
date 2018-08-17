const Governance = artifacts.require('Governance');
const GovernanceData = artifacts.require('GovernanceData');
const SimpleVoting = artifacts.require('SimpleVoting');
const catchRevert = require('../helpers/exceptions.js').catchRevert;
const encode = require('../helpers/encoder.js').encode;
const GBTStandardToken = artifacts.require('GBTStandardToken');
let gv;
let gd;
let sv;
let gbt;

contract('Governance Data', function([owner, taker]) {

  before(function() {
    Governance.deployed().then(function(instance) {
      gv = instance;
      return GovernanceData.deployed();
    }).then(function(instance) {
      gd = instance;
      return SimpleVoting.deployed();
    }).then(function(instance) {
      sv = instance;
      return GBTStandardToken.deployed();
    }).then(function(instance) {
      gbt = instance;
    });
  });

  it('Should create a proposal with solution', async function() {
    this.timeout(100000);
    let actionHash = encode('addNewMemberRole(bytes32,string,address,bool)', '0x41647669736f727920426f617265000000000000000000000000000000000000', 'New member role', owner, false);
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
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

  it('Should check getters', async function() {
    this.timeout(100000);
    let g1 = await gd.constructorCheck();
    let pl = await gd.getProposalLength();
    let g3 = await gd.getVotingTypeDetailsById(0);
    let g4 = await gd.callProposalVersionEvent(0, 0, 'yo', 0);
    let g5 = await gd.getProposalDetailsById2(0);
    let g6 = await gd.getProposalDetailsById3(0);
    let g7 = await gd.getProposalDetailsById6(0);
    let g9 = await gd.getTotalProposalIncentive();
    let g10 = await gd.getProposalVersion(0);
    let g12 = await gd.getStatusOfProposals();
    let g13 = await gd.getStatusOfProposalsForMember([0]);
    let g14 = await gd.getAllSolutionIdsByAddress(owner);
    assert.equal(g1, true, 'Not initialized');
    // TODO verify the data returned
  });

  it('Should change member rep points', async function() {
    this.timeout(100000);
    await gd.changeMemberReputationPoints(20, 15);
    let pop = await gd.addProposalOwnerPoints();
    assert.equal(pop.toNumber(), 20, 'Member points not changed correctly');
    await gd.changeProposalOwnerAdd(25);
    pop = await gd.addProposalOwnerPoints();
    assert.equal(pop.toNumber(), 25, 'Member points not changed correctly');
    await gd.changeSolutionOwnerAdd(30);
    pop = await gd.addSolutionOwnerPoints();
    assert.equal(pop.toNumber(), 30, 'Member points not changed correctly');
  });

  it('Should set dApp supports locking', async function() {
    this.timeout(100000);
    await gd.setDAppTokenSupportsLocking(true);
    assert.equal(await gd.dAppTokenSupportsLocking(), true, 'dAppTokenSupportsLocking not changed correctly');
  });
  
  it('Should pause unpause proposal', async function() {
    this.timeout(100000);
    await gd.setProposalPaused(0, true);
    let p1 = await gd.proposalPaused(0);
    await gd.resumeProposal(0);
    let p2 = await gd.proposalPaused(0);
    assert.notEqual(p1, p2, 'proposal not paused unpaused properly');
  });

  it('Should change parameters', async function() {
    this.timeout(100000);
    await gd.changeStakeWeight(20);
    let param = await gd.stakeWeight();
    assert.equal(param.toNumber(), 20, 'parameter changed correctly');
    await gd.changeBonusStake(25);
    param = await gd.bonusStake();
    assert.equal(param.toNumber(), 25, 'parameter changed correctly');
    await gd.changeReputationWeight(30);
    param = await gd.reputationWeight();
    assert.equal(param.toNumber(), 30, 'parameter changed correctly');
    await gd.changeBonusReputation(20);
    param = await gd.bonusReputation();
    assert.equal(param.toNumber(), 20, 'parameter changed correctly');
    await gd.changeQuorumPercentage(25);
    param = await gd.quorumPercentage();
    assert.equal(param.toNumber(), 25, 'parameter changed correctly');
    await gd.setPunishVoters(true);
    assert.equal(await gd.punishVoters(), true, 'parameter changed correctly');
  });
});