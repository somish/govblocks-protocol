const MemberRoles = artifacts.require('MemberRoles');
const getAddress = require('../helpers/getAddress.js').getAddress;
const initializeContracts = require('../helpers/getAddress.js')
  .initializeContracts;
const catchRevert = require('../helpers/exceptions.js').catchRevert;
let mr;
let address;

contract('MemberRoles', function([owner, member, other]) {
  it('should be initialized', async function() {
    await initializeContracts(owner);
    address = await getAddress('MR');
    mr = await MemberRoles.at(address);
    await catchRevert(mr.memberRolesInitiate('0x41', owner, owner));
  });

  it('should have added initial member roles', async function() {
    const ab = await mr.memberRoleLength.call();
    assert.equal(
      ab,
      3,
      'Initial member roles not created'
    );
  });

  it('should have added owner to AB', async function() {
    const roles = await mr.getRoleIdByAddress(owner);
    assert.equal(
      await mr.checkRoleIdByAddress(owner, 1),
      true,
      'Owner not added to AB'
    );
    assert.equal(
      await mr.checkRoleIdByAddress(member, 1),
      false,
      'user added to AB incorrectly'
    );
    assert.equal(roles[0].toNumber(), 1, 'Owner added to AB');
  });

  it('should add a member to a role', async function() {
    await mr.updateMemberRole(member, 1, true);
    assert.equal(
      await mr.checkRoleIdByAddress(member, 1),
      true,
      'user not added to AB'
    );
  });

  it('Should fetch all address by role id', async function() {
    const g3 = await mr.getAllAddressByRoleId(1);
    assert.equal(g3[1][0], owner);
  });

  it('Should fetch total number of members by role id', async function() {
    const g4 = await mr.getAllMemberLength(1);
    assert.equal(g4.toNumber(), 2);
  });

  it('Should fetch address by role id and index', async function() {
    const g5 = await mr.getMemberAddressByRoleAndIndex(1, 0);
    assert.equal(g5, owner);
  });

  it('Should fetch member count of all roles', async function() {
    const g6 = await mr.getMemberLengthForAllRoles();
    assert.equal(g6.length, 3);
    assert.equal(g6[0],0);
    assert.equal(g6[1],2);
  });

  it('Should follow the upgradable interface', async function() {
    await mr.changeMasterAddress(owner); // just for interface, they do nothing
    await mr.updateDependencyAddresses(); // just for interface, they do nothing
  });

  it('Should not list invalid member as valid', async function() {
    var a = await mr.checkRoleIdByAddress(member, 1);
    await mr.updateMemberRole(member, 1, false);
    assert.equal(
      await mr.checkRoleIdByAddress(member, 1),
      false,
      'user incorrectly added to AB'
    );
    await mr.updateMemberRole(member, 1, true);
    assert.equal(
      await mr.checkRoleIdByAddress(member, 1),
      true,
      'user not added to AB'
    );
  });

  it('Should be able to remove member from a role', async function() {
    await mr.updateMemberRole(member, 1, false);
    assert.equal(
      await mr.checkRoleIdByAddress(member, 1),
      false,
      'user not removed from AB'
    );
    catchRevert(mr.updateMemberRole(member, 1, false));
  });

  it('Should not allow unauthorized people to update member roles', async function() {
    await mr.changeCanAddMember(1, owner);
    await catchRevert(
      mr.updateMemberRole(member, 1, true, { from: other })
    );
  });

  it('Should change authorizedAddress when rquested by authorizedAddress', async function() {
    await mr.changeCanAddMember(1, member);
    assert.equal(
      await mr.getAuthrizedMemberAgainstRole(1),
      member,
      'Authorized address not changed'
    );
  });

  it('Should get proper Roles', async () => {
    const mrs = await mr.getRoleIdByAddress(owner);
    assert.equal(
      await mr.checkRoleIdByAddress(owner, 1),
      true,
      'Owner not added to AB'
    );
    assert.equal(mrs[0].toNumber(), 1);
    const mrs2 = await mr.getRoleIdByAddress(other);
  });

  it('Should allow anyone to be of member role 0', async () => {
    assert.equal(await mr.checkRoleIdByAddress(owner, 0), true);
  });

  it('Should check if a user holds dApp token', async () => {
    assert.equal(await mr.checkRoleIdByAddress(owner, 2), true);
    assert.equal(await mr.checkRoleIdByAddress(other, 2), false);
  });
});
