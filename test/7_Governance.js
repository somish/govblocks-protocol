const Governance = artifacts.require("Governance");
const GovernanceData = artifacts.require("GovernanceData");
const catchRevert = require("../helpers/exceptions.js").catchRevert;
const encode = require("../helpers/encoder.js").encode;
let gd;
let gv;
const sampleBytes32 = "0x41647669736f727920426f617264000000000000000000000000000000000000";
const sampleAddress = "0x0000000000000000000000000000000000000001";

//todo changePendingProposalStart

contract('Governance', function([owner,taker]) {
    before(function(){
        Governance.deployed().then(function(instance){
            gv = instance;
            return  GovernanceData.deployed()
        }).then(function(instance){
            gd = instance;
        });
    })
  it("Should create an uncategorized proposal", async function () {
    this.timeout(100000);
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
    await gv.createProposal("Add new member", "Add new member", "Addnewmember", 0, 0);
    p2 = await gd.getAllProposalIdsLengthByAddress(owner);
    assert.equal(p1.toNumber() + 1, p2.toNumber(), "Proposal not created");
  }); 
  it("Should categorize the proposal", async function () {
    this.timeout(100000);
    p = await gd.getAllProposalIdsLengthByAddress(owner);
    p = p.toNumber() - 1;
    await gv.categorizeProposal(p, 1, 0);
    let category = await gd.getProposalCategory(p);
    assert.equal(category.toNumber(), 1, "Category not set properly");
  });
  it("Should submit proposal with solution", async function () {
    this.timeout(100000);
    var actionHash = encode('addNewMemberRole(bytes32,string,address,bool)',"0x41647669736f727920426f617265000000000000000000000000000000000000","New member role",owner,false);
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
    await gv.submitProposalWithSolution(p1.toNumber() - 1, "Addnewmember", actionHash);
    await catchRevert(gv.submitProposalWithSolution(p1.toNumber() - 1, "Addnewmember", actionHash));
    let remainingTime = await gv.getMaxCategoryTokenHoldTime(1);
    await assert.isAtLeast(remainingTime.toNumber(), 1, "Remaining time not set");
    remainingTime = await gv.getRemainingClosingTime(p1.toNumber() - 1, 0);
    await assert.isAtLeast(remainingTime.toNumber(), 1, "Remaining time not set");
  });
  it("Should check getters", async function (){
    let g1 = gv.getMemberDetails(owner);
    let g2 = gv.getSolutionIdAgainstAddressProposal(owner,0);
    let g3 = gv.getAllVoteIdsLengthByProposal(0);
    try {await gv.changePendingProposalStart();}
    catch(exceptions) {
        console.log("need to be run after master is initialized");
    }
    //TODO verify the data returned
  });
});