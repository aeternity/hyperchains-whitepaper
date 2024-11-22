# Staking


#### **Constants:**

- **`MINIMUM_STAKE`**: The minimum amount of tokens required to be eligible for leader selection in any given epoch.

#### **Participant's Balances:**

- **Total Balance (TB)**: The total number of tokens a participant has deposited in the staking contract via the `stake()` function.
- **Locked Balance (LB)**: The max of staked amounts over the **current staking cycle**, i.e., epochs `N` to `N + C`, where `C` is the number of epochs in the staking cycle (in our case, `C = 3`).
- **Available Balance (AB)**: The portion of the Total Balance that is not locked in the current staking cycle.
  - **AB = TB - LB**
- **Staking Schedule (SC)**: A mapping of epochs to the amount of tokens the participant has committed to stake in each of those epochs and onwards if not changed. As an orderd list ({epoch, stake amount, locked amount})

Automatic Restaking: Unless adjusted, the stake for an epoch automatically continues into future cycles.

---

#### **API Functions**

1. **`deposit(producer:pubkey)`** (Payable Endpoint)
   - **Description**: Allows a participant to deposit tokens into the staking contract, increasing their Total Balance (TB) and Available Balance (AB).
   - **Parameters**:
     - producer - the pubkey of the producer who can become leader and then produce and sign blocks.
     -  (the amount is determined by the value of tokens sent with the transaction).
   - **When Callable**: At any time.
   - **Behavior**:
     - Increases TB by the amount of tokens sent.
     - Increases AB by the same amount.

2. **`withdraw(producer:pubkey, amount:unsigned integer)`**
   - **Description**: Allows a participant to withdraw tokens from their Available Balance (AB).
   - **Parameters**:
     - `producer`: The pubkey of the producer, must match the signature of the call transaction (do we need it).
     - `amount`: The amount of tokens to withdraw.
   - **When Callable**: At any time.
   - **Constraints**:
     - `amount` must be less than or equal to AB.
     - Cannot withdraw tokens locked in the current staking cycle (i.e., tokens committed in SS for epochs `N` to `N + C`).

