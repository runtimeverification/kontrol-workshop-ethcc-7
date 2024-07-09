ETHCC[7] Kontrol Workshop
-------------------------

In this repo you'll find all the examples treated at the ETHCC[7] Kontrol workshop with detailed instructions.

You can also step through the [presentation](./Presentation-ETHCC7.pdf).

## Getting Kontrol

We recommend installing Kontrol via the K framework package manager, `kup`.

To get `kup` and install Kontrol:
```shell
bash <(curl https://kframework.org/install)
kup install kontrol
```

For more information you can visit the [`kup` repo](https://github.com/runtimeverification/kup) and the [`kup` cheatsheet](https://docs.runtimeverification.com/kontrol/cheatsheets/kup-cheatsheet).

## Using Docker Instead

We also provide a docker image with all the commands already executed in case you want to walk through the instructions provided but don't want to compute the examples yourself.

To get the docker image and run a bash shell do
```shell
docker run -it ghcr.io/runtimeverification/kontrol/kontrol-workshop-ethcc-7
```

## `run-kontrol.sh`

It is customary with Kontrol projects to have a `run-kontrol.sh` script containing the steps to reproduce the proofs and some other features.
In this example we have a top-level `run-kontrol.sh` which in turn executes each folder's `run-kontrol.sh`.

The options for the toplevel `run-kontrol.sh` are to execute examples or to clean the produced files by the execution.

#### Running examples
- `./run-kontrol.sh` will run all subsequent `run-kontrol.sh` for each folder, executing all the examples in order
- `./run-kontrol.sh $folder_name` will run `$folder_name`'s `run-kontrol.sh`, executing only `$folder_name`'s examples

#### Cleaning computation files
- `./run-kontrol.sh clean` will orderly clean all computation files in each folder
- `./run-kontrol.sh clean $folder_name` will clean `$folder_name`'s execution files

## Examples Walkthrough

Examples are divided intwo two sections: basic Kontrol usage and Kontrol on Roids. First block corresponds to basic Kontrol usage, to get familiar with the tool. The second block contains powerful resources that we use to increase Kontrol's capabilities as much as possible.

### Kontrol usage

Here you'll learn from the very basic commands to how to start debugging a Kontrol proof.

#### 1. [Your First Kontrol Proof](./1-your-first-proof)

This folder exemplifies how to use `kontrol build` and `kontrol prove` with the default template code produced by `forge init`.

#### 2. [When Fuzzing Fails](./2-when-fuzzing-fails)

How does an example of something that might not be catched by a fuzz test, but is catched by Kontrol? Here we go over a simple (but eloquent) example of how such a case might look like, and how to appropriately read the output in Kontrol.

#### 3. [Proof Debugging](./3-proof-debugging)

The last step to becomming more comfortable with Kontrol is to learn how to debug a proof. Not all failed proofs mean that there's a bug in the code. Through this example we show a way of discerning why can a proof fail and how to correctly address it. The function under verification is Solady's `mulWad`.

If you're running the examples with the docker image, in this example we have one extra Foundry profile called `lemmas` that will succesfully run the `mulWad` specs, whereas the regular foundry profile will not.

### Kontrol On Roids

What follows is the most recent improvements we have made to Kontrol, allowing you to take its usage to the next level.

#### 4. [External Computation](./4-external-computation)

Kontrol is both time and resource intensive, but here's a way of saving an arbitrary amount of time when executing a proof in Kontrol. This example instrucs on how to offload the initial part of your proof computation to Foundry (which is blazing fast) and then incorporate it into a Kontrol proof. Pretty neat!

#### 5. [Compositional Symbolic Execution (CSE)](5-compositional-symbolic-execution)

Continuing our efforts to improve Kontrol's performance, we introduce a novel technique to scale execution by composing multiple proofs. The aim is to enhance the process of symbolic execution by avoiding computation redundancies. If a function is executed multiple times, we will prove it once and then reuse the proof every time it is called. As an example, we will be using an ERC20 token contract.

#### 6. Parallelization

Although this section doesn't come with an example, we briefly show here how to parallelize execution in Kontrol.

You can run multiple proofs in parallel and multiple proof branches in parallel. The one rule of thumb we usually follow is to have `(RAM - 8) / 8` parallel Kontrol processes for a machine with `RAM`GB of memory. Note that this is not a hard limit! If you run out of memory you'll just get a Kontrol error about resource exhaustion.

**Running Parallel Proofs:** Add `--workers n` to `kontrol prove` to run `n` proofs in parallel. E.g.,
```
kontrol prove --mt test1 --mt test2 --workers 2
```
Note that if you create a Kontrol project via `kontrol init`, the default value set in `kontrol.toml` is of `--workers 4`.

**Running Parallel Branches:** There's a two step process to run a proof with parallel branches, one for `kontrol build` and another one with `kontrol prove`.

1. Add `GHCRTS=''` to `kontrol build`:
    ```
    GHCRTS='' kontrol build
    ```
2. Add `GHCRTS='-Nn'` together with `--max-frontier-parallel n` to `kontrol prove` to run `n` parallel branches:
    ```
    GHCRTS='-N6' kontrol prove --mt prove_collatz_conjecture --max-frontier-parallel 6
    ```

## Documentation, Socials and Posts

Have more appetite for formal verification and Kontrol? The following resources will sort you out!

### Kontrol ecosystem

Get to know Kontrol more in depth. Open a PR or an issue!

- [Kontrol documentation](https://docs.runtimeverification.com/kontrol/cheatsheets/kup-cheatsheet)
- [Kontrol repo](https://github.com/runtimeverification/kontrol)

### Socials

You can reach us on any of these platforms. We'll answer any questions and provide guidance throughout your Kontrol journey!

- [Telegram](https://t.me/rv_kontrol)
- [Discord](https://discord.com/invite/CurfmXNtbN)
- [Twitter/X](https://x.com/rv_inc)

### Blog Posts

Want to learn more about Kontrol, formal verification, and the cool things we do? Read any of these posts!

- [Optimism's pausability system verification](https://runtimeverification.com/blog/kontrol-integrated-verification-of-the-optimism-pausability-mechanism)
- [Kontrol 101](https://runtimeverification.com/blog/kontrol-101)
- [Why does Formal Verification work?](https://runtimeverification.com/blog/formal-verification-lore)
