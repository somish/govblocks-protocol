const Governance = artifacts.require('Governance');
const GovernanceData = artifacts.require('GovernanceData');
const catchRevert = require('../helpers/exceptions.js').catchRevert;
const encode = require('../helpers/encoder.js').encode;
let gd;
let gv;

contract('Governance', function([owner]) {

  before(function() {
    Governance.deployed().then(function(instance) {
      gv = instance;
      return GovernanceData.deployed();
    }).then(function(instance) {
      gd = instance;
    });
  });

  it('Should create an uncategorized proposal', async function() {
    this.timeout(100000);
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
    await gv.createProposal('Add new member', 'Add new member', 'Addnewmember', 0, 0);
    p2 = await gd.getAllProposalIdsLengthByAddress(owner);
    assert.equal(p1.toNumber() + 1, p2.toNumber(), 'Proposal not created');
  });

  it('Should categorize the proposal', async function() {
    this.timeout(100000);
    p = await gd.getAllProposalIdsLengthByAddress(owner);
    p = p.toNumber() - 1;
    await gv.categorizeProposal(p, 1, 0);
    let category = await gd.getProposalCategory(p);
    assert.equal(category.toNumber(), 1, 'Category not set properly');
  });

  it('Should submit proposal with solution', async function() {
    this.timeout(100000);
    let actionHash = encode('addNewMemberRole(bytes32,string,address,bool)', '0x41647669736f727920426f617265000000000000000000000000000000000000', 'New member role', owner, false);
    p1 = await gd.getAllProposalIdsLengthByAddress(owner);
    await gv.submitProposalWithSolution(p1.toNumber() - 1, 'Addnewmember', actionHash);
    await catchRevert(gv.submitProposalWithSolution(p1.toNumber() - 1, 'Addnewmember', actionHash));
    let remainingTime = await gv.getMaxCategoryTokenHoldTime(1);
    await assert.isAtLeast(remainingTime.toNumber(), 1, 'Remaining time not set');
    remainingTime = await gv.getRemainingClosingTime(p1.toNumber() - 1, 0);
    await assert.isAtLeast(remainingTime.toNumber(), 1, 'Remaining time not set');
  });
  
  it('Should check getters', async function() {
    this.timeout(100000);
    let g1 = await gv.getMemberDetails(owner);
    let g2 = await gv.getSolutionIdAgainstAddressProposal(owner, 0);
    let g3 = await gv.getAllVoteIdsLengthByProposal(0);
    let g4 = await gv.master();
    // TODO verify the data returned
  });
});