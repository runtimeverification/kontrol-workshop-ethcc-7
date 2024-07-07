## Verifying Solady's `mulWad`

As an example of proof development we're going to verify the Solady `mulWad` function. You can find it in the [Solady repo](https://github.com/Vectorized/solady/blob/65a32cda377153622c4ad49ca79c0127e0f32a73/src/utils/FixedPointMathLib.sol#L64), but we provide a version in [src/MulWad.sol](./src/MulWad.sol):

```solidity
    function mulWad(uint256 x, uint256 y) public pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                mstore(0x00, 0xbac65e5b) // `MulWadFailed()`.
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), WAD)
        }
    }
```

### `mulWad` specs

Let's specify how `mulWad` should behave. Executing `mulWad(x, y)` should perform a rounded-down fixed-point multiplication of `x` and `y` with the first 18 digits treated as decimal. This is captured by the formula `(x * y)/WAD` where `WAD=1e18`.

That is for the case wehre `x * y` doesn't overflow. In the case `x * y > types(uint256).max`, `mulWad(x, y)` should revert. This is captured by the following test:

```solidity
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
```

### Proving that the specs hold

To prove that the above specification holds we must execute it symbolically with Kontrol. This will ensure that for every possible `uint256 x` and `uint256 y`, what the property test describes holds.

As we have done before, we first build the project
```
kontrol build
```
and then execute the proof
```
kontrol prove --mt testMulWad
```

### Trouble in paradise

If you've successfully executed the above steps, you've also have been "greeted" by the following message
```
❌ PROOF FAILED ❌ test%MulWadTest.testMulWad(uint256,uint256):0
```
together with this model
```
Model:
  TIMESTAMP_CELL = 0
  C_MULWADTEST_ID = 2
  VV1_y_114b9705 = 1
  CALLER_ID = maxUInt160
  NUMBER_CELL = 0
  ORIGIN_ID = 10
  VV0_x_114b9705 = maxUInt256
```
informing us that the proof is failing for `x = maxUInt256` and `y = 1`. But... these values don't seem problematic at all. To understand the cause of the failure we'll need to inspect the KCFG (K Control Flow Graph) by running
```
kontrol show testMulWad
```

We can see that the problematic part starts at node 11 and ends reverting at node 16:
```
      ├─ 11 (split)
      │   k: JUMPI 2674 bool2Word ( chop ( ( VV1_y_114b9705:Int *Int bool2Word ( ( maxUInt256 ...
      │   pc: 2660
      │   callDepth: 0
      │   statusCode: STATUSCODE:StatusCode
      ┃
      ┃ (branch)
      ┣━━┓ constraint: 0 ==Int chop ( ( VV1_y_114b9705:Int *Int bool2Word ( ( maxUInt256 /Int VV1_y_114b9705:Int ) <Int VV0_x_114b9705:Int ) ) )
      ┃  │
      ┃  ├─ 13
      ┃  │   k: JUMPI 2674 bool2Word ( chop ( ( VV1_y_114b9705:Int *Int bool2Word ( ( maxUInt256 ...
      ┃  │   pc: 2660
      ┃  │   callDepth: 0
      ┃  │   statusCode: STATUSCODE:StatusCode
      ┃  │
      ┃  │  (146 steps)
      ┃  ├─ 15 (terminal)
      ┃  │   k: #halt ~> CONTINUATION:K
      ┃  │   pc: 394
      ┃  │   callDepth: 0
      ┃  │   statusCode: EVMC_SUCCESS
      ┃  │   src: lib/forge-std/src/StdInvariant.sol:110:111
      ┃  │
      ┃  ┊  constraint: true
      ┃  ┊  subst: OMITTED SUBST
      ┃  └─ 2 (leaf, target, terminal)
      ┃      k: #halt ~> CONTINUATION:K
      ┃      pc: PC_CELL_5d410f2a:Int
      ┃      callDepth: CALLDEPTH_CELL_5d410f2a:Int
      ┃      statusCode: STATUSCODE_FINAL:StatusCode
      ┃
      ┗━━┓ constraint: ( notBool chop ( ( VV1_y_114b9705:Int *Int bool2Word ( ( maxUInt256 /Int VV1_y_114b9705:Int ) <Int VV0_x_114b9705:Int ) ) ) ==Int 0 )
         │
         ├─ 14
         │   k: JUMPI 2674 bool2Word ( chop ( ( VV1_y_114b9705:Int *Int bool2Word ( ( maxUInt256 ...
         │   pc: 2660
         │   callDepth: 0
         │   statusCode: STATUSCODE:StatusCode
         │
         │  (26 steps)
         └─ 16 (leaf, terminal)
             k: #halt ~> CONTINUATION:K
             pc: 2673
             callDepth: 0
             statusCode: EVMC_REVERT
```

