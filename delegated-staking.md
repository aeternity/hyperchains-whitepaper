# Delegated Staking

#### **Nomenclature:**

- **`Main staking logic`**: The already existing staking logic contracts (and possibly other code) designed for hyperchains

- **`Staker`**: An account that provides funds to the main staking logic, which are locked for a certain amount of epochs.

- **`Delegating`**: Providing own funds to some logic to the benefit of a potential block producer, thereby increasing his stake, and thereby the chance to be elected for the production of a block. This delegated stake is added to the stake of an account in the main staking logic.

- **`Delegatee`**: A staker who agreed to accept funds from other accounts which will be added to his own staked funds in the election of becoming a block producer, in exchange for a share of the block production reward which is percentual to the delegated amount.

- **`Delegator`**: An account delegating funds to a delegatee.

- **`Delegation` / `Delegated Stake`**: A record holding information about funds delegated to a delegatee.
```
    record delegated_stake = {
        delegator: address,
        stake_amount: int,
        from_epoch : int,
        reward: int
        } 
``` 
`delegator`: Owner of the delegation.
`stake_amount`: The amount of **this particular** delegation.
`from_epoch`: The epoch the funds were delegated / the delegation was created.
`reward`: The amount of rewards **this particular** delegation has aggregated already.

#### **Constants:**

- **`MINIMUM_DELEGATION_DURATION`**: **5** The minimum amount of epochs a delegation has to be delegated to be eligible for rewards. Prevents delegating to stakers which will foreseeably win the election.

- **`MAXIMUM_DELEGATORS_PER_STAKER`**: **30** The maximum amount of delegators per staker which declared to accept delegations (also: `delegatee`). Limited (to currently arbitrary number) to prevent gas fees / computation effort for splitting rewards and other operations from getting too high.

- **`MINIMUM_DELEGATION_THRESHOLD`**: **1** (tbd). The percentage of the delegatee's stake used to calculate the minimum amount for a delegation. E.g. `minimal delegation amount = delegatee's stake * (MINIMUM_DELEGATION_THRESHOLD / 100)`. If a staker staked 1 AE in the `main staking logic`, the `delegator` needs to delegate at least 0,01 AE.  Higher Number: Less spam and more serious user commitment, but higher hurdle for participators. Lower Number: More spam and less serious engagement, but lower hurdle for participation.

----
#### **Tracking Stakes and Delegations:**

- **All delegatees**: The logic keeps track of all stakers that signaled to become delegatees.

- **My delegatees**: All delegatees that a specific user has delegated stakes to.

- **Delegated stakes**: Mapping the address of a delegatee to a list of `delegation`s.


Automatic Restaking: Unless adjusted, the delegation to a delegatee remains in place until it is revoked by the delegator.

---

#### **API Functions**

The following logic assumes to be running in a context where information from the `main staking logic` is available. The functions are listed in roughly the order they are most likely to be executed in a round-trip scenario.

1. **`register_as_delegatee()`** 
 - **Description**: Allows a staker to signal the acceptance of delegations, thereby becoming a delegatee.
 - **Parameters**: None
 - **When**: When staker is not a delegatee yet
 - **Behavior**: 
   - Checks the main staking logic if the caller has actually some funds staked
   - If above condition is true, creates following delegation record in yet empty list of delegations under `delegated stakes` for that delegatee:
 ```
       {delegator = Call.caller,
       stake_amount = stake, // staked amount from main staking logic
       from_epoch = 1, 
       reward = 0} 
   ```   
 The delegatee is tracked like a delegator for the sake of easily splitting rewards further down, with the exemption of the `epoch` his delegation is given, which shall keep him eligible for rewards at any time. If the staker decided to become a delegatee at Epoch `N - 1` and becomes eligible for a reward in block `N`, he should receive the reward even though he has not met the required criteria of having delegated stake for 5 epochs before being eligible for a payout.
  
  
2. **`delegate_stake(address: delegatee)`** (Payable endpoint)
 - **Description**: Used to delegate stake to a delegatee.
 - **Parameters**: 
   - delegatee: Must be an address that is registered as a delegatee.
 - **When**: Any time.
  - **Behavior**: Checks if
       - the provided address is a delegatee and has at least 100 aettos staked. This is important for the following check to work.
       - Checks if the `MINIMUM_DELEGATION_THRESHOLD` condition is met. (Min. 100 aettos staked by delegatee allows 1 aetto delegation)
       - the Caller is not the delegatee account
       - the maximum delegations count for this delegatee is not exceeded
       - If above conditions are true, pushes following `delegation` record to the list of delegations under `delegated stakes` for that delegatee:
 ```
       {delegator = Call.caller,
       stake_amount = Call.value
       from_epoch = <CURRENT_EPOCH>, 
       reward = 0} 
   ``` 


3. **`split_reward_to_delegators()`** (Payable endpoint(tbd))
 - **Description**: Distributes a nominal share of the block production reward among eligible delegations (sic!) if the block producer is a delegatee.
 - **Parameters**: None
 - **When**: Every time a block production reward is available in a call context (needs more information: is that the `step` function in the main staking logic?)
 - **Behavior**: 
   - Current implementation assumes the Caller is the block producer. Function returns immediately, if the block producer is not a delegatee.
   - If the block producer is a delegatee 
        1. the total eligible delegated stake is accumulated (`TEDS`), which is the sum of the delegatees stake and all delegations' value that have been staked for at least 5 epochs.
        2. For each delegation, its fraction of the `TEDS` is calculated and the corresponding fraction of the block reward added to its `reward` field. E.g. given these three delegations for some delegatee at Epoch 10:
 ```

     {delegator = <delegatee>
      stake_amount = 10 AE
      from_epoch = 1, 
      reward = 1AE } 
