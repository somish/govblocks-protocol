const SimpleVoting = artifacts.require('SimpleVoting');
const GovernanceData = artifacts.require('GovernanceData');
const catchRevert = require('../helpers/exceptions.js').catchRevert;
let sv;
const nullAddress = 0x0000000000000000000000000000000000000000;

// proposalVoting, adddSolution, claimReward, closeProposal tested already
contract('Simple Voting', function([owner]) {
  before(function() {
    SimpleVoting.deployed()
      .then(function(instance) {
        sv = instance;
        return GovernanceData.deployed();
      })
      .then(function(instance) {
        gd = instance;
      });
  });

  it('Should be initialized', async function() {
    await catchRevert(sv.simpleVotingInitiate());
  });

  it('Should check getters', async function() {
    this.timeout(100000);
    let g1 = await sv.votingTypeName();
    let g2 = await sv.constructorCheck();
    let g3 = await sv.dAppName();
    let g4 = await sv.getAllVoteIdsByAddress(owner);
    let g5 = await sv.getSolutionByVoteId(0);
    let g6 = await sv.getVoteIdAgainstMember(owner, 0);
    let g7 = await sv.getVoterAddress(0);
    let g8 = await sv.getAllVoteIdsByProposalRole(0, 1);
    let g9 = await sv.getVoteValue(0);
    let g10 = await sv.allVotesTotal();
    let g11 = await sv.getSolutionByVoteIdAndIndex(0, 0);
    let g12 = await sv.getVoteDetailById(0);
    await catchRevert(sv.getSolutionByVoteIdAndIndex(0, 1));
    assert.equal(g2, true, 'Not initialized');
    // TODO verify the data returned
  });

  it('Should not allow self function to be called by others', async function() {
    this.timeout(100000);
    await catchRevert(sv.addAuthorized(owner));
    await catchRevert(sv.addVotingType(owner, 'yo'));
  });
});
