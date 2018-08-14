let Governance = artifacts.require("Governance");
let GovernanceData = artifacts.require("GovernanceData");
let MemberRoles = artifacts.require("MemberRoles");
let SimpleVoting = artifacts.require("SimpleVoting");
let catchRevert = require("../helpers/exceptions.js").catchRevert;
let encode = require("../helpers/encoder.js").encode;
var GBTStandardToken = artifacts.require("GBTStandardToken");


var gv;
var gd;
var mr;
var sv;
var mrLength;
var gbt;
contract('Proposal, solution and voting', function([owner]) {
    before(function(){
        Governance.deployed().then(function(instance){
            gv = instance;
            return  GovernanceData.deployed()
        }).then(function(instance){
            gd = instance;
            return  SimpleVoting.deployed()
        }).then(function(instance){
            sv = instance;
            return  MemberRoles.deployed()
        }).then(function(instance){
            mr = instance;
            return  GBTStandardToken.deployed()
        }).then(function(instance){
            gbt = instance;
        });
    });
    it("Should create a proposal with solution to add new member role", async function () {
      this.timeout(100000);
      var actionHash = encode('addNewMemberRole(bytes32,string,address,bool)',"0x41647669736f727920426f617265000000000000000000000000000000000000","New member role",owner,false);
      p1 = await gd.getAllProposalIdsLengthByAddress(owner);
      mrLength = await mr.getTotalMemberRoles();
      var amount = 50000000000000000000;
      await gbt.lock("GOV", amount, 5468545613353456);
      await gv.createProposalwithSolution("Add new member", "Add new member", "Addnewmember", 0, 1, "Add new member", actionHash);
      p2 = await gd.getAllProposalIdsLengthByAddress(owner);
      assert.equal(p1.toNumber() + 1, p2.toNumber(), "Proposal not created");
    }); 
    it("Should vote in favour of the proposal", async function () {
        this.timeout(100000);
        p = await gd.getAllProposalIdsLengthByAddress(owner);
        p = p.toNumber() - 1;
        let lt = await gbt.tokensLockedAtTime(owner, "GOV", 546854561335345);
        await sv.proposalVoting(p,[1]);
        await catchRevert(sv.proposalVoting(p,[1]));
    });
    it("Should close the proposal", async function () {
        this.timeout(100000);
        p = await gd.getAllProposalIdsLengthByAddress(owner);
        p = p.toNumber() - 1;
        await sv.closeProposalVote(p);
        await catchRevert(sv.closeProposalVote(p));
    });
    it("Should have added new member role", async function () {
        this.timeout(100000);
        mrLength2 = await mr.getTotalMemberRoles();
        assert.equal(mrLength.toNumber() + 1, mrLength2.toNumber(), "Member Role Not Added");
    });
  });