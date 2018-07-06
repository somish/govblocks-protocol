# GovBlocks
GovBlocks is a multi-factorial governance framework for blockchain applications. 

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. 


### Requirements
```
Node >= 7.6
```


### Installing
Firstly, you need to clone this repo. You can do so by downloading the repo as a zip and unpacking or using the following git command

```
git clone https://github.com/somish/govblocks-protocol.git
```

Now, It's time to install the dependencies.

```
npm install
```
We need to compile the contracts before deploying. We'll be using truffle for that (You can use Remix or solc directly).
```
truffle compile
```
To deploy the smart contracts, you need to set your mnemonic seed in truffle config (You can use remix or mist as well for deploying). To deploy the contracts with truffle on kovan testnet, run
```
truffle migrate --network kovan
```
Your GBTStandardToken and GovBlockMaster contract is live now, you can use these contract to setup the GovBlocks platform and create register dApps using the GUI provided by GovBlocks platform.


### Modularity
GovBlocks is built on the Ethereum blockchain and it uses a modular system for grouping of Ethereum smart contracts, allowing logical components of the system to be upgraded without affecting the other components. Following are the key modules of GovBlocks.


#### Master
Master module of every contract is used to bind all the modules together. It contains addresses of all other contracts and updates them when a new version is added.
Contract:
* [Master.sol]

Some important functions : 
1) addNewVersion : It is used to add new version of all the contracts.
2) switchToRecentVersion : It switches to new verison, updates all the dependency addresses in respective contracts.
3) configureGlobalParameters : It is used to configure global parameters


### Governance
Governance module is used for doing the core governance like submitting proposals.
Contracts:
* [Governance.sol]
* [GovernanceData.sol]

Some important functions : 
1) createProposal : It is used to submit new proposal.
2) createProposalwithSolution : It is used to submit new proposal with a solution.
3) calculateMemberReward : It is used to calculate the reward to be deistributed once the proposal is closed.


#### MemberRoles
MemberRoles module of manages all the member roles. Every member role can have different authorizations
Contract:
* [MemberRoles.sol]

Some important functions : 
1) addNewMemberRole : It is used to add new member role.
2) getAllAddressByRoleId : It returns all member address that have a particular role


#### Pool
Pool of every dApp holds the Ethereum and GBT for distributing the default incentive upon acceptance of a proposal. It is also used to call oraclize to close proposal when the time is over.
Contract:
* [Pool.sol]

Some important functions : 
1) buyPoolGBT : It is used to buy GBT using Ethereum.
2) closeProposalOraclise : Closes Proposal voting using oraclize once the time is over.


### ProposalCategory
ProposalCategory module is used to manage the proposal categories and sub categories. It contains all the category and sub category data.
Contract:
* [ProposalCategory.sol]

Some important functions : 
1) addNewCategory : It is used to add a new category.
2) updateCategory : It updates an exisitng category.
3) addNewSubCategory : It is used to add a new sub category under an existing category.
4) updateSubCategory : It is used to edit an exisitng sub category.


### SimpleVoting
SimpleVoting is a simple VotingType which works when only one solution can be selected for voting. It also helps distribute reward when a proposal is closed.
Contract:
* [SimpleVoting.sol]

Some important functions : 
1) addSolution : It is used to add a solution to a proposal.
2) proposalVoting : It is used for casting votes.
3) closeProposalVote : It moves voting to next phase (if next phase is available)
4) giveRewardAfterFinalDecision : It sets the reward to be distributed. Users can claim these rewards once the proposal is closed.


### Todos

 - Write Tests


   [master.sol]: <https://github.com/somish/govblocks-protocol/blob/master/contracts/Master.sol>
   [Governance.sol]: <https://github.com/somish/govblocks-protocol/blob/master/contracts/Governance.sol>
   [GovernanceData.sol]: <https://github.com/somish/govblocks-protocol/blob/master/contracts/GovernanceData.sol>
   [MemberRoles.sol]: <https://github.com/somish/govblocks-protocol/blob/master/contracts/MemberRoles.sol>
   [Pool.sol]: <https://github.com/somish/govblocks-protocol/blob/master/contracts/Pool.sol>
   [ProposalCategory.sol]: <https://github.com/somish/govblocks-protocol/blob/master/contracts/ProposalCategory.sol>
   [SimpleVoting.sol]: <https://github.com/somish/govblocks-protocol/blob/master/contracts/SimpleVoting.sol>
  