3. **`adjustStake(producer:pubkey, amount:integer)`**
   - **Description**: Adjusts the amount of tokens a participant wishes to stake for the **next staking cycle**.
   - **Parameters**:
     - `producer`: The pubkey of the producer, must match the signature of the call transaction (do we need it).
     - `amount`: The amount to adjust (positive to increase stake, negative to decrease stake).
   - **When Callable**: Only during the **Staking Epoch** of a cycle, but every epoch is the staking epoch of some cycle, so syou can always call it.
   - **Constraints**:
     - Adjustments made in the current epoch `N` affect the staking cycle starting in epoch `N`, with leader election in epoch  `N + 1`.
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
            [{n, n_stake, n_lock}|Rest1]  ->
                [{current_epoch, new_stake, max(new_stake, n_lock)} | case Rest1 of
                    [{n1, n1_stake, n1_lock} | Rest2] ->
                        [{n1, new_stake, max(new_stake, n1_lock)} | case Rest2 of
                            [{n2, n2_stake, n2_lock} | Rest3] ->
                                [{n2, new_stake, max(new_stake, n2_lock)} | case Rest3 of
                                    [{n3, n3_stake, n3_lock}] ->
                                        [{n3, new_stake, max(new_stake, n3_lock)}];
                                    [] ->
                                        [{n3, new_stake, max(new_stake, n2_lock)}]
                                end];
                            [] ->
                                [{n2, new_stake, max(new_stake, n1_lock)},
                                 {n3, new_stake, max(new_stake, n1_lock)}]
                            end];
                    [] ->
                        [{n1, new_stake, max(new_stake, n_lock)}, {n2, new_stake, max(new_stake, n_lock)},
                         {n3, new_stake, max(new_stake, n_lock)}]
                    end];
            [] ->
                [{n, new_stake, new_stake}, {n1, new_stake, new_stake},
                 {n2, new_stake, new_stake}, {n3, new_stake, new_stake}]
        end
        ```
     - Recalculats LB (max of SC)
     - Recalculates AB = TB - LB
     - All these values are stored in a map with producer as key.
Alternatively

1. **`stake(producer:pubkey, amount:unsigned integer)`**
   - **Description**: sets the amount of tokens a participant wishes to stake for the **next staking cycle**.
   - **Parameters**:
     - `producer`: The pubkey of the producer, must match the signature of the call transaction (do we need it).
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
- **Locked Balance (LB)**: The total amount of tokens locked in the current staking cycle, i.e., epochs `N` to `N + 3`.
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
   - Cannot affect tokens locked in the any of the 4 concurrent staking cycles.

4. **Epoch Transition:**
   - At the end of the Payout Epoch (`N + 3`):
     - Tokens locked in the current staking cycle become available.
     - **LB** decreases by the amount of tokens that were locked.
     - **AB** increases accordingly.

---

### **Updated Example Scenario**

Let's illustrate how the balances change over epochs with this updated model.

#### **Constants and Parameters**

- **Current Epoch (`N`)**: 10 (Staking Epoch)
- **Staking Cycle Length (`C`)**: 4 epochs (epochs 10 to 13)
  - Epoch 10: Staking Epoch
  - Epoch 11: Leader Election Epoch
  - Epoch 12: Block Production Epoch
  - Epoch 13: Payout Epoch
- **Participant**: Alice
- **`MINIMUM_STAKE`**: 100 tokens

#### **Alice's Balances**

- **Total Balance (TB)**: 1000 tokens (Alice has already deposited these via `deposit()`).
- **Available Balance (AB)**: 1000 tokens (initially, no tokens are locked).
- **Locked Balance (LB)**: 0 tokens.

#### **Epoch 10 (Staking Epoch)**

- **Action 1**: Alice decides to stake 400 tokens for the next staking cycle (epochs 11 to 13).
  - She calls `adjustStake(400)`.
  - **AB** decreases by 400 tokens:
    - AB = 1000 - 400 = 600 tokens.
  - **Stake Commitment**:
    - Alice's stake commitment for the next staking cycle is now 400 tokens.

- **Action 2**: Alice withdraws 100 tokens.
  - She calls `withdraw(100)`.
  - **TB** decreases by 100 tokens:
    - TB = 1000 - 100 = 900 tokens.
  - **AB** decreases by 100 tokens:
    - AB = 600 - 100 = 500 tokens.

- **Locked Balance (LB)**:
  - Set at 400 from the call to adjustStake till the end of the Staking Epoch.

#### **Epoch 11 (Leader Election Epoch)**

- **Transition to New Staking Cycle**:
  - Alice's stake of 400 tokens becomes locked for the duration of the staking cycle (epochs 11 to 13).
  - **LB** increases by 400 tokens:
    - LB = 0 + 400 = 400 tokens.
  - **AB** remains at 500 tokens:
    - AB = TB - LB = 900 - 400 = 500 tokens.

- **Adjusting Stake for Next Cycle**:
  - Alice can now adjust her stake for the **next staking cycle** (epochs 11 to 14) during the Staking Epoch of that cycle.
 - She calls `adjustStake(-400)` this will not free up her available balance right away but in epoch 14.

#### **Epochs 11 to 13**

- **Funds Locked**:
  - The 400 tokens are locked and cannot be withdrawn until the end of the Payout Epoch (epoch 13).
  - **AB** remains at 500 tokens.

- **Actions**:
  - Alice cannot adjust her current stake but can plan for the next cycle.

#### **Epoch 14 (Next Staking Epoch)**

- **Unlocking Funds**:
  - At the end of epoch 13 (Payout Epoch), the 400 tokens become possible to unlock which Alice did in epoch 11.
  - **LB** decreases by 400 tokens:
    - LB = 400 - 400 = 0 tokens.
  - **AB** increases by 400 tokens:
    - AB = TB - LB = 900 - 0 = 900 tokens.

- **Adjusting Stake for Next Cycle**:
  - Alice decides to increase her stake to 500 tokens for the next staking cycle.
    - She calls `adjustStake(500)`.
    - **AB** decreases by 500 tokens:
      - AB = 900 - 500 = 400 tokens.
    - **LB** increases to  500 tokens.

#### **Withdrawal After Epoch 14**

- Alice has an AB of 400 tokens.
- She can choose to:
  - Withdraw up to 400 tokens via `withdraw()`.
  - Leave the tokens in the staking contract for future staking.

---

### **Summary of Balances Over Epochs**

| Epoch | TB   | LB   | AB   | Notes                                                |
|-------|------|------|------|------------------------------------------------------|
| 09    | 1000 | 0    | 1000 | Previous deposit                                     |
| 10    | 900  | 0    |  500 | After staking and withdrawal actions                 |
| 11    | 900  | 400  |  500 | 400 tokens locked for staking cycle                  |
| 12    | 900  | 400  |  500 | (Alice produces blocks according to leader schedule) |
| 13    | 900  | 400  |  500 | Payout Epoch; tokens remain locked until end         |
| 14    | 900  | 0    |  900 | Tokens unlocked; AB recalculated                     |
| After | 900  | 0    |  400 | After adjusting stake for next cycle (500 tokens)    |


### **SC Over Epochs**


| Epoch | TB   | LB   | AB   | SC Entries                                              | Notes                                                |
|-------|------|------|------|---------------------------------------------------------|------------------------------------------------------|
| 09    | 1000 | 0    | 1000 | *Empty*                                                 | Previous deposit                                     |
| 10    | 900  | 0    | 500  | `{10, 400, 400}, {11, 400, 400}, {12, 400, 400}, {13, 400, 400}` | After staking and withdrawal actions                 |
| 11    | 900  | 400  | 500  | `{11, 0, 400}, {12, 0, 400}, {13, 0, 400}, {14, 0, 0}`  | Alice reduces stake by 400 tokens; tokens remain locked |
| 12    | 900  | 400  | 500  | `{12, 0, 400}, {13, 0, 400}, {14, 0, 0}`                | No further adjustments                               |
| 13    | 900  | 400  | 500  | `{13, 0, 400}, {14, 0, 0}`                              | Payout Epoch                                         |
| 14    | 900  | 0    | 900  | `{14, 0, 0}`                                            | Tokens unlocked; AB recalculated                     |
| After | 900  | 0    | 400  | `{14, 500, 500}, {15, 500, 500}, {16, 500, 500}, {17, 500, 500}` | After adjusting stake for next cycle (500 tokens)    |


---

### **Key Points**

- **Staking Adjustments:**
  - Adjustments via `adjustStake()` affect the **next staking cycle**.
  - Funds committed are locked for the duration of the staking cycle (epochs `N` to `N + C`).

- **Balances:**
  - **TB** changes when depositing (`deposit()`) or withdrawing (`withdraw()`).
  - **LB** represents the total amount of tokens locked in the current staking cycle.
  - **AB** is recalculated as **AB = TB - LB**.

- **Eligibility for Leader Selection:**
  - Participants must have at least `MINIMUM_STAKE` committed to be eligible in the upcoming staking cycle.
  - In our example, Alice had 400 tokens committed, meeting the requirement.

- **Withdrawal Constraints:**
  - Participants can withdraw up to their AB at any time.
  - Cannot withdraw tokens locked in the current staking cycle.

---

### **Edge Cases and Additional Notes**

- **Adjusting Stake During Staking Epoch:**
  - Participants can only adjust their stake for the **next staking cycle** during the Staking Epoch.
  - Once the Staking Epoch ends, the stake commitments are locked.

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
  - Receives **X% of the block fees**, X defaults to 75% but is configurable in genisis.
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

