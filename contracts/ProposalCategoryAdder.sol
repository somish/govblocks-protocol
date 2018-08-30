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
    function addSubC(address _to) public { //solhint-disable-line
        ProposalCategory proposalCategory = ProposalCategory(_to);
        uint[] memory stakeInecntive = new uint[](3); 
        uint8[] memory rewardPerc = new uint8[](3);
        rewardPerc[0] = 30;
        rewardPerc[1] = 30;
        rewardPerc[2] = 40;
        stakeInecntive[0] = 10 ** 5;
        stakeInecntive[1] = 604800;
        stakeInecntive[2] = 10 ** 5;
        proposalCategory.addInitialSubC(
            "Configure parameters",
            "QmW9zZAfeaErTNPVcNhiDNEEo4xp4avqnVbS9zez9GV3Ar",
            3,
            address(0),
            "MS",
            stakeInecntive,
            rewardPerc
        );
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
        stakeInecntive[2] = 0;
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
            "QmWP3P58YcmveHeXqgsBCRmDewTYV1QqeQqBmRkDujrDLR",
            5,
            address(0),
            "MS",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC(
            "Add new voting type",
            "QmeWbgsSkeHUL9PWwugnvbnuvSr711CDpmkksB5dEyMFWj",
            5,
            address(0),
            "SV",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC(
            "Add new authorized address",
            "QmRczxM2yN11th3MB8159rm1qAnk4VSrYYmFQCEXXRUf9Z",
            5,
            address(0),
            "SV",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC(
            "Pause Proposal",
            "QmS5SrwX6J8Cfhp3LAb6N54KYDc55hpnLdFgG6eCPkGvQx",
            6,
            address(0),
            "GD",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC(
            "Unpause Proposal",
            "QmS5SrwX6J8Cfhp3LAb6N54KYDc55hpnLdFgG6eCPkGvQx",
            6,
            address(0),
            "GD",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC(
            "Change dApp Token Proxy",
            "QmWqSFWYbmQYS9wqs7cvHXdDDGXJ8wtUv9h2w3nxbjDKUb",
            3,
            address(0),
            "MS",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC(
            "dApp Token locking support",
            "QmWfqjytQ4Qx3p4BJMbAUUMC6yQHcMqc4eMj5RaY4MbJQe",
            3,
            address(0),
            "GD",
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