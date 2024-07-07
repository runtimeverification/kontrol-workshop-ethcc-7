// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Counter} from "./Counter.sol";
import {SaveAddress} from "./SaveAddress.sol";

// forge script src/ExternalComputation.sol:ExternalComputation --sig severalCountersDump --ffi
// kontrol load-state-diff RecordedState state-dump/StateDump.json --contract-names state-dump/AddressNames.json --output-dir test
// kontrol prove --mt prove_multiple_counters --init-node-from-dump state-dump/StateDump.json

contract ExternalComputation is SaveAddress, Test {
    Counter counter;

    function severalCountersDump() public {
        for (uint256 i; i <= 9; ++i) {
            counter = new Counter();
            counter.setNumber(i);
            vm.deal(address(counter), i * (1 ether));
            string memory addressName = string.concat("counter", vm.toString(i));
            save_address(address(counter), addressName);
        }
        vm.dumpState(check_file(folder, dumpStateFile));
    }
}
