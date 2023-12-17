// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IPool {
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referalCode
    ) external;
}
