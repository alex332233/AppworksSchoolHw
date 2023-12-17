// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IPool.sol";
import "../Uniswap/ISwapRouter.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../CToken.sol";
import "../CErc20Delegator.sol";

contract AaveFlashLoan {
    IPool pool = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
    ISwapRouter router =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    ERC20 uni = ERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);

    function flashLoan(
        address token,
        uint256 amount,
        bytes calldata params
    ) external {
        pool.flashLoanSimple(address(this), token, amount, params, 0);
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        require(msg.sender == address(pool), "only pool can call");
        require(initiator == address(this), "only this contract can call");
        require(premium <= amount, "premium too high");

        CErc20Delegator cUSDC = abi.decode(params, (CErc20Delegator));
        CErc20Delegator cUNI = abi.decode(params, (CErc20Delegator));
        address user1 = abi.decode(params, (address));

        ERC20(asset).approve(address(cUSDC), amount);
        cUSDC.liquidateBorrow(user1, amount, cUNI);
        cUNI.redeem(cUNI.balanceOf(address(this)));

        uni.approve(address(router), uni.balanceOf(address(this)));
        router.exactInputSingle(
            ISwapRouter.ExactInputSingleParams(
                address(uni),
                address(asset),
                3000, // 0.3% fee
                address(this),
                block.timestamp,
                uni.balanceOf(address(this)),
                0,
                0
            )
        );

        ERC20(asset).approve(address(pool), amount + premium);

        ERC20(asset).transfer(
            msg.sender,
            ERC20(asset).balanceOf(address(this))
        );

        return true;
    }
}
