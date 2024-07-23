## External Computation with Kontrol

One of the ways of speeding up Kontrol proofs is to offload an initial part of the proof execution to Foundry.

The way we achieve this is via the cheatcodes [`vm.stopAndReturnStateDiff`](https://book.getfoundry.sh/cheatcodes/stop-and-return-state-diff) or `vm.dumpState` (undocumented at the time of writing). Depending on the cheatcode used the approach is slightly different. However, in both cases we produce a JSON containing the state of the chain after executing some code, and load that state into Kontrol.

We'll be using `vm.dumpState` since it's easier to work with. For complete instructions on how to include external computation with `vm.stopAndReturnStateDiff` [see the documentation](https://github.com/runtimeverification/kontrol/tree/master/docs/external-computation).

### Record your Foundry execution

Follow these steps to properly record any Foundry execution of your choice.

#### 1. Create the JSON file where the state updates will be recorded (not necessary if using our contracts)

In this example we've used the file [`state-dump/StateDump.json`](./state-dump/StateDump.json).

#### 2. Give Foundry permissions to write to the file

This is done by adding the following lines to the `foundry.toml` file. Note that we've selected the entire `state-dump` folder.
```toml
fs_permissions = [
  { access="read-write", path="state-dump" }
]
```

#### 3. Add `vm.dumpState` to your function

To have Foundry record your executions into `state-dump/StateDiff.json`, add the `vm.dumpState("state-dump/StateDump.json")` cheatcode to the function you want to record as in [our example](./src/ExternalComputation.sol), where we deploy 9 different `Counter` contracts, set a number and deal it some ETH:
```solidity
function severalCountersDump() public {
    for (uint256 i; i <= 9; ++i) {
        counter = new Counter();
        counter.setNumber(i);
        vm.deal(address(counter), i * (1 ether));
    }
    vm.dumpState("state-dump/StateDump.json");
}
```

#### 4. Execute the function with Foundry

To run this function with Foundry we recommend using `forge script` since it can execute functions with arbitrary names including cheatcodes. To run the function above, which is in the contract `ExternalComputation` of the `src/ExternalComputation.sol` file, you can run
```
forge script src/ExternalComputation.sol:ExternalComputation --sig severalCountersDump
```
This will produce a [JSON](./state-dump/StateDump.json) where each entry is an address indicating its state:
```json
  "0x2e234dae75c793f67a35089c9d99245e1c58470b": {
    "nonce": "0x1",
    "balance": "0xde0b6b3a7640000",
    "code": "0x6080604052348015600f57600080fd5b5060043610603c5760003560e01c80633fb5c1cb1460415780638381f58a146053578063d09de08a14606d575b600080fd5b6051604c3660046083565b600055565b005b605b60005481565b60405190815260200160405180910390f35b6051600080549080607c83609b565b9190505550565b600060208284031215609457600080fd5b5035919050565b60006001820160ba57634e487b7160e01b600052601160045260246000fd5b506001019056fea264697066735822122037d3e0197c9d08f161dbb1697fcd490e178cceed9f688846b9eca0fb960fecdc64736f6c63430008190033",
    "storage": {
      "0x0000000000000000000000000000000000000000000000000000000000000000": "0x0000000000000000000000000000000000000000000000000000000000000001"
    }
  }
```

#### 5. Save the name of deployed contracts

However, note that the information provided here is not pointing to any contract name. This will make it quite hard to write tests if we can only refer to the deployed contracts by their address. To resolve this, we provide the `save_address` function in the [`SaveAddress` contract](src/SaveAddress.sol), which saves the addresses together with the name we'll want to use in our tests.

We also provide the `check_file` function, which checks if the provided file exists and creates it if not.
Note that the variables `folder`, `dumpStateFile` and `addressNameFile` are set in the `SaveAddress` contract.

Thus, the final version of the `severalCountersDump` recording all the information necessary is the following:
```solidity
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
```
To successfully execute this function we must append `--ffi` to the above command due to the `check_file` function:
```
forge script src/ExternalComputation.sol:ExternalComputation --sig severalCountersDump --ffi
```
Now we'll also have a [`state-dump/AddressNames.json`](state-dump/AddressNames.json) containing addresses and names:
```json
"0x2e234DAe75C793f67A35089C9d99245E1C58470b": "counter1"
```
You can check that the address of `counter1` corresponds to the above entry where `number` (slot 0) is set to `1`!

### Write specs using offloaded computation

So far, we have deployed `10` `Counter` contracts, set `number` to `n-1`, and dealt `n-1` ETH respectively for each contract. We've also stored the state updates resulting from this together with the names of each address. The next natural step is writing a test that will take this information into account. Follow the next steps to successfully include your recorded computation into any Kontrol proof.

#### 1. Generate helper contracts with Kontrol

The very first step is to convert the JSON files produced above into a Solidity contract that we can use. We'll use the Kontrol feature `load-state-diff` to save the necessary helper contracts to `test/RecordedState.sol`:
```
kontrol load-state-diff RecordedState state-dump/StateDump.json --contract-names state-dump/AddressNames.json --output-dir test
```
Executing this command will create the files [`test/RecordedState.sol`](test/RecordedState.sol) and [`test/RecordedStateCode.sol`](test/RecordedStateCode.sol). The last one only contains the code of the addresses. The first one, `RecordedStates.sol`, consists of two parts: naming the addresses as provided by the `AddressNames.json` file,
```solidity
address internal constant counter8Address = 0x03A6a84cD762D9707A21605b548aaaB891562aAb;
address internal constant counter6Address = 0x1d1499e622D69689cdf9004d05Ec547d650Ff211;
address internal constant counter1Address = 0x2e234DAe75C793f67A35089C9d99245E1C58470b;
address internal constant counter0Address = 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f;
address internal constant counter3Address = 0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9;
address internal constant counter7Address = 0xA4AD4f68d0b91CFD19687c881e50f3A00242828c;
address internal constant counter9Address = 0xD6BbDE9174b1CdAa358d2Cf4D57D1a9F7178FBfF;
address internal constant counter2Address = 0xF62849F9A0B5Bf2913b396098F7c7019b51A820a;
address internal constant counter5Address = 0xa0Cb889707d426A7A386870A03bc70d1b0697598;
address internal constant counter4Address = 0xc7183455a4C133Ae270771860664b6B7ec320bB1;
```
and a function to recreate the state in `StateDump.json`
```solidity
function recreateState() public {
		bytes32 slot;
		bytes32 value;
		vm.etch(counter3Address, counter3Code);
		vm.deal(counter3Address, 3000000000000000000);
		slot = hex'0000000000000000000000000000000000000000000000000000000000000000';
		value = hex'0000000000000000000000000000000000000000000000000000000000000003';
		vm.store(counter3Address, slot, value);
        ...
```

#### 2. Write the test using the helper contracts

We now have a contract allowing us to name the addresses that we have records of. Thus, if we want to test that each contract has the amount of ETH and the number we recorded, one can write [that test](test/ExternalComputation.t.sol) as follows:
```solidity
contract ExternalComputationTest is RecordedState {
    function prove_multiple_counters() public {
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
```
#### 3. Run your test with Kontrol

However, note that the test starts with `prove` and not `test`, and that we have not called the `recreateState` function in any part of the test. Indeed, the reason for the first observation is the second one. If we were to execute the `prove_multiple_counters` in Foundry we would get an error. The reason being that from Foundry's point of view, all these 10 addresses don't have any state associated with them.

One way to solve this is by calling `recreateState` at some point. But if we're running the test with Kontrol, we don't need to call `recreateState`. We can just pass the `StateDump.json` via the `--init-node-from-dump` flag to indicate which are the state updates needed to take into account before running the test (don't forget to `kontrol build` first):
```
kontrol prove --mt prove_multiple_counters --init-node-from-dump state-dump/StateDump.json
```
After executing this command we'll get the following gratifying message:
```
✨ PROOF PASSED ✨ test%ExternalComputationTest.prove_multiple_counters():0
```
