const MemberRoles = artifacts.require('MemberRoles');
const GovBlocksMaster = artifacts.require('GovBlocksMaster');
const Master = artifacts.require('Master');
const GBTStandardToken = artifacts.require('GBTStandardToken');
const Governance = artifacts.require('DelegatedGovernance');
const ProposalCategory = artifacts.require('ProposalCategory');
const setMasterAddress = require('../helpers/masterAddress.js')
  .setMasterAddress;

let gbt;
let gbm;
let gd;
let mr;
let sv;
let gv;
let ms;
let punishVoters;

module.exports = deployer => {
  console.log('GovBlocks Initialization started!');
  deployer
    .then(() => GBTStandardToken.deployed())
    .then(function(instance) {
      gbt = instance;
      return GovBlocksMaster.deployed();
    })
    .then(function(instance) {
      gbm = instance;
      return MemberRoles.deployed();
    })
    .then(function(instance) {
      mr = instance;
      return ProposalCategory.deployed();
    })
    .then(function(instance) {
      pc = instance;
      return Governance.deployed();
    })
    .then(function(instance) {
      gv = instance;
      const addr = [mr.address, pc.address, gv.address];
      return gbm.setImplementations(addr);
    })
    .then(function() {
      punishVoters = false;
      // var result =gbm.addGovBlocksDapp(
      //   '0x41',
      //   gbt.address,
      //   gbt.address,
      //   punishVoters
      // );
      return Master.deployed();
    })
    .then(function(result) {
      ms = Master.at(result.address);
      console.log(result.address);
      const addr = [mr.address, pc.address, gv.address];
      var result1 =ms.initMaster(web3.eth.accounts[0], punishVoters, gbt.address, gbt.address, addr);
      setMasterAddress(ms.address, punishVoters);
      punishVoters = true;
      return result1;
    })
    .then(function(result) {
      // var result1 = gbm.addGovBlocksDapp(
      //   '0x42',
      //   gbt.address,
      //   gbt.address,
      //   punishVoters
      // );
      return Master.new();
    })
    .then(function(result) {
      ms = Master.at(result.address);
      console.log(result.address);
      // ms = Master.at(result.logs[0].args.masterAddress);
      var addr1 = [mr.address, pc.address, gv.address];
      ms.initMaster(web3.eth.accounts[0], punishVoters, gbt.address, gbt.address, addr1);
      setMasterAddress(ms.address, punishVoters);
      console.log(
        'GovBlocks Initialization completed, GBM Address: ',
        gbm.address
      );
    });
};
