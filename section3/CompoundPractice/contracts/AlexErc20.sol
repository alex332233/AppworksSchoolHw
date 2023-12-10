// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AlexErc20 is ERC20 {
    constructor() ERC20("AlexErc20", "AE2") {}
}

contract AlexErc20TokenB is ERC20 {
    constructor() ERC20("AlexErc20TokenB", "AE2B") {}
}
