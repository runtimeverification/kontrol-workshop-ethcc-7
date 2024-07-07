# Scaling Computation using CSE

Another way to scale the execution of Kontrol proofs is to make use of the compositionality of the proofs.
When a function is symbolically executed with Kontrol, all the possible paths are explored.
When the same function is called multiple times, all its execution paths are analyzed every time, which is redundant and time consuming.

In this example, we take a basic ERC20 token mock.
In [src/GLDToken.sol](src/GLDToken.sol) we define the contract, and the tests are under [tests/GLDToken.t.sol](tests/GLDToken.t.sol).
For this workshop, we did not add the initial supply or the option to mint tokens.
The reason for this is that the we want to make use of the `kevm.symbolicStorage(address)` cheat code, changing the storage of the contract to a symbolic, abstract storage.
With this, we can assume anything about the storage.
Any preconditions we need to make storage more constrained can be added with `vm.assume(bool)`. Otherwise, storage variables accessed during the execution will have a symbolic, abstract value.

You can notice that the test contract has a few auxiliary functions:
    - `hashedLocation(address,bytes32)` - This one is needed to compute the storage slot of the balance of an address in the storage.
    - `_notBuiltinOrPrecompiledAddress(address)` - This one is used to improve performance and remove redundant branches by assumming that a symbolic address is not any of the specific addresses used by Foundry and Kontrol, such as the address of the cheat code contracts, or the deployed test contract.
    - `unchangedStorage(bytes32)` - With the help of this modifier, we can ensure that the storage does not change for any given storage slot by comparing the storage slot value before and after executing the test.


#### Symbolic exploration of a Solidity funciton

Running `kontrol prove --match-test Contract.functionName --cse` on a function that does not have a prefix like `test`, `proof`, `check` will result in a symbolic exploration of that function.
The function will be executed symbolically, in a similar way to how a test function would be executed.
The difference between symbolically executing a test vs a function is that:
  1. the success predicate is not checked for functions.
This means that exceptional final states such as reverts are accepted, without marking the proof as a failed one.
  2. the function is executed in a more abstract and general state.


In addition to this, `--minimize-proofs` can be used as a flag to `kontrol prove` to minimize the resulting KCFG of a proof.
So, let's say you want to symbolically explore the `GLDToken.transfer(address,uint256)` function.

You can run
```
kontrol prove --match-test 'GLDToken.transfer(address,uint256)' --minimize-proofs --cse
```

After the proof has been finished, you can inspect the KCFG using `kontrol show 'GLDToken.transfer(address,uint256)'`.

#### Using CSE

Now, there are two ways to make use of the CSE of the proofs.
The first way is to manually instruct Kontrol to use the proof you have already generated as a dependency.
For this, you would run

```
kontrol prove --match-test GLDTokenTest.testTransferFailure_0 --include-summary 'GLDToken.transfer(address,uint256)' --minimize-proofs
```

What happens here is that for each proof you choose to include, Kontrol will parse the KCFG and generate simplification lemmas for each branch of the proof.
i.e.: If the calldata matches the signature of the `GLDToken.transfer(address,uint256)` function, and the `msg.sender` is `address(0)`, then directly apply the modifications of the final state that results in an `ERC20InvalidSender(address(0))` revert, instead of executing each opcode in the function.

The second way to use CSE is by adding `--cse` to a `prove` command.
This way, Kontrol will automatically parse the AST of the test function and identify all external calls made by this function, adding them as dependencies.

The advantage of this approach, is that the proof for `GLDToken.transfer(address,uint256)` will be executed once, and its summary will be used every time a `transfer` call is being made.

Want to try it?
Edit the `kontrol.toml` file to set `cse` and `minimize-proofs` to `true` in the `[prove.default]` profile, then just fire it up with `kontrol prove`.
