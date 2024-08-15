-module(prob).

-compile(export_all).


%%% Directly from the source:
%%% https://www.keithschwarz.com/darts-dice-coins/
%%%

select_stakers(N, StakeHolders) ->
  select_stakers(erlang:now(), N, StakeHolders).

select_stakers(Seed, N, StakeHolders) ->
  rand:seed(default, Seed),
  TotalStake = lists:sum([ W || {_, W} <- StakeHolders ]),
  Probs = [ {Ix, W/TotalStake} || {Ix, {_X, W}} <- lists:enumerate(0, StakeHolders) ],
  BiasProbs = transform(lists:sort(fun({I1, W1}, {I2, W2}) -> W1 > W2 end, Probs), 1),
  io:format("Probs: ~p\nBias ~p\n", [Probs, BiasProbs]),
  Stakers = maps:from_list(lists:enumerate(0, [X || {X, _} <- StakeHolders])),
  transform_draws(N, BiasProbs, Stakers).
  %% [ maps:get(X, Stakers) || X <- bias_draws(N, Probs) ].

transform([{I, _}], _Mass) -> [{I, 1}];
transform([{I, W} | Probs], Mass) ->
  [{I, W/Mass} | transform(Probs, Mass - W)].

transform_draws(N, BiasProbs, Stakers) ->
  [ maps:get(transform_draw(BiasProbs), Stakers) || _ <- lists:seq(1, N)].

transform_draw([{I, _}]) -> I;
transform_draw([{I, W} | Rest]) ->
  case rand:uniform() =< W of
    true -> I;
    false -> transform_draw(Rest)
  end.


bias_draws(0, _Probs) ->
  [];
bias_draws(N, Probs) when N > 0 ->
  [bias_draw(Probs, 1) | bias_draws(N - 1, Probs)].

bias_draw([{I, _}], _) ->
  I;
bias_draw([{I, PI} | Probs], Mass) ->
  case rand:uniform() =< PI / Mass of
    true ->
      I;
    false ->
      bias_draw(Probs, Mass - PI)
  end.


%% Property here
%%

distribution([]) ->
  #{};
distribution(Stakers) ->
  lists:reverse(lists:keysort(2, distribution(Stakers, #{}))).

distribution([], Dist) ->
  Total = lists:sum(maps:values(Dist)),
  maps:fold(fun(Staker, Count, Acc) -> [{Staker, Count/Total}| Acc] end,
            [], Dist);
distribution([Staker | Stakers], Dist) ->
  distribution(Stakers, maps:put(Staker, maps:get(Staker, Dist, 0) + 1, Dist)).

