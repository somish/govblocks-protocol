const MemberRoles = artifacts.require('MemberRoles');
const GovBlocksMaster = artifacts.require('GovBlocksMaster');
const Master = artifacts.require('Master');
const GBTStandardToken = artifacts.require('GBTStandardToken');
const Governance = artifacts.require('Governance');
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
      var result = gbm.addGovBlocksDapp(
        '0x41',
        gbt.address,
        gbt.address,
        punishVoters
      );
      return result;
    })
    .then(function(result) {
      ms = Master.at(result.logs[0].args.masterAddress);
      const addr = [mr.address, pc.address, gv.address];
      // ms.initMaster(web3.eth.accounts[0], addr, punishVoters);
      setMasterAddress(result.logs[0].args.masterAddress, punishVoters);
      punishVoters = true;
      var result1 = gbm.addGovBlocksDapp(
        '0x42',
        gbt.address,
        gbt.address,
        punishVoters
      );
      return result1;
    })
    .then(function(result) {
      ms = Master.at(result.logs[0].args.masterAddress);
      setMasterAddress(ms.address, punishVoters);
      console.log(
        'GovBlocks Initialization completed, GBM Address: ',
        gbm.address
      );
    });
};
