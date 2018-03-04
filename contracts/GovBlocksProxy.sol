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
import "./memberRoles.sol";
import "./governanceData.sol";
import "./ProposalCategory.sol";

contract GovBlocksProxy
{
    governanceData GD;
    memberRoles MR;
    ProposalCategory PC;
    address PCAddress;
    address GDAddress;
    address MRAddress;

    function changeAllContractAddress(address _PCContractAddress,address _GDContractAddress, address _MRContractAddress)
    {
        PCAddress = _PCContractAddress;
        GDAddress = _GDContractAddress;
        MRAddress = _MRContractAddress;
    }

    // function addNewMemberRoleGBP(uint _proposalId)
    // {
    //     GD=governanceData(GDAddress);
    //     MR=memberRoles(MRAddress);
    //     PC=ProposalCategory(PCAddress);
        
    //     uint category = GD.getProposalCategory(_proposalId);
    //     bytes32 parameterName = PC.getCategoryParamNameBytes(category,0);
    //     uint finalOptionIndex = GD.getProposalFinalOption(_proposalId);

    //     bytes32 roleName = GD.getParameterDetailsById2(_proposalId,parameterName,finalOptionIndex);
    //     MR.addNewMemberRole(roleName,"");
    // }

    // function assignMemberRoleGBP(uint _proposalId)
    // {
    //     GD=governanceData(GDAddress);
    //     MR=memberRoles(MRAddress);
    //     PC=ProposalCategory(PCAddress);

    //     uint category = GD.getProposalCategory(_proposalId);
    //     uint8 paramInt; uint8 paramBytes32; uint8 paramAddress;
    //     (,,,,paramInt,paramBytes32,paramAddress,,) = PC.getCategoryDetails(category);
    //     uint finalOptionIndex = GD.getProposalFinalOption(_proposalId);

    //     bytes32 parameterNameUint = PC.getCategoryParamNameUint(category,0);
    //     uint roleIdToAssign = GD.getParameterDetailsById1(_proposalId,parameterNameUint,finalOptionIndex);

    //     bytes32 parameterNameBytes = PC.getCategoryParamNameUint(category,0);
    //     address memberAddress = GD.getParameterDetailsById3(_proposalId,parameterNameBytes,finalOptionIndex);

    //     MR.assignMemberRole(memberAddress,roleIdToAssign);
    // }

    // function removeMemberRoleGBP(uint _proposalId)
    // {
    //     GD=governanceData(GDAddress);
    //     MR=memberRoles(MRAddress);
    //     PC=ProposalCategory(PCAddress);

    //     uint category = GD.getProposalCategory(_proposalId);
    //     uint8 paramInt; uint8 paramBytes32; uint8 paramAddress;
    //     (,,,,paramInt,paramBytes32,paramAddress,,) = PC.getCategoryDetails(category);
    //     uint finalOptionIndex = GD.getProposalFinalOption(_proposalId);

    //     bytes32 parameterNameUint = PC.getCategoryParamNameUint(category,0);
    //     uint removeFromId = GD.getParameterDetailsById1(_proposalId,parameterNameUint,finalOptionIndex);

    //     bytes32 parameterNameBytes = PC.getCategoryParamNameUint(category,0);
    //     address memberAddress = GD.getParameterDetailsById3(_proposalId,parameterNameBytes,finalOptionIndex);

    //     MR.removeMember(memberAddress,removeFromId);
    // } 
}
