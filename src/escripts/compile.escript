#!/usr/bin/env escript
%% -*- coding: utf-8 -*-
%%! -setcookie monster
-define(SELF_NODE, list_to_atom( "compile_" ++ integer_to_list(rand:uniform(16#FFFFFFFFF)) ++ "@127.0.0.1")).

main([Source]) ->
  {ok, _} = net_kernel:start([?SELF_NODE, longnames]),
    case rpc:call('xqerl@127.0.0.1', xqerl, compile, [Source]) of
    Err when is_tuple(Err), element(1, Err) == xqError -> 
      io:format([Source,":",integer_to_list(element(2,element(5,Err))),":E: ",binary_to_list(element(3,Err))]),
      io:format(["\n"]);
    Info when is_atom(Info) -> 
       io:format([Source,":1:I: compiled ok!"]);
    _ -> 
    rpc:call('xqerl@127.0.0.1', xqerl, compile, [Source])
       % io:format([Source,":1:W: file not found!"])
    end.


