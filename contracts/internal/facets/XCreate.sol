// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import '@solidstate/contracts/access/ownable/OwnableInternal.sol';
import { TXProject } from "../../libraries/Structs.sol";
import { LibXPad } from "../../libraries/LibXPad.sol";
import "../../external/Reserve.sol";
import "../../libraries/Errors.sol";

contract XCreate is OwnableInternal {

    event HANDLE_NEW_XPAD_PROJECT(address indexed reserveAddr,uint256 id,uint256 when);

    function xCreate(
        TXProject memory _params
    ) 
        external 
        onlyOwner 
    {
        LibXPad.Layout storage xs = LibXPad.layout();
        if(xs.xProject[_params.projectId].isExist){ revert Invalid_Action(); }

        xs.xProject[_params.projectId] = _params;
        xs.xPad.projects.push(_params.projectId);

        unchecked {
            xs.xPad.projectCount++;
        }

        Reserve reserveContract = new Reserve(_params.details.name,_params.projectWalletAddress);
        xs.xProject[_params.projectId].projectReserveContract = address(reserveContract);
        emit HANDLE_NEW_XPAD_PROJECT(address(reserveContract),_params.projectId,block.timestamp);
    }

}