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
    
pragma solidity ^0.4.8;

import "./VotingType.sol";
import "./Governance.sol";
import "./ProposalCategory.sol";
import "./GBTStandardToken.sol";
import "./GovBlocksMaster.sol";
import "./governanceData.sol";
import "./Master.sol";

contract GBTController 
{
    using SafeMath for uint;
    address public GBMAddress;
    address public owner;
    address M1Address;
    address GBTStandardTokenAddress;
    governanceData GD;
    Master MS;
    GovBlocksMaster GBM;
    GBTStandardToken GBTS;
    VotingType VT;
    Governance G1;
    ProposalCategory PC;
    uint public tokenPrice;
    uint public actual_amount;

    modifier onlyGBM
    {
        require(msg.sender == GBMAddress);
        _;
    }
    
    function GBTController(address _GBMAddress) 
    {
        owner = msg.sender;
        tokenPrice = 1*10**15;
        GBMAddress = _GBMAddress;
    }

    function changeGBTtokenAddress(address _Address) onlyGBM
    {
        GBTStandardTokenAddress = _Address;
    }

    function changeGBMAddress(address _GBMAddress) onlyGBM
    {
        GBMAddress = _GBMAddress;
    }

    function transferGBT(address _to, uint256 _value,string _description) 
    {
        GBTS=GBTStandardToken(GBTStandardTokenAddress);

        require(_value <= GBTS.balanceOf(address(this)));
        GBTS.addInBalance(_to,_value);
        GBTS.subFromBalance(address(this),_value);
        GBTS.callTransferGBTEvent(address(this), _to, _value, _description);
    }
    
    // function receiveGBT(address _from,uint _value, string _description) 
    // {
    //     GBTS=GBTStandardToken(GBTStandardTokenAddress);

    //     require(_value <= GBTS.balanceOf(_from));
    //     GBTS.addInBalance(address(this),_value);
    //     GBTS.subFromBalance(_from,_value);
    //     GBTS.callTransferGBTEvent(_from, address(this), _value, _description);
    // }  

     function receiveGBT(uint _value, string _description) internal
    {
        GBTS=GBTStandardToken(GBTStandardTokenAddress);

        require(_value <= GBTS.balanceOf(msg.sender));
        GBTS.addInBalance(address(this),_value);
        GBTS.subFromBalance(msg.sender,_value);
        GBTS.callTransferGBTEvent(msg.sender, address(this), _value, _description);
    }  
    
    function buyTokenGBT(address _to) payable 
    {
        GBTS=GBTStandardToken(GBTStandardTokenAddress);
        actual_amount = SafeMath.mul(SafeMath.div(msg.value,tokenPrice),10**GBTS.decimals());         
        rewardToken(_to,actual_amount);
    }

    function rewardToken(address _to,uint _amount) internal  
    {
        GBTS=GBTStandardToken(GBTStandardTokenAddress);
        GBTS.addInBalance(_to,_amount);
        GBTS.addInTotalSupply(_amount);
        GBTS.callTransferGBTEvent(GBTStandardTokenAddress, _to, _amount, "GBT Purchased");
    }

    function changeTokenPrice(uint _price)
    {
        uint _tokenPrice = _price;
        tokenPrice = _tokenPrice;
    }

    function getTokenPrice() constant returns(uint)
    {
        return tokenPrice;
    }

    function setTokenHoldingTime(uint _newValidity)
    {
        tokenHoldingTime = _newValidity;
    }

   function openProposalForVoting(bytes32 _gbUserName,uint _proposalId,uint _TokenAmount) public
   {
        GBM=GovBlocksMaster(GBMAddress);
        GBTS=GBTStandardToken(GBTStandardTokenAddress);
        address master = GBM.getDappMasterAddress(_gbUserName); address G1Address;address GDAddress;
        MS=Master(master);
        uint versionNo = MS.versionLength()-1; 
        (,G1Address) = MS.allContractVersions(versionNo,8);
        (,GDAddress) = MS.allContractVersions(versionNo,1);
        G1=Governance(G1Address);
        GD=governanceData(GDAddress);

        // receiveGBT(_TokenAmount,"Payable GBT Stake to submit proposal for voting");
        // receiveGBT(GD.getProposalIncentive(_proposalId),"Dapp incentive to be distributed in GBT");
        // G1.setProposalValue(_proposalId,_TokenAmount);

        GBTS.lockMemberToken(_gbUserName,_proposalId,_TokenAmount);
        uint depositAmount = SafeMath.div(SafeMath.mul(_TokenAmount,GD.depositPercProposal()),100);
        uint finalAmount = depositAmount + GD.getDepositTokensByAddress(msg.sender,_proposalId);
        GD.setDepositTokens(msg.sender,_proposalId,finalAmount,'P');
        GD.setProposalStake(_proposalId,_memberStake);
        G1.openProposalForVoting(_proposalId,msg.sender,GD.getProposalCategory(_proposalId));
   }

   function createProposalwithOption(bytes32 _gbUserName,string _proposalDescHash,uint _votingTypeId,uint8 _categoryId,uint _TokenAmount,string _optionHash) public
   {
        GBM=GovBlocksMaster(GBMAddress);

        address master = GBM.getDappMasterAddress(_gbUserName); address G1Address;address PCAddress;
        MS=Master(master);
        uint versionNo = MS.versionLength()-1; 
        (,G1Address) = MS.allContractVersions(versionNo,8);
        (,PCAddress) = MS.allContractVersions(versionNo,3);
        PC=ProposalCategory(PCAddress);
        G1=Governance(G1Address); 

        receiveStakeInGbt(_TokenAmount,PC.getCatIncentive(_categoryId));
        G1.createProposalwithOption(_proposalDescHash,msg.sender,_TokenAmount,_votingTypeId,_categoryId,_optionHash);
   }

   function submitProposalWithOption(bytes32 _gbUserName,uint _proposalId,uint _TokenAmount,string _optionHash) public
   {
        GBM=GovBlocksMaster(GBMAddress);

        address master = GBM.getDappMasterAddress(_gbUserName); address G1Address;address PCAddress;
        MS=Master(master);
        uint versionNo = MS.versionLength()-1; 
        (,G1Address) = MS.allContractVersions(versionNo,8);
        (,PCAddress) = MS.allContractVersions(versionNo,3);
        PC=ProposalCategory(PCAddress);
        G1=Governance(G1Address);

        receiveStakeInGbt(_TokenAmount,GD.getProposalIncentive(_proposalId));
        G1.submitProposalWithOption(_proposalId,msg.sender,_TokenAmount,_optionHash);     
    }

    function receiveStakeInGbt(uint _TokenAmount,uint _Incentive) internal
    {
        // receiveGBT(gbtTransfer,"Payable GBT Stake to submit proposal for voting");
        // receiveGBT(amount,"Payable GBT Stake for adding solution against proposal");
        // receiveGBT(_Incentive,"Dapp incentive to be distributed in GBT");

        uint gbtTransfer = SafeMath.div(_TokenAmount,2); uint depositAmount;uint finalAmount;
        uint amount = _TokenAmount - gbtTransfer;

        GBTS.lockMemberToken(_gbUserName,_proposalId,gbtTransfer);
        depositAmount = ((gbtTransfer*GD.depositPercProposal())/100);
        finalAmount = depositAmount + GD.getDepositTokensByAddress(msg.sender,_proposalId);
        GD.setDepositTokens(msg.sender,_proposalId,finalAmount,'P');

        GBTS.lockMemberToken(_gbUserName,_proposalId,amount);
        depositAmount = ((amount*GD.depositPercOption())/100);
        finalAmount = depositAmount + GD.getDepositTokensByAddress(msg.sender,_proposalId);
        GD.setDepositTokens(msg.sender,_proposalId,finalAmount,'S');
    }

    function initiateVerdictOption(bytes32 _gbUserName,uint _proposalId,uint _GBTPayableTokenAmount,string _optionHash,uint _dateAdd) public
    {
        GBM=GovBlocksMaster(GBMAddress);
        GBTS=GBTStandardToken(GBTStandardTokenAddress);

        address master = GBM.getDappMasterAddress(_gbUserName); address GDAddress;address PCAddress; uint finalAmount;
        MS=Master(master);
        uint versionNo = MS.versionLength()-1; 
        (,GDAddress) = MS.allContractVersions(versionNo,1);
        (,PCAddress) = MS.allContractVersions(versionNo,3);
        PC=ProposalCategory(PCAddress);
        GD=governanceData(GDAddress);

        GBTS.lockMemberToken(_gbUserName,_proposalId,gbtTransfer);
        uint depositAmount = ((gbtTransfer*GD.depositPercOption())/100);
        finalAmount = depositAmount + GD.getDepositTokensByAddress(msg.sender,_proposalId);
        GD.setDepositTokens(msg.sender,_proposalId,finalAmount,'S');

        VT=VotingType(GD.getProposalVotingType(_proposalId));
        VT.initiateVerdictOption(_proposalId,msg.sender,_GBTPayableTokenAmount,_optionHash,_dateAdd);

        //receiveGBT(_GBTPayableTokenAmount,"Payable GBT Stake for adding solution against proposal");
    }

    function proposalVoting(bytes32 _gbUserName,uint _GBTPayableTokenAmount,uint _proposalId,uint[] _optionChosen) public
    {
        GBM=GovBlocksMaster(GBMAddress);
        GBTS=GBTStandardToken(GBTStandardTokenAddress);

        address master = GBM.getDappMasterAddress(_gbUserName); address GDAddress;address PCAddress;
        MS=Master(master);
        uint versionNo = MS.versionLength()-1; 
        (,GDAddress) = MS.allContractVersions(versionNo,1);
        (,PCAddress) = MS.allContractVersions(versionNo,3);
        GD=governanceData(GDAddress);
        PC=ProposalCategory(PCAddress);

        GBTS.lockMemberToken(_gbUserName,_proposalId,_TokenAmount);
        uint depositAmount = ((gbtTransfer*GD.depositPercVote())/100);
        finalAmount = depositAmount + GD.getDepositTokensByAddress(msg.sender,_proposalId);
        GD.setDepositTokens(msg.sender,_proposalId,finalAmount,'V');

        VT=VotingType(GD.getProposalVotingType(_proposalId));
        VT.proposalVoting(_proposalId,_optionChosen,msg.sender,_GBTPayableTokenAmount);

        //receiveGBT(_GBTPayableTokenAmount,"Payable GBT Stake for voting against proposal");
    }
}
