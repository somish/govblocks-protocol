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
    GBTStandardToken.deployed().then(function(){ 
        EventCaller.deployed().then(function(){
            GovBlocksMaster.deployed().then(function(instance){
                instance.govBlocksMasterInit(GBTStandardToken.address, EventCaller.address).then(function() {
                    instance.setMasterByteCode(bytecode.substring(10000)).then(function() {
                        instance.setMasterByteCode(bytecode).then(function() {
                            instance.addGovBlocksUser("0x41", GBTStandardToken.address, "descHash").then(function(){
                                GovernanceData.deployed().then(function(){ 
                                    MemberRoles.deployed().then(function(){
                                        ProposalCategory.deployed().then(function(){ 
                                            SimpleVoting.deployed().then(function(){ 
                                                Governance.deployed().then(function(){ 
                                                    Pool.deployed().then(function(){
                                                        // Master.deployed().then(function(mast){
                                                        //     mast.initMaster(owner,"0x41").then(function(){
                                                        //         mast.changeGBMAddress(GovBlocksMaster.address).then(function(){
                                                        //             instance.changeDappMasterAddress("0x41", master.address).then(function(){
                                                        //                 var addr = [GovernanceData.address, MemberRoles.address, ProposalCategory.address, SimpleVoting.address, Governance.address, Pool.address];
                                                        //                 mast.addNewVersion(addr);
                                                        //             });
                                                        //         });
                                                        //     });
                                                        // });
                                                    });
                                                });
                                            });
                                        });
                                    });
                                });
                            });
                        });
                    });
                });
            });
        });
    });
};

// var mad = instance.getDappMasterAddress("0x41").then(function(madr){
//     console.log(madr);
//     console.log(addr);
//     let ms = Master.at(madr).then(function(){
//         ms.addNewVersion.call(addr);
//     });
// }); 

