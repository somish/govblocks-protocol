var MemberRoles = artifacts.require("MemberRoles");
var GovBlocksMaster = artifacts.require("GovBlocksMaster");
var Master = artifacts.require("Master");


contract('GovBlocksMaster', function([owner]) {
  let gbm;
  it('should setup gbm', async function () {
    gbm = await GovBlocksMaster.new(owner)
  })
  contract('Master', function([owner]) {
    let mr = await Master.new(owner);
    contract('MemberRoles', function([owner]) {
      let mr = await MemberRoles.new(owner);
      it("should deploy MemberRoles with constructorCheck false", function() {
          assert.equal(await mr.constructorCheck(), false, "constructorCheck wasn't false");
      });
      it("should initiate MemberRoles and deafult Roles", function() {
          return mr.memberRolesInitiate().then(function() {
            return mr.getMemberRoleNameById(1).then(function(RoleId, RoleName) {
              assert.equal(RoleName.toString(), "Advisory Board", "Advisory Board created").then(function() {
                return mr.getMemberRoleNameById(2).then(function(RoleId, RoleName) {
                  assert.equal(RoleName.toString(), "Token Holder", "Token Holder created");
                });
              });
            });
          });
        });
      });
    });
  });












/*
  it("should send coin correctly", function() {
    var meta;

    // Get initial balances of first and second account.
    var account_one = accounts[0];
    var account_two = accounts[1];

    var account_one_starting_balance;
    var account_two_starting_balance;
    var account_one_ending_balance;
    var account_two_ending_balance;

    var amount = 10;

    return MetaCoin.deployed().then(function(instance) {
      meta = instance;
      return meta.getBalance.call(account_one);
    }).then(function(balance) {
      account_one_starting_balance = balance.toNumber();
      return meta.getBalance.call(account_two);
    }).then(function(balance) {
      account_two_starting_balance = balance.toNumber();
      return meta.sendCoin(account_two, amount, {from: account_one});
    }).then(function() {
      return meta.getBalance.call(account_one);
    }).then(function(balance) {
      account_one_ending_balance = balance.toNumber();
      return meta.getBalance.call(account_two);
    }).then(function(balance) {
      account_two_ending_balance = balance.toNumber();

      assert.equal(account_one_ending_balance, account_one_starting_balance - amount, "Amount wasn't correctly taken from the sender");
      assert.equal(account_two_ending_balance, account_two_starting_balance + amount, "Amount wasn't correctly sent to the receiver");
    });
  });*/

