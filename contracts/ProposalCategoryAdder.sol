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

    /// @dev ads the default govBlocks categories and some sub cat to dApps
    function addCat(address _to) public { //solhint-disable-line
        ProposalCategory proposalCategory = ProposalCategory(_to);
        uint[] memory stakeIncentive = new uint[](2);
        uint rs;
        uint[] memory al = new uint[](2);
        uint[] memory alex = new uint[](1);
        uint mv;
        uint ct;
        uint tokenHoldingTime;
        rs = 1;
        mv = 50;
        al[0] = 1;
        al[1] = 2;
        alex[0] = 0;
        ct = 72000;

        stakeIncentive[0] = 0;
        stakeIncentive[1] = 0;
        tokenHoldingTime = 604800;

        proposalCategory.addInitialCategories(
            "Uncategorized",
            rs,
            mv,
            25,
            al,
            ct,
            "QmRnwMshX2L6hTv3SgB6J6uahK7tRgPNfkt91siznLqzQX",
            address(0),
            "MR",
            0,
            stakeIncentive
        );
        proposalCategory.addInitialCategories(
            "Add new member role",
            rs,
            mv,
            25,
            al,
            ct,
            "QmT3sMfqAvTgCkcsdVgiHvMycEWoeoQiD86e4H744pqfhF",
            address(0),
            "MR",
            tokenHoldingTime,
            stakeIncentive
        );
        proposalCategory.addInitialCategories(
            "Update member role",
            rs,
            mv,
            25,
            al,
            ct,
            "QmV55gWxnEBF8reTrVKrhbg5QrwqA65kFhMEFWDnnpphrJ",
            address(0),
            "MR",
            tokenHoldingTime,
            stakeIncentive
        );
        proposalCategory.addInitialCategories(
            "Add new category",
            rs,
            mv,
            25,
            al,
            ct,
            "QmVXcXmr1aXeK3XSvGXAbDmhEQordetU1Z71h1zmbAZXBf",
            address(0),
            "PC",
            tokenHoldingTime,
            stakeIncentive
        );
        proposalCategory.addInitialCategories(
            "Edit category",
            rs,
            mv,
            25,
            al,
            ct,
            "QmXB8fB6LpkWqLjhkNYT3412z439VNyN5tRxPV6JTyEHKu",
            address(0),
            "PC",
            tokenHoldingTime,
            stakeIncentive
        );

        proposalCategory.addInitialCategories(
            "Change dApp Token Proxy",
            rs,
            mv,
            25,
            al,
            ct,
            "QmPR9K6BevCXRVBxWGjF9RV7Pmtxr7D4gE3qsZu5bzi8GK",
            address(0),
            "MS",
            tokenHoldingTime,
            stakeIncentive
        );

        stakeIncentive[0] = uint256(10) ** 18;
        stakeIncentive[1] = uint256(10) ** 18;

        proposalCategory.addInitialCategories(
            "Transfer Ether",
            rs,
            mv,
            25,
            al,
            ct,
            "QmRUmxw4xmqTN6L2bSZEJfmRcU1yvVWoiMqehKtqCMAaTa",
            address(0),
            "PL",
            tokenHoldingTime,
            stakeIncentive
        );
        proposalCategory.addInitialCategories(
            "Transfer Token",
            rs,
            mv,
            25,
            al,
            ct,
            "QmbvmcW3zcAnng3FWgP5bHL4ba9kMMwV9G8Y8SASqrvHHB",
            address(0),
            "PL",
            tokenHoldingTime,
            stakeIncentive
        );

        proposalCategory.addInitialCategories(
            "Add new version",
            rs,
            mv,
            25,
            al,
            ct,
            "QmeMBNn9fs5xYVFVsN8HgupMTfgXdyz4vkLPXakWd2BY3w",
            address(0),
            "MS",
            tokenHoldingTime,
            stakeIncentive
        );
        proposalCategory.addInitialCategories(
            "Add new contract",
            rs,
            mv,
            25,
            al,
            ct,
            "QmWP3P58YcmveHeXqgsBCRmDewTYV1QqeQqBmRkDujrDLR",
            address(0),
            "MS",
            tokenHoldingTime,
            stakeIncentive
        );
        proposalCategory.addInitialCategories(
            "Add new authorized address",
            rs,
            mv,
            25,
            al,
            ct,
            "QmRczxM2yN11th3MB8159rm1qAnk4VSrYYmFQCEXXRUf9Z",
            address(0),
            "SV",
            tokenHoldingTime,
            stakeIncentive
        );
        proposalCategory.addInitialCategories(
            "Upgrade a contract Implementation",
            rs,
            mv,
            25,
            al,
            ct,
            "Qme4hGas6RuDYk9LKE2XkK9E46LNeCBUzY12DdT5uQstvh",
            address(0),
            "MS",
            tokenHoldingTime,
            stakeIncentive
        );
        proposalCategory.addInitialCategories( 
            "Upgrade a contract proxy",
            rs,
            mv,
            25,
            al,
            ct,
            "QmUNGEn7E2csB3YxohDxBKNqvzwa1WfvrSH4TCCFD9DZsg",
            address(0),
            "MS",
            tokenHoldingTime,
            stakeIncentive
        );
        proposalCategory.addInitialCategories( 
            "Resume Proposal",
            rs,
            mv,
            25,
            al,
            ct,
            "QmQPWVjmv2Gt2Dzt1rxmFkHCptFSdtX4VC5g7VVNUByLv1",
            address(0),
            "GD",
            tokenHoldingTime,
            stakeIncentive
        );
        proposalCategory.addInitialCategories( 
            "Pause Proposal",
            rs,
            mv,
            25,
            al,
            ct,
            "QmWWoiRZCmi61LQKpGyGuKjasFVpq8JzbLPvDhU8TBS9tk",
            address(0),
            "GD",
            tokenHoldingTime,
            stakeIncentive
        );
        proposalCategory.addInitialCategories( 
            "Buy GBT in Pool",
            rs,
            mv,
            25,
            al,
            ct,
            "QmUc6apk3aRoHPaSwafo7RkV4XTJaaWS6Q7MogTMqLDyWs",
            address(0),
            "PL",
            tokenHoldingTime,
            stakeIncentive
        );
        proposalCategory.addInitialCategories(
            "External Proposal", 
            rs,
            mv,
            25,
            alex,
            ct,
            "", 
            address(0), 
            "EX",
            tokenHoldingTime,
            stakeIncentive
        );
        proposalCategory.addInitialCategories(
            "Others, not specified",
            rs,
            mv,
            25,
            alex,
            ct,
            "", 
            address(0), 
            "EX",
            tokenHoldingTime,
            stakeIncentive
        );
    }
}