const MemberRoles = artifacts.require('MemberRoles');
const catchRevert = require('../helpers/exceptions.js').catchRevert;
let mr;

// addMemberRole tested already
contract('MemberRoles', ([owner, member, other]) => {
  before(() => {
    MemberRoles.deployed().then(instance => {
      mr = instance;
    });
  });

  it('should be initialized with default roles', async function() {
    this.timeout(100000);
    await catchRevert(mr.memberRolesInitiate('0x41', owner, owner));
    const ab = await mr.getMemberRoleNameById.call(1);
    const th = await mr.getMemberRoleNameById(2);

    assert.equal(
      ab[1],
      '0x41647669736f727920426f617264000000000000000000000000000000000000',
      'Advisory Board not created'
    );
    assert.equal(
      th[1],
      '0x546f6b656e20486f6c6465720000000000000000000000000000000000000000',
      'Token Holder not created'
    );
    const roles = await mr.getRoleIdByAddress(owner);

    assert.equal(
      await mr.checkRoleIdByAddress(owner, 1),
      true,
      'Owner not added to AB'
    );
    assert.equal(roles[0].toNumber(), 1, 'Owner not added to AB');
  });

  it('should add a member to a role', async function() {
    this.timeout(100000);
    await mr.updateMemberRole(member, 1, true, 356800000054);
    assert.equal(
      await mr.checkRoleIdByAddress(member, 1),
      true,
      'user not added to AB'
    );
  });

  it('Should check getters', async function() {
    this.timeout(100000);
    const g3 = await mr.getAllAddressByRoleId(1);
    assert.equal(g3[1][0], owner);
    const g4 = await mr.getAllMemberLength(1);
    assert.equal(g4.toNumber(), 2);
    const g5 = await mr.getAllMemberAddressById(1, 0);
    assert.equal(g5, owner);
    const g6 = await mr.getRolesAndMember();
    await mr.changeMasterAddress(); // just for interface, they do nothing
    await mr.updateDependencyAddresses(); // just for interface, they do nothing
  });

  it('Should change validity of member', async function() {
    this.timeout(100000);
    await mr.setRoleValidity(1, true);
    await mr.setValidityOfMember(member, 1, 5);
    const mrs22 = await mr.getAllAddressByRoleId(1);
    const val = await mr.getValidity(member, 1);
    assert.equal(val.toNumber(), 5, 'Validity not updated');
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
    await mr.updateMemberRole(member, 1, false, 0);
    assert.equal(
      await mr.checkRoleIdByAddress(member, 1),
      false,
      'user not removed from AB'
    );
    catchRevert(mr.updateMemberRole(member, 1, false, 0));
  });

  it('Should change can add member', async function() {
    this.timeout(100000);
    await mr.changeCanAddMember(1, member);
    await catchRevert(
      mr.updateMemberRole(member, 1, true, 356854, { from: other })
    );
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
    assert.equal(await mr.checkRoleIdByAddress(owner, 0), true);
  });
});
