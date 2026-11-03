%%%-------------------------------------------------------------------
%% @doc practica_erlang_otp public API
%% @end
%%%-------------------------------------------------------------------

-module(practica_erlang_otp_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    practica_erlang_otp_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
