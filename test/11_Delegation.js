const Governance = artifacts.require('DelegatedGovernance');
const MemberRoles = artifacts.require('MemberRoles');
const catchRevert = require('../helpers/exceptions.js').catchRevert;
const encode = require('../helpers/encoder.js').encode;
const getProposalIds = require('../helpers/reward.js').getProposalIds;
const getAddress = require('../helpers/getAddress.js').getAddress;
const initializeContracts = require('../helpers/getAddress.js')
  .initializeContracts;
const increaseTime = require('../helpers/increaseTime.js').increaseTime;
const { toHex, toWei } = require('../helpers/ethTools.js');
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

// const e18 = new BigNumber(1e18);

contract('Proposal, solution and voting', function([
  ab1,
  ab2,
  ab3,
  ab4,
  ab5,
  mem1,
  mem2,
  mem3,
  mem4,
  mem5,
  mem6,
  mem7,
  notMember
]) {

  async function gvProposalWithIncentive(...args) {
    let catId = args[0];
    let actionHash = args[1];
    let mr = args[2];
    let gv = args[3];
    let seq = args[4];
    let incentive = args[5];
    let p = await gv.getProposalLength();
    await gv.createProposal('proposal', 'proposal', 'proposal', 0);
    await gv.categorizeProposal(p, catId, incentive);
    await gv.submitProposalWithSolution(p, 'proposal', actionHash);
    let members = await mr.members(seq);
    let iteration = 0;
    if(members[1].length == 2) {
      await gv.submitVote(p, 1);
    }
    for (iteration = 2; iteration < members[1].length; iteration++) {
      await gv.submitVote(p, 1, {
        from: members[1][iteration]
      });
    }
    // console.log(await gv.proposalDetails(p));
    await increaseTime(604800);
    if (seq != 3) await gv.closeProposal(p);
    let proposal = await gv.proposal(p);
    assert.equal(proposal[2].toNumber(), 3);
  }

  it('Should fetch addresses from master', async function() {
    let punishVoters = false;
    await initializeContracts(punishVoters);
    punishVoters = true;
    await initializeContracts(punishVoters);
    address = await getAddress('GBT', false);
    gbt = await GBTStandardToken.at(address);
    address = await getAddress('GV', false);
    gv = await Governance.at(address);
    await gbt.transfer(address, 1e18*100);
    address = await getAddress('MR', false);
    mr = await MemberRoles.at(address);
    address = await getAddress('PC', false);
    pc = await ProposalCategory.at(address);
  });

  it('15.24 Initialising Members', async function() {
    let actionHash;
    actionHash = encode("changeAuthorized(uint,address)",1,web3.eth.accounts[0])
    await gvProposalWithIncentive(14, actionHash, mr, gv, 1, 0);
    actionHash = encode("addRole(bytes32,string,address)","0x41","",web3.eth.accounts[0]);
    await gvProposalWithIncentive(1, actionHash, mr, gv, 1, 0);
    // await mr.addRole("0x41","",web3.eth.accounts[0]);
    for(let i = 1;i<5;i++) {
      // actionHash = encode('updateRole(address,uint,bool)',web3.eth.accounts[i],1,true);
      await mr.updateRole(web3.eth.accounts[i],1,true);
    }
    for(let i = 5;i<12;i++) {
      // actionHash = encode('updateRole(address,uint,bool)',web3.eth.accounts[i],2,true);
      await mr.updateRole(web3.eth.accounts[i],3,true);
      // await gvProposalWithIncentive(2, actionHash, mr, gv, 1, 10);
    }
    actionHash = encode(
      'addCategory(string,uint,uint,uint,uint[],uint,string,address,bytes2,uint[])',
      'Yo',
      3,
      50,
      25,
      [1,2,3],
      604800,
      '',
      "0x0000000000000000000000000000000000000000",
      'EX',
      [0, 0]
    );
    await gvProposalWithIncentive(3, actionHash, mr, gv, 1, 0);
  });
  it('15.25 Fllower cannot delegate vote if Leader is not open for delegation', async function() {
    await catchRevert(gv.delegateVote(ab1, { from: mem1 }));
  });
  it('15.26 AB member cannot delegate vote to AB', async function() {
    await gv.setDelegationStatus(true, { from: ab1 });
    await catchRevert(gv.delegateVote(ab1, { from: ab2 }));
  });
  it('15.27 Owner cannot delegate vote', async function() {
    await gv.setDelegationStatus(true, { from: ab3 });
    await catchRevert(gv.delegateVote(ab3, { from: ab1 }));
  });
  it('15.28 AB member cannot delegate vote to Member', async function() {
    await gv.setDelegationStatus(true, { from: mem1 });
    await catchRevert(gv.delegateVote(mem1, { from: ab4 }));
  });
  it('15.29 AB member cannot delegate vote to Non-Member', async function() {
    await catchRevert(gv.delegateVote(notMember, { from: ab4 }));
  });
  it('15.30 Non-Member cannot delegate vote', async function() {
    await catchRevert(gv.delegateVote(ab1, { from: notMember }));
  });
  it('15.31 AB member cannot delegate vote to AB who is follower', async function() {
    await gv.setDelegationStatus(true, { from: ab2 });
    await catchRevert(gv.delegateVote(ab2, { from: ab4 }));
  });
  it('15.32 Member can delegate vote to AB who is not a follower', async function() {
    await gv.setDelegationStatus(true, { from: ab1 });
    await gv.delegateVote(ab1, { from: mem1 });
    let alreadyDelegated = await gv.alreadyDelegated(ab1);
    assert.equal(alreadyDelegated, true);
  });
  it('15.34 Member can delegate vote to Member who is not follower', async function() {
    await gv.setDelegationStatus(true, { from: mem3 });
    await gv.delegateVote(mem3, { from: mem5 });
    let followers = await gv.getFollowers(mem3);
    let delegationData = await gv.allDelegation(followers[0].toNumber());
    assert.equal(delegationData[0], mem5);
  });
  it('15.35 Leader cannot delegate vote', async function() {
    await catchRevert(gv.delegateVote(ab3, { from: mem3 }));
  });
  it('15.36 Member cannot delegate vote to Non-Member', async function() {
    await catchRevert(gv.delegateVote(notMember, { from: mem2 }));
  });
  it('15.37 Member cannot delegate vote to member who is follower', async function() {
    await catchRevert(gv.delegateVote(mem5, { from: mem2 }));
  });
  it('15.38 Create a proposal', async function() {
    pId = (await gv.getProposalLength()).toNumber();
    await gv.createProposal('Proposal1', 'Proposal1', 'Proposal1', 0); //Pid 2
    await gv.categorizeProposal(pId, 17, toWei(10));
    await gv.submitProposalWithSolution(
      pId,
      'changes to pricing model',
      '0x'
    );
  });
  // it('15.39 Ab cannot vote twice on a same proposal and cannot transfer nxm to others', async function() {
  //   await gv.submitVote(pId, 1, { from: ab3 });
  //   await catchRevert(gv.submitVote(pId, 1, { from: ab3 }));
  // });
  it('15.40 Member cannot vote twice on a same proposal', async function() {
    await gv.submitVote(pId, 1, { from: mem4 });
    await catchRevert(gv.submitVote(pId, 1, { from: mem4 }));
  });
  it('15.41 Member cannot assign proxy if voted within 7 days', async function() {
    await catchRevert(gv.delegateVote(ab1, { from: mem4 }));
  });
  it('15.42 Follower cannot vote on a proposal', async function() {
    await catchRevert(gv.submitVote(pId, 1, { from: mem5 }));
  });
  it('15.43 Member can assign proxy if voted more than 7 days earlier', async function() {
    await increaseTime(604850);
    await gv.delegateVote(ab1, { from: mem4 });
  });
  it('15.44 Follower can undelegate vote if not voted since 7 days', async function() {
    await increaseTime(604800);
    await gv.unDelegate({ from: mem5 });
    await gv.alreadyDelegated(mem3);
    await increaseTime(259200);
  });
  it('15.45 Leader can change delegation status if there are no followers', async function() {
    await gv.setDelegationStatus(false, { from: mem5 });
  });
  it('15.46 Follower cannot assign new proxy if revoked proxy within 7 days', async function() {
    await catchRevert(gv.delegateVote(ab1, { from: mem5 }));
  });
  it('15.47 Undelegated Follower cannot vote within 7 days since undelegation', async function() {
    pId = (await gv.getProposalLength()).toNumber();
    await gv.createProposal('Proposal2', 'Proposal2', 'Proposal2', 0); //Pid 3
    await gv.categorizeProposal(pId, 17, toWei(10));
    await gv.submitProposalWithSolution(
      pId,
      'changes to pricing model',
      '0x'
    );
    await catchRevert(gv.submitVote(pId, 1, { from: mem5 }));
    await increaseTime(432000); //7 days will be completed since revoking proxy
    await gv.delegateVote(ab1, { from: mem7 });
  });
  it('15.48 Undelegated Follower can vote after 7 days', async function() {
    await gv.submitVote(pId, 1, { from: mem2 });
    await gv.submitVote(pId, 1, { from: mem3 });
    await gv.submitVote(pId, 1, { from: mem5 });
    await increaseTime(604810);
    await gv.closeProposal(pId);
  });
  it('15.51 Follower cannot undelegate if there are rewards pending to be claimed', async function() {
    await catchRevert(gv.unDelegate({ from: mem5 }));
    await gv.claimReward(mem5, 10, { from: mem5 });
  });
  it('15.52 Follower should not get reward if delegated within 7days', async function() {
    let pendingReward = await gv.getPendingReward(mem7);
    assert.equal(pendingReward.toNumber(), 0);
  });
  it('15.53 Follower can assign new proxy if revoked proxy more than 7 days earlier', async function() {
    await increaseTime(604810);
    await gv.delegateVote(ab1, { from: mem5 });
  });
  it('15.54 Should not get rewards if not participated in voting', async function() {
    let pendingReward = await gv.getPendingReward(mem6);
    assert.equal(pendingReward.toNumber(), 0);
  });
  it('15.55 Should not add followers more than followers limit', async function() {
    await increaseTime(604810);
    pId = (await gv.getProposalLength()).toNumber();
    await gv.createProposal('Proposal2', 'Proposal2', 'Proposal2', 0); //Pid 3
    await gv.categorizeProposal(pId, 15, 0);
    let actionHash = encode(
      'updateUintParameters(bytes8,uint)',
      'MAXFOL',
      2
    );
    await gv.submitProposalWithSolution(
      pId,
      'update max followers limit',
      actionHash
    );
    await gv.submitVote(pId, 1, { from: ab1 });
    await gv.submitVote(pId, 1, { from: ab2 });
    await gv.submitVote(pId, 1, { from: ab3 });
    await increaseTime(604810);
    await gv.closeProposal(pId);
    await catchRevert(gv.delegateVote(ab1, { from: mem6 }));
  });
});
