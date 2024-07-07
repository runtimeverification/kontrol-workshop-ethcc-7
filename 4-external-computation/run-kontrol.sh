#!/bin/bash

forge script src/ExternalComputation.sol:ExternalComputation --sig severalCountersDump --ffi

kontrol load-state RecordedState state-dump/StateDump.json --contract-names state-dump/AddressNames.json --output-dir test

kontrol build

kontrol prove --mt prove_multiple_counters --init-node-from-dump state-dump/StateDump.json
