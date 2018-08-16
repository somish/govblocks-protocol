const ProposalCategory = artifacts.require("ProposalCategory");
const GovernanceData = artifacts.require("GovernanceData");
const catchRevert = require("../helpers/exceptions.js").catchRevert;
const encode = require("../helpers/encoder.js").encode;
let pc;
let gv;
const sampleBytes32 = "0x41647669736f727920426f617264000000000000000000000000000000000000";
const sampleAddress = "0x0000000000000000000000000000000000000001";

contract('Proposal Category', function([owner,taker]) {
    before(function(){
      ProposalCategory.deployed().then(function(instance){
            pc = instance;
            return  GovernanceData.deployed()
        }).then(function(instance){
            gd = instance;
        });
    })
  it("Should check getters", async function (){
    this.timeout(100000);
    let g1 = await pc.allSubCategory(0);
    let g2 = await pc.allCategory(0);
    let g3 = await pc.updateDependencyAddresses();
    let g4 = await pc.changeMasterAddress();
    let g5 = await pc.getContractName(0);
    let g6 = await pc.getContractAddress(0);
    let g7 = await pc.getSubCategoryIdAtIndex(0,0);
    let g8 = await pc.getAllSubIdsByCategory(0);
    let g9 = await pc.getMRAllowed(0);
    let g10 = await pc.getAllSubIdsLengthByCategory(0);
    let g11 = await pc.getRoleMajorityVotelength(0);
    let g12 = await pc.getCategoryIncentive(0);
    let g13 = await pc.addInitialSubC("Yo","yo",1,sampleAddress,"0x4164",[1,1,1],[1,1,1]);
    //TODO verify the data returned
  });
  it("Should add a proposal category", async function() {
    this.timeout(100000);
    let c1 = await pc.getCategoryLength();
    //will throw once owner's permissions are revoked
    await pc.addNewCategory("Yo",[1],[1],[1],[1]);
    let c2 = await pc.getCategoryLength();
    assert.isAbove(c2.toNumber(), c1.toNumber(), "category not added");
  });
  it("Should update a proposal category", async function() {
    this.timeout(100000);
    let c1 = await pc.getCategoryLength();
    c1 = c1.toNumber() - 1; 
    let cat1 = await pc.getCategoryName(c1);
    //will throw once owner's permissions are revoked
    await pc.updateCategory(c1,"YoYo",[1],[1],[1],[1]);
    let cat2 = await pc.getCategoryName(c1);
    assert.notEqual(cat1[1], cat2[2], "category not updated");
  });
  it("Should add a proposal sub category", async function() {
    this.timeout(100000);
    let c1 = await pc.getSubCategoryLength();
    //will throw once owner's permissions are revoked
    await pc.addNewSubCategory("Yo","yo",1,sampleAddress,"0x4164",[1,1,1],[1,1,1]);
    let c2 = await pc.getSubCategoryLength();
    assert.isAbove(c2.toNumber(), c1.toNumber(), "Sub category not added");
  });
  it("Should update a proposal category", async function() {
    this.timeout(100000);
    let c1 = await pc.getCategoryLength();
    c1 = c1.toNumber() - 1; 
    let cat1 = await pc.getSubCategoryName(c1);
    //will throw once owner's permissions are revoked
    await pc.updateSubCategory("YoYo","yo",1,sampleAddress,"0x4141",[1,1,1],[1,1,1]);
    let cat2 = await pc.getSubCategoryName(c1);
    assert.notEqual(cat1, cat2, "Sub category not updated");
  });
});