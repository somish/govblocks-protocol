/* Copyright (C) 2017 GovBlocks.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.4.24;

import "./ProposalCategory.sol";

contract ProposalCategoryAdder {

    /// @dev ads the default govBlocks sub categories to dApps
    function addSubC(address _to) public {
        ProposalCategory proposalCategory = ProposalCategory(_to);
        uint[] memory stakeInecntive = new uint[](3); 
        uint8[] memory rewardPerc = new uint8[](3);
        rewardPerc[0] = 10;
        rewardPerc[1] = 20;
        rewardPerc[2] = 70;
        stakeInecntive[0] = 1 ** 18;
        stakeInecntive[1] = 604800;
        stakeInecntive[2] = 1 ** 18;
        proposalCategory.addInitialSubC(
            "Configure parameters",
            "QmW9zZAfeaErTNPVcNhiDNEEo4xp4avqnVbS9zez9GV3Ar",
            3,
            address(0),
            "MS",
            stakeInecntive,
            rewardPerc
        );
        stakeInecntive[2] = 0;
        proposalCategory.addInitialSubC(
            "Transfer Ether",
            "QmRUmxw4xmqTN6L2bSZEJfmRcU1yvVWoiMqehKtqCMAaTa",
            4,
            address(0),
            "PL",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC(
            "Transfer Token",
            "QmbvmcW3zcAnng3FWgP5bHL4ba9kMMwV9G8Y8SASqrvHHB",
            4,
            address(0),
            "PL",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC(
            "Add new version",
            "QmeMBNn9fs5xYVFVsN8HgupMTfgXdyz4vkLPXakWd2BY3w",
            5,
            address(0),
            "MS",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC(
            "Add new contract",
            "QmaPH84hSyoAz1pvzrbfAXdzVFaDyqmKKmCzcmk8LZHgjr",
            5,
            address(0),
            "MS",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC(
            "Add new voting type",
            "QmaPH84hSyoAz1pvzrbfAXdzVFaDyqmKKmCzcmk8LZHgjr",
            5,
            address(0),
            "SV",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC(
            "Add new authorized address",
            "QmaPH84hSyoAz1pvzrbfAXdzVFaDyqmKKmCzcmk8LZHgjr",
            5,
            address(0),
            "SV",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC(
            "Toggle Proposal",
            "QmaPH84hSyoAz1pvzrbfAXdzVFaDyqmKKmCzcmk8LZHgjr",
            6,
            address(0),
            "GD",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC(
            "Change dApp Token Proxy",
            "QmW9zZAfeaErTNPVcNhiDNEEo4xp4avqnVbS9zez9GV3Ar",
            3,
            address(0),
            "MS",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC(
            "dApp Token locking support",
            "QmW9zZAfeaErTNPVcNhiDNEEo4xp4avqnVbS9zez9GV3Ar",
            3,
            address(0),
            "MS",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC(
            "Others, not specified",
            "", 
            7, 
            address(0), 
            "EX",
            stakeInecntive,
            rewardPerc
        );
    }
}