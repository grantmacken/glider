#!/usr/bin/env escript
%% -*- coding: utf-8 -*-
%%! -setcookie monster
-define(SELF_NODE, list_to_atom( "escript_" ++ integer_to_list(rand:uniform(16#FFFFFFFFF)) ++ "@127.0.0.1")).

-record(xqAtomicValue, {
    type = undefined :: atom(),
    value = undefined :: term() | []
}).

-record(xqError, {
    name,
    description = [],
    value = [],
    % {Module, Line, Column}
    location = undefined,
    additional = []
}).

print([]) -> ok;
print([H|T]) ->
  io:format("~s~n", [ binary_to_list(H#xqAtomicValue.value) ]),
  print(T).

main([]) ->
   {ok, _} = net_kernel:start([?SELF_NODE, longnames]),
   Timeout = 1000,
 try rpc:call( 'xqerl@127.0.0.1',
                xqerl,
                run,
                ["for-each(uri-collection(),function($item){uri-collection($item)})"],
                Timeout) of
  #xqAtomicValue{value = A} when is_binary(A) ->
            io:format("~s~n", [ binary_to_list(A)]) ;
  #xqError{description = D }  ->
            io:format("~p~n", [ D ]) ;
  List when is_list(List) -> print(List)
 catch 
    error:_ErrReason -> io:format("RPC ERROR: ~p ~n" , [ _ErrReason ]);
    exit:_ExitReason -> io:format("RPC EXIT: ~p ~n" , [  _ExitReason ])
  end. 


