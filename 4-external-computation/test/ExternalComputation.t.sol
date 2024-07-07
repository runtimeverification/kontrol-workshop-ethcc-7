// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";
import {RecordedState} from "./RecordedState.sol";

contract ExternalComputationTest is RecordedState {
    function prove_multiple_counters() public view {
        Counter[] memory counters = new Counter[](10);

        // Load all counters
        counters[0] = (Counter(address(counter0Address)));
        counters[1] = (Counter(address(counter1Address)));
        counters[2] = (Counter(address(counter2Address)));
        counters[3] = (Counter(address(counter3Address)));
        counters[4] = (Counter(address(counter4Address)));
        counters[5] = (Counter(address(counter5Address)));
        counters[6] = (Counter(address(counter6Address)));
        counters[7] = (Counter(address(counter7Address)));
        counters[8] = (Counter(address(counter8Address)));
        counters[9] = (Counter(address(counter9Address)));


        for (uint256 i; i <= 9; ++i) {
            require(counters[i].number() == i, "Bad number");
            require(address(counters[i]).balance == i * (1 ether), "Ill funded");
        }
    }
}
