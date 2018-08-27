const MemberRoles = artifacts.require('MemberRoles');
const catchRevert = require('../helpers/exceptions.js').catchRevert;
let mr;

contract('MemberRoles', function([owner, member, other]) {
  before(() => {
    MemberRoles.deployed().then(instance => {
      mr = instance;
    });
  });

  it('should be initialized', async function() {
    await catchRevert(mr.memberRolesInitiate('0x41', owner, owner));
  });

  it('should have AB role defined', async function() {
    const ab = await mr.getMemberRoleNameById.call(1);
    assert.equal(
      ab[1],
      '0x41647669736f727920426f617264000000000000000000000000000000000000',
      'Advisory Board not created'
    );
  });

  it('should have Token Holder role defined', async function() {
    const th = await mr.getMemberRoleNameById(2);
    assert.equal(
      th[1],
      '0x546f6b656e20486f6c6465720000000000000000000000000000000000000000',
      'Token Holder not created'
    );
  });

  it('should have added owner to AB', async function() {
    const roles = await mr.getRoleIdByAddress(owner);
    assert.equal(
      await mr.checkRoleIdByAddress(owner, 1),
      true,
      'Owner not added to AB'
    );
    assert.equal(roles[0].toNumber(), 1, 'Owner not added to AB');
  });

  it('should add a member to a role', async function() {
    await mr.updateMemberRole(member, 1, true, 356800000054);
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
    const g5 = await mr.getMemberAddressById(1, 0);
    assert.equal(g5, owner);
  });

  it('Should fetch all address and role id', async function() {
    const g6 = await mr.getRolesAndMember();
    assert.equal(g6[0].length, 3);
  });

  it('Should follow the upgradable interface', async function() {
    await mr.changeMasterAddress(); // just for interface, they do nothing
    await mr.updateDependencyAddresses(); // just for interface, they do nothing
  });

  it('Should change validity of role', async function() {
    await mr.setRoleValidity(1, true);
    assert.equal(await mr.getRoleValidity(1), true);
  });

  it('Should change validity of member', async function() {
    await mr.setValidityOfMember(member, 1, 5);
    const mrs22 = await mr.getAllAddressByRoleId(1);
    const val = await mr.getValidity(member, 1);
    assert.equal(val.toNumber(), 5, 'Validity not updated');
  });

  it('Should not list expired member as valid', async function() {
    await mr.updateMemberRole(member, 1, true, 1);
    assert.equal(
      await mr.checkRoleIdByAddress(member, 1),
      false,
      'user incorrectly added to AB'
    );
    await mr.updateMemberRole(member, 1, true, 356000000000854);
    assert.equal(
      await mr.checkRoleIdByAddress(member, 1),
      true,
      'user not added to AB'
    );
  });

  it('Should be able to remove member from a role', async function() {
    await mr.updateMemberRole(member, 1, false, 0);
    assert.equal(
      await mr.checkRoleIdByAddress(member, 1),
      false,
      'user not removed from AB'
    );
    catchRevert(mr.updateMemberRole(member, 1, false, 0));
  });

  it('Should not allow unauthorized people to update member roles', async function() {
    await mr.changeCanAddMember(1, owner);
    await catchRevert(
      mr.updateMemberRole(member, 1, true, 356854, { from: other })
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
    assert.equal(mrs[0], 1);
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
