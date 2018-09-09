const GBTStandardToken = artifacts.require('GBTStandardToken');
const catchRevert = require('../helpers/exceptions.js').catchRevert;
const increaseTime = require('../helpers/increaseTime.js').increaseTime;
let gbts;
const supply = 100000000000000000000;
const lockReason = 'GOV';
const lockReason2 = 'CLAIM';
const lockedAmount = 200;
const lockPeriod = 1000;
let blockNumber = web3.eth.blockNumber;
const lockTimestamp = web3.eth.getBlock(blockNumber).timestamp;
const approveAmount = 10;
const nullAddress = 0x0000000000000000000000000000000000000000;

contract('GBTStandardToken', function([owner, receiver, spender]) {
  before(function() {
    GBTStandardToken.deployed().then(function(instance) {
      gbts = instance;
    });
  });

  it('has the right balance for the contract owner', async () => {
    const balance = await gbts.balanceOf(owner);
    const totalBalance = await gbts.totalBalanceOf(owner);
    const totalSupply = await gbts.totalSupply();
    assert.equal(balance.toNumber(), supply);
    assert.equal(totalBalance.toNumber(), supply);
    assert.equal(totalSupply.toNumber(), supply);
  });

  it('should buy/mint 100 GBT', async function() {
    this.timeout(100000);
    let b1 = await gbts.balanceOf.call(owner);
    await gbts.buyToken({
      value: 100000000000000000
    });
    let b2 = await gbts.balanceOf.call(owner);
    assert.equal(
      b2.toNumber(),
      b1.toNumber() + 100000000000000000000,
      'GBT was not mint properly'
    );
  });

  it('reduces locked tokens from transferable balance', async () => {
    const origBalance = await gbts.balanceOf(owner);
    blockNumber = web3.eth.blockNumber;
    const newLockTimestamp = web3.eth.getBlock(blockNumber).timestamp;
    await gbts.lock(lockReason, lockedAmount, lockPeriod);
    const balance = await gbts.balanceOf(owner);
    const totalBalance = await gbts.totalBalanceOf(owner);
    assert.equal(balance.toNumber(), origBalance.toNumber() - lockedAmount);
    assert.equal(totalBalance.toNumber(), origBalance.toNumber());
    let actualLockedAmount = await gbts.tokensLocked(owner, lockReason);
    assert.equal(lockedAmount, actualLockedAmount.toNumber());
    actualLockedAmount = await gbts.tokensLockedAtTime(
      owner,
      lockReason,
      newLockTimestamp + lockPeriod + 1
    );
    assert.equal(0, actualLockedAmount.toNumber());
    const transferAmount = 1;
    const { logs } = await gbts.transfer(receiver, transferAmount, {
      from: owner
    });
    const newSenderBalance = await gbts.balanceOf(owner);
    const newReceiverBalance = await gbts.balanceOf(receiver);
    assert.equal(newReceiverBalance.toNumber(), transferAmount);
    assert.equal(newSenderBalance.toNumber(), balance - transferAmount);
    assert.equal(logs.length, 1);
    assert.equal(logs[0].event, 'Transfer');
    assert.equal(logs[0].args.from, owner);
    assert.equal(logs[0].args.to, receiver);
    assert(logs[0].args.value.eq(transferAmount));
  });

  it('reverts locking more tokens via lock function', async () => {
    const balance = await gbts.balanceOf(owner);
    await catchRevert(gbts.lock(lockReason, balance, lockPeriod));
  });

  it('can extend lock period for an existing lock', async () => {
    await gbts.tokensLocked(owner, lockReason);
    const lockValidityOrig = await gbts.locked(owner, lockReason);
    await gbts.extendLock(lockReason, lockPeriod);
    const lockValidityExtended = await gbts.locked(owner, lockReason);
    assert.equal(
      lockValidityExtended[1].toNumber(),
      lockValidityOrig[1].toNumber() + lockPeriod
    );
    await catchRevert(gbts.extendLock(lockReason2, lockPeriod));
    await catchRevert(gbts.increaseLockAmount(lockReason2, lockPeriod));
  });

  it('can increase the number of tokens locked', async () => {
    const actualLockedAmount = await gbts.tokensLocked(owner, lockReason);
    await gbts.increaseLockAmount(lockReason, lockedAmount);
    const increasedLockAmount = await gbts.tokensLocked(owner, lockReason);
    assert.equal(
      increasedLockAmount.toNumber(),
      actualLockedAmount.toNumber() + lockedAmount
    );
  });

  it('cannot transfer tokens to null address', async function() {
    await catchRevert(
      gbts.transfer(nullAddress, 100, {
        from: owner
      })
    );
  });

  it('cannot transfer tokens greater than transferable balance', async () => {
    const balance = await gbts.balanceOf(owner);
    await catchRevert(
      gbts.transfer(receiver, balance + 1, {
        from: owner
      })
    );
  });

  it('can approve transfer to a spender', async () => {
    const initialAllowance = await gbts.allowance(owner, spender);
    await gbts.approve(spender, approveAmount);
    const newAllowance = await gbts.allowance(owner, spender);
    assert(newAllowance.toNumber(), initialAllowance + approveAmount);

    it('cannot transfer tokens from an address greater than allowance', async () => {
      await catchRevert(
        gbts.transferFrom(owner, receiver, 2, {
          from: spender
        })
      );
    });
  });

  it('cannot transfer tokens from an address to null address', async () => {
    await catchRevert(
      gbts.transferFrom(owner, nullAddress, 100, {
        from: owner
      })
    );
  });

  it('cannot transfer tokens from an address greater than owners balance', async () => {
    const balance = await gbts.balanceOf(owner);
    await gbts.approve(spender, balance);
    await catchRevert(
      gbts.transferFrom(owner, receiver, balance.toNumber() + 1, {
        from: spender
      })
    );
  });

  it('can transfer tokens from an address less than owners balance', async () => {
    const balance = await gbts.balanceOf(owner);
    await gbts.approve(spender, balance.toNumber());
    const amount = balance.toNumber() / 2;
    const { logs } = await gbts.transferFrom(owner, receiver, amount, {
      from: spender
    });
    assert.equal(logs.length, 1);
    assert.equal(logs[0].event, 'Transfer');
    assert.equal(logs[0].args.from, owner);
    assert.equal(logs[0].args.to, receiver);
    assert(logs[0].args.value.eq(amount));
  });

  it('can unLockTokens', async () => {
    const lockValidityExtended = await gbts.locked(owner, lockReason);
    const balance = await gbts.balanceOf(owner);
    await increaseTime(lockValidityExtended[1].toNumber() + 60 - lockTimestamp);
    unlockableToken = await gbts.getUnlockableTokens(owner);
    assert.equal(
      unlockableToken.toNumber(),
      lockValidityExtended[0].toNumber()
    );
    await gbts.unlock(owner);
    unlockableToken = await gbts.getUnlockableTokens(owner);
    assert.equal(unlockableToken.toNumber(), 0);
    const newBalance = await gbts.balanceOf(owner);
    assert.equal(
      newBalance.toNumber(),
      balance.toNumber() + lockValidityExtended[0].toNumber()
    );
  });
});
