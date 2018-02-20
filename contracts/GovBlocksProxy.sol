/* Copyright (C) 2017 NexusMutual.io

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


pragma solidity ^0.4.8;
import "./MemberRoles.sol";
import "./GovernanceData.sol";

contract GovBlocksProxy
{
    GovernanceData GD;
    MemberRoles MR;
    address GDAddress;
    address MRAddress;

    function changeAllContractAddress(address _GDContractAddress, address _MRContractAddress)
    {
        GDAddress = _GDContractAddress;
        MRAddress = _MRContractAddress;
    }

    function addNewMemberRoleGBP(uint _proposalId)
    {
        GD=GovernanceData(GDAddress);
        MR=MemberRoles(MRAddress);

        bytes32[] bytesParam;
        (,,bytesParam,addressParam) = GD.getProposalOptionWon(_proposalId);

        bytes32 roleName = bytesParam[0];
        uint finalVerdict;
        (,,,,finalVerdict,) = GD.getProposalDetailsById2(_proposalId);
        MR.addNewMemberRole(roleName,GD.getOptionDescByProposalId(_proposalId,finalVerdict));
    }
}
