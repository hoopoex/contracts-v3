// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import  "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import '@solidstate/contracts/access/ownable/OwnableInternal.sol';
import { LibMembership } from "../../libraries/LibMembership.sol";
import { Modifiers } from "../../libraries/Modifiers.sol";
import { IHoopNFT } from "../../interfaces/IHoopNFT.sol";
import { LibStake } from "../../libraries/LibStake.sol";
import { TUser } from "../../libraries/Structs.sol";
import { Utils } from "../../libraries/Utils.sol";
import "../../libraries/Errors.sol";

contract Stake is Modifiers, ReentrancyGuard, OwnableInternal {

    event HANDLE_CLAIM(address indexed addr,uint256 when);
    event HANDLE_UNSTAKE(address indexed addr,uint256 when);
    event HANDLE_ADD_LIQUIDITY(address indexed addr,uint256 when);
    event HANDLE_STAKE(address indexed addr,uint256 id,uint256 when);

    function stake(
        uint256 _id
    ) 
        external 
        nonReentrant 
        whenNotContract(msg.sender) 
    {
        Utils.Layout storage us = Utils.layout();
        LibStake.Layout storage ss = LibStake.layout();
        if(ss.stakeVeriables.isPausedStake)revert Paused();
        if(ss.user[msg.sender].isStaker)revert User_Already_Staked();
        if(!Utils.checkExistence(us.utils.tokenIds,_id))revert Invalid_Action();

        uint256 nftMultipler = LibMembership.layout().nft[us.utils.nftContract][_id].multipler;

        unchecked {
            ss.stakePool.poolTotalStakeScore += nftMultipler;
            ss.stakePool.poolNumberOfStakers += 1;
        }

        ss.user[msg.sender] = TUser({
            isStaker               : true,
            userMultipler          : nftMultipler,
            userChangeCountIndex   : 0,
            userStakedNFTId        : _id,
            userEarnedToken0Amount : ss.user[msg.sender].userEarnedToken0Amount,
            userEarnedToken1Amount : ss.user[msg.sender].userEarnedToken1Amount
        });

        LibStake.supportUpdateChc(msg.sender);

        LibStake.supportTransferERC1155(_id,1,msg.sender,address(this),us.utils.nftContract);

        emit HANDLE_STAKE(msg.sender,_id,block.timestamp);
    }

    function unstake(
    ) 
        external 
        nonReentrant 
        whenNotContract(msg.sender) 
    {
        Utils.Layout storage us = Utils.layout();
        LibStake.Layout storage ss = LibStake.layout();

        if(LibStake.layout().stakeVeriables.isPausedStake)revert Paused();
        if(!ss.user[msg.sender].isStaker)revert User_Not_Staker();

        LibStake.supportSafeClaim(msg.sender);

        unchecked {
            ss.stakePool.poolTotalStakeScore   -= ss.user[msg.sender].userMultipler;
            ss.stakePool.poolNumberOfStakers   -= 1;
        }

        uint256 stakedNFTId = ss.user[msg.sender].userStakedNFTId;

        ss.user[msg.sender] = TUser({
            isStaker               : false,
            userMultipler          : 0,
            userChangeCountIndex   : 0,
            userStakedNFTId        : 0,
            userEarnedToken0Amount : ss.user[msg.sender].userEarnedToken0Amount,
            userEarnedToken1Amount : ss.user[msg.sender].userEarnedToken1Amount
        });

        LibStake.supportUpdateChc(address(0));

        IHoopNFT(us.utils.nftContract).safeTransferFrom(address(this),msg.sender,stakedNFTId,1,"");

        emit HANDLE_UNSTAKE(msg.sender,block.timestamp);
    }

    function claimRewards(
    ) 
        external 
        nonReentrant 
        whenNotContract(msg.sender) 
    {
        if(LibStake.layout().stakeVeriables.isPausedStake)revert Paused();
        if(!LibStake.layout().user[msg.sender].isStaker)revert User_Not_Staker();

        LibStake.supportSafeClaim(msg.sender);
        LibStake.supportUpdateChc(msg.sender);

        emit HANDLE_CLAIM(msg.sender,block.timestamp);
    }

    function addLiquidity(
        uint256 _amount,
        address _tokenAddress
    ) 
        external 
        onlyOwner 
        isValidContract(_tokenAddress) 
    {
        LibStake.Layout storage ss = LibStake.layout();

        if (_tokenAddress == ss.stakeVeriables.token0ContractAddress) {
            unchecked {
                ss.stakePool.poolToken0LiquidityAmount += _amount;
                ss.stakePool.poolToken0RewardPerTime = _amount / 365 days;
                ss.stakePool.poolToken0DistributionEndDate = block.timestamp + 365 days;
            }
        } else if (_tokenAddress == ss.stakeVeriables.token1ContractAddress) {
            unchecked {
                ss.stakePool.poolToken1LiquidityAmount += _amount;
                ss.stakePool.poolToken1RewardPerTime = _amount / 365 days;
                ss.stakePool.poolToken1DistributionEndDate = block.timestamp + 365 days;
            }
        } else {
            revert Invalid_Address();
        }

        LibStake.supportTransferERC20(_amount,msg.sender,address(this),_tokenAddress);
        LibStake.supportUpdateChc(address(0));

        emit HANDLE_ADD_LIQUIDITY(msg.sender,block.timestamp);
    }

    function onERC1155Received(
        address, 
        address, 
        uint256, 
        uint256, 
        bytes memory
    ) 
        public 
        virtual 
        returns(bytes4) 
    {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address, 
        address, 
        uint256[] memory, 
        uint256[] memory, 
        bytes memory
    ) 
        public 
        virtual 
        returns(bytes4) 
    {
        return this.onERC1155BatchReceived.selector;
    }
    
}