```

 ```

     {delegator = <alice>
      stake_amount = 20 AE
      from_epoch = 5, 
      reward = 2AE } 
```

 ```

     {delegator = <bob>
      stake_amount = 20 AE
      from_epoch = 8, 
      reward = 0AE } 
```

Only the delegatee and alice are eligible for a percentage of the reward, as they have staked for at least 5 epochs already. The `TEDS` is 30 AE. Based on the `stake_amount`s, the delegatee's delegation receives one third of the reward added to its value, alice's delegation receives two thrids of the reward. Note: Alice and Bob could have more `delegations` delegated for this delegatee. **All delegator's stakes are kept separately to allow easier distinguishing of stakes that have been delegated for sufficiently long.** 



4. **`withdraw_rewards(delegatee: address)`** 
 - **Description**: Allows a delegator to withdraw the rewards accumulated in his`delegation`s for a particular delegatee.
  - **Parameters**: 
     - `delegatee`:  the delegatee a user staked to. 
 - **When**: Any time.
 - **Behavior**: Iterates over all `delegations` under the provided `delegatee`, finds the ones belonging to the caller, accumulates all  `rewards` amounts, resets them to 0 and transfers the accumulated amount to the caller.




5. **`withdraw_delegated_stakes(delegatee: address)`** 
 - **Description**: Allows a `delegator` to withdraw / unstake all `delegation`s and their rewards for one particular `delegatee`.
  - **Parameters**: 
     - `delegatee`:  the delegatee a user staked to. 
 - **When**: Any time
 - **Behavior**: Aggregates all `delegation`s of the caller for the particular `delegatee`, accumulates all the amounts and rewards, transfers them to the caller and removes these `delegation`s from the list of `delegations` to that particular `delegatee`.

6. **`update_delegatees_stake()`** 
 - **Description**: Sets the correct amount a `delegatee` has staked in the main staking logic.
  - **Parameters**: None.
 - **When**: Every time a staker in the main staking logic, who also registered as a `delegatee`, changes his staked amount in any way (stake, adjust, unstake)
 - **Behavior**: In the list of all `delegations` for this `delegatee`, finds the `delegation` belonging to the `delegatee`, and adjusts the field `staked_amount` accordingly.

  ---

### **Pending investigations**

1. In the above-described logic, delegated funds count directly to the stakers *election weight* (proper term required). Staker's funds are required to be locked for a certain amout of epochs. This is diametral to the current delegation logic of allowing `delegated stakes` to be contributed and withdrawn at any time. 

    For the contributing: Where is what kind of additional logic needed to somehow delay the attribution of the delegated funds to the staking power of a block producer, or, somehow otherwise take the necessity of a constant amount of funds to be locked for some epochs into account?

    For the withdrawing: What checks and conditions could be applied to the `withdraw_delegated_stakes` function to prevent delegations to be withdrawn at an epoch they are supposed to be still locked, semantically as part of a locked block producer's stake?
    
2. Although `split_reward_to_delegators()` only distributes funds nominally instead of transfering actual value, it is to be verified whether the call to it has actually `value` assigned to it or not, therefore adding / removing the `payable` modifier might be necessary.
  
  
### **Contextual constraints**
 The above delegation logic assumes the following requirements to the `main staking logic` to be met: 
 
 1. On any adjustment of a staker's amount, who registered as a `delegatee`, `update_delegatees_stake()` is called to keep the delegation logic's book-keeping in sync with the amount of funds staked by stakers in the `main staking logic`. By checking if the Caller is a `delegatee`, all delegatee's calls to adjust their stake shall be forwarded *to the delegation logic* (as for example the direct withdrawal from the staker's total stake in the `main staking logic` would withdraw also the funds *delegated* to him). The delegation logic has means of adjusting the staked amount in the `main staking logic` in accordance to the changes in its book keeping, according stubs are included in the current code.
 3. It is assumed there is some function in the `main staking logic` that is called by the block producer every time he produces a block. (Current information: There is supposedly a function called `step()` to which this applies).
 4. It is assumed that rewards for blocks produced by stakers that registered as `delegatee`s remain in the contract of the `main staking logic`, from which the eligible parties can withdraw them utilizing the delegation logic's `withdraw_rewards()`. 
 5. Every time a block was produced, the `split_reward()` function is to be called (presumably in the function referenced in 3.) . This is safe, because `split_reward()` immediately returns, if the caller is not a registered `delegatee`. It is assumed, that in this call, the earned block reward is `Call.value`. If that is not the case, the delegation logic can easily be adjusted to reference this value from somewhere else which is accessible to the contract.
  
 