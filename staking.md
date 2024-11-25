# Staking


#### **Constants:**

- **`MINIMUM_STAKE`**: The minimum amount of tokens required to be eligible for leader selection in any given epoch.

#### **Participant's Balances:**

- **Total Balance (TB)**: The total number of tokens a participant has deposited in the staking contract via the `stake()` function.
- **Locked Balance (LB)**: The max of staked amounts over the **current staking cycle**, i.e., epochs `N` to `N + C`, where `C` is the number of epochs in the staking cycle (in our case, `C = 3`).
- **Available Balance (AB)**: The portion of the Total Balance that is not locked in the current staking cycle.
  - **AB = TB - LB**
- **Staking Schedule (SC)**: A mapping of epochs to the amount of tokens the participant has committed to stake in each of those epochs and onwards if not changed. As an ordered list ({epoch, stake amount, locked amount})

Automatic Restaking: Unless adjusted, the stake for an epoch automatically continues into future cycles.

---

#### **API Functions**
ytgg
1. **`deposit(producer:pubkey)`** (Payable Endpoint)
   - **Description**: Allows a participant to deposit tokens into the staking contract, increasing their Total Balance (TB) and Available Balance (AB).
   - **Parameters**:
     - producer - the pubkey of the producer who can become leader and then produce and sign blocks.
     -  (the amount is determined by the value of tokens sent with the transaction).
   - **When Callable**: At any time.
   - **Behavior**:
     - Increases TB by the amount of tokens sent.
     - Increases AB by the same amount.

2. **`withdraw(amount:unsigned integer)`**
   - **Description**: Allows a participant to withdraw tokens from their Available Balance (AB).
   - **Parameters**:
     - `producer`: The pubkey of the producer given in Call.caller.
     - `amount`: The amount of tokens to withdraw.
   - **When Callable**: At any time.
   - **Constraints**:
     - `amount` must be less than or equal to AB.
     - Cannot withdraw tokens locked in the current staking cycle (i.e., tokens committed in SS for epochs `N` to `N + C`).

3. **`adjustStake(amount:integer)`**
   - **Description**: Adjusts the amount of tokens a participant wishes to stake for the **next staking cycle**.
   - **Parameters**:
     - `producer`: The pubkey of the producer in Call.caller.
     - `amount`: The amount to adjust (positive to increase stake, negative to decrease stake).
   - **When Callable**: Only during the **Staking Epoch** of a cycle, but every epoch is the staking epoch of some cycle, so you can always call it.
   - **Constraints**:
     - Adjustments made in the current epoch `N` affect the staking cycle starting in epoch `N`, with leader election and production in epoch  `N + 3`.
     - **Positive `amount`**:
       - Must have sufficient AB to cover the increase.
     - **Negative `amount`**:
       - Cannot reduce the stake below zero for the next staking cycle.
     - **Minimum Stake Requirement**:
       - After adjustment, if the participant's stake is below `MINIMUM_STAKE`, they will not be eligible for leader selection in the upcoming cycle.
   - **Behavior**:
       - SC: is an orderd list `[{epoch, stake amount, locked amount}| ... ]`
       - Calculate new_stake: find the stake for current_epoch in SC or take the value of the last epoch in the list.
         - `new_stake = stake + amount`
       - drop all values in SC where epcoh < current_epoch
       - n = current_epoch (n1 = leder selection epoch, n2 = production epoch, n3 = payout epoch)
       - Recreate the list:
        ```
        case SC of
          [{n, n_stake, n_lock}|Rest1] ->
              [{n, new_stake, max(new_stake, n_lock)} | case Rest1 of
                  [{n1, n1_stake, n1_lock} | Rest2] ->
                      [{n1, new_stake, max(new_stake, n1_lock)} | case Rest2 of
                          [{n2, n2_stake, n2_lock} | Rest3] ->
                              [{n2, new_stake, max(new_stake, n2_lock)} | case Rest3 of
                                  [{n3, n3_stake, n3_lock} | Rest4] ->
                                      [{n3, new_stake, max(new_stake, n3_lock)} | case Rest4 of
                                          [{n4, n4_stake, n4_lock}] ->
                                              [{n4, new_stake, max(new_stake, n4_lock)}];
                                          [] ->
                                              [{n4, new_stake, max(new_stake, n3_lock)}]
                                      end];
                                  [] ->
                                      [{n3, new_stake, max(new_stake, n2_lock)},
                                      {n4, new_stake, max(new_stake, n2_lock)}]
                                  end];
                          [] ->
                              [{n2, new_stake, max(new_stake, n1_lock)},
                              {n3, new_stake, max(new_stake, n1_lock)},
                              {n4, new_stake, max(new_stake, n1_lock)}]
                          end];
                  [] ->
                      [{n1, new_stake, max(new_stake, n_lock)},
                      {n2, new_stake, max(new_stake, n_lock)},
                      {n3, new_stake, max(new_stake, n_lock)},
                      {n4, new_stake, max(new_stake, n_lock)}]
                  end];
          [] ->
              [{n, new_stake, new_stake},
              {n1, new_stake, new_stake},
              {n2, new_stake, new_stake},
              {n3, new_stake, new_stake},
              {n4, new_stake, new_stake}]
        end
        ```
     - Recalculate LB (max of SC)
     - Recalculates AB = TB - LB
     - All these values are stored in a map with producer as key.
