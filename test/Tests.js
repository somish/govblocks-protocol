var MemberRoles = artifacts.require("MemberRoles");
var GovBlocksMaster = artifacts.require("GovBlocksMaster");
var Master = artifacts.require("Master");
var GBTStandardToken = artifacts.require("GBTStandardToken");
var Governance = artifacts.require("Governance");
var GovernanceData = artifacts.require("GovernanceData");
var MemberRoles = artifacts.require("MemberRoles");
var Pool = artifacts.require("Pool");
var ProposalCategory = artifacts.require("ProposalCategory");
var SimpleVoting = artifacts.require("SimpleVoting");
var EventCaller = artifacts.require("EventCaller");
var gbts;
var ec;
var gbm;
var gd;
var mr;
var pc;
var sv;
var gv;
var pl;
var add = [];
var ms;
const json = require('./../build/contracts/Master.json');
const bytecode = json['bytecode'];

describe('Deploy GovBlocks', function() {
  it("Should deploy gbm", async function () {
    this.timeout(100000);
    gbts = await GBTStandardToken.new();
    ec = await EventCaller.new();
    gbm = await GovBlocksMaster.new();
    await gbm.govBlocksMasterInit(gbts.address, ec.address);
    await gbm.setMasterByteCode(bytecode);
    assert.equal(await gbm.gbtAddress(), gbts.address, "GBM not initialized");
  });
  it("Should create a new dApp", async function () {
    this.timeout(100000);
    await gbm.addGovBlocksUser("0x41", gbts.address, "descHash");
    gd = await GovernanceData.new();
    mr = await MemberRoles.new();
    pc = await ProposalCategory.new();
    sv = await SimpleVoting.new();
    gv = await Governance.new();
    pl = await Pool.new();
    add.push(gd.address);
    add.push(mr.address);
    add.push(pc.address);
    add.push(sv.address);
    add.push(gv.address);
    add.push(pl.address);
    let mad = await gbm.getDappMasterAddress("0x41");
    ms = await Master.at(mad);
    await ms.addNewVersion(add);
    assert.equal(await ms.versionLength(), 1, "dApp version not created");
  });
});


