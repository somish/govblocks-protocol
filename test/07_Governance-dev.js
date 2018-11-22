const Governance = artifacts.require('Governance');
const GovernanceData = artifacts.require('GovernanceData');
const catchRevert = require('../helpers/exceptions.js').catchRevert;
const increaseTime = require('../helpers/increaseTime.js').increaseTime;
const encode = require('../helpers/encoder.js').encode;
const getProposalIds = require('../helpers/reward.js').getProposalIds;
const getAddress = require('../helpers/getAddress.js').getAddress;
const initializeContracts = require('../helpers/getAddress.js')
  .initializeContracts;
const Pool = artifacts.require('Pool');
const SimpleVoting = artifacts.require('SimpleVoting');
const Master = artifacts.require('Master');
const GBTStandardToken = artifacts.require('GBTStandardToken');
const ProposalCategory = artifacts.require('ProposalCategory');
const MemberRoles = artifacts.require('MemberRoles');
const TokenProxy = artifacts.require('TokenProxy');
const sampleAddress = 0x0000000000000000000000000000000000000001;

let gbt;
let sv;
let pl;
let gd;
let gv;
let ms;
let mr;
let pc;
let dAppToken;
let propId;
let pid;
let ownerProposals;
let voterProposals;

const BigNumber = web3.BigNumber;
require('chai')
  .use(require('chai-bignumber')(BigNumber))
  .should();

const e18 = new BigNumber(1e18);

contract('Governance', ([owner, notOwner, noStake]) => {
  it('Should fetch addresses from master', async function() {
    await initializeContracts();
    address = await getAddress('GV');
    gv = await Governance.at(address);
    address = await getAddress('GD');
    gd = await GovernanceData.at(address);
    address = await getAddress('SV');
    sv = await SimpleVoting.at(address);
    address = await getAddress('MR');
    mr = await MemberRoles.at(address);
    address = await getAddress('GBT');
    gbt = await GBTStandardToken.at(address);
    address = await getAddress('PC');
    pc = await ProposalCategory.at(address);
    address = await getAddress('PL');
    pl = await Pool.at(address);
    tp = await TokenProxy.new(gbt.address);
    address = await getAddress('MS');
    ms = await Master.at(address);
    address = await ms.dAppLocker();
    dAppToken = await GBTStandardToken.at(address);
  });

  it('Should create an uncategorized proposal',async function(){
    gd.setPunishVoters(true);
    pid = await gd.getProposalLength();
    await gbt.transfer(notOwner, e18.mul(10));
    await gv.createProposal(
      'Add new member',
      'Add new member',
      'hash',
      0
    );
    await gv.createProposal(
      'Add new member',
      'Add new member',
      'hash',
      0,
      { from: notOwner }
    );
    assert.equal(pid.toNumber()+2,(await gd.getProposalLength()).toNumber(),"Proposal not created");
  });

  it('Should not categorize if pool balance is less than category default incentive',async function(){
    await catchRevert(gv.categorizeProposal(pid, 10));
    await dAppToken.transfer(pl.address, e18.mul(20));
    await gbt.transfer(pl.address, e18.mul(20));
  });

  it('Should not allow to categorize if tokens are not locked',async function(){
    await catchRevert(gv.categorizeProposal(pid, 10 , { from: notOwner }));
  });

  it('Should not allow unauthorized person to categorize proposal',async function(){
    await dAppToken.lock('GOV', e18.mul(10), 54685456133563456, { from: notOwner });
    await catchRevert(gv.categorizeProposal(pid, 10, { from: notOwner }));
  });

  it('Should categorize proposal',async function(){
    await dAppToken.lock('GOV', e18.mul(10), 54685456133563456);
    await gv.categorizeProposal(pid, 1);
    assert.equal((await gd.getProposalCategory(pid)).toNumber(), 1 ,"Not categorized");
  });

  it('Should allow authorized people to categorize multiple times',async function(){
    const a = await mr.memberRoleLength();
    console.log(a);
    await gv.categorizeProposal(pid, 2);
    assert.equal((await gd.getProposalCategory(pid)).toNumber(), 2 ,"Not categorized");
    await mr.updateMemberRole(notOwner, 1, true);
    await gv.categorizeProposal(pid, 11);
    assert.equal((await gd.getProposalCategory(pid)).toNumber(), 11 ,"Not categorized");
    await mr.updateMemberRole(notOwner, 1, false);
  });

  it('Should not allow unauthorized people to open proposal for voting and submit solutions', async () => {
    const initSol = await gd.getTotalSolutions(pid);
    await catchRevert(
      gv.submitProposalWithSolution(pid, '0x0', '0x0', { from: noStake })
    );
    await catchRevert(
      gv.submitProposalWithSolution(pid, '0x0', '0x0', { from: notOwner })
    );
    const finalSol = await gd.getTotalSolutions(pid);
    assert.equal(initSol.toNumber(), finalSol.toNumber());
  });

  it('Should allow anyone to submit solution', async () =>{
    sv.addSolution(pid, notOwner, '0x0', '0x0', { from: notOwner });
  });

  it('Should not allow to categorize if there are solutions', async () => {
    await catchRevert(gv.categorizeProposal(pid, 2));
  });

  it('Should not allow voting before proposal is open for voting', async () => {
    await catchRevert(sv.proposalVoting(pid, [1]));
  });

  it('Should allow authorized people to submit solution', async () => {
    const initSol = await gd.getTotalSolutions(pid);
    await gv.submitProposalWithSolution(pid, '0x0', '0x0');
    const finalSol = await gd.getTotalSolutions(pid);
    assert.equal(finalSol.toNumber(), initSol.toNumber() + 1);
  });

  it('Should not allow voting for non existent solution', async () => {
    await catchRevert(sv.proposalVoting(pid, [5]));
  });

  it('Should not allow unauthorized people to vote', async () => {
    await catchRevert(sv.proposalVoting(pid, [1], { from: notOwner }));
  });

  it('Should allow voting', async () => {
    await sv.proposalVoting(pid, [2]);
  });

  it('Should close proposal', async () => {
    await sv.closeProposalVote(pid);
    await catchRevert(sv.closeProposalVote(pid));
  });

  it('Should claim reward after proposal passed', async () =>{
    voterProposals = await getProposalIds(owner, gd, sv);
    const balance =await dAppToken.balanceOf(owner);
    await pl.claimReward(owner, voterProposals);
    assert.isAbove((await dAppToken.balanceOf(owner)).toNumber(), balance.toNumber());
  });

  it('Should check reward distribution when there are more voters', async () =>{
    await mr.updateMemberRole(notOwner, 1, true);
    await gv.createProposal(
      'Add new member',
      'Add new member',
      'hash',
      0
    );
    propId = (await gd.getProposalLength()).toNumber() -1;
    await gv.categorizeProposal( propId, 12);
    await gv.submitProposalWithSolution(propId, '0x0', '0x0');
    await sv.proposalVoting(propId, [1]);
    await sv.proposalVoting(propId, [1], { from: notOwner});
    console.log(await dAppToken.balanceOf(owner));
    console.log(voterProposals);
    await sv.closeProposalVote(propId);
    voterProposals = await getProposalIds(owner, gd, sv);
    await dAppToken.transfer(pl.address, e18.mul(10));    
    await pl.claimReward(owner, voterProposals);
    console.log(await dAppToken.balanceOf(owner));
  });

});