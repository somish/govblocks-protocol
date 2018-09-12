async function getProposalIds(member, gd, sv) {
  let ownerProposals = [];
  let voterProposals = [];
  let voteId;
  const totalProposals = (await gd.getProposalLength()).toNumber();
  ownerProposals.push(0);
  voterProposals.push(0);
  for (let i = 1; i < totalProposals; i++) {
    if ((await gd.getProposalStatus(i)).toNumber() > 2) {
      if (!(await gd.getRewardClaimed(i, member))) ownerProposals.push(i);
      voteId = (await sv.getVoteIdAgainstMember(member, i)).toNumber();
      if (voteId > 0 && !(await sv.rewardClaimed(voteId)))
        voterProposals.push(i);
    }
  }
  return [ownerProposals, voterProposals];
}

module.exports = { getProposalIds };
