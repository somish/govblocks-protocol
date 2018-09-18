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
    function addCat(address _to) public { //solhint-disable-line
        ProposalCategory proposalCategory = ProposalCategory(_to);
        uint[] memory stakeInecntive = new uint[](3); 
        uint8[] memory rewardPerc = new uint8[](3);

        stakeInecntive[0] = 0;
        stakeInecntive[1] = 604800;
        stakeInecntive[2] = 0;
        rewardPerc[0] = 10;
        rewardPerc[1] = 20;
        rewardPerc[2] = 70;

        proposalCategory.addDefaultCategories();

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
            "QmZAjwUTsMdhhTHAL87RHFch7nq8op6MnEUXiud8SjecT9",
            1,
            address(0),
            "MR",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC(
            "Add new category",
            "QmQ9EzwyUsLdkyayJsFU6iig1zPD6FdqLQ3ZF1jETL1tT2",
            2,
            address(0),
            "PC",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC(
            "Edit category",
            "QmY31mwTHmgd7SL2shQeX9xuhnrNXpNNhTXb3ZyyXJJTWL",
            2,
            address(0),
            "PC",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC(
            "Add new sub category",
            "QmXX2XxNjZeoEN2iiMdgWY3Xpo1XpGs9opD7SJnuotXyBu",
            2,
            address(0),
            "PC",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC(
            "Edit sub category",
            "Qmd1yPsk9cfDN447AQVHMEnxTxx693VhnAXFeo3Q3JefHJ",
            2,
            address(0),
            "PC",
            stakeInecntive,
            rewardPerc
        );

        rewardPerc[0] = 30;
        rewardPerc[1] = 30;
        rewardPerc[2] = 40;

        proposalCategory.addInitialSubC(
            "Configure parameters",
            "QmW9zZAfeaErTNPVcNhiDNEEo4xp4avqnVbS9zez9GV3Ar",
            3,
            address(0),
            "GD",
            stakeInecntive,
            rewardPerc
        );

        proposalCategory.addInitialSubC( //Update
            "Change dApp Token Proxy",
            "QmPR9K6BevCXRVBxWGjF9RV7Pmtxr7D4gE3qsZu5bzi8GK",
            3,
            address(0),
            "MS",
            stakeInecntive,
            rewardPerc
        );

        stakeInecntive[0] = 10 ** 18;
        stakeInecntive[1] = 604800;
        stakeInecntive[2] = 10 ** 18;

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
            "Upgrade a contract Implementation",
            "Qme4hGas6RuDYk9LKE2XkK9E46LNeCBUzY12DdT5uQstvh",
            5,
            address(0),
            "MS",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC( 
            "Upgrade a contract proxy",
            "QmUNGEn7E2csB3YxohDxBKNqvzwa1WfvrSH4TCCFD9DZsg",
            5,
            address(0),
            "MS",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC( 
            "Resume Proposal",
            "QmQPWVjmv2Gt2Dzt1rxmFkHCptFSdtX4VC5g7VVNUByLv1",
            5,
            address(0),
            "GD",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC( 
            "Pause Proposal",
            "QmWWoiRZCmi61LQKpGyGuKjasFVpq8JzbLPvDhU8TBS9tk",
            6,
            address(0),
            "GD",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC( 
            "Buy GBT in Pool",
            "QmUc6apk3aRoHPaSwafo7RkV4XTJaaWS6Q7MogTMqLDyWs",
            6,
            address(0),
            "PL",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC(
            "External Proposal", //19
            "", 
            7, 
            address(0), 
            "EX",
            stakeInecntive,
            rewardPerc
        );
        proposalCategory.addInitialSubC(
            "Others, not specified",
            "", 
            8, 
            address(0), 
            "EX",
            stakeInecntive,
            rewardPerc
        );
        //21 sub cat len, 20 sub cat id
    }
}