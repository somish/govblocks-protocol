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

    ProposalCategory internal proposalCategory;

    function addSubC(address _to) public {
        proposalCategory = ProposalCategory(_to);
        uint[] memory stakeInecntive = new uint[](3); 
        uint8[] memory rewardPerc = new uint8[](3);
        stakeInecntive[0] = 0;
        stakeInecntive[1] = 604800;
        stakeInecntive[2] = 0;
        rewardPerc[0] = 10;
        rewardPerc[1] = 20;
        rewardPerc[2] = 70;
        proposalCategory.addInitialSubC(
            "Add new member role",
            "QmRnwMshX2L6hTv3SgB6J6uahK7tRgPNfkt91siznLqzQX",
            1,
            address(0),
            "MR",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC(
            "Update member role",
            "QmbsXSZ3rNPd8mDizVBV33GVg1ThveUD5YnM338wisEJyd",
            1,
            address(0),
            "MR",
            stakeInecntive,
            rewardPerc
        );
        stakeInecntive[0] = 1 ** 18;
        proposalCategory.addInitialSubC(
            "Add new category",
            "QmNazQ3hQ5mssf8KAYkjxwVjwZvM9XjZgrJ1kf3QUmprCB",
            2,
            address(0),
            "PC",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC(
            "Edit category",
            "QmYWSuy3aZFK1Yavpq5Pm89rg6esyZ8rn5CNf6PdgJCpR6",
            2,
            address(0),
            "PC",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC(
            "Add new sub category",
            "QmeyPccQzMTNxSavJp4dL1J88zzb4xNESn5wLTPzqMFFJX",
            2,
            address(0),
            "PC",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC(
            "Edit sub category",
            "QmVeSBUghB71WHhnT8tXajSctnfz1fYx6fWXc9wXHJ8r2p",
            2,
            address(0),
            "PC",
            stakeInecntive,
            rewardPerc
        );
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
            "MS",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC(
            "Others, not specified",
            "", 
            4, 
            address(0), 
            "EX",
            stakeInecntive,
            rewardPerc
        );
    }
}