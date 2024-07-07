// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    uint256 public number;

    error CoffeeBreak();

    function setNumberCaffeinated(uint256 newNumber, bool isTime) public {
        if (newNumber == 0xC0FFEE && isTime) {
            revert CoffeeBreak();
        }
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}
