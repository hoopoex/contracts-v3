// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;


import { TStakePool,TStakeVeriables, TUser,TMembership,TNFT,TUtils,TXPad,TXProject,TXUserInfo,TXUserData } from "../../libraries/Structs.sol";
import { LibMembership } from "../../libraries/LibMembership.sol";
import { LibStake } from "../../libraries/LibStake.sol";
import { LibXPad } from "../../libraries/LibXPad.sol";
import { Utils } from "../../libraries/Utils.sol";

contract Query {

    function getStakePool(
    ) 
        public 
        view 
        returns (
            TStakePool memory pool_
        ) 
    {
        pool_ = LibStake.layout().stakePool;
    }

    function getStakeVeriables(
    ) 
        public 
        view 
        returns (
            TStakeVeriables memory veriables_
        ) 
    {
        veriables_ = LibStake.layout().stakeVeriables;
    }

    function getStaker(
        address _user
    ) 
        public 
        view 
        returns (
            TUser memory user_
        ) 
    {
        user_ = LibStake.layout().user[_user];
    }

    function getRewards(
        address _user
    ) 
        public 
        view 
        returns (uint256,uint256) 
    {
        (
            uint256 token0Rewards,
            uint256 token1Rewards
        ) = LibStake.supportCalculateRewards(_user);

        return (token0Rewards,token1Rewards);
    }

    function getMembership(
    ) 
        public 
        view 
        returns (
            TMembership memory membership_
        ) 
    {
        membership_ = LibMembership.layout().membership;
    }

    function getNft(
        uint256 _id
    ) 
        public 
        view 
        returns (
            TNFT memory nft_
        ) 
    {
        nft_ = LibMembership.layout().nft[Utils.layout().utils.nftContract][_id];
    }

    function getUtils(
    ) 
        public 
        view 
        returns (
            TUtils memory utils_
        ) 
    {
        utils_ = Utils.layout().utils;
    }

    function getXPad(
    ) 
        public 
        view 
        returns (
            TXPad memory xpad_
        ) 
    {
        xpad_ = LibXPad.layout().xPad;
    }

    function getXProjects(
    ) 
        public 
        view 
        returns (
            TXProject[] memory
        ) 
    {
        LibXPad.Layout storage xs = LibXPad.layout();
        uint256[] memory ids = xs.xPad.projects;
        uint256 idsLength = ids.length;
        TXProject[] memory projects = new TXProject[](idsLength);

        for (uint256 i = 0; i < idsLength;) {
            projects[i] = xs.xProject[ids[i]];

            unchecked{
                i++;
            }
        }
        return projects;
    }

    function getXProject(
        uint256 _id
    ) 
        public 
        view 
        returns(
            TXProject memory project_
        ) 
    {
        project_ =  LibXPad.layout().xProject[_id];
    }

    function getXUser(
        uint256 _id,
        address _address
    ) 
        public 
        view 
        returns(
            TXUserInfo memory xUser_
        ) 
    {
        xUser_ = LibXPad.layout().xUser[_address][_id];
    }

    function getXInvestmentors(
        uint256 _id
    ) 
        public 
        view 
        returns (
            TXUserData[] memory investmentors_
        ) 
    {
        investmentors_ = LibXPad.layout().xUserData[_id];
    }

}