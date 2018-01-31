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

import "./GovernanceData.sol";
import "./SimpleVoting.sol";
import "./RankBasedVoting.sol";
import "./FeatureWeighted.sol";
import "./MemberRoles.sol";
import "./ProposalCategory.sol";
import "./StandardVotingType.sol";
import "./Governance.sol";
import "./zeppelin-solidity/contracts/token/MintableToken.sol";
import "./zeppelin-solidity/contracts/token/BasicToken.sol";
// import "./MintableToken.sol";
// import "./BasicToken.sol";

contract Master is Ownable {

    struct contractDetails{
        bytes32 name;
        address contractAddress;
    }

    struct changeVersion{
        uint date_implement;
        uint versionNo;
    }

    uint  public versionLength;
    changeVersion[]  contractChangeDate;
    mapping(uint=>contractDetails[]) public allContractVersions;
    mapping(address=>uint) public contracts_active;
    
    address governanceDataAddress;
    address memberRolesAddress;
    address proposalCategoryAddress;
    address mintableTokenAddress;
    address basicTokenAddress;
    address simpleVotingAddress;
    address rankBasedVotingAddress;
    address featureWeightedAddress;
    address masterAddress;
    address standardVotingTypeAddress;
    address GBTOwner;
    address governanceAddress;
    Governance G1;
    GovernanceData GD;
    MemberRoles MR;
    ProposalCategory PC;
    MintableToken MT;
    BasicToken BT;
    SimpleVoting SV;
    RankBasedVoting RB;
    FeatureWeighted FW;
    StandardVotingType SVT;

    /// @dev Constructor
    function Master()
    {
        masterAddress=address(this);
        contracts_active[masterAddress]=0;
        contracts_active[address(this)]=1;
        versionLength =0;
    }
   
    modifier onlyGBTOwner
    {
      require(msg.sender == owner || msg.sender == GBTOwner);
      _;
    }

    modifier onlyInternal 
    {
        require(contracts_active[msg.sender] == 1 || owner==msg.sender);
        _; 
    }

    function GovBlocksOwner()
    {
        require(GBTOwner == 0x00);
        GBTOwner = msg.sender;
    }

    function isInternal(address _contractAdd) constant returns(uint check)
    {
        check=0;
        if(contracts_active[msg.sender] == 1 || owner==msg.sender)
            check=1;
    }

    function isOwner(address _ownerAddress) constant returns(uint check)
    {
        check=0;
        if(owner == _ownerAddress)
            check=1;
    }

    /// @dev Creates a new version of contract addresses.
    function addNewVersion(address[] _contractAddresses) onlyOwner
    {
        uint versionNo = versionLength;
        setVersionLength(versionNo+1);
        
        addContractDetails(versionNo,"Master",masterAddress);
        addContractDetails(versionNo,"GovernanceData",_contractAddresses[0]);
        addContractDetails(versionNo,"MemberRoles",_contractAddresses[1]);
        addContractDetails(versionNo,"ProposalCategory",_contractAddresses[2]);
        addContractDetails(versionNo,"MintableToken",_contractAddresses[3]); 
        addContractDetails(versionNo,"BasicToken",_contractAddresses[4]); 
        addContractDetails(versionNo,"SimpleVoting",_contractAddresses[5]);
        addContractDetails(versionNo,"RankBasedVoting",_contractAddresses[6]); 
        addContractDetails(versionNo,"FeatureWeighted",_contractAddresses[7]); 
        addContractDetails(versionNo,"StandardVotingType",_contractAddresses[8]); 
        addContractDetails(versionNo,"Governance",_contractAddresses[9]); 
    }

    /// @dev Adds Contract's name  and its ethereum address in a given version.
    function addContractDetails(uint _versionNo,bytes32 _contractName,address _contractAddresse) internal
    {
        allContractVersions[_versionNo].push(contractDetails(_contractName,_contractAddresse));        
    }

    /// @dev Changes all reference contract addresses in master 
    function changeAddressInMaster(uint _version) onlyInternal
    {
        changeAllAddress(_version);
        governanceDataAddress = allContractVersions[_version][1].contractAddress;
        memberRolesAddress = allContractVersions[_version][2].contractAddress;
        proposalCategoryAddress = allContractVersions[_version][3].contractAddress;
        mintableTokenAddress = allContractVersions[_version][4].contractAddress;
        basicTokenAddress = allContractVersions[_version][5].contractAddress;
        simpleVotingAddress = allContractVersions[_version][6].contractAddress;
        rankBasedVotingAddress = allContractVersions[_version][7].contractAddress;
        featureWeightedAddress = allContractVersions[_version][8].contractAddress;
        standardVotingTypeAddress = allContractVersions[_version][9].contractAddress;
        governanceAddress = allContractVersions[_version][10].contractAddress;

    }

    /// @dev Sets the older version contract address as inactive and the latest one as active.
    function changeAllAddress(uint version) internal
    {
        addRemoveAddress(version,1);
        addRemoveAddress(version,2);
        addRemoveAddress(version,3);
        addRemoveAddress(version,4);
        addRemoveAddress(version,5);
        addRemoveAddress(version,6);
        addRemoveAddress(version,7);
        addRemoveAddress(version,8);
        addRemoveAddress(version,9);
        addRemoveAddress(version,10);
    }

    /// @dev Deactivates address of a contract from last version.
    function addRemoveAddress(uint _version,uint _index) internal
    {
        uint version_old=0;
        if(_version>0)
            version_old=_version-1;
        contracts_active[allContractVersions[version_old][_index].contractAddress]=0;
        contracts_active[allContractVersions[_version][_index].contractAddress]=1;
    }

    /// @dev Links all contracts to master.sol by passing address of Master contract to the functions of other contracts.
    function changeMasterAddress(address _masterAddress) onlyOwner
    {
        GD=GovernanceData(governanceDataAddress);
        GD.changeMasterAddress(_masterAddress);
                             
        SV=SimpleVoting(simpleVotingAddress);
        SV.changeMasterAddress(_masterAddress);

        RB=RankBasedVoting(rankBasedVotingAddress);
        RB.changeMasterAddress(_masterAddress);

        FW=FeatureWeighted(featureWeightedAddress);
        FW.changeMasterAddress(_masterAddress);

        SVT=StandardVotingType(standardVotingTypeAddress);
        SVT.changeMasterAddress(_masterAddress);

        G1=Governance(governanceAddress);
        G1.changeMasterAddress(_masterAddress);
    }

   /// @dev Link contracts to one another.
   function changeOtherAddress() onlyInternal
   {  
        GD=GovernanceData(governanceDataAddress);
        GD.changeAllContractsAddress(basicTokenAddress,mintableTokenAddress);

        SV=SimpleVoting(simpleVotingAddress);
        SV.changeAllContractsAddress(basicTokenAddress,standardVotingTypeAddress,governanceDataAddress,memberRolesAddress,proposalCategoryAddress);

        RB=RankBasedVoting(rankBasedVotingAddress);
        RB.changeAllContractsAddress(basicTokenAddress,standardVotingTypeAddress,governanceDataAddress,memberRolesAddress,proposalCategoryAddress);

        FW=FeatureWeighted(featureWeightedAddress);
        FW.changeAllContractsAddress(basicTokenAddress,standardVotingTypeAddress,governanceDataAddress,memberRolesAddress,proposalCategoryAddress);

        SVT=StandardVotingType(standardVotingTypeAddress);
        SVT.changeAllContractsAddress(basicTokenAddress,governanceDataAddress,memberRolesAddress,proposalCategoryAddress);
        SVT.changeOtherContractAddress(simpleVotingAddress,rankBasedVotingAddress,featureWeightedAddress);
        
        G1=Governance(governanceAddress);
        G1.changeAllContractsAddress(basicTokenAddress,governanceDataAddress,memberRolesAddress,proposalCategoryAddress);
   
        PC=ProposalCategory(proposalCategoryAddress);
        PC.changeAllContractsAddress(memberRolesAddress);
   }

    /// @dev Change GBT token address all contracts
    function changeGBTAddress(address _tokenAddress) onlyGBTOwner
    {
        GD=GovernanceData(governanceDataAddress);
        GD.changeGBTtokenAddress(_tokenAddress);
        
        SV=SimpleVoting(simpleVotingAddress);
        SV.changeGBTtokenAddress(_tokenAddress);

        RB=RankBasedVoting(rankBasedVotingAddress);
        RB.changeGBTtokenAddress(_tokenAddress);

        FW=FeatureWeighted(featureWeightedAddress);
        FW.changeGBTtokenAddress(_tokenAddress);

        SVT=StandardVotingType(standardVotingTypeAddress);
        SVT.changeGBTtokenAddress(_tokenAddress);
    }

    /// @dev Switch to the recent version of contracts. (Last one)
    function switchToRecentVersion() onlyInternal
    {
        uint version = versionLength-1;
        addInContractChangeDate(now,version);
        changeAddressInMaster(version);
    }

    /// @dev Stores the date when version of contracts get switched.
    function addInContractChangeDate(uint _date , uint _versionNo) internal
    {
        contractChangeDate.push(changeVersion(_date,_versionNo));
    }
  
    /// @dev Sets the length of version.
    function setVersionLength(uint _length) internal
    {
        versionLength = _length;
    }

}
