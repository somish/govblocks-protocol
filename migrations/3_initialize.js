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
const ProposalCategoryAdder = artifacts.require('ProposalCategoryAdder');
const TokenProxy = artifacts.require('TokenProxy');
const json = require('./../build/contracts/Master.json');
const bytecode = json['bytecode'];

module.exports = deployer => {
  let gbt;
  let ec;
  let gbm;
  let gd;
  let mr;
  let sv;
  let pc;
  let gv;
  let pl;
  let ms;
  let tp;
  let owner;
  deployer
    .then(() => GBTStandardToken.deployed())
    .then(function(instance) {
      gbt = instance;
      return EventCaller.deployed();
    })
    .then(function(instance) {
      ec = instance;
      return GovBlocksMaster.deployed();
    })
    .then(function(instance) {
      gbm = instance;
      return TokenProxy.deployed();
    })
    .then(function(instance) {
      tp = instance;
      return gbm.govBlocksMasterInit(gbt.address, ec.address);
    })
    .then(function() {
      return gbm.setMasterByteCode(bytecode);
    })
    .then(function() {
      return gbm.addGovBlocksUser('0x41', gbt.address, gbt.address, 'descHash');
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
      return pc.proposalCategoryInitiate('0x41');
    })
    .then(function() {
      return ProposalCategoryAdder.deployed();
    })
    .then(function(instance) {
      pca = instance;
      return pca.addSubC(pc.address);
    })
    .then(function() {
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
      return Master.deployed();
    })
    .then(function(instance) {
      ms = instance;
      return gbm.owner();
    })
    .then(function(own) {
      owner = own;
      return ms.initMaster(own, '0x41');
    })
    .then(function() {
      return mr.memberRolesInitiate('0x41', GBTStandardToken.address, owner);
    })
    .then(function() {
      return ms.changeGBMAddress(GovBlocksMaster.address);
    })
    .then(function() {
      var addr = [
        gd.address,
        mr.address,
        pc.address,
        sv.address,
        gv.address,
        pl.address
      ];
      return ms.addNewVersion(addr);
    })
    .then(function() {
      return ms.getCurrentVersion();
    })
    .then(function(v) {
      return gbm.changeDappMasterAddress('0x41', Master.address);
    })
    .then(function() {
      console.log('GovBlocks Initialization completed!');
    });
};
