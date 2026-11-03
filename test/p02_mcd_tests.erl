%%%-------------------------------------------------------------------
%% @doc Pruebas EUnit para `p02_mcd`.
%% @end
%%%-------------------------------------------------------------------

-module(p02_mcd_tests).

-include_lib("eunit/include/eunit.hrl").

%%%-------------------------------------------------------------------
%% Pares indicados en el enunciado
%%%-------------------------------------------------------------------

mcd_252_105_test() ->
    ?assertEqual(21, p02_mcd:mcd(252, 105)).

mcd_1071_462_test() ->
    ?assertEqual(21, p02_mcd:mcd(1071, 462)).

mcd_100_75_test() ->
    ?assertEqual(25, p02_mcd:mcd(100, 75)).

%%%-------------------------------------------------------------------
%% Ceros
%%%-------------------------------------------------------------------

mcd_cero_y_numero_test() ->
    ?assertEqual(5, p02_mcd:mcd(0, 5)).

mcd_numero_y_cero_test() ->
    ?assertEqual(5, p02_mcd:mcd(5, 0)).

mcd_cero_cero_test() ->
    ?assertEqual(0, p02_mcd:mcd(0, 0)).

%%%-------------------------------------------------------------------
%% Números iguales, coprimos y orden invertido
%%%-------------------------------------------------------------------

mcd_iguales_test() ->
    ?assertEqual(7, p02_mcd:mcd(7, 7)).

mcd_iguales_compuestos_test() ->
    ?assertEqual(36, p02_mcd:mcd(36, 36)).

mcd_coprimos_test() ->
    ?assertEqual(1, p02_mcd:mcd(17, 13)).

mcd_orden_invertido_test() ->
    ?assertEqual(21, p02_mcd:mcd(105, 252)).

%%%-------------------------------------------------------------------
%% Entradas inválidas
%%%-------------------------------------------------------------------

mcd_negativo_test() ->
    ?assertError({entrada_invalida, -4, 6}, p02_mcd:mcd(-4, 6)).

mcd_no_entero_test() ->
    ?assertError({entrada_invalida, 4.0, 6}, p02_mcd:mcd(4.0, 6)).
