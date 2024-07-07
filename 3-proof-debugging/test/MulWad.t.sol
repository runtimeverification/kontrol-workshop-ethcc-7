// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {MulWad} from "../src/MulWad.sol";

contract MulWadTest is MulWad, Test {
    function testMulWad(uint256 x, uint256 y) public {
        // No overflow case
        if (y == 0 || x <= type(uint256).max / y) {
            uint256 zSpec = (x * y) / WAD;
            uint256 zImpl = mulWad(x, y);
            // mulWad behaves as specified
            assert(zImpl == zSpec);
        } else {
            // If overflow, it should revert
            vm.expectRevert(MulWadFailed.selector);
            // External call needed for expectRevert to kick in
            this.mulWad(x, y);
        }
    }
}
