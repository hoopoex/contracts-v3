// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { ISolidStateERC20 } from "@solidstate/contracts/token/ERC20/ISolidStateERC20.sol";
import  "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Modifiers } from "../../libraries/Modifiers.sol";
import { LibStake } from "../../libraries/LibStake.sol";
import { LibXPad } from "../../libraries/LibXPad.sol";
import "../../libraries/Errors.sol";

contract XPad is Modifiers, ReentrancyGuard {
    using Math for uint256;

    event HANDLE_XPAD_DEPOSIT(address indexed addr,uint256 id,uint256 when);
    event HANDLE_REGISTER_XPAD(address indexed addr,uint256 id,uint256 when);

    function xRegister(
        uint256 _id
    ) 
        external 
        nonReentrant 
        whenNotContract(msg.sender) 
    {
        LibXPad.Layout storage xs = LibXPad.layout();
        if(xs.xPad.isPausedXPad)revert Paused();
        if(!xs.xProject[_id].isExist)revert Invalid_Input();
        if(xs.xUser[msg.sender][_id].isRegister)revert User_Already_Registered();
        if(block.timestamp < xs.xProject[_id].registerStartDate)revert Wait_For_Register_Times();
        if(block.timestamp > xs.xProject[_id].registerEndDate)revert Wait_For_Register_Times();

        uint256 stakeScore = LibStake.layout().user[msg.sender].userMultipler;
        if(stakeScore < 1)revert User_Not_Staker();

        xs.xUser[msg.sender][_id].isRegister = true;
        xs.xUser[msg.sender][_id].xScore = stakeScore;

        unchecked {
            xs.xProject[_id].totalRegisteredScore += stakeScore;
            xs.xPad.userCount++;
        }

        emit HANDLE_REGISTER_XPAD(msg.sender,_id,block.timestamp);
    }

    function xDeposit(
        uint256 _id,
        uint256 _amount
    ) 
        external 
        nonReentrant 
        whenNotContract(msg.sender) 
    {
        LibXPad.Layout storage xs = LibXPad.layout();
        if(xs.xPad.isPausedXPad)revert Paused();
        if(!xs.xProject[_id].isExist)revert Invalid_Input();
        if(xs.xUser[msg.sender][_id].isInvestmentor)revert User_Not_Expired();
        if(!xs.xUser[msg.sender][_id].isRegister)revert User_Already_Registered();
        if(block.timestamp > xs.xProject[_id].depositEndDate)revert Insufficient_Deposit_Time();
        if(block.timestamp < xs.xProject[_id].depositStartDate)revert Insufficient_Deposit_Time();
        if(xs.xProject[_id].toBeCollectedValue == xs.xProject[_id].collectedValue)revert Sale_End();
        if(_amount < xs.xProject[_id].minDepositValue || _amount > xs.xProject[_id].maxDepositValue)revert Invalid_Price();

        uint256 remainingAmount = xs.xProject[_id].toBeCollectedValue - xs.xProject[_id].collectedValue;
        if(_amount > remainingAmount)revert Overflow_0x11();

        (uint256 allocation) = xCalculateAllocation(_id,msg.sender);
        if(_amount > allocation)revert Overflow_0x11();

        xs.xUser[msg.sender][_id].isInvestmentor = true;

        unchecked {
            xs.xPad.totalCollectedValue += _amount;
            xs.xProject[_id].collectedValue += _amount;
            xs.xUser[msg.sender][_id].depositedValue = _amount;
        }

        LibXPad._supportStoreUserData(_id,_amount,msg.sender);
        LibStake.supportTransferERC20(_amount,msg.sender,address(this),xs.xPad.usedToken);
        ISolidStateERC20(xs.xPad.usedToken).transfer(xs.xProject[_id].projectReserveContract,_amount);

        emit HANDLE_XPAD_DEPOSIT(msg.sender,_id,block.timestamp);
    }

    function xCalculateAllocation(
        uint256 _id,
        address _user
    ) 
        public 
        view 
        returns (
            uint256 allocation_
        )
    {
        LibXPad.Layout storage xs = LibXPad.layout();
        if (
            block.timestamp < xs.xProject[_id].depositEndDate && 
            block.timestamp > xs.xProject[_id].depositStartDate && 
            !xs.xUser[_user][_id].isInvestmentor
        ) {
            uint256 decimals = (10 ** ISolidStateERC20(xs.xPad.usedToken).decimals());
            uint256 weight = xs.xUser[_user][_id].xScore.mulDiv(decimals,xs.xProject[_id].totalRegisteredScore);
            allocation_ = weight.mulDiv(xs.xProject[_id].toBeCollectedValue,decimals);
        }
    }

}