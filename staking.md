# Staking


#### **Constants:**

- **`MINIMUM_STAKE`**: The minimum amount of tokens required to be eligible for leader selection in any given epoch.

#### **Participant's Balances:**

- **Total Balance (TB)**: The total number of tokens a participant has deposited in the staking contract via the `stake()` function.
- **Staking Schedule (SS)**: A mapping of epochs to the amount of tokens the participant has committed to stake in each of those epochs.
- **Locked Balance (LB)**: The max of staked amounts over the **current staking cycle**, i.e., epochs `N` to `N + C`, where `C` is the number of epochs in the staking cycle (in our case, `C = 3`).
- **Available Balance (AB)**: The portion of the Total Balance that is not locked in the current staking cycle.
  - **AB = TB - LB**

---

#### **API Functions**

1. **`deposit()`** (Payable Endpoint)
   - **Description**: Allows a participant to deposit tokens into the staking contract, increasing their Total Balance (TB) and Available Balance (AB).
   - **Parameters**: None (the amount is determined by the value of tokens sent with the transaction).
   - **When Callable**: At any time.
   - **Behavior**:
     - Increases TB by the amount of tokens sent.
     - Increases AB by the same amount.

2. **`withdraw(amount)`**
   - **Description**: Allows a participant to withdraw tokens from their Available Balance (AB).
   - **Parameters**:
     - `amount`: The amount of tokens to withdraw.
   - **When Callable**: At any time.
   - **Constraints**:
     - `amount` must be less than or equal to AB.
     - Cannot withdraw tokens locked in the current staking cycle (i.e., tokens committed in SS for epochs `N` to `N + C`).

3. **`adjustStake(amount:integer)`**
   - **Description**: Adjusts the amount of tokens a participant wishes to stake for the **next staking cycle**.
   - **Parameters**:
     - `amount`: The amount to adjust (positive to increase stake, negative to decrease stake).
   - **When Callable**: Only during the **Staking Epoch**.
   - **Constraints**:
     - Adjustments made in the current epoch `N` affect the staking cycle starting in epoch `N`, with leader election in epoch  `N + 1`.
     - **Positive `amount`**:
       - Must have sufficient AB to cover the increase.
     - **Negative `amount`**:
       - Cannot reduce the stake below zero for the next staking cycle.
     - **Minimum Stake Requirement**:
       - After adjustment, if the participant's stake is below `MINIMUM_STAKE`, they will not be eligible for leader selection in the upcoming cycle.
   - **Behavior**:
     - Updates the participant's stake commitment for the next staking cycle.
     - Recalculats LB:
       - **LB = LB + amount**
     - Recalculates AB:
       - **AB = TB - LB**

Alternatively

1. **`stake(amount:unsigned integer)`**
   - **Description**: sets the amount of tokens a participant wishes to stake for the **next staking cycle**.
   - **Parameters**:
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


4. **`getStakedAmount(epoch)`**
   - **Description**: Returns the amount of tokens the participant has committed to stake in the staking cycle starting at `epoch` and ending in `epoch + 3`
   - **Parameters**:
     - `epoch`: The epoch number.
   - **When Callable**: At any time.

5. **`getAvailableBalance()`**
   - **Description**: Returns the participant's current Available Balance (AB).
   - **Parameters**: None.
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
- **Staking Cycle Length (`C`)**: 3 epochs (epochs 10 to 13)
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
  - Remains at 0 during the Staking Epoch.

#### **Epoch 11 (Leader Election Epoch)**

- **Transition to New Staking Cycle**:
  - Alice's stake of 400 tokens becomes locked for the duration of the staking cycle (epochs 11 to 13).
  - **LB** increases by 400 tokens:
    - LB = 0 + 400 = 400 tokens.
  - **AB** remains at 500 tokens:
    - AB = TB - LB = 900 - 400 = 500 tokens.

- **Adjusting Stake for Next Cycle**:
  - Alice can now adjust her stake for the **next staking cycle** (epochs 14 to 16) during the Staking Epoch of that cycle.

#### **Epochs 11 to 13**

- **Funds Locked**:
  - The 400 tokens are locked and cannot be withdrawn until the end of the Payout Epoch (epoch 13).
  - **AB** remains at 500 tokens.

- **Actions**:
  - Alice cannot adjust her current stake but can plan for the next cycle.

#### **Epoch 14 (Next Staking Epoch)**

- **Unlocking Funds**:
  - At the end of epoch 13 (Payout Epoch), the 400 tokens become unlocked.
  - **LB** decreases by 400 tokens:
    - LB = 400 - 400 = 0 tokens.
  - **AB** increases by 400 tokens:
    - AB = TB - LB = 900 - 0 = 900 tokens.

- **Adjusting Stake for Next Cycle**:
  - Alice decides to increase her stake to 500 tokens for the next staking cycle.
    - She calls `adjustStake(500)`.
    - **AB** decreases by 500 tokens:
      - AB = 900 - 500 = 400 tokens.
    - **LB** remains at 0 tokens (since the new stake is for the next cycle).

#### **Withdrawal After Epoch 14**

- Alice has an AB of 400 tokens.
- She can choose to:
  - Withdraw up to 400 tokens via `withdraw()`.
  - Leave the tokens in the staking contract for future staking.

---

### **Summary of Balances Over Epochs**

| Epoch | TB   | LB   | AB   | Notes                                                |
|-------|------|------|------|------------------------------------------------------|
| 10    | 900  | 0    | 500  | After staking and withdrawal actions                 |
| 11    | 900  | 400  | 500  | 400 tokens locked for staking cycle                  |
| 12    | 900  | 400  | 500  | (Alice produces blocks according to leader schedule) |
| 13    | 900  | 400  | 500  | Payout Epoch; tokens remain locked until end         |
| 14    | 900  | 0    | 900  | Tokens unlocked; AB recalculated                     |
| After | 900  | 0    | 400  | After adjusting stake for next cycle (500 tokens)    |

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
  - Tokens unlocked after the Payout Epoch become part of AB.
  - Participants must call `adjustStake()` during the next Staking Epoch to commit these tokens to the next staking cycle.

---

### **Example with Varying Stakes Across Epochs**

If participants can adjust their stake for each epoch within the staking cycle, the LB calculation becomes the maximum over the epochs.

Suppose Alice stake different amounts in each epoch:

- **Epoch 11**: 500 tokens
- **Epoch 12**: 300 tokens
- **Epoch 13**: 400 tokens

Then in epoch 13, we are still in the cycle started in epoch 11.

- **LB = max(SS[11] + SS[12] + SS[13])**
- **LB = max(500,300,400) = 500 tokens**

