var MemberRoles = artifacts.require("MemberRoles");
var GovBlocksMaster = artifacts.require("GovBlocksMaster");
var Master = artifacts.require("Master");
var GBTStandardToken = artifacts.require("GBTStandardToken");
var Governance = artifacts.require("Governance");
var GovernanceData = artifacts.require("GovernanceData");
var Pool = artifacts.require("Pool");
var ProposalCategory = artifacts.require("ProposalCategory");
var SimpleVoting = artifacts.require("SimpleVoting");
var EventCaller = artifacts.require("EventCaller");
const json = require('./../build/contracts/Master.json');
var bytecode = json['bytecode'];

module.exports = function(deployer) {
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
    console.log("1");
    GBTStandardToken.deployed().then(function(instance){ 
        gbt = instance;
        console.log("2");
        return EventCaller.deployed();
    })
    .then(function(instance){
        ec = instance;
        console.log("3");
        return GovBlocksMaster.deployed();
    })
    .then(function(instance){
        gbm = instance;
        console.log("4");
        return gbm.govBlocksMasterInit(gbt.address, ec.address);
    })
    .then(function() {
        console.log("5");
        return gbm.setMasterByteCode(bytecode.substring(10000));
    })
    .then(function() {
        console.log("6");
        return gbm.setMasterByteCode(bytecode);
    })
    .then(function() {
        console.log("7");
        return gbm.addGovBlocksUser("0x41", GBTStandardToken.address, "descHash");
    })
    .then(function(){
        console.log("8");
        return GovernanceData.deployed();
    })
    .then(function(instance){ 
        gd = instance;
        console.log("9");
        return MemberRoles.deployed();
    })
    .then(function(instance){
        mr = instance;
        console.log("10");
        return ProposalCategory.deployed();
    })
    .then(function(instance){
        pc = instance;
        console.log("11");
        return pc.proposalCategoryInitiate();
    })
    .then(function(){ 
        return SimpleVoting.deployed();
    })
    .then(function(instance){ 
        sv = instance;
        console.log("12");
        return Governance.deployed();
    })
    .then(function(instance){ 
        gv = instance;
        console.log("13");
        return Pool.deployed();
    })
    .then(function(instance){
        pl = instance;
        console.log("14");
        return Master.deployed();
    })
    .then(function(instance){
        ms = instance;
        console.log("15");
        return gbm.owner();
    })
    .then(function(own){
        console.log("16");
        return ms.initMaster(own,"0x41");
    })
    .then(function(){
        console.log("17");
        return ms.changeGBMAddress(GovBlocksMaster.address);
    })
    .then(function(){
        console.log("18");
        var addr = [gd.address, mr.address, pc.address, sv.address, gv.address, pl.address];
        return ms.addNewVersion(addr);
    })
    .then(function(){
        console.log("19");
        return gbm.changeDappMasterAddress("0x41", Master.address);
    })
    .then(function(){
        console.log("20");
    });
};