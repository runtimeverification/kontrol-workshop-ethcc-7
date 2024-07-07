## When Fuzzing Fails

Now we have a caffeinated version of `setNumber`, `setNumberCaffeinated`, which has a scheduled `0xC0FEE` break:

```solidity
function setNumberCaffeinated(uint256 newNumber, bool isTime) public {
        if(newNumber == 0xC0FFEE && isTime){
            revert CoffeBreak();
        }
        number = newNumber;
    }
```

We can duplicate the test of the original `setNumber`:

```solidity
function testFuzz_SetNumberCaffeinated(uint256 x, bool isTime) public {
        counter.setNumberCaffeinated(x, isTime);
        assertEq(counter.number(), x);
    }
```

However, `forge test --mt testFuzz_SetNumberCaffeinated` might just fail if the `0xC0FFEE` break is not found...

### In search of the `0xC0FFEE` break

Finding the `0xC0FFEE` break with Kontrol is as easy as running a fuzz test: first `kontrol build` and then

```
kontrol prove --mt testFuzz_SetNumberCaffeinated
````

We'll always get the following message informing us that a `0xC0FFEE` break has been found:

```
❌ PROOF FAILED ❌ test%CounterTest.testFuzz_SetNumberCaffeinated(uint256,bool):0
```

We also get a model from Kontrol telling us which were the parameters enabling the `0xC0FFEE` break:

```
  Model:
    NUMBER_CELL = 0
    CALLER_ID = 10
    ORIGIN_ID = 10
    VV0_x_114b9705 = 12648430
    VV1_isTime_114b9705 = 1
    TIMESTAMP_CELL = 0
```

The symbolic variables are `VV0_x_114b9705` and `VV1_isTime_114b9705`, which stand for our test inputs `x` and `isTime`. We can see that `x` is set to `12648430` (`uint` version of `0xC0FFEE`) and `isTime` to `1`, Kontrol's `true` representation.

### Further investigation:

To see how the execution tree looks like, run the following:

```
kontrol view-kcfg testFuzz_SetNumberCaffeinated
```
