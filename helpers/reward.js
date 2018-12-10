async function getProposalIds(member, gd, gov) {
  let ownerProposals = [];
  let voterProposals = [];
  let voteId;
  let eventData;
  const totalProposals = (await gd.getProposalLength()).toNumber();
  // ownerProposals.push(0);
  // voterProposals.push(0);
  for (let i = 1; i < totalProposals; i++) {
    if ((await gd.getProposalStatus(i)).toNumber() > 2) {
      eventData = (await gov.Vote({from:member, proposalId:i},{ fromBlock:0, toBlock:'latest'}));
      if (voteId > 0 && !(await sv.rewardClaimed(eventData.args.voteId)))
        voterProposals.push(i);
    }
  }
  return voterProposals;
}

module.exports = { getProposalIds };