Alternatively

1. **`stake(amount:unsigned integer)`**
   - **Description**: sets the amount of tokens a participant wishes to stake for the **next staking cycle**.
   - **Parameters**:
     - `producer`: The pubkey of the producer in Call.caller.
     - `amount`: The amount to stake in this staking cycle.
   - **When Callable**: Only during the **Staking Epoch**.
   - **Constraints**:
     - Staking made in the current epoch `N` affect the staking cycle starting in epoch `N`, with leader election in epoch  `N + 1`.
     - **Positive `amount`**:
       - Must have sufficient AB to cover the increase.
     - **Minimum Stake Requirement**:
       - After adjustment, if the participant's stake is below `MINIMUM_STAKE`, they will not be eligible for leader selection in the upcoming cycle.
   - **Behavior**:
     - Updates the participant's stake commitment for the next staking cycle.
     - Recalculats LB:
       - **LB = amount**
     - Recalculates AB:
       - **AB = TB - LB**


4. **`getStakedAmount(producer:pubkey, epoch:integer)`**
   - **Description**: Returns the amount of tokens the participant has committed to stake in the staking cycle starting at `epoch` and ending in `epoch + 3`
   - **Parameters**:
     - `producer`: The pubkey of the producer.
     - `epoch`: The epoch number. (Or possibly a block height?)
   - **When Callable**: At any time.

5. **`getAvailableBalance(producer:pubkey)`**
   - **Description**: Returns the participant's current Available Balance (AB).
   - **Parameters**:
     - `producer`: The pubkey of the producer.
   - **When Callable**: At any time.

---

## **Explanation of Balances Across Epochs**

### **Key Concepts**

- **Total Balance (TB)**: Sum of all tokens deposited via `deposit()` and not yet withdrawn.
- **Locked Balance (LB)**: The total amount of tokens locked in the current staking cycle, i.e., epochs `N` to `N + 4`.
- **Available Balance (AB)**: Calculated as the difference between TB and LB.
  - **AB = TB - LB**

### **Lifecycle of Tokens in the Staking Contract**

1. **Staking Tokens (`deposit()`):**
   - Increases TB and AB.
   - No immediate effect on staking commitments until `adjustStake()` (or `stake()`) is called.

2. **Adjusting Stake (`adjustStake()`):**
   - Adjusts the participant's stake commitment for the next staking cycle.
   - **Positive Adjustment:**
     - Decreases AB by `amount`.
     - Increases the stake commitment for the next staking cycle by `amount`.
   - **Negative Adjustment:**
     - Increases AB by `-amount`.
     - Decreases the stake commitment for the next staking cycle by `-amount`.
   - **AB Recalculation:**
     - **AB = TB - LB**

3. **Withdrawal (`withdraw()`):**
   - Decreases TB and AB by `amount`.
   - Cannot affect tokens locked in the any of the 5 concurrent staking cycles.

4. **Epoch Transition:**
   - At the end of the Payout Epoch (`N + 4`):
     - Tokens locked in the current staking cycle become available.
     - **LB** decreases by the amount of tokens that were locked.
     - **AB** increases accordingly.

