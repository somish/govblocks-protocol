let MemberRoles = artifacts.require("MemberRoles");
let catchRevert = require("../helpers/exceptions.js").catchRevert;
let encode = require("../helpers/encoder.js").encode;

var mr;
// let toAscii = require("web3").toAscii;

contract('MemberRoles', function([owner,member,nonmember]) {
  before(function(){
    MemberRoles.deployed().then(function(instance){
      mr = instance;
    });
  });
  it("should be initialized with default roles", async function () {
    this.timeout(100000);
    let ab = await mr.getMemberRoleNameById.call(1);
    let th = await mr.getMemberRoleNameById(2);

    assert.equal(ab[1], "0x41647669736f727920426f617264000000000000000000000000000000000000", "Advisory Board not created");
    assert.equal(th[1], "0x546f6b656e20486f6c6465720000000000000000000000000000000000000000", "Token Holder not created");
    assert.equal(await mr.checkRoleIdByAddress(owner,1), true, "Owner not added to AB");
  });
  it("should add a member to a role", async function () {
    this.timeout(100000);
    await mr.updateMemberRole(member,1,true,356854);
    assert.equal(await mr.checkRoleIdByAddress(member,1), true, "user not added to AB");
  });

  // it("Should add new member role", async function () {
  //   this.timeout(100000);
  //   console.log(encode('updateMemberRole(address,uint256,bool,uint256)',nonmember,1,true,356854));
  //   await catchRevert(mr.updateMemberRole(nonmember,1,true,356854, {from: member}));
  // }); 
});