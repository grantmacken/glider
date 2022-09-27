#!/usr/bin/env escript
%% -*- coding: utf-8 -*-
%%! -setcookie monster
-define(SELF_NODE, list_to_atom( "compile_" ++ integer_to_list(rand:uniform(16#FFFFFFFFF)) ++ "@127.0.0.1")).
% {xqError, "-record(xqError,{name,description,value,location,additional})."}
%

formatError(Source, Err) -> 
Msg = binary_to_list(element(3,Err)),
Line = integer_to_list(element(2,element(5,Err))),
io:format("src/~s:~s:Error: ~s ~n" , [ Source, Line, Msg ]).
  

main([Source]) ->
   {ok, _} = net_kernel:start([?SELF_NODE, longnames]),
   Timeout = 10000,
 try rpc:call( 'xqerl@127.0.0.1',
                    xqerl,
                    compile,
                    [Source],
                    Timeout) of
    Err when is_tuple(Err) -> formatError(Source, Err); 
    Mod when is_atom(Mod) -> 
         rpc:call( 'xqerl@127.0.0.1',
                   xqerl,
                   run,
                   [Mod])
 catch 
    error:_ErrReason -> io:format("RPC ERROR: ~p ~n" , [ _ErrReason ]);
    exit:_ExitReason -> io:format("RPC EXIT: ~p ~n" , [  _ExitReason ])
  end. 

