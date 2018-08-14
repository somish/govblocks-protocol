var GBTStandardToken = artifacts.require("GBTStandardToken");
var gbts;

contract('GBTStandardToken', function([owner,taker]) {
  before(function(){
    GBTStandardToken.deployed().then(function(instance){
      gbts = instance;
    });
  });
  // it("should get the deployed insance of GBT", async function () {
  //   GBTStandardToken.deployed().then(function(instance){
  //     gbts = instance;
  //   });
  //   assert.equal(1, 1, "something is not right");
  // });
  // it("should be initialized", async function () {
  //   this.timeout(100000);
  //   assert.equal(await gbts.owner(), owner, "owner was not set properly");
  //   assert.equal(await gbts.name(), "GBT", "name was not set properly");
  //   assert.equal(await gbts.symbol(), "GBT", "symbol was not set properly");
  //   assert.equal(await gbts.decimals(), 18, "decimals was not set properly");
  //   assert.equal(await gbts.tokenPrice(), 1000000000000000, "tokenPrice was not set properly");
  // });
  // it("should buy/mint 100 GBT", async function() {
  //   this.timeout(100000);
  //   await gbts.buyToken({ value: 100000000000000000 });
  //   assert.equal(await gbts.balanceOf(owner), 100000000000000000000, "GBT was not mint properly"); 
  //   assert.equal(await gbts.totalSupply(), 100000000000000000000, "Total Supply not set properly");
  // });
  it("should transfer coin", async function() {
    this.timeout(100000);
    var b11 = await gbts.balanceOf.call(owner);
    var b21 = await gbts.balanceOf.call(taker);
    var amount = 10;
    await gbts.transfer(taker, amount);
    var b12 = await gbts.balanceOf.call(owner);
    var b22 = await gbts.balanceOf.call(taker);
    assert.equal(b12.toNumber(), b11.toNumber() - amount, "Amount wasn't correctly taken from the sender");
    assert.equal(b22.toNumber(), b21.toNumber() + amount, "Amount wasn't correctly sent to the receiver");
  });
  // it("should transfer coin with message", async function() {
  //   this.timeout(100000);
  //   var memberAddress = 0xed2f74e1fb73b775e6e35720869ae7a7f4d755ad;
  //   var amount = 50000000000000000000;
  //   var b11 = await gbts.balanceOf.call(owner);
  //   var b21 = await gbts.balanceOf.call(memberAddress);
  //   await gbts.transferMessage(memberAddress, amount, "0x46");
  //   var b12 = await gbts.balanceOf.call(owner);
  //   var b22 = await gbts.balanceOf.call(memberAddress);
  //   assert.equal(b12.toNumber(), b11.toNumber() - amount, "Amount wasn't correctly taken from the sender");
  //   assert.equal(b22.toNumber(), b21.toNumber() + amount, "Amount wasn't correctly sent to the receiver");
  // });
  // it("should verify sign", async function() {
  //   this.timeout(100000);
  //   var memberAddress = 0xed2f74e1fb73b775e6e35720869ae7a7f4d755ad;
  //   var amount = 10000000000000000000;
  //   var validUpto = ;
  //   var v = ;
  //   var r = ;
  //   var s = ;
  //   var lockTokenTxHash = ;
  //   var result = await verifySign(owner, memberAddress, amount, validUpto, lockTokenTxHash, v, r, s);
  //   assert.equal(result, true, "sign not verified correctly");
  // });
  // it("should lock tokens", async function() {
  //   this.timeout(100000);
  //   var memberAddress = 0xed2f74e1fb73b775e6e35720869ae7a7f4d755ad;
  //   var amount = 10000000000000000000;
  //   var validUpto = ;
  //   var v = ;
  //   var r = ;
  //   var s = ;
  //   var lockTokenTxHash = ;
  //   await gbts.lockToken(memberAddress, amount, validUpto, v, r, s, lockTokenTxHash);
  //   var lockedTokens = await gbts.getLockToken(memberAddress);
  //   assert.equal(lockedTokens, amount, "tokens not locked successfully");
  // });
  it("should approve a spender", async function() {
    this.timeout(100000);
    amount = 10;
    var result = await gbts.approve(taker, amount);
    var allowance = await gbts.allowance(owner, taker);
    assert.equal(amount, allowance, "allowance not added successfully");
  });
  it("should increase and decrease allowance", async function() {
    this.timeout(100000);
    amount = 10;
    var allowance = await gbts.allowance(owner, taker);
    var result = await gbts.increaseApproval(taker, amount);
    var allowance2 = await gbts.allowance(owner, taker);
    assert.equal(allowance2.toNumber(), allowance.toNumber() + amount, "allowance not increased successfully");
    result = await gbts.decreaseApproval(taker, amount);
    allowance2 = await gbts.allowance(owner, taker);
    assert.equal(allowance2.toNumber(), allowance.toNumber(), "allowance not decreased successfully");
  });
  it("should lock user's tokens", async function() {
    this.timeout(100000);
    var b11 = await gbts.balanceOf.call(owner);
    var amount = 50000000000000000000;
    await gbts.lock("GOV", amount, 5468545613353456);
    var b12 = await gbts.balanceOf.call(owner);
    assert.equal(b12.toNumber() + amount, b11.toNumber(), "tokens not deducted from balance");
    var lockedTokens = await gbts.tokensLockedAtTime(owner, "GOV", 546854561335345);
    assert.equal(lockedTokens.toNumber(), amount, "Tokens not added to lock properly");
  });
  // it("should change token price", async function() {
  //   this.timeout(100000);
  //   var newprice = 100000000000000;
  //   await gbts.changeTokenPrice(newprice);
  //   assert.equal(await gbts.tokenPrice(), newprice, "price not changed");
  // });
  // it("should close minting", async function() {
  //   this.timeout(100000);
  //   assert.equal(await gbts.mintingFinished(), false, "minting finished already");
  //   var result = await gbts.finishMinting();
  //   assert.equal(await gbts.mintingFinished(), true, "minting not finished");
  // });
  // it("should transfer from with message", async function() {
  //   this.timeout(100000);
  //   var memberAddress = 0xed2f74e1fb73b775e6e35720869ae7a7f4d755ad;
  //   var amount = 5;
  //   var allowance = await gbts.allowance(owner, taker);
  //   var b11 = await gbts.balanceOf.call(owner);
  //   var b21 = await gbts.balanceOf.call(taker);
  //   var b31 = await gbts.balanceOf.call(memberAddress);
  //   var result = await gbts.transferFromMessage(owner, memberAddress, amount, "0x46", { from: taker });
  //   var b12 = await gbts.balanceOf.call(owner);
  //   var b22 = await gbts.balanceOf.call(taker);
  //   var b32 = await gbts.balanceOf.call(memberAddress);
  //   assert.equal(b12.toNumber(), b11.toNumber() - amount, "Amount wasn't correctly taken from the sender");
  //   assert.equal(b32.toNumber(), b31.toNumber() + amount, "Amount wasn't correctly sent to the receiver");
  //   assert.equal(b22.toNumber(), b21.toNumber(), "Amount taken/given to the wrong guy");
  //   assert.equal(await gbts.allowance(owner, taker), allowance - amount, "Allowance wasn't decreased" );
  // });
});
