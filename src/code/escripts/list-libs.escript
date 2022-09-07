#!/usr/bin/env escript
%% -*- coding: utf-8 -*-
%%! -setcookie monster
-define(SELF_NODE, list_to_atom( "escript_" ++ integer_to_list(rand:uniform(16#FFFFFFFFF)) ++ "@127.0.0.1")).

print([]) -> ok;
print([H|T]) ->
  io:format("~s~n", [ binary_to_list(H)]),
  print(T).

main([]) ->
   {ok, _} = net_kernel:start([?SELF_NODE, longnames]),
   Timeout = 1000,
 try rpc:call( 'xqerl@127.0.0.1',
                xqerl_code_server,
                library_namespaces,
                [],
                Timeout) of
    List when is_list(List) -> print(List)

 catch 
    error:_ErrReason -> io:format("RPC ERROR: ~p ~n" , [ _ErrReason ]);
    exit:_ExitReason -> io:format("RPC EXIT: ~p ~n" , [  _ExitReason ])
  end. 


