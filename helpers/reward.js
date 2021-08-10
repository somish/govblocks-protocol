async function getProposalIds(member, gov) {
  let ownerProposals = [];
  let voterProposals = [];
  let voteId;
  const totalProposals = (await gov.getProposalLength()).toNumber();
  // ownerProposals.push(0);
  // voterProposals.push(0);
  for (let i = 1; i < totalProposals; i++) {
    let data = await gov.proposal(i);
    if (data[2].toNumber() > 2) {
      voteId = await gov.addressProposalVote(member, i);
      if (voteId > 0 && !(await gov.rewardClaimed(voteId)))
        voterProposals.push(i);
    }
  }
  return voterProposals;
}

module.exports = { getProposalIds };
