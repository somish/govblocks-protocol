const Master = artifacts.require("Master");
const GovernanceData = artifacts.require("GovernanceData");
const catchRevert = require("../helpers/exceptions.js").catchRevert;
const encode = require("../helpers/encoder.js").encode;
let ms;
let gv;
const sampleBytes32 = "0x41647669736f727920426f617264000000000000000000000000000000000000";
const sampleAddress = "0x0000000000000000000000000000000000000001";

contract('Master', function([owner,taker]) {
    before(function(){
        Master.deployed().then(function(instance){
            ms = instance;
            return  GovernanceData.deployed()
        }).then(function(instance){
            gd = instance;
        });
    })
  it("Should check getters", async function (){
    this.timeout(100000);
    let g1 = await ms.versionDates(0);
    let g2 = await ms.dAppName();
    let g3 = await ms.gbmAddress();
    let g4 = await ms.getCurrentVersion();
    let g5 = await ms.getVersionData(1);
    let g6 = await ms.getLatestAddress("MS");
    let g7 = await ms.getEventCallerAddress();
    let g8 = await ms.getGovernCheckerAddress();
    assert.isAtLeast(g1.toNumber(), 1, "Master version date not set");
    //TODO verify the data returned
  });
  it("Should set dAppTokenProxy", async function() {
    this.timeout(100000);
    await ms.setDAppTokenProxy(sampleAddress);
    let tp = await ms.dAppTokenProxy();
    assert.equal(tp, sampleAddress, "Token Proxy not set");
  });

  it("Should not allow non-gbm address to change gbt address", async function() {
    this.timeout(100000);
    await catchRevert(ms.changeGBTSAddress(sampleAddress));
  });
  
  it("Should configure Global Parameters", async function() {
    this.timeout(100000);
    //Will throw once owner's permissions are removed. will need to create proposal then.
    await ms.configureGlobalParameters("QP",58);
    let qp = await gd.quorumPercentage();
    assert(qp.toNumber(), 58, "Global parameter not changed");
  });

  it("Should add new contract", async function() {
    this.timeout(100000);
    //Will throw once owner's permissions are removed. will need to create proposal then.
    await ms.addNewContract("QP",sampleAddress);
    assert(await ms.getLatestAddress("QP"), sampleAddress, "new contract not added");
  });
});