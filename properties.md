# Hyperchain Properties

Here we summarize some properties the should hold for hyperchains. These properties are input to later test cases.


## Leader election

1. Leaders election is deterministic from a specific random seed, obtained from parent chain entropy.
2. In child generations, the leaders are chosen fairly. That is, the distribution of stake is similar to the distribution of chosen leaders.

The first property is rather straightforward to test, but the second one is a statistical property and needs a bit of thinking.

Preparation of that work is implementing a small algorithm for weighted random drawings based upon
[Darts Dice Coins](https://www.keithschwarz.com/darts-dice-coins/).

With some straightforward Erlang code, it can already be spotted that there is a challenge in decising that an
algorithm is good enough and selecting a good enough algorithm.
For example, a rather naive implementation seems to work well if we have few stake holders all with a larger set of coins.
```erlang
89> prob:distribution(prob:select_stakers(10000, [{thomas, 80}, {hans, 10}, {erik, 10}])).
[{thomas,0.8103},{hans,0.0965},{erik,0.0932}]
90> prob:distribution(prob:select_stakers(10000, [{thomas, 80}, {hans, 10}, {erik, 10}])).
[{thomas,0.7957},{erik,0.1053},{hans,0.099}]
```
If thomas has 80 percent of the coins and hans and erik 10 percent each, then with a client generation length of 10000 blocks, we
spot that thomas gets to produce around 8000 of those blocks and hans and erik between 932 and 1053. We need criteria to determine whether this is good enough.

But even if this might be good enough, what about a situation in which we have 100 users that have a very small stake.
Do they get chosen at all? What if the generation length is 100, do they then get chosen reasonably well in 10 generations of 100 long?.

```erlang
108> prob:distribution(prob:select_stakers(100, [{thomas, 800}, {hans, 80}, {erik, 80}] ++ [{N, 1} || N <- lists:seq(1,40)])).
[{thomas,0.84},{erik,0.09},{hans,0.05},{31,0.01},{37,0.01}]
109> prob:distribution(prob:select_stakers(100, [{thomas, 800}, {hans, 80}, {erik, 80}] ++ [{N, 1} || N <- lists:seq(1,40)])).
[{thomas,0.86},{hans,0.06},{erik,0.06},{19,0.01},{23,0.01}]
110> prob:distribution(prob:select_stakers(100, [{thomas, 800}, {hans, 80}, {erik, 80}] ++ [{N, 1} || N <- lists:seq(1,40)])).
[{thomas,0.77},
 {erik,0.09},
 {hans,0.07},
 {7,0.02},
 {14,0.02},
 {9,0.01},
 {24,0.01},
 {34,0.01}]


111> prob:distribution(prob:select_stakers(10000, [{thomas, 800}, {hans, 80}, {erik, 80}] ++ [{N, 1} || N <- lists:seq(1,40)])).
[{thomas,0.808},
 {hans,0.0773},
 {erik,0.0769},
 {18,0.0017},
 {7,0.0016},
 {22,0.0015},
 {33,0.0015},
 {14,0.0015},
 {13,0.0014},
 {11,0.0013},
 {15,0.0012},
 {39,0.0011},
 {40,0.0011},
 {1,0.0011},
 {35,0.0011},
 {30,0.0011},
 {25,0.001},
 {3,0.001},
 {2,0.001},
 {32,0.001},
 {5,0.001},
 {4,0.0009},
 {28,0.0009},
 {29,0.0009},
 {19,0.0009},
 {17,0.0009},
 {27,0.0009},
 {34,...},
 {...}|...]
```

We need a property to test this for different implementations to help choose a correct one.



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

## Parent chain compatibility

1. The child-chain should be able to extract the necessary information from the parent chain. API testing.


