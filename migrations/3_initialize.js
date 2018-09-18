const MemberRoles = artifacts.require('MemberRoles');
const GovBlocksMaster = artifacts.require('GovBlocksMaster');
const Master = artifacts.require('Master');
const GBTStandardToken = artifacts.require('GBTStandardToken');
const Governance = artifacts.require('Governance');
const GovernanceData = artifacts.require('GovernanceData');
const Pool = artifacts.require('Pool');
const ProposalCategory = artifacts.require('ProposalCategory');
const SimpleVoting = artifacts.require('SimpleVoting');
const EventCaller = artifacts.require('EventCaller');

let gbt;
let ec;
let gbm;
let gd;
let mr;
let sv;
let gv;
let pl;
let ms;

module.exports = deployer => {
  console.log('GovBlocks Initialization started!');
  deployer
    .then(() => GBTStandardToken.deployed())
    .then(function(instance) {
      gbt = instance;
      return EventCaller.deployed();
    })
    .then(function(instance) {
      ec = instance;
      return Master.deployed();
    })
    .then(function(instance) {
      ms = instance;
      return GovBlocksMaster.deployed();
    })
    .then(function(instance) {
      gbm = instance;
      return gbm.govBlocksMasterInit(gbt.address, ec.address, ms.address);
    })
    .then(function() {
      return GovernanceData.deployed();
    })
    .then(function(instance) {
      gd = instance;
      return MemberRoles.deployed();
    })
    .then(function(instance) {
      mr = instance;
      return ProposalCategory.deployed();
    })
    .then(function(instance) {
      pc = instance;
      return SimpleVoting.deployed();
    })
    .then(function(instance) {
      sv = instance;
      return Governance.deployed();
    })
    .then(function(instance) {
      gv = instance;
      return Pool.deployed();
    })
    .then(function(instance) {
      pl = instance;
    })
    .then(function() {
      const addr = [
        gd.address,
        mr.address,
        pc.address,
        sv.address,
        gv.address,
        pl.address
      ];
      return gbm.setImplementations(addr);
    })
    .then(function() {
      return gbm.addGovBlocksUser('0x41', gbt.address, gbt.address, 'descHash');
    })
    .then(function() {
      console.log(
        'GovBlocks Initialization completed, GBM Address: ',
        gbm.address
      );
    });
};