---

## **Example Scenario**

Let's illustrate how the balances change over epochs.

### **Constants and Parameters**

- **Current Epoch (`N`)**: 10 (**Staking Epoch**)
- **Staking Cycle Length (`C`)**: 5 epochs (epochs 10 to 14)
  - **Epoch 10**: Staking Epoch
  - **Epoch 11**: Entropy Epoch
  - **Epoch 12**: Leader Election Epoch
  - **Epoch 13**: Block Production Epoch
  - **Epoch 14**: Payout Epoch
- **Participant**: Alice
- **`MINIMUM_STAKE`**: 100 tokens

### **Alice's Balances**

- **Total Balance (TB)**: 1000 tokens (Alice has already deposited these via `deposit()`).
- **Available Balance (AB)**: 1000 tokens (initially, no tokens are locked).
- **Locked Balance (LB)**: 0 tokens.

---

### **Epoch 10 (Staking Epoch)**

#### **Action 1**: Alice Stakes 400 Tokens

- Alice decides to stake **400 tokens** for this staking cycle (epochs **10** to **14**) with production in epoch **13**.
- She calls `adjustStake(400)`.
- **Available Balance (AB)** decreases by 400 tokens:
  - **AB** = 1000 - 400 = **600 tokens**.
- **Stake Commitment**:
  - Alice's stake commitment for this staking cycle is now **400 tokens**.
- **Locked Balance (LB)** remains at **0 tokens** till the end of the epoch (the stake will be locked in Epoch 11).

#### **Action 2**: Alice Withdraws 100 Tokens

- She calls `withdraw(100)`.
- **Total Balance (TB)** decreases by 100 tokens:
  - **TB** = 1000 - 100 = **900 tokens**.
- **Available Balance (AB)** decreases by 100 tokens:
  - **AB** = 600 - 100 = **500 tokens**.
- **Locked Balance (LB)** **400 tokens**.

---

### **Epoch 11 (Entropy Epoch)**

- Alice can now plan her stake for the **following** staking cycle and decides on no change.

- **System Process**:
  - The system awaits the parent chain's hash to generate entropy.
- **Alice's Balances**:
  - No changes occur in this epoch.
  - **AB** remains at **500 tokens**.
  - **LB** remains at **400 tokens**.

---

### **Epoch 12 (Leader Election Epoch)**

- Alice's stake of **400 tokens** stays **locked** for the duration of the staking cycle (epochs **12** to **14**).
- **Alice's Balances**:
  - **LB** = **400 tokens**.
  - **AB** = **500 tokens**.

#### **Adjusting Stake for Next Cycle**
- Alice can now plan her stake for the next next staking cycle (block production in epoch 15) and decides on no change.
- She decides to **withdraw** her stake after the current cycle:
  - She calls `adjustStake(-400)`.
  - This action schedules her stake to be reduced by 400 tokens after the current cycle ends.
- **Note**: The **AB** and **LB** remain unchanged until the stake is unlocked.

---

### **Epoch 13 (Block Production Epoch)**

- **Block Production**:
  - Alice participates in block production based on her **locked stake** of **400 tokens**.
- **Alice's Balances**:
  - No changes occur in this epoch.
  - **AB** remains at **500 tokens**.
  - **LB** remains at **400 tokens**.

---

### **Epoch 14 (Payout Epoch)**

#### **Rewards Distribution**

- Alice receives rewards based on her participation, paid out directly to her account.
- Alice's **stake adjustment** from Epoch 12 takes effect.
- **Locked Balance (LB)** decreases by 400 tokens:
  - **LB** = 400 - 400 = **0 tokens**.
- **Available Balance (AB)** increases by 400 tokens:
  - **AB** = 500 + 400 = **900 tokens**.
- **Total Balance (TB)** remains at **900 tokens**.

---

### **Epoch 15 (Next Staking Epoch)**

#### **Adjusting Stake for New Cycle**

- Alice decides to **increase** her stake to **500 tokens** for the staking cycle in epochs **15** to **19**.
- She calls `adjustStake(500)`.
- **Available Balance (AB)** decreases by 500 tokens:
  - **AB** = 900 - 500 = **400 tokens**.
- **Stake Commitment**:
  - Alice's stake commitment for the next staking cycle is now **500 tokens**.
