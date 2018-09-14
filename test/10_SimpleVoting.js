const SimpleVoting = artifacts.require('SimpleVoting');
const catchRevert = require('../helpers/exceptions.js').catchRevert;
let sv;
const getAddress = require('../helpers/getAddress.js').getAddress;
const initializeContracts = require('../helpers/getAddress.js')
  .initializeContracts;

// proposalVoting, adddSolution, claimReward, closeProposal tested already
contract('Simple Voting', function([owner]) {
  it('Should fetch addresses from master', async function() {
    await initializeContracts();
    address = await getAddress('SV');
    sv = await SimpleVoting.at(address);
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
    await catchRevert(sv.upgrade());
    await catchRevert(sv.addVotingType(owner, 'yo'));
  });
});
