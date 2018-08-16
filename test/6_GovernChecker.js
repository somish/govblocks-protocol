let GovernCheckerContract = artifacts.require("GovernCheckerContract");
var gc;

contract('GovernCheckerContract', function([first,second]) {
  before(function(){
    GovernCheckerContract.deployed().then(function(instance){
      gc = instance;
    });
  });

  it("should initalize authorized", async function() {
    this.timeout(100000);
    await gc.initializeAuthorized("0x41",first);
    let authorizedAddressNumber = await gc.authorizedAddressNumber("0x41", first);
    assert.isAtLeast(authorizedAddressNumber.toNumber(), 1, "authorized not initialized properly");
    //assert.equal(b22.toNumber(), b21.toNumber() + amount, "Amount wasn't correctly sent to the receiver");
  });

  it("should add authorized", async function() {
    this.timeout(100000);
    await gc.addAuthorized("0x41",second);
    let authAddress = await gc.authorized("0x41", 1);
    assert.equal(authAddress, second, "authorized not added properly");
  });
  
  it("should update authorized", async function() {
    this.timeout(100000);
    await gc.updateAuthorized("0x41",gc.address);
    let authorizedAddressNumber = await gc.authorizedAddressNumber("0x41", first);
    assert.equal(authorizedAddressNumber.toNumber(), 0, "authorized not removed properly");
  });

  it("should add gbm", async function() {
    this.timeout(100000);
    await gc.updateGBMAdress(first);
    assert.equal(await gc.GetGovBlockMasterAddress(), first, "gbm not added properly");
  });
});
