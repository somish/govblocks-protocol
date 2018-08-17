const TokenProxy = artifacts.require("TokenProxy");
const GBTStandardToken = artifacts.require("GBTStandardToken");
const catchRevert = require("../helpers/exceptions.js").catchRevert;
const lockReason = 'GOV';
const lockReason2 = 'CLAIM';
const lockedAmount = 200;
const lockPeriod = 1000;
let blockNumber = web3.eth.blockNumber;
const lockTimestamp = web3.eth.getBlock(blockNumber).timestamp;

const increaseTime = function(duration) {
  web3.currentProvider.sendAsync({
    jsonrpc: '2.0',
    method: 'evm_increaseTime',
    params: [duration],
    id: lockTimestamp,
  }, (err, resp) => {
    if (!err) {
      web3.currentProvider.send({
        jsonrpc: '2.0',
        method: 'evm_mine',
        params: [],
        id: lockTimestamp + 1,
      });
    }
  });
};

let tp;
let gbts;

contract('TokenProxy', function([owner, receiver, spender]) {
  before(function(){
    GBTStandardToken.deployed().then(function(instance){
      gbts = instance;
    });
  });

  it("should proxy correct data", async function () {
    this.timeout(100000);
    tp = await TokenProxy.new(gbts.address);
    let tpd = await tp.totalSupply();
    let gbtd = await gbts.totalSupply();
    assert.equal(tpd.toNumber(), tpd.toNumber(), "Not proxying Total Supply correctly");
    tpd = await tp.balanceOf(owner);
    gbtd = await gbts.balanceOf(owner);
    await gbts.approve(tp.address, gbtd.toNumber())
    assert.equal(tpd.toNumber(), tpd.toNumber(), "Not proxying balanceOf correctly");
    assert.equal(await tp.name(), await gbts.name(), "Not proxying name correctly");
    assert.equal(await tp.symbol(), await gbts.symbol(), "Not proxying symbol correctly");
    tpd = await tp.decimals();
    gbtd = await gbts.decimals();
    assert.equal(tpd.toNumber(), tpd.toNumber(), "Not proxying Total decimals correctly");
  });

  it('reduces locked tokens from transferable balance', async () => {
    const origBalance = await tp.balanceOf(owner);
    blockNumber = web3.eth.blockNumber;
    const newLockTimestamp = web3.eth.getBlock(blockNumber).timestamp;
    await tp.lock(lockReason, lockedAmount, lockPeriod);
    const balance = await tp.balanceOf(owner);
    const totalBalance = await tp.totalBalanceOf(owner);
    assert.equal(balance.toNumber(), origBalance.toNumber() - lockedAmount);
    assert.equal(totalBalance.toNumber(), origBalance.toNumber());
    let actualLockedAmount = await tp.tokensLocked(owner, lockReason);
    assert.equal(lockedAmount, actualLockedAmount.toNumber());
    actualLockedAmount = await tp.tokensLockedAtTime(
      owner,
      lockReason,
      newLockTimestamp + lockPeriod + 1
    );
    assert.equal(0, actualLockedAmount.toNumber());
  });

  it('reverts locking more tokens via lock function', async () => {
    const balance = await tp.balanceOf(owner);
    await catchRevert(tp.lock(lockReason, balance, lockPeriod));
  });

  it('can extend lock period for an existing lock', async () => {
    await tp.tokensLocked(owner, lockReason);
    const lockValidityOrig = await tp.locked(owner, lockReason);
    await tp.extendLock(lockReason, lockPeriod);
    const lockValidityExtended = await tp.locked(owner, lockReason);
    assert.equal(
      lockValidityExtended[1].toNumber(),
      lockValidityOrig[1].toNumber() + lockPeriod
    );
    await catchRevert(tp.extendLock(lockReason2, lockPeriod));
    await catchRevert(tp.increaseLockAmount(lockReason2, lockPeriod));
  });

  it('can increase the number of tokens locked', async () => {
    const actualLockedAmount = await tp.tokensLocked(owner, lockReason);
    await tp.increaseLockAmount(lockReason, lockedAmount);
    const increasedLockAmount = await tp.tokensLocked(owner, lockReason);
    assert.equal(
      increasedLockAmount.toNumber(),
      actualLockedAmount.toNumber() + lockedAmount
    );
  });

  it('can unLockTokens', async () => {
    const lockValidityExtended = await tp.locked(owner, lockReason);
    const balance = await tp.balanceOf(owner);
    await increaseTime((lockValidityExtended[1].toNumber() + 60) - lockTimestamp);
    unlockableToken = await tp.getUnlockableTokens(owner);
    assert.equal(
      unlockableToken.toNumber(),
      lockValidityExtended[0].toNumber()
    );
    await tp.unlock(owner);
    unlockableToken = await tp.getUnlockableTokens(owner);
    assert.equal(unlockableToken.toNumber(), 0);
    const newBalance = await tp.balanceOf(owner);
    assert.equal(
      newBalance.toNumber(),
      balance.toNumber() + lockValidityExtended[0].toNumber()
    );
  });

});