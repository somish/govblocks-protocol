const Governance = artifacts.require('Governance');
const GovernanceData = artifacts.require('GovernanceData');
const SimpleVoting = artifacts.require('SimpleVoting');
const catchRevert = require('../helpers/exceptions.js').catchRevert;
const encode = require('../helpers/encoder.js').encode;
const getAddress = require('../helpers/getAddress.js').getAddress;
const initializeContracts = require('../helpers/getAddress.js')
  .initializeContracts;
const GBTStandardToken = artifacts.require('GBTStandardToken');
let gv;
let gd;
let sv;
let gbt;

contract('Governance Data', function([owner, notOwner]) {
  it('Should fetch addresses from master', async function() {
    await initializeContracts();
    address = await getAddress('GV');
    gv = await Governance.at(address);
    address = await getAddress('GD');
    gd = await GovernanceData.at(address);
    address = await getAddress('SV');
    sv = await SimpleVoting.at(address);
    address = await getAddress('GBT');
    gbt = await GBTStandardToken.at(address);
  });

  it('Should create a proposal with solution and vote', async function() {
    this.timeout(100000);
    let actionHash = encode(
      'addNewMemberRole(bytes32,string,address,bool)',
      '0x41647669736f727920426f617265000000000000000000000000000000000000',
      'New member role',
      owner,
      false
    );
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
    let amount = 50000000000000000000;
    await gbt.lock('GOV', amount, 5468545613353456);
    await gv.createProposalwithVote(
      'Add new member',
      'Add new member',
      'Addnewmember',
      1,
      'Add new member',
      actionHash
    );
    p2 = await gd.getAllProposalIdsLengthByAddress(owner);
    assert.equal(p1.toNumber() + 1, p2.toNumber(), 'Proposal not created');
  });

  it('Should not vote again', async function() {
    this.timeout(100000);
    p = await gd.getAllProposalIdsLengthByAddress(owner);
    p = p.toNumber();
    await catchRevert(sv.proposalVoting(p, [1]));
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
    let g1 = await gd.constructorCheck();
    let pl = await gd.getProposalLength();
    let g4 = await gd.callProposalVersionEvent(0, 0, 'yo', 0);
    let g5 = await gd.getProposalVotingDetails(0);
    let g6 = await gd.getProposalStatusAndVerdict(0);
    let g7 = await gd.getProposalDetails(0);
    let g9 = await gd.getTotalProposalIncentive();
    let g12 = await gd.getStatusOfProposals();
    let g14 = await gd.getAllSolutionIdsByAddress(owner);
    let g15 = await gd.getLatestVotingAddress();
    let g16 = await gd.getProposalDateUpd(0);
    await gd.storeProposalVersion(0, 'x');
    await catchRevert(gd.governanceDataInitiate());
    await gd.callReputationEvent(owner, 0, 'x', 1, '0x0');
    assert.equal(g1, true, 'Not initialized');
    // TODO verify the data returned
  });

  it('Should set punish voters', async function() {
    this.timeout(100000);
    // Will throw once owner's permissions are removed. will need to create proposal then.
    await gd.setPunishVoters(true);
    let pv = await gd.punishVoters();
    assert(pv, true, 'Punish voters not changed');
  });

  it('Should minimum vote weight', async function() {
    this.timeout(100000);
    // Will throw once owner's permissions are removed. will need to create proposal then.
    await gd.setMinVoteWeight(10);
    let pv = await gd.getMinVoteWeight();
    assert(pv, 10, 'Minimum vote weight not changed');
  });

  it('Should pause unpause proposal', async function() {
    this.timeout(100000);
    await catchRevert(gd.resumeProposal(0));
    await gd.pauseProposal(0);
    const p1 = await gd.proposalPaused(0);
    assert.equal(p1, true);
    await gd.resumeProposal(0);
    const p2 = await gd.proposalPaused(0);
    assert.equal(p2, false);
    await catchRevert(gd.pauseProposal(0, { from: notOwner }));
  });
});
