# Hyperchain Properties

Here we summarize some properties the should hold for hyperchains. These properties are input to later test cases.


## Leader election

1. Leaders election is deterministic from a specific random seed, obtained from parent chain entropy.
2. In child generations, the leaders are chosen fairly. That is, the distribution of stake is similar to the distribution of chosen leaders.

The first property is rather straightforward to test, but the second one is a statistical property and needs a bit of thinking.

## Synchronization

1. Over a number of parent chain generations that together have the expected durations, the child chain generations are in sync.
2. The child chain can adapt to the block production time of the parent chain by changing 'child generation length'. After such change, the above property holds again.
3. The voting mechanism for adapting the child generation length works as expected and in time.

Here we also have some more statistic properties to test and one needs to think about margins of validity

## Pinning

1. Pinning incentives are correctly implemented: correct pinning results in correct rewards.
2. Pinning proof of inclusion can be verified by all stakeholders.


## Non-productive stakers

1. The mechanism dealing with non-productive stakers does not violate the other properties.(Possibly with distribution of leaders if we penalize.)


