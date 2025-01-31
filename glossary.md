# Glossary

## Chains

### Hyperchain (HC)
A hybrid blockchain technology consisting of two blockchains: a delegated proof of stake (DPoS) child chain (CC) and a proof of work (PoW) parent chain (PC) where the child chain periodically synchronizes with the parent chain.

As a PoW secured DPoS, a hyperchain benefits from the scalability advantages of a DPoS blockchain with the security advantages of a PoW blockchain.

### Child Chain (CC)
A Delegated Proof of Stake blockchain that is one half of a hyperchain. The CC is configurable by the initiator and loosely connected to the parent chain. The child chain uses the parent chain as a source of entropy and for "pinning," but the parent chain has no knowledge of the child chain.

### Parent Chain (PC)
Any PoW blockchain that fulfills the role of "the other half" of a hyperchain by providing entropy for the CC and allowing for the pinning of data from the CC. The parent chain functions independently from and has no knowledge of the child chain.

## Blocks

### CC Block
Contains one keyblock and possibly one microblock.

### Keyblock
A block containing the state tree hashes and indicating which leader should produce a microblock.

### Microblock
A block with transactions.

## Epochs

### Child Chain Epoch
Period of time represented in blocks during which validators are pre-selected to produce blocks and after which the state of the CC can be pinned to the PC.
the unqualified "Epoch" may be assuemd to refer to a child chain epoch.

### Parent Chain Epoch
The number of blocks on the parent chain that indicates which parent chain block will be used as the source of entropy for leader election.

### Staking Cycle
Contains 5 epochs: staking epoch, entropy epoch, leader (s)election epoch, block production + pinning epoch, payout epoch. Represents minimum duration during which tokens are locked into staking contract.


```mermaid
gantt
    dateFormat  YYYY-MM-DD
    axisFormat  %W cycle
    tickInterval 1week

    section CC Epoch 1
    Staking          :a1, 2024-01-01, 6d

    section CC Epoch 2
    Staking          :a2, 2024-01-07, 6d
    Entropy          :a1, 2024-01-01, 6d

    section CC Epoch 3
    Staking          :c1, 2024-01-14, 6d
    Entropy          :a2, 2024-01-07, 6d
    Leader Election  :b1, 2024-01-01, 6d

    section CC Epoch 4
    Staking          :a1, 2024-01-21, 6d
    Entropy          :c1, 2024-01-14, 6d
    Leader Election  :b2, 2024-01-07, 6d
    Block Production :c1, 2024-01-01, 6d

    section CC Epoch 5
    Entropy          :b4, 2024-01-21, 6d
    Leader Election  :b3, 2024-01-14, 6d
    Block Production :c2, 2024-01-07, 6d
    Payout           :d1, 2024-01-01, 6d


    section CC Epoch 6
    Leader Election  :b4, 2024-01-21, 6d
    Block Production :c3, 2024-01-14, 6d
    Payout           :d2, 2024-01-07, 6d


    section CC Epoch 7
    Block Production :c4, 2024-01-21, 6d
    Payout           :d3, 2024-01-14, 6d

    section CC Epoch 8
    ... :c4, 2024-01-21, 6d
```

## Actors

### Initiator
The user who configures and launches the hyperchain.

### Node Operators (Staked and non-staked validators)
All participants running a CC node are node operators.


### Pinner (Pinning Leader)
Block producer at the end of epoch that is allowed to collect a reward for pinning on the parent chain and posting the proof back on the child chain.

### Validator
A node that acts on behalf of a staking contract to produce new block and validate the chain up till the previous block.


### Validator Pool
Validators eligible to become producers due to staking tokens

### Leader List
Producers chosen to act as leaders during an epoch

### Leader
Producer chosen to produce the current block


### Producers
Validator that produces a block.

### Delegator
Wallet/account that deposits tokens into staking contract on behalf of validator in order to increase the stake. Does not run a node or have further interaction with CC or PC.
Also sometimes called a staker.

## Delegate
The staking contract, its owner, the validator node and its operator.

```mermaid
graph TD
    %% Define graph direction
    direction LR

    %% Nodes and relationships
    G([👤 Producer Node Operator]) -->|Operates| F[[🖥️ Producer Node/Leader]]
    A([👤 Delegate/Staking Contract Owner]) -->|Manages| B[(📜 Staking Contract)]
    A -->|Probably same as| G
    C([👤 Staker/Delegator]) -->|Deposits Tokens| B
    B[(📜 Staking Contract)] -->|Represents Stake| D
    B'[(📜 Other Staking Contracts)] -->|Represents Stake| D
    D{{🗃️ Validator Pool}} -->|Eligible for Selection| D'
    D'{{🗃️ Leader List}} -->|Used for Selecting| E([🔍 Validator])
    E([🔍 Validator]) -->|May Become| F[[🖥️ Producer Node/Leader]]
    F -->|Validates and Produces Blocks| F

```


## Actions & Events

### Stake
The amount of tokens deposited by delegators representing the selection weight of the validator to be chosen as a leader.

### Leader Election
The weighted random selection of leader from among eligible validators based on the amount to tokens staked in a staking contract.

### Block Production
The act of creation of a block done by the producer


### Block Reward
Tokens minted and/or transferred to staking contract to reward successful block production.

### Pinning Reward
Tokens minted and/or transferred to staking contract to reward successful pinning operation.

### Halting
A situation when no more blocks are produced (due to all producers being inactive).
This creates a problem for the HC creator to recover the HC and resume the block production.

### Termination
Willful end of a hyperchain

## On-Chain Protocol Components

### Staking Contract
Contract used by validator to represent the validator's stake, the ID and stake amount of delegators, and contains the functions for withdrawal of rewards.


### Leader Election Contract
Election rules defined at contract level (as opposed to consensus level).

### Genesis Accounts
Accounts in which HC tokens are generated during the first block of CC.

