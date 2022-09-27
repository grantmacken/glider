#!/usr/bin/env escript
%% -*- coding: utf-8 -*-
%%! -setcookie monster
-define(SELF_NODE, list_to_atom( "escript_" ++ integer_to_list(rand:uniform(16#FFFFFFFFF)) ++ "@127.0.0.1")).

main([Arg1, Arg2]) ->
 try 
   {ok, _} = net_kernel:start([?SELF_NODE, longnames]),
   Timeout = 10000,
    M = 'file____usr_local_xqerl_code_main_modules_xdm-item.xq',
    C = #{<<"uri">> => list_to_binary(Arg1), <<"b64">> => list_to_binary(Arg2) },
    _ = rpc:call( 'xqerl@127.0.0.1',
                    xqerl,
                    run,
                   [M,C],
                   Timeout),
    Compiled = rpc:call( 'xqerl@127.0.0.1',
                    xqerl,
                    compile,
                   ["./code/main_modules/xdm_item.xq"],
                   Timeout),
    Return = rpc:call( 'xqerl@127.0.0.1',
                    xqerl,
                    run,
                   [Compiled],
                   Timeout),
    io:format(" ~s ~n", [ Return ] )
  catch 
    error:_ErrReason -> io:format("RPC ERROR: ~s ~p ~n" , [ Arg1 , _ErrReason ]);
    exit:_ExitReason -> io:format("RPC EXIT:  ~p ~n" , [  _ExitReason ])
  end. 

