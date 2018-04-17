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

import "./governanceData.sol";
import "./simpleVoting.sol";
import "./RankBasedVoting.sol";
import "./FeatureWeighted.sol";
import "./memberRoles.sol";
import "./ProposalCategory.sol";
import "./StandardVotingType.sol";
import "./Governance.sol";
import "./Pool.sol";
import "./GBTController.sol";
import "./GBTStandardToken.sol";
import "./GovBlocksMaster.sol";
import "./Ownable.sol";

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
    bytes32 public DappName;
    changeVersion[]  contractChangeDate;
    mapping(uint=>contractDetails[]) public allContractVersions;
    mapping(address=>uint) public contracts_active;
    
    address governanceDataAddress;
    address memberRolesAddress;
    address proposalCategoryAddress;
    address simpleVotingAddress;
    address rankBasedVotingAddress;
    address featureWeightedAddress;
    address masterAddress;
    address standardVotingTypeAddress;
    address governanceAddress;
    address poolAddress;
    address GBTCAddress;
    address GBTSAddress;
    address public GBMAddress;
    GovBlocksMaster GBM;
    GBTController GBTC;
    GBTStandardToken GBTS;
    Pool P1;
    Governance G1;
    governanceData GD;
    memberRoles MR;
    ProposalCategory PC;
    simpleVoting SV;
    RankBasedVoting RB;
    FeatureWeighted FW;
    StandardVotingType SVT;

    /// @dev Constructor function for master
    /// @param _GovBlocksMasterAddress GovBlocks master address
    /// @param _gbUserName GovBlocks username
    function Master(address _GovBlocksMasterAddress,bytes32 _gbUserName)
    {
        masterAddress=address(this);
        contracts_active[masterAddress]=0;
        contracts_active[address(this)]=1;
        versionLength =0;
        GBMAddress = _GovBlocksMasterAddress;
        DappName = _gbUserName;
    }
   
    modifier onlyOwner
    {  
        require(isOwner(msg.sender) == 1);
        _; 
    }

    modifier onlyAuthorizedGB
    {
        GBM=GovBlocksMaster(GBMAddress);
        require(GBM.isAuthorizedGBOwner(DappName,msg.sender) == 1);
        _;
    }

    modifier onlyInternal 
    {
        require(contracts_active[msg.sender] == 1 || owner==msg.sender);
        _; 
    }

    /// @dev Checks for authorized GovBlocks owner
    /// @param _memberaddress Address to be checked
    /// @return check Check flag value (1 = authorized GovBlocks owner)
    function isAuthGB(address _memberaddress) constant returns(uint check)
    {
        GBM=GovBlocksMaster(GBMAddress);
        require(GBM.isAuthorizedGBOwner(DappName,_memberaddress) == 1);
            check = 1;
    }

    /// @dev Checks for internal 
    /// @param _address Contract address to be checked for internal
    /// @return check Check flag (boolean value)
    function isInternal(address _address) constant returns(uint check)
    {
        check=0;
        if(contracts_active[_address] == 1 || owner==_address)
            check=1;
    }

    /// @dev Checks for owner 
    /// @param _ownerAddress Contract address to be checked for owner
    /// @return check Check flag (boolean value)
    function isOwner(address _ownerAddress) constant returns(uint check)
    {
        check=0;
        if(owner == _ownerAddress)
            check=1;
    }
    
    /// @dev Sets owner 
    /// @param _memberaddress Contract address to be set as owner
    function setOwner(address _memberaddress)
    {
        require(msg.sender == GBMAddress || msg.sender == owner);
        owner = _memberaddress;
    }
    
    /// @dev Gets GBT controller address
    /// @return _GBTCAddress GBT controller address
    function getGBTCAddress()constant returns(address _GBTCAddress)
    {
        GBM=GovBlocksMaster(GBMAddress);
        (_GBTCAddress,)= GBM.getGBTandGBTC();
    }
    
    /// @dev Gets GBT token address
    /// @return _GBTAddress GBT token address
    function getGBTokenAddress()constant returns(address _GBTAddress)
    {
        GBM=GovBlocksMaster(GBMAddress);
        (,_GBTAddress)= GBM.getGBTandGBTC();
    }
    
    
    /// @dev Creates a new version of contract addresses
    /// @param _contractAddresses Array of nine contract addresses which will be generated
    function addNewVersion(address[9] _contractAddresses) onlyAuthorizedGB
    {
        uint versionNo = versionLength;
        setVersionLength(versionNo+1);
     
        addContractDetails(versionNo,"Master",masterAddress);
        addContractDetails(versionNo,"GovernanceData",_contractAddresses[0]);
        addContractDetails(versionNo,"MemberRoles",_contractAddresses[1]);
        addContractDetails(versionNo,"ProposalCategory",_contractAddresses[2]); 
        addContractDetails(versionNo,"SimpleVoting",_contractAddresses[3]);
        addContractDetails(versionNo,"RankBasedVoting",_contractAddresses[4]); 
        addContractDetails(versionNo,"FeatureWeighted",_contractAddresses[5]); 
        addContractDetails(versionNo,"StandardVotingType",_contractAddresses[6]); 
        addContractDetails(versionNo,"Governance",_contractAddresses[7]); 
        addContractDetails(versionNo,"Pool",_contractAddresses[8]); 
        addContractDetails(versionNo,"GBTController",getGBTCAddress()); 
        addContractDetails(versionNo,"GBTStandardToken",getGBTokenAddress()); 
    }

    /// @dev Adds contract's name  and its address in a given version
    /// @param _versionNo Version number of the contracts
    /// @param _contractName Contract name
    /// @param _contractAddresse Contract addresse
    function addContractDetails(uint _versionNo,bytes32 _contractName,address _contractAddresse) internal
    {
        allContractVersions[_versionNo].push(contractDetails(_contractName,_contractAddresse));        
    }


    /// @dev Changes all reference contract addresses in master 
    /// @param _version Version of the new contracts
    function changeAddressInMaster(uint _version) internal 
    {
        changeAllAddress(_version);
        governanceDataAddress = allContractVersions[_version][1].contractAddress;
        memberRolesAddress = allContractVersions[_version][2].contractAddress;
        proposalCategoryAddress = allContractVersions[_version][3].contractAddress;
        simpleVotingAddress = allContractVersions[_version][4].contractAddress;
        rankBasedVotingAddress = allContractVersions[_version][5].contractAddress;
        featureWeightedAddress = allContractVersions[_version][6].contractAddress;
        standardVotingTypeAddress = allContractVersions[_version][7].contractAddress;
        governanceAddress = allContractVersions[_version][8].contractAddress;
        poolAddress = allContractVersions[_version][9].contractAddress;
        GBTCAddress = allContractVersions[_version][10].contractAddress;
        GBTSAddress = allContractVersions[_version][11].contractAddress;
    }

    /// @dev Sets the older versions of contract addresses as inactive and the latest one as active.
    /// @param version Version of the new contracts
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
        addRemoveAddress(version,11);
    }

    /// @dev Deactivates address of a contract from last version
    /// @param _version Version of the new contracts
    /// @param _index Index of the contracts
    function addRemoveAddress(uint _version,uint _index) internal
    {
        uint version_old=0;
        if(_version>0)
            version_old=_version-1;
        contracts_active[allContractVersions[version_old][_index].contractAddress]=0;
        contracts_active[allContractVersions[_version][_index].contractAddress]=1;
    }

    /// @dev Links all contracts to master by passing address of master contract to the functions of other contracts.
    /// @param _masterAddress Master address of the contracts
    function changeMasterAddress(address _masterAddress) internal 
    {
        GD=governanceData(governanceDataAddress);
        GD.changeMasterAddress(_masterAddress);
                             
        SV=simpleVoting(simpleVotingAddress);
        SV.changeMasterAddress(_masterAddress);

        SVT=StandardVotingType(standardVotingTypeAddress);
        SVT.changeMasterAddress(_masterAddress);

        G1=Governance(governanceAddress);
        G1.changeMasterAddress(_masterAddress);

        P1=Pool(poolAddress);
        P1.changeMasterAddress(_masterAddress);

        GBTC=GBTController(GBTCAddress);
        GBTC.changeMasterAddress(_masterAddress);

        PC=ProposalCategory(proposalCategoryAddress);
        PC.changeMasterAddress(_masterAddress);

        MR=memberRoles(memberRolesAddress);
        MR.changeMasterAddress(_masterAddress);
    }

   /// @dev Links contracts to one another
   function changeOtherAddress() internal 
   {  
        changeGBTAddress(GBTSAddress);
        changeGBTControllerAddress(GBTCAddress);
        
        GD=governanceData(governanceDataAddress);
        GD.editVotingType(0,simpleVotingAddress);
        GD.editVotingType(1,rankBasedVotingAddress);
        GD.editVotingType(2,featureWeightedAddress);

        SV=simpleVoting(simpleVotingAddress);
        SV.changeAllContractsAddress(standardVotingTypeAddress,governanceDataAddress,memberRolesAddress,proposalCategoryAddress,governanceAddress);

        SVT=StandardVotingType(standardVotingTypeAddress);
        SVT.changeAllContractsAddress(governanceDataAddress,memberRolesAddress,proposalCategoryAddress,governanceAddress,poolAddress);
        SVT.changeOtherContractAddress(simpleVotingAddress,rankBasedVotingAddress,featureWeightedAddress);

        G1=Governance(governanceAddress);
        G1.changeAllContractsAddress(governanceDataAddress,memberRolesAddress,proposalCategoryAddress,poolAddress);
        
        PC=ProposalCategory(proposalCategoryAddress);
        PC.changeAllContractsAddress(memberRolesAddress);
   
        MR=memberRoles(memberRolesAddress);
        MR.changeAllContractAddress(governanceDataAddress);
   }

    /// @dev Changes GBT token address in GD, GBT controller, and pool contracts
    /// @param _tokenAddress Address of the GBT token
    function changeGBTAddress(address _tokenAddress) 
    {
        GBM=GovBlocksMaster(GBMAddress);
        uint version = versionLength-1;
        if((version == 0 && msg.sender== owner) || msg.sender == GBMAddress || GBM.isAuthorizedGBOwner(DappName,msg.sender) == 1)
        {
            GD=governanceData(governanceDataAddress);
            GD.changeGBTtokenAddress(_tokenAddress);
            
            SV=simpleVoting(simpleVotingAddress);
            SV.changeGBTSAddress(_tokenAddress);
            
            G1=Governance(governanceAddress);
            G1.changeGBTSAddress(_tokenAddress);
            
            SVT=StandardVotingType(standardVotingTypeAddress);
            SVT.changeGBTSAddress(_tokenAddress);
        }
    }

    /// @dev Changes GBT controller address
    /// @param _controllerAddress New GBT controller address
    function changeGBTControllerAddress(address _controllerAddress) 
    {
        GBM=GovBlocksMaster(GBMAddress);
        uint version = versionLength-1;
        if((version == 0 && msg.sender== owner) || msg.sender == GBMAddress || GBM.isAuthorizedGBOwner(DappName,msg.sender) == 1)
        {
            G1=Governance(governanceAddress);
            G1.changeGBTControllerAddress(_controllerAddress);

            SV=simpleVoting(simpleVotingAddress);
            SV.changeGBTControllerAddress(_controllerAddress);

            P1=Pool(poolAddress);
            P1.changeGBTControllerAddress(_controllerAddress);      
        }
    }

    /// @dev Switches to the recent version of contracts
    function switchToRecentVersion() 
    {
        uint version = versionLength-1;
        GBM=GovBlocksMaster(GBMAddress);
        require((version == 0 && msg.sender== owner) || GBM.isAuthorizedGBOwner(DappName,msg.sender) == 1);
    
        addInContractChangeDate(now,version);
        changeAddressInMaster(version);
        changeMasterAddress(allContractVersions[version][0].contractAddress);
            callConstructorGDMRPC(version);

        changeOtherAddress();
    }

    /// @dev Calls contructor governance data, member roles, proposal category contracts
    /// @param version Version of the new contracts
    function callConstructorGDMRPC(uint version) internal 
    {
        GD=governanceData(governanceDataAddress);
        MR=memberRoles(memberRolesAddress);
        PC=ProposalCategory(proposalCategoryAddress);

        if(GD.constructorCheck() == 0)
            GD.GovernanceDataInitiate(GBMAddress);

        if(MR.constructorCheck() == 0)
            MR.MemberRolesInitiate(GBMAddress);
            
        if(PC.constructorCheck() == 0)
            PC.ProposalCategoryInitiate(GBMAddress);

    }

    /// @dev Stores the date when version of contracts get switched
    /// @param _date Contract change date
    /// @param _versionNo Version of the new contracts
    function addInContractChangeDate(uint _date , uint _versionNo) internal 
    {
        contractChangeDate.push(changeVersion(_date,_versionNo));
    }
  
    /// @dev Sets the length of version
    /// @param _length Length of the version
    function setVersionLength(uint _length) internal
    {
        versionLength = _length;
    }

    /// @dev Gets current version amd its master address
    /// @return versionNo Current version number
    /// @return masterAddress Master address
    function getCurrentVersion() constant returns(uint versionNo, address masterAddress)
    {
       versionNo = versionLength - 1;
       masterAddress = allContractVersions[versionNo][0].contractAddress;
    }

    /// @dev Gets latest version name and address
    /// @param _versionNo Version number
    /// @return versionNo Version number
    /// @return contractsName Latest version's contract names
    /// @return contractsAddress Latest version's contract addresses
    function getLatestVersionData(uint _versionNo)constant returns(uint versionNo,bytes32[] contractsName, address[] contractsAddress)
    {
       versionNo = _versionNo;
       contractsName=new bytes32[](allContractVersions[versionNo].length);
       contractsAddress=new address[](allContractVersions[versionNo].length);
   
       for(uint i=0; i < allContractVersions[versionNo].length; i++)
       {
           contractsName[i]=allContractVersions[versionNo][i].name;
           contractsAddress[i] = allContractVersions[versionNo][i].contractAddress;
       }
    }

    function changeGBMAddress(address _GBMnewAddress)
    {
        require(msg.sender == GBMAddress);
        GBMAddress == _GBMnewAddress;
    }

    /// @dev Changes master in GovBlocks master
    /// @param _gbUserName GovBlocks username
    /// @param _newMasterAddress New master address
    function changeMasterin_GBM(bytes32 _gbUserName,address _newMasterAddress) onlyOwner
    {
      GBM=GovBlocksMaster(GBMAddress);
      GBM.changeDappMasterAddress(_gbUserName,_newMasterAddress);
    }

    /// @dev Changes token address in GovBlocks master
    /// @param _gbUserName GovBlocks username
    /// @param _newTokenAddress New token address for dApp
    function changeDappTokenAddressin_GBM(bytes32 _gbUserName,address _newTokenAddress) onlyOwner
    {
      GBM=GovBlocksMaster(GBMAddress);
      GBM.changeDappTokenAddress(_gbUserName,_newTokenAddress);
    }

    /// @dev Changes dApp description in GovBlocks master
    /// @param _gbUserName GovBlocks username
    /// @param _dappDescHash New dApp description hash
    function changeDappDescIn_GBM(bytes32 _gbUserName,string _dappDescHash) onlyOwner
    {
      GBM=GovBlocksMaster(GBMAddress);
      GBM.changeDappDescHash(_gbUserName,_dappDescHash);
    }

    /// @dev Changes dApp token in GovBlocks master
    /// @return dappTokenAddress New dApp token address
    function getDappTokenAddress()constant returns(address dappTokenAddress)
    {
        GBM=GovBlocksMaster(GBMAddress);
        dappTokenAddress=GBM.getDappTokenAddress(DappName);
        return (dappTokenAddress);
    }
}