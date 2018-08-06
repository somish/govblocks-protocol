pragma solidity 0.4.24;

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  modifier restricted() {
    _;
  }

  constructor() public {
  }

  function setCompleted(uint completed) public restricted {
  }

  function upgrade(address new_address) public restricted {
  }
}