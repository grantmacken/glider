#!/usr/bin/env escript
%% -*- coding: utf-8 -*-
%%! -setcookie monster
-define(SELF_NODE, list_to_atom( "escript_" ++ integer_to_list(rand:uniform(16#FFFFFFFFF)) ++ "@127.0.0.1")).

main([Script,Arg]) ->
 try 
   {ok, _} = net_kernel:start([?SELF_NODE, longnames]),
   Timeout = 1000,
    M = rpc:call( 'xqerl@127.0.0.1',
                    xqerl,
                    compile,
                    Script,
                    Timeout),
    C = #{<<"arg">> => list_to_binary(Arg) },
    R = rpc:call( 'xqerl@127.0.0.1',
                    xqerl,
                    run,
                   [M,C],
                   Timeout),
    io:format(" ~s ~n", [ R ] )
  catch 
    error:_ErrReason -> io:format("RPC ERROR: ~s ~p ~n" , [ Arg , _ErrReason ]);
    exit:_ExitReason -> io:format("RPC EXIT:  ~p ~n" , [  _ExitReason ])
  end. 


