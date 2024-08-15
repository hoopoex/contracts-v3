// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import  "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { LibMembership } from "../../libraries/LibMembership.sol";
import { TMembership } from "../../libraries/Structs.sol";
import { Modifiers } from "../../libraries/Modifiers.sol";
import { IHoopNFT } from "../../interfaces/IHoopNFT.sol";
import { LibStake } from "../../libraries/LibStake.sol";
import { IHoopx } from "../../interfaces/IHoopx.sol";
import { Utils } from "../../libraries/Utils.sol";
import "../../libraries/Errors.sol";

contract Membership is Modifiers, ReentrancyGuard {
    using Math for uint256;

    event HANDLE_NFT_BUY_PROCESS(address indexed addr_,uint256 id_,uint256 when_);
    event HANDLE_NFT_UPGRADING_PROCESS(address indexed addr_,uint256 oldid_, uint256 id_, uint256 when_);
    event HANDLE_NFT_MINT_PROCESS(address indexed addr_,uint256 id_,uint256 when_);

    function buyNFT(
        uint256 _id
    ) 
        external 
        nonReentrant 
        whenNotContract(msg.sender) 
    {
        Utils.Layout storage us = Utils.layout();
        LibMembership.Layout storage ms = LibMembership.layout();

        if(ms.membership.isPausedMembership)revert Paused();
        if(!Utils.checkExistence(us.utils.tokenIds,_id))revert Invalid_Action();
        (
            bool isMember
        ) = checkMember(msg.sender);
        if(isMember)revert User_Is_Member();

        IHoopx token = IHoopx(ms.nft[us.utils.nftContract][_id].acceptableToken);
        uint256 amount = ms.nft[us.utils.nftContract][_id].price;

        if(token.balanceOf(msg.sender) < amount)revert Insufficient_Balance();
        if(token.allowance(msg.sender, address(this)) < amount)revert Insufficient_Allowance();

        uint256 burnAmount = amount.mulDiv(ms.membership.burnPercentage,1000);
        uint256 reserveAmount = amount - burnAmount;

        token.burnFrom(msg.sender,burnAmount);
        token.transferFrom(msg.sender,us.utils.reserveContract,reserveAmount);

        IHoopNFT(Utils.layout().utils.nftContract).mint(msg.sender,_id,1,"");
        
        emit HANDLE_NFT_BUY_PROCESS(msg.sender,_id,block.timestamp);
    }

    function upgradeNFT(
        uint256 _id,
        uint256 _upId
    ) 
        external 
        nonReentrant 
        whenNotContract(msg.sender) 
    {
        Utils.Layout storage us = Utils.layout();
        LibMembership.Layout storage ms = LibMembership.layout();

        // if(LibStake.layout().user[user].userIsStaker)revert User_Is_Staker();

        if(_id > _upId)revert Invalid_Action();
        if(ms.membership.isPausedMembership)revert Paused();
        if(!Utils.checkExistence(us.utils.tokenIds,_id))revert Invalid_Action();
        if(!Utils.checkExistence(us.utils.tokenIds,_upId))revert Invalid_Action();

        IHoopNFT nft = IHoopNFT(Utils.layout().utils.nftContract);

        if(nft.balanceOf(msg.sender, _id) == 0)revert Insufficient_Balance();
        if(!nft.isApprovedForAll(msg.sender, address(this)))revert Insufficient_Allowance();

        uint256 tokenPrice = ms.nft[us.utils.nftContract][_id].price;
        uint256 upgradePrice = ms.nft[us.utils.nftContract][_upId].price;
        uint256 expectedPrice = upgradePrice - tokenPrice;

        IHoopx token = IHoopx(ms.nft[us.utils.nftContract][_upId].acceptableToken);
        if(token.balanceOf(msg.sender) < expectedPrice)revert Insufficient_Balance();
        if(token.allowance(msg.sender, address(this)) < expectedPrice)revert Insufficient_Allowance();

        uint256 burnAmount = expectedPrice.mulDiv(ms.membership.burnPercentage,1000);
        uint256 reserveAmount = expectedPrice - burnAmount;

        token.burnFrom(msg.sender,burnAmount);
        token.transferFrom(msg.sender,us.utils.reserveContract,reserveAmount);

        nft.burn(msg.sender,_id,1);
        nft.mint(msg.sender,_upId,1,"");

        emit HANDLE_NFT_UPGRADING_PROCESS(msg.sender,_id,_upId,block.timestamp);
    }


    function checkMember(
        address _user
    ) 
        public 
        view 
        returns (
            bool isMember
        ) 
    {
        IHoopNFT nft = IHoopNFT(Utils.layout().utils.nftContract);
        uint256[] memory tokenIds = Utils.layout().utils.tokenIds;
        uint256 idsLength = tokenIds.length;

        if(LibStake.layout().user[_user].isStaker){
            isMember = true;
        }else {
            for (uint256 i = 0; i < idsLength;) {
                bool member = nft.balanceOf(_user,tokenIds[i]) > 0;
                if (!member) {
                    unchecked {
                        i++;
                    }
                }else {
                    isMember = true;
                    break;
                }
            }
        }
    }

    function getOwnedNFTs(
        address _user
    ) 
        public 
        view 
        returns(uint256[] memory) 
    {
        Utils.Layout storage us = Utils.layout();
        IHoopNFT nft = IHoopNFT(us.utils.nftContract); 

        uint256[] memory tokenIDs = us.utils.tokenIds;
        uint256 tokenIDLengths = tokenIDs.length;

        uint256 count = 0;
        uint256[] memory ownedNFTs = new uint256[](tokenIDLengths);
        
        for (uint256 i = 0; i < tokenIDLengths;){
            if (nft.balanceOf(_user, tokenIDs[i]) > 0){
                ownedNFTs[count] = tokenIDs[i];
                unchecked {
                    count++;
                }
            }
            unchecked {
                i++;
            }
        }

        uint256[] memory result = new uint256[](count);

        for (uint256 j = 0; j < count;){
            result[j] = ownedNFTs[j];

            unchecked {
                j++;
            }
        }
        return result;
    }

}