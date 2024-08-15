// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { TUtils,TMembership,TNFT,TStakeVeriables,TXPad,TXProject } from "../../libraries/Structs.sol";
import '@solidstate/contracts/access/ownable/OwnableInternal.sol';
import { LibMembership } from "../../libraries/LibMembership.sol";
import { Modifiers } from "../../libraries/Modifiers.sol";
import { LibStake } from "../../libraries/LibStake.sol";
import { LibXPad } from "../../libraries/LibXPad.sol";
import { Utils } from "../../libraries/Utils.sol";
import "../../libraries/Errors.sol";

contract Settings is Modifiers,OwnableInternal {

    function setStakeVeriables(
        TStakeVeriables memory _veriables
    ) 
        external 
        onlyOwner 
    {
        LibStake.layout().stakeVeriables = _veriables;
    }

    function setUtils(
        TUtils memory _params
    ) 
        external 
        onlyOwner 
    {
        Utils.layout().utils = _params;
    }

    function setReserveContract(
        address _contract
    ) 
        external 
        onlyOwner 
    {
        Utils.layout().utils.reserveContract = _contract;
    }
    
    function setNFTContract(
        address _contract
    ) 
        external 
        onlyOwner 
    {
        Utils.layout().utils.nftContract = _contract;
    }

    function setPausedMembership(
        bool _status
    ) 
        external 
        onlyOwner 
    {
        LibMembership.layout().membership.isPausedMembership = _status;
    }

    function setMembershipBurnPercentage(
        uint256 _percentage
    ) 
        external 
        onlyOwner 
    {
        if(_percentage > 1000)revert Invalid_Action();
        LibMembership.layout().membership.burnPercentage = _percentage;
    }

    function setTokenIds(
        uint256[] memory _ids
    ) 
        external 
        onlyOwner 
    {
        Utils.layout().utils.tokenIds = _ids;
    }

    function setNFTs(
        TNFT[] memory _paramsArray
    ) 
        public 
        onlyOwner 
    {
        LibMembership.Layout storage ms = LibMembership.layout();
        address nftContract = Utils.layout().utils.nftContract;
        uint256[] storage tokenIDs = Utils.layout().utils.tokenIds;
        TNFT[] memory paramsArray = _paramsArray;
        for(uint256 i = 0; i < paramsArray.length;) {
            TNFT memory params = paramsArray[i];
            if(!Utils.checkExistence(tokenIDs,params.id))revert Invalid_Action();
            ms.nft[nftContract][params.id] = params;

            unchecked{
                i++;
            }
        }
    }

    function setNFT(
        TNFT memory _params
    )
        external 
        onlyOwner 
    {
        LibMembership.layout().nft[Utils.layout().utils.nftContract][_params.id] = _params;
    }

    function setXPad(
        TXPad memory _params
    ) 
        external 
        onlyOwner 
    {
        LibXPad.layout().xPad = _params;
    }

    function setXPaused(
        bool _status
    ) 
        external 
        onlyOwner 
    {
        LibXPad.layout().xPad.isPausedXPad = _status;
    }

    function setXUsedToken(
        address _token
    ) 
        external 
        onlyOwner 
        isValidContract(_token) 
    {
        LibXPad.layout().xPad.usedToken = _token;
    }

    function setXProjectIsView(
        bool _status,
        uint256 _id
    ) 
        external 
        onlyOwner 
    {
        if(!LibXPad.layout().xProject[_id].isExist)revert Invalid_Input();
        LibXPad.layout().xProject[_id].isView = _status;
    }

    function setXProject(
        uint256 _id,
        TXProject memory _params
    ) 
        external 
        onlyOwner 
    {
        if(!LibXPad.layout().xProject[_id].isExist)revert Invalid_Input();
        LibXPad.layout().xProject[_id] = _params;
    }

    function setXProjectVestingContractAddress(
        uint256 _id,
        address _contractAddress
    ) 
        external 
        onlyOwner 
    {
        if(!LibXPad.layout().xProject[_id].isExist)revert Invalid_Input();
        LibXPad.layout().xProject[_id].vestingContractAddress = _contractAddress;
    }

}