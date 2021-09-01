const GovBlocksMaster = artifacts.require('GovBlocksMaster');
const DemoDAPP = artifacts.require('DemoDApp');
const DemoToken = artifacts.require('DemoToken');
const TokenProxy = artifacts.require('TokenProxy');
const MemberRoles = artifacts.require('MemberRoles');
const Governance = artifacts.require('Governance');
const Master = artifacts.require('Master');
const ProposalCategory = artifacts.require('ProposalCategory');
const setMasterAddress = require('../helpers/masterAddress.js')
  .setMasterAddress;
const SampleAddress = "0x0000000000000000000000000000000000000001";
const encode = require('../helpers/encoder.js').encode;

let gbm,mr,ms;
let gvMaster;
let dapp,dappToken;
let lockableToken;

contract('new dApp', function([owner, user1, user2, user3, user4]) {
  it('should onboard new dApp', async () => {
    gbm = await GovBlocksMaster.deployed();
    dappToken = await DemoToken.new("5000000000000000000000")
    lockableToken = await TokenProxy.new(dappToken.address,18);
    const rc = await gbm.addGovBlocksDapp(
      "0x44656d6f415050",
      dappToken.address,
      lockableToken.address,
      false
    );
    gvMaster = rc.receipt.logs[2].args[1];
    ms = await Master.at(gvMaster)
    dapp = await DemoDAPP.new();
    await ms.addNewContract("0x4444",dapp.address);
    dapp = await DemoDAPP.at(await ms.getLatestAddress("0x4444"));
    console.log(await dapp.masterAddress());
    console.log("owner Bal: ", (await dappToken.balanceOf(owner))/1);
    await dappToken.transfer(dapp.address,"200000000000000000000");
    console.log("owner Bal: ", (await dappToken.balanceOf(owner))/1);
    console.log('MasterAddress: ', rc.receipt.logs[2].args[1]);
    console.log('Gas used in deploying dApp: ', rc.receipt.gasUsed);
  });
  it('initialize instances', async () => {
    mr = await MemberRoles.at(await ms.getLatestAddress("0x4d52"));
    gv = await Governance.at(await ms.getLatestAddress("0x4756"));
    pc = await ProposalCategory.at(await ms.getLatestAddress("0x5043"));
  });

  it('Add new Member role', async function() {

    mrLength = await mr.totalRoles();
    await mr.addRole("0x4d656d62657273","Members of daap", owner);
    
    mrLength1 = await mr.totalRoles();
    assert.isAbove(mrLength1.toNumber(), mrLength.toNumber(), 'Role not added');

    await mr.updateRole(user1,3,true);
    await mr.updateRole(user2,3,true);
    await mr.updateRole(user3,3,true);
    // console.log(await mr.members(3));

    await dappToken.transfer(user1,"50000000000000000000");
    await dappToken.transfer(user2,"50000000000000000000");
    await dappToken.transfer(user3,"50000000000000000000");
  });

  it('Add category to mint from dapp', async () => {

    let c1 = await pc.totalCategories();
    await pc.addCategory('Mint By Governance',3,50,50,[1,2],24*3600,'',dapp.address,'0x4558',[0,0]);
    const c2 = await pc.totalCategories();
    assert.isAbove(c2.toNumber(), c1.toNumber(), 'category not added');
    
  });

  it('Create Proposal with solution for minting dapp token', async () => {

    let actionHash = encode(
      'sendFunds(address,uint256)',
      user4,
      "100000000000000000000"
    ); 

    let amount = "50000000000000000000";
    await dappToken.approve(lockableToken.address,amount,{from:user1});
    await lockableToken.lock('0x474f56', amount, "604800",{from:user1});

    
    // let actionHash1 = encode(
    //   'sendFunds(address,uint256)',
    //   "0xbc100dcA0Df9587D85a8C30CBdfE88d6E5487e0e",
    //   "100000000000000000000"
    // ); 
    // console.log("Action hash: ",actionHash);
    console.log("===> ",(await gv.getProposalLength())/1);
    let c1 = await pc.totalCategories();
    await gv.createProposalwithSolution(
      'Mint Tokens',
      'Payment towards service',
      '',
      c1-1,
      'mintByGovern',
      actionHash,
      {from:user1}
    );
    console.log("===> ",(await gv.getProposalLength())/1);

    // console.log(await gv.proposal());

    console.log("prop status ",(await gv.canCloseProposal(1))/1);
    await gv.submitVote(1,1,{from:user2});
    await gv.submitVote(1,1,{from:user3});
    console.log("prop status ",(await gv.canCloseProposal(1))/1);

    console.log("user4 bal ", (await dappToken.balanceOf(user4))/1);

    await gv.closeProposal(1);

    console.log("user4 bal ", (await dappToken.balanceOf(user4))/1);
    
  });


});
