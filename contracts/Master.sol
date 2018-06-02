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
import "./GBTStandardToken.sol";
import "./GovBlocksMaster.sol";
import "./Ownable.sol";

contract Master is Ownable {

    struct changeVersion
    {
        uint date_implement;
        uint16 versionNo;
    }

    uint16 public versionLength;
    bytes32 public DappName;
    bytes2[] allContractNames;
    changeVersion[] public contractChangeDate;
    mapping(address=>bool) public contracts_active;
    mapping(uint16=>mapping(bytes2=>address)) public allContractVersions;
    mapping(bytes2=>mapping(bytes2=>bool)) contract_dependency_new;

    GovBlocksMaster GBM;
    GBTStandardToken GBTS;
    Pool P1;
    Governance GOV;
    governanceData GD;
    memberRoles MR;
    ProposalCategory PC;
    simpleVoting SV;
    RankBasedVoting RB;
    FeatureWeighted FW;
    StandardVotingType SVT;
    bool constructorCheck;
    address public GBMAddress;

    /// @dev Constructor function for master
    /// @param _GovBlocksMasterAddress GovBlocks master address
    /// @param _gbUserName GovBlocks username
    function Master(address _GovBlocksMasterAddress,bytes32 _gbUserName)
    {
        contracts_active[address(this)]=true;
        versionLength=0;
        GBMAddress=_GovBlocksMasterAddress;
        DappName=_gbUserName;
    }
    
    function masterInit(bytes2[] _contracts)
    {
       require(constructorCheck == false);
         addContractNames(_contracts);
         addContractDependencies();
         constructorCheck = true;
    }
    
    modifier onlyOwner
    {  
        require(isOwner(msg.sender) == true);
        _; 
    }

    modifier onlyAuthorizedGB
    {
        GBM=GovBlocksMaster(GBMAddress);
        require(GBM.isAuthorizedGBOwner(DappName,msg.sender) == true);
        _;
    }

    modifier onlyInternal 
    {
        require(contracts_active[msg.sender] == true || owner==msg.sender);
        _; 
    }

    function isGBM(address _GBMaddress)constant returns(bool check)
    {
        require(_GBMaddress == GBMAddress);
    }

    /// @dev Checks for authorized Member for Dapp
    /// @param _memberaddress Address to be checked
    /// @return check Check flag value (authorized GovBlocks owner = 1)
    function isAuthGB(address _memberaddress) constant returns(bool check)
    {
        GBM=GovBlocksMaster(GBMAddress);
        require(GBM.isAuthorizedGBOwner(DappName,_memberaddress) == true);
            check = true;
    }

    /// @dev Checks for internal 
    /// @param _address Contract address to be checked for internal
    /// @return check Check flag (boolean value)
    function isInternal(address _address) constant returns(bool check)
    {
        if(contracts_active[_address] == true || owner==_address)
            check = true;
    }

    /// @dev Checks for owner 
    /// @param _ownerAddress Contract address to be checked for owner
    /// @return check Check flag (boolean value)
    function isOwner(address _ownerAddress) constant returns(bool check)
    {
        if(owner == _ownerAddress)
            check = true;
    }

    /// @dev Sets owner 
    /// @param _memberaddress Contract address to be set as owner
    function setOwner(address _memberaddress)
    {
        require(msg.sender == GBMAddress || msg.sender == owner);
        owner = _memberaddress;
    }
    

    function addContractNames(bytes2[] _contracts) internal
    {
        for(uint8 i=0; i<_contracts.length; i++)
        {
              allContractNames.push(_contracts[i]);   
        }
    }

    function addContractDependencies() internal
    {
        contract_dependency_new['GD']['SV'] = true;
        contract_dependency_new['GD']['RB'] = true;
        contract_dependency_new['GD']['FW'] = true;
        contract_dependency_new['GD']['GV'] = true;
        contract_dependency_new['SV']['VT'] = true;
        contract_dependency_new['SV']['GD'] = true;
        contract_dependency_new['SV']['MR'] = true;
        contract_dependency_new['SV']['GV'] = true;
        contract_dependency_new['SV']['PC'] = true;
        contract_dependency_new['VT']['GD'] = true;
        contract_dependency_new['VT']['MR'] = true;
        contract_dependency_new['VT']['PC'] = true;
        contract_dependency_new['VT']['GV'] = true;
        contract_dependency_new['VT']['PL'] = true;
        contract_dependency_new['GV']['GD'] = true;
        contract_dependency_new['GV']['MR'] = true;
        contract_dependency_new['GV']['PC'] = true;
        contract_dependency_new['GV']['PL'] = true;
        contract_dependency_new['PC']['GD'] = true;
        contract_dependency_new['PC']['MR'] = true;
    }

    /// @dev Creates a new version of contract addresses
    /// @param _contractAddresses Array of nine contract addresses which will be generated
    function addNewVersion(address[9] _contractAddresses) onlyAuthorizedGB
    {
        uint16 versionNo = versionLength;
        GBM=GovBlocksMaster(GBMAddress);
        setVersionLength(versionNo+1);
        addContractDetails(versionNo,"MS",address(this));
        addContractDetails(versionNo,"GD",_contractAddresses[0]);
        addContractDetails(versionNo,"MR",_contractAddresses[1]);
        addContractDetails(versionNo,"PC",_contractAddresses[2]); 
        addContractDetails(versionNo,"SV",_contractAddresses[3]);
        addContractDetails(versionNo,"RB",_contractAddresses[4]); 
        addContractDetails(versionNo,"FW",_contractAddresses[5]); 
        addContractDetails(versionNo,"VT",_contractAddresses[6]); 
        addContractDetails(versionNo,"GV",_contractAddresses[7]); 
        addContractDetails(versionNo,"PL",_contractAddresses[8]); 
        addContractDetails(versionNo,"GS",GBM.getGBTAddress()); 
    }

    /// @dev Adds contract's name  and its address in a given version
    /// @param _versionNo Version number of the contracts
    /// @param _contractName Contract name
    /// @param _contractAddress Contract addresse
    function addContractDetails(uint16 _versionNo,bytes2 _contractName,address _contractAddress) internal
    {
        allContractVersions[_versionNo][_contractName] = _contractAddress;        
    }

    /// @dev Switches to the recent version of contracts
    function switchToRecentVersion() 
    {
        uint16 version = versionLength-1;
        // require((version == 0 && msg.sender== owner) || GBM.isAuthorizedGBOwner(DappName,msg.sender) == true);
        require(isValidateOwner() == true);
        addInContractChangeDate(now,version);
        changeAllAddress(version);
        changeMasterAddress(allContractVersions[version]['MS'],version);
        // callConstructorGDMRPC(version);
        // changeOtherAddress(version);
    }

    /// @dev Stores the date when version of contracts get switched
    /// @param _date Contract change date
    /// @param _versionNo Version of the new contracts
    function addInContractChangeDate(uint _date , uint16 _versionNo) internal 
    {
        contractChangeDate.push(changeVersion(_date,_versionNo));
    }

    /// @dev Sets the older versions of contract addresses as inactive and the latest one as active.
    /// @param _version Version of the new contracts
    function changeAllAddress(uint16 _version) internal
    {
        for(uint8 i=0; i < allContractNames.length; i++)
        {
           addRemoveAddress(_version,allContractNames[i]);
        }
    }

    /// @dev Deactivates address of a contract from last version
    /// @param _version Version of the new contracts
    /// @param _contractName Contract name
    function addRemoveAddress(uint16 _version,bytes2 _contractName) internal
    {
        uint16 version_old=0;
        if(_version>0)
            version_old=_version-1;
        contracts_active[allContractVersions[version_old][_contractName]]=false;
        contracts_active[allContractVersions[_version][_contractName]]=true;
    }

    /// @dev Links all contracts to master by passing address of master contract to the functions of other contracts.
    /// @param _masterAddress Master address of the contracts
    function changeMasterAddress(address _masterAddress,uint16 version)  
    {
        GD=governanceData(allContractVersions[version]['GD']);
        GD.changeMasterAddress(_masterAddress);
                             
        SV=simpleVoting(allContractVersions[version]['SV']);
        SV.changeMasterAddress(_masterAddress);

        SVT=StandardVotingType(allContractVersions[version]['VT']);
        SVT.changeMasterAddress(_masterAddress);

        GOV=Governance(allContractVersions[version]['GV']);
        GOV.changeMasterAddress(_masterAddress);

        P1=Pool(allContractVersions[version]['PL']);
        P1.changeMasterAddress(_masterAddress);

        PC=ProposalCategory(allContractVersions[version]['PC']);
        PC.changeMasterAddress(_masterAddress);

        MR=memberRoles(allContractVersions[version]['MR']);
        MR.changeMasterAddress(_masterAddress);


        if(GD.constructorCheck() == false)
            GD.GovernanceDataInitiate();

        if(MR.constructorCheck() == false)
            MR.MemberRolesInitiate();
            
        if(PC.constructorCheck() == false)
            PC.ProposalCategoryInitiate();


        uint8 i;
        for( i=0; i<allContractNames.length; i++)
        {
          if(contract_dependency_new['GD'][allContractNames[i]] == true)
          {
                if(version == 0)
                  GD.changeAddress(allContractNames[i], allContractVersions[version][allContractNames[i]]);
                else if(allContractVersions[version-1][allContractNames[i]] !=  allContractVersions[version][allContractNames[i]] || allContractVersions[version-1]['GD'] != allContractVersions[version]['GD'])
                  GD.changeAddress(allContractNames[i], allContractVersions[version][allContractNames[i]]);
          }

          if(contract_dependency_new['PC'][allContractNames[i]] == true)
          {
                if(version == 0)
                  PC.changeAddress(allContractNames[i], allContractVersions[version][allContractNames[i]]);
                else if( allContractVersions[version-1][allContractNames[i]] !=  allContractVersions[version][allContractNames[i]] || allContractVersions[version-1]['PC'] != allContractVersions[version]['PC'])
                  PC.changeAddress(allContractNames[i], allContractVersions[version][allContractNames[i]]);
          }

          if(contract_dependency_new['SV'][allContractNames[i]] == true)
          {
              if(version == 0)
                  SV.changeAddress(allContractNames[i], allContractVersions[version][allContractNames[i]]);
              else if( allContractVersions[version-1][allContractNames[i]] !=  allContractVersions[version][allContractNames[i]] || allContractVersions[version-1]['SV'] != allContractVersions[version]['SV'])
                  SV.changeAddress(allContractNames[i], allContractVersions[version][allContractNames[i]]);
          }

          if(contract_dependency_new['VT'][allContractNames[i]] == true)
          {
                if(version == 0)
                  SVT.changeAddress(allContractNames[i], allContractVersions[version][allContractNames[i]]);
                else if( allContractVersions[version-1][allContractNames[i]] !=  allContractVersions[version][allContractNames[i]] || allContractVersions[version-1]['VT'] != allContractVersions[version]['VT'])
                  SVT.changeAddress(allContractNames[i], allContractVersions[version][allContractNames[i]]);
          }

          if(contract_dependency_new['GV'][allContractNames[i]] == true)
          {
                if(version == 0)
                  GOV.changeAddress(allContractNames[i], allContractVersions[version][allContractNames[i]]);
                else if( allContractVersions[version-1][allContractNames[i]] !=  allContractVersions[version][allContractNames[i]] || allContractVersions[version-1]['GV'] != allContractVersions[version]['GV'])
                  GOV.changeAddress(allContractNames[i], allContractVersions[version][allContractNames[i]]);
          }
      }

      changeGBTAddress(allContractVersions[version]['GS']);
    }

    //  /// @dev Calls contructor of governance data, member roles, proposal category contracts
    //  /// @param version Version of the new contracts
    //  function callConstructorGDMRPC(uint16 version)  
    //  {
    //      GD=governanceData(allContractVersions[version]['GD']);
    //      MR=memberRoles(allContractVersions[version]['MR']);
    //      PC=ProposalCategory(allContractVersions[version]['PC']);

    //      if(GD.constructorCheck() == false)
    //          GD.GovernanceDataInitiate();

    //      if(MR.constructorCheck() == false)
    //          MR.MemberRolesInitiate();
            
    //      if(PC.constructorCheck() == false)
    //          PC.ProposalCategoryInitiate();
    //  }

    // /// @dev Links contracts to one another
    // function changeOtherAddress(uint16 version)  
    // {  
    //          GD=governanceData(allContractVersions[version]['GD']);
    //          PC=ProposalCategory(allContractVersions[version]['PC']);
    //          SV=simpleVoting(allContractVersions[version]['SV']);
    //          SVT=StandardVotingType(allContractVersions[version]['VT']);
    //          GOV=Governance(allContractVersions[version]['GV']);

    //          uint8 i;
    //          for( i=0; i<allContractNames.length; i++)
    //          {
    //             if(contract_dependency_new['GD'][allContractNames[i]] == true)
    //             {
    //                  if(version == 0)
    //                     GD.changeAddress(allContractNames[i], allContractVersions[version][allContractNames[i]]);
    //                  else if(allContractVersions[version-1][allContractNames[i]] !=  allContractVersions[version][allContractNames[i]] || allContractVersions[version-1]['GD'] != allContractVersions[version]['GD'])
    //                     GD.changeAddress(allContractNames[i], allContractVersions[version][allContractNames[i]]);
    //             }

    //             if(contract_dependency_new['PC'][allContractNames[i]] == true)
    //             {
    //                  if(version == 0)
    //                     PC.changeAddress(allContractNames[i], allContractVersions[version][allContractNames[i]]);
    //                  else if( allContractVersions[version-1][allContractNames[i]] !=  allContractVersions[version][allContractNames[i]] || allContractVersions[version-1]['PC'] != allContractVersions[version]['PC'])
    //                     PC.changeAddress(allContractNames[i], allContractVersions[version][allContractNames[i]]);
    //             }

    //             if(contract_dependency_new['SV'][allContractNames[i]] == true)
    //             {
    //                 if(version == 0)
    //                     SV.changeAddress(allContractNames[i], allContractVersions[version][allContractNames[i]]);
    //                 else if( allContractVersions[version-1][allContractNames[i]] !=  allContractVersions[version][allContractNames[i]] || allContractVersions[version-1]['SV'] != allContractVersions[version]['SV'])
    //                     SV.changeAddress(allContractNames[i], allContractVersions[version][allContractNames[i]]);
    //             }

    //             if(contract_dependency_new['VT'][allContractNames[i]] == true)
    //             {
    //                  if(version == 0)
    //                     SVT.changeAddress(allContractNames[i], allContractVersions[version][allContractNames[i]]);
    //                  else if( allContractVersions[version-1][allContractNames[i]] !=  allContractVersions[version][allContractNames[i]] || allContractVersions[version-1]['VT'] != allContractVersions[version]['VT'])
    //                     SVT.changeAddress(allContractNames[i], allContractVersions[version][allContractNames[i]]);
    //             }

    //             if(contract_dependency_new['GV'][allContractNames[i]] == true)
    //             {
    //                  if(version == 0)
    //                     GOV.changeAddress(allContractNames[i], allContractVersions[version][allContractNames[i]]);
    //                  else if( allContractVersions[version-1][allContractNames[i]] !=  allContractVersions[version][allContractNames[i]] || allContractVersions[version-1]['GV'] != allContractVersions[version]['GV'])
    //                     GOV.changeAddress(allContractNames[i], allContractVersions[version][allContractNames[i]]);
    //             }
    //         }

    //      changeGBTAddress(allContractVersions[version]['GS']);
    // }

    /// @dev Changes GBT token address in GD, SV, SVT and governance contracts
    /// @param _tokenAddress Address of the GBT token
    function changeGBTAddress(address _tokenAddress) 
    {
        // GBM=GovBlocksMaster(GBMAddress);
        uint16 version = versionLength-1;
        // if((version == 0 && msg.sender== owner) || msg.sender == GBMAddress || GBM.isAuthorizedGBOwner(DappName,msg.sender) == true)
        // { 
            
            require (isValidateOwner() == true);
            
            SV=simpleVoting(allContractVersions[version]['SV']);
            SV.changeGBTSAddress(_tokenAddress);
            
            GOV=Governance(allContractVersions[version]['GV']);
            GOV.changeGBTSAddress(_tokenAddress);
            
            SVT=StandardVotingType(allContractVersions[version]['VT']);
            SVT.changeGBTSAddress(_tokenAddress);

            P1=Pool(allContractVersions[version]['PL']);
            P1.changeGBTSAddress(_tokenAddress);
        // }
    }

    function isValidateOwner() constant returns(bool)
    {
        GBM=GovBlocksMaster(GBMAddress);
        uint16 version = versionLength-1;
        if((version == 0 && msg.sender== owner) || msg.sender == GBMAddress || GBM.isAuthorizedGBOwner(DappName,msg.sender) == true)
         return true;
    }

    /// @dev Changes GovBlocks Master address
    /// @param _GBMnewAddress New GovBlocks master address
    function changeGBMAddress(address _GBMnewAddress)
    {
        require(msg.sender == GBMAddress);
        GBMAddress == _GBMnewAddress;
    }

    // /// @dev Changes master in GovBlocks master
    // /// @param _gbUserName GovBlocks username
    // /// @param _newMasterAddress New master address
    // function changeDappMasterin_GBM(bytes32 _gbUserName,address _newMasterAddress) onlyOwner
    // {
    //   GBM=GovBlocksMaster(GBMAddress);
    //   GBM.changeDappMasterAddress(_gbUserName,_newMasterAddress);
    // }

    // /// @dev Changes token address in GovBlocks master
    // /// @param _gbUserName GovBlocks username
    // /// @param _newTokenAddress New token address for dApp
    // function changeDappTokenAddressin_GBM(bytes32 _gbUserName,address _newTokenAddress) onlyOwner
    // {
    //   GBM=GovBlocksMaster(GBMAddress);
    //   GBM.changeDappTokenAddress(_gbUserName,_newTokenAddress);
    // }
  
    /// @dev Sets the length of version
    /// @param _length Length of the version
    function setVersionLength(uint16 _length) internal
    {
        versionLength = _length;
    }

    /// @dev Gets current version amd its master address
    /// @return versionNo Current version number
    /// @return MSAddress Master address
    function getCurrentVersion() constant returns(uint16 versionNo, address MSAddress)
    {
       versionNo = versionLength - 1;
       MSAddress = allContractVersions[versionNo]['MS'];
    }

    /// @dev Gets latest version name and address
    /// @param _versionNo Version number
    /// @return versionNo Version number
    /// @return contractsName Latest version's contract names
    /// @return contractsAddress Latest version's contract addresses
    function getLatestVersionData(uint16 _versionNo)constant returns(uint16 versionNo,bytes2[] contractsName, address[] contractsAddress)
    {
       versionNo = _versionNo;
       contractsName=new bytes2[](allContractNames.length);
       contractsAddress=new address[](allContractNames.length);
   
       for(uint8 i=0; i < allContractNames.length; i++)
       {
           contractsName[i]=allContractNames[i];
           contractsAddress[i] = allContractVersions[versionNo][allContractNames[i]];
       }
    }

}