- **Locked Balance (LB)** remains at **0 tokens** (the stake will be locked in Epoch 16).

---

### **Epoch 16 (Entropy Epoch)**
- Alice's stake of **500 tokens** becomes **locked** for the duration of the staking cycle (epochs **16** to **19**).

- **System Process**:
  - The system waits for the parent chain's hash for entropy.
- **Alice's Balances**:
  - The stake become locked
  - **AB** remains at **400 tokens**.
  - **LB** is set to **500 tokens**.

---

### **Epoch 17 (Leader Election Epoch)**

- **Alice's Balances**:
  - No changes occur.
  - **AB** remains at **400 tokens**.
  - **LB** is set to **500 tokens**.

---

### **Epochs 17 to 19**

- **Block Production and Payout**:
  - Alice participates in block production.
  - Rewards are earned and distributed in the Payout Epoch (epoch **19**).
- **Actions**:
  - Alice cannot adjust her **current** stake but can plan for the **next** cycle during Epoch 20.

---

### **Summary of Alice's Balances Over Epochs**

| Epoch | TB (tokens) | AB (tokens) | LB (tokens) | Notes                                                 |
|-------|-------------|-------------|-------------|-------------------------------------------------------|
| 09    | 1000        | 500         |   0         | Inital balance 1000 tokens                            |
| 10    |  900        | 500         |   0         | Staked 400 tokens, withdrew 100 tokens                |
| 11    |  900        | 500         | 400         | **Stake locked at start of Entropy Epoch**            |
| 12    |  900        | 500         | 400         | Leader Election Epoch                                 |
| 13    |  900        | 500         | 400         | Block Production Epoch                                |
| 14    |  900        | 900         |   0         | Stake unlocked; AB increases by 400 tokens            |
| 15    |  900        | 400         |   0         | Staked 500 tokens for next cycle                      |
| 16    |  900        | 400         | 500         | **Stake locked at start of Entropy Epoch**            |
| 17    |  900        | 400         | 500         | Leader Election Epoch                                 |
| 18    |  900        | 400         | 500         | Block Production Epoch                                |
| 19    |  900        | 400         |   0         | Stake unlocked; rewards added to AB                   |
---


### **SC Over Epochs**


| Epoch | TB   | LB   | AB   | SB   | SC Entries (epoch, stake, locked amount)                                                 | Notes                                               |
|-------|------|------|------|------|------------------------------------------------------------------------------------------|-----------------------------------------------------|
| 09    | 1000 |    0 | 1000 |    0 | *Empty*                                                                                  | Initial balance                                     |
| 10    | 900  |    0 | 500  |  400 | `{10, 400, 0}`, `{11, 400, 400}`, `{12, 400, 400}`, `{13, 400, 400}`, `{14, 400, 400}`   | Staked 400 tokens, withdrew 100 tokens              |
| 11    | 900  | 400  | 500  |  400 | `{10, 400, 0}`, `{11, 400, 400}`, `{12, 400, 400}`, `{13, 400, 400}`, `{14, 400, 400}`   | Stake locked at start of Entropy Epoch              |
| 12    | 900  | 400  | 500  |  400 | `{12, 400, 400}`, `{13, 0, 400}`, `{14, 0, 400}`, `{15, 0, 0}`                           | Reduced stake by 400 tokens                         |
| 13    | 900  | 400  | 500  |  400 | `{12, 400, 400}`, `{13, 0, 400}`, `{14, 0, 400}`, `{15, 0, 0}`                           | Block Production Epoch                              |
| 14    | 900  | 400  | 500  |    0 | `{12, 400, 400}`, `{13, 0, 400}`, `{14, 0, 400}`, `{15, 0, 0}`                           | Payout Epoch                                        |
| 15    | 900  | 0    | 400  |  500 | `{15, 500, 0}` , `{16, 500, 500}`, `{17, 500, 500}`, `{18, 500, 500}`, `{19, 500, 500}`  | New Stake of 500                                    |
| 16    | 900  | 500  | 400  |  500 | `{15, 500, 0}` , `{16, 500, 500}`, `{17, 500, 500}`, `{18, 500, 500}`, `{19, 500, 500}`  |                                                     |
---

### **Edge Cases and Additional Notes**

- **Adjusting Stake During Staking Epoch:**
  - Participants can only adjust their stake for the **current staking cycle** during the Staking Epoch.
  - Once the Staking Epoch ends, the stake commitments are locked till the end of the cycle.

- **Insufficient AB for Adjusting Stake:**
  - If a participant tries to increase their stake but does not have sufficient AB, they must first increase TB via `deposit()`.

- **Withdrawal Limitations:**
  - Participants cannot withdraw tokens that are locked in the current staking cycle.
  - Attempting to withdraw more than AB will result in an error.

- **Automatic Re-Staking:**
  - Tokens do not automatically unlock, instead if no change in staking is registerd they remain at stake.
  - Participants must call `adjustStake()` during the next Staking Epoch to free tokens during the next staking cycle.

---

### **Example with Varying Stakes Across Epochs**

If participants can adjust their stake for each epoch within the staking cycle, the LB calculation becomes the maximum over the epochs.

Suppose Alice stake different amounts in each epoch:

- **Epoch 11**: 500 tokens
- **Epoch 12**: 300 tokens
- **Epoch 13**: 400 tokens

Then in epoch 13, we are still in the cycle started in epoch 11.

- **LB = max(SS[11], SS[12], SS[13])**
- **LB = max(500,300,400) = 500 tokens**

## Locking

In the current proposal a stake is only locked for one cycle.
We could consider adding a network/hyperchain parameter stating the number of epochs or cycles that
a stake is locked.
In this case the `adjustStake` function would need to be updated to keep track of the locking for
the whole locking period.

# Block Rewards

## Glossary and Concepts

- **Leader Schedule**: Blocks are produced in accordance with a predetermined leader schedule. Each validator is assigned specific slots during which they are responsible for producing blocks.

- **Timely Block Production**: Validators are expected to produce blocks **on time** during their assigned slots to ensure the smooth operation of the network.

- **Missed Blocks**: If a validator fails to produce a block in their assigned time slot, this results in a **missing block**.

- **Producing a 'Hole'**:
  - The subsequent validator in the leader schedule is allowed to produce a special type of block called a **'hole'**.
  - **Hole Characteristics**:
    - Represents the absence of the expected block.
    - Contains no transactions.
    - Serves as a placeholder to maintain the continuity of the blockchain.
  - **No Rewards for Holes**:
    - Validators producing holes do **not** receive any rewards for these blocks.
    - The missed block's potential rewards are effectively forfeited, including the award of fees for following the previous block.


## Reward Distribution for Correct Blocks

When a validator successfully produces a block on time, the rewards are distributed as follows:

### Components of Rewards

1. **Block Fees**: Transaction fees collected from transactions included in the block.
2. **Epoch Coinbase**: Newly minted tokens allocated for that epoch.

### Distribution Breakdown

- **Block Producer (Current Validator)**:
  - Receives **X% of the block fees**, X defaults to 75% but is configurable in genesis.
  - Receives the **full epoch coinbase reward**.
  - **Incentive**: Encourages validators to produce blocks promptly and include transactions to maximize fees.

- **Next Validator (Following Validator)**:
  - Receives **(100-X)% of the block fees** from the previous block.
  - **Role**:
    - Validates the correctness of the previous block.
    - Builds upon it by producing the next block in the chain.
  - **Incentive**: Motivates validators to participate actively in the validation process and ensures they have a stake in the accuracy of preceding blocks.

### Visualization of Reward Flow

```plaintext
+-----------------------+                   +-----------------------+
|                       |                   |                       |
|  Validator A          |                   |  Validator B          |
|  (Block Producer)     |                   |  (Next Validator)     |
|                       |                   |                       |
| - Validates Block N-1 |                   |  - Validates Block N  |
|  - Produces Block N   |                   |  - Builds Block N+1   |
|  - Receives:          |                   |  - Receives:          |
|    * 25% of N-1 Fees  |                   |    * 75% of Block N+1 |
|    * 75% of Block     |------------------>|    * 25% of N-1 Fees  |
|            N Fees     |                   |                       |
|    * Epoch Coinbase   |                   |    * Epoch Coinbase   |
|                       |                   |                       |
+-----------------------+                   +-----------------------+
```

## Fee Payout Timing

- **Payout Fee Epoch**: The rewards (fees and coinbase) are not distributed immediately but are paid out during the **Payout Fee Epoch** of the staking cycle.

- **Staking Cycle Phases**:
  1. **Staking Epoch**: Validators stake their tokens.
  2. **Leader Selection Epoch**: Leaders (validators) are selected based on their stake.
  3. **Block Production Epoch**: Validators produce blocks according to the leader schedule.
  4. **Payout Fee Epoch**: Accumulated rewards are distributed to validators.

- **Benefits**:
  - Allows for accounting of all rewards and penalties within a cycle.
  - Provides a window to resolve disputes or adjust for any detected misbehavior before rewards are paid.

---

## Reward Distribution Mechanics

### Configurable Parameters

- **75/25 Fee Split**:
  - The proportion of fees allocated to the block producer and the next validator is **configurable** for a Hyperchain.
  - Networks can adjust the split (e.g., 80/20, 70/30) based on governance decisions or to incentivize certain behaviors.

- **Epoch Coinbase Amount**:
  - The coinbase reward (newly minted tokens) per epoch is **configurable** per chain.
  - Allows for economic flexibility and inflation control across different Hyperchains.

### Reward Accumulation and Distribution

- **Accumulation**:
  - Fees and coinbase rewards earned by validators are accumulated during the staking cycle.
  - Rewards are tracked per validator and stored within the protocol until payout.

- **Distribution**:
  - During the **Payout Fee Epoch**, rewards are disbursed to validators' accounts.
  - Validators receive their total accumulated rewards for the cycle in a lump sum.

### Payment to Delegator Contracts

- **Delegator Contracts**:
  - Validators may have associated **delegator contracts**, where other token holders delegate their stake to the validator.
  - Rewards can be configured to be paid directly to these contracts.

- **Benefits**:
  - Facilitates the distribution of rewards to delegators according to agreed terms.
  - Encourages participation from token holders who may not run validator nodes themselves.

---

## Example Scenario

### Assumptions

- **Fee Split**: 75% to block producer, 25% to next validator.
- **Epoch Coinbase**: 10 tokens per epoch.
- **Block Fees**: Varies per block.

### Block Production Sequence

1. **Validator A** produces Block N on time.
2. **Validator B** is scheduled to produce Block N+1.

### Reward Distribution

- **Validator A (Block N Producer)**:
  - Receives:
    - **75% of Block N Fees**.
    - **Epoch Coinbase** (10 tokens).

- **Validator B (Block N+1 Producer)**:
  - Receives:
    - **25% of Block N Fees** (for validating and building upon Block N).
    - Their own rewards for producing Block N+1 when applicable.

### Missed Block Scenario

- If **Validator A** fails to produce Block N:
  - **Validator B** produces a **hole** instead.
  - **No Rewards**:
    - Validator B receives **no rewards** for the hole.
    - Validator A forfeits potential rewards for Block N.
  - **Continued Operation**:
    - **Validator B** continues with Block N+1.

---

## Configurability and Governance

- **Hyperchain Configurability**:
  - The fee split ratio and coinbase amounts are parameters that can be adjusted through governance mechanisms.
  - This flexibility allows each Hyperchain to tailor economic incentives to its specific needs.

- **Possible Governance Process**:
  - In future versions we could add:
    - Changes to the reward parameters can be proposed and voted upon by stakeholders.
    - Ensures that adjustments reflect the consensus of the network participants.

# Penalties & Slashable Offenses

Here we describe the effects of penalties on staking and rewards for validators who commit slashable offenses. It outlines how these penalties impact a validator's staked tokens, their eligibility for rewards, and their future participation in the network.

## Overview of Penalties and Slashable Events

Penalties are enforced to deter malicious actions or protocol violations. **Slashable events** are actions that result in the forfeiture of a validator's stake, reputation, or other penalties to maintain network integrity and fairness. Any participant can submit proof of such wrongdoing, ensuring a decentralized and fair enforcement mechanism.

### Slashable Offenses

1. **Producing Two Versions of a Block at a Specific Height (Double-Spending Attack)**
2. **Double Voting**
3. **Ignoring Votes**
4. **Consistently Failing to Submit Blocks on Time**

### Minor Offenses
1. **Ignoring the `finalize_epoch` Fork**
2. **Ignoring a Correctly Pinned Fork**

 For minor offenses like ignoring forks (items 1 and 2), the protocol ignore the validator's actions without imposing penalties.

### Details TBD
The exact details of what these offenses and how proof of these offense should look and the penalties is yet to be decided.

## Effects of Penalties on Staking

### Slashing of Staked Tokens

- **Reduction of Total Staked Balance**: When a validator commits a slashable offense, a portion or the entirety of their **Total Balance (TB)** of staked tokens is **slashed** (i.e., permanently deducted).
- **Impact on Locked Balance (LB)**: The **Locked Balance**, which is the amount currently staked and locked for participation, decreases by the slashed amount.
- **Available Balance (AB)**: The **Available Balance**, representing tokens that can be withdrawn or restaked, remains unaffected by the slashing unless the slashed amount exceeds the LB, in which case it may be reduced to cover the penalty.

### Example Scenario

- **Before Penalty**:
  - **Total Balance (TB)**: 1,000 tokens
  - **Locked Balance (LB)**: 800 tokens
  - **Available Balance (AB)**: 200 tokens
- **Penalty Imposed**: 400 tokens slashed due to a severe offense.
- **After Penalty**:
  - **TB**: 600 tokens (1,000 - 400)
  - **LB**: 400 tokens (800 - 400)
  - **AB**: 200 tokens (unchanged)

### Implications

- **Reduced Staking Power**: With a lower TB and LB, the validator's influence in leader elections and block production diminishes.
- **Risk of Falling Below Minimum Stake**: If the remaining LB falls below the **Minimum Stake Requirement**, the validator becomes ineligible for leader selection until they top up their stake.

---

## Effects of Penalties on Rewards

### Forfeiture of Rewards

- **No Rewards Paid Out**: Validators who commit slashable offenses **forfeit any pending rewards** for the current and possibly future epochs.
  - **Block Rewards**: They lose eligibility for block rewards associated with blocks they produced during the period of misbehavior.
  - **Transaction Fees**: They forfeit any transaction fees collected in blocks they produced or validated.
- **Redistribution of Forfeited Rewards**:
  - **To Honest Validators**: The forfeited rewards may be redistributed among honest validators as an incentive for maintaining network integrity.
  - **To Reporter**: A portion of the forfeited rewards or slashed stake may be awarded to the participant who submitted the valid proof of misconduct.

## Process for Applying Penalties

### Submission of Proof of Misconduct

- **Any Participant Can Report**: Network participants can submit evidence of a validator's wrongdoing via a special "Proof of Misconduct" transaction to the election contract.
- **Required Information**:
  - **Evidence**: Detailed and verifiable proof of the validator's misconduct. TBD.
  - **Reporter Address**: The identity of the participant submitting the proof.
  - **Signature**: Digital signature of the reporter to ensure authenticity.

### Verification and Enforcement

1. **Verification of Evidence**:
   - The network validates the submitted evidence against blockchain data. TBD.
   - Ensures that the proof is legitimate and the offense is verifiable.

2. **Application of Penalties**:
   - **Slashing of Stake**: Deducts the specified amount from the validator's TB and LB.
   - **Forfeiture of Rewards**: Removes any pending rewards owed to the validator.

3. **Distribution of Slashed Funds**:
   - **Reporter Reward**: Allocates a portion of the slashed stake to the reporter as a reward for maintaining network security.
   - **Network Treasury**: Remaining slashed funds may be burned or allocated to other stakers. TBD.

---

## Impact on Validator's Future Participation

### Loss of Stake Balance
- **Loss of staking power**: By loosing staking power in the staking contract the ability of a validator to earn future rewards is decreased.
- **Below Minimum Stake**: If slashing reduces the validator's LB below the required **Minimum Stake**, they become ineligible for:
  - **Leader Selection**: Cannot be selected to produce blocks.
  - **Voting Rights**: May lose the ability to participate in governance decisions.
- **Reputation Loss**: Validators with a history of penalties may be viewed as untrustworthy, affecting their chances of being selected in delegation pools or staking contracts.

### Rebuilding Stake and Reputation

- **Re-Staking Required**: Validators must deposit additional tokens to meet the minimum stake if they wish to resume participation.