We can see that node 11 results in the following branching condition:
```
0 ==Int chop ( ( VV1_y_114b9705:Int *Int bool2Word ( ( maxUInt256 /Int VV1_y_114b9705:Int ) <Int VV0_x_114b9705:Int ) ) )
```
Which, if we remove syntactic clutter and rewrite `chop _` by `_ mod maxUInt256`:
```
0 == (y * bool2Word ( ( maxUInt256 / y ) < x )) mod maxUInt256
```
From looking at the above `mulWad` function we can identify this statement with the `if` condition:
```solidity
if mul(y, gt(x, div(not(0), y)))
```

Thus, the branch that starts with node `13` evaluates to `0` the condition of the `if` statement, whereas the branch starting with node `14` evaluates the condition to `!= 0`, entering the branch and reverting.

But if Kontrol gave us `x = maxUInt256` and `y = 1` as a counterexample, how is it possible that the condition in the `mul(y, gt(x, div(not(0), y)))` is evaluated to something different than `0`? Something is off here. Let's look at thesome of the constraints of the node leading to the branch, node `11`, that concern to `x` and `y`:
```
{ true #Equals 0 <=Int VV0_x_114b9705:Int }
{ true #Equals 0 <=Int VV1_y_114b9705:Int }
{ true #Equals VV0_x_114b9705:Int <Int pow256 }
{ true #Equals VV1_y_114b9705:Int <Int pow256 }
{ true #Equals ( notBool VV1_y_114b9705:Int ==Int 0 ) }
{ true #Equals VV0_x_114b9705:Int <=Int ( maxUInt256 /Int VV1_y_114b9705:Int ) }
```

So, we have that `y != 0` and `x <= maxUInt256 / y`! This implies that `( maxUInt256 / y ) < x` is false, and therefore the branch that leads to the revert should not exist! Why is this happening?

If we look at the branching condition, `chop ( ( VV1_y_114b9705:Int *Int bool2Word ( ( maxUInt256 /Int VV1_y_114b9705:Int ) <Int VV0_x_114b9705:Int ) ) )`, the only non-arithmetic function is `bool2Word`, a KEVM function that maps `true` to `1` and `false` to 0. To learn more about the function we can go to th [evm-semantics repo](https://github.com/runtimeverification/evm-semantics/) and ask how is this defined. To do this, from the root of the evm-semantics repo run:
```
cd kevm-pyk/src/kevm_pyk/kproj/evm-semantics
```
and then search for the rules that define `bool2Word`:
```
git grep "rule bool2Word"
```
which outputs the following rules:
```k
rule bool2Word( true  ) => 1
rule bool2Word( false ) => 0
rule bool2Word(A) |Int bool2Word(B) => bool2Word(A  orBool B) [simplification]
rule bool2Word(A) &Int bool2Word(B) => bool2Word(A andBool B) [simplification]
rule bool2Word(_B) |Int 1 => 1            [simplification]
rule bool2Word( B) &Int 1 => bool2Word(B) [simplification]
rule bool2Word(X ==Int 1) => X         requires #rangeBool(X) [simplification]
rule bool2Word( B:Bool ) ==Int I => B ==K word2Bool(I)    [simplification, concrete(I)]
```

Without entering too much in the nitty-gritty of what these rules mean, we can see that there are no rules for evaluating the contents of `bool2Word`. This means that Kontrol is treating `bool2Word ( ( maxUInt256 /Int VV1_y_114b9705:Int ) <Int VV0_x_114b9705:Int ) )` as symbolic, instead of trying to evaluate it.

### Telling Kontrol what to do

Our mission is clear now. Kontrol has enough information to determine that
```
bool2Word ( ( maxUInt256 /Int VV1_y_114b9705:Int ) <Int VV0_x_114b9705:Int )
```
evaluates to `0`, and thus so does the condition of the `JUMPI` instruction of node `11`:
```
bool2Word ( chop ( ( VV1_y_114b9705:Int *Int bool2Word ( ( maxUInt256 /Int VV1_y_114b9705:Int ) <Int VV0_x_114b9705:Int ) ) ) )
```
which means that the reverting branch should not exist.

How do we instruct Kontrol to try to evaluate the conditions inside the `bool2Word` functions? Using ✨lemmas✨.

We must provide two new rules to Kontrol about the `bool2Word` function defining the behavior of evaluating its contents. The rules in question are the following:
```
rule bool2Word ( X ) => 1 requires X         [simplification]
rule bool2Word ( X ) => 0 requires notBool X [simplification]
```
Now Kontrol will try to simplify the expressions inside `bool2Word` to see if it can be rewritten to `1` or `0`.

The way of telling Kontrol "hey, use this extra rules when you're reasoning" is via the [`lemmas.k`](./lemmas.k) file. Once we've written the new rules (also called lemmas) into the `lemmas.k` file we have to feed it to Kontrol while building the project:
```
kontrol build --requires lemmas.k --module MulWad:KONTROL-LEMMAS
```

After having done this, we can successfully run the specs:

```
kontrol prove --mt testMulWad
```
which will result in the happy message `✨ PROOF PASSED ✨ test%MulWadTest.testMulWad(uint256,uint256)`
