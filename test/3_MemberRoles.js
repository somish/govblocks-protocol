var MemberRoles = artifacts.require("MemberRoles");
var mr;

contract('MemberRoles', function([owner,member]) {
  it("should get the deployed insance of MemberRoles", async function () {
    MemberRoles.deployed().then(function(instance){
      mr = instance;
    });
    assert.equal(1, 1, "something is not right");
  });
  it("should be initialized with default roles", async function () {
    this.timeout(100000);
    let ab = await mr.getMemberRoleNameById(1);
    let th = await mr.getMemberRoleNameById(2);
    assert.equal(await mr.constructorCheck(), true, "constructorCheck wasn't true");
    assert.equal(ab.toString(), "Advisory Board", "Advisory Board not created");
    assert.equal(th.toString(), "Token Holder", "Token Holder not created");
    assert.equal(await mr.checkRoleIdByAddress(owner,1), true, "Owner not added to AB");
  });
  it("should add a member to a role", async function () {
    this.timeout(100000);
    await mr.updateMemberRole(member,1,true,356854);
    assert.equal(await mr.checkRoleIdByAddress(member,1), true, "user not added to AB");
  });

});