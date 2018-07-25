var MemberRoles = artifacts.require("MemberRoles");

contract('MemberRoles', function(accounts) {
  it("should deploy MemberRoles with constructorCheck false", function() {
    return MemberRoles.deployed().then(function(instance) {
      return instance.constructorCheck();
    }).then(function(constructorCheck) {
      assert.equal(constructorCheck, false, "constructorCheck wasn't false");
    });
  });
});
