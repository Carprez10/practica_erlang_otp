%%%-------------------------------------------------------------------
%% @doc Pruebas EUnit para `p07_kaprekar`.
%% @end
%%%-------------------------------------------------------------------

-module(p07_kaprekar_tests).

-include_lib("eunit/include/eunit.hrl").

%%%-------------------------------------------------------------------
%% Ejemplos del enunciado
%%%-------------------------------------------------------------------

ejemplo_1234_test() ->
    ?assertEqual([1234, 3087, 8352, 6174], p07_kaprekar:secuencia(1234)),
    ?assertEqual(3, p07_kaprekar:iteraciones(1234)).

ejemplo_5678_test() ->
    ?assertEqual([5678, 3087, 8352, 6174], p07_kaprekar:secuencia(5678)),
    ?assertEqual(3, p07_kaprekar:iteraciones(5678)).

ejemplo_9981_test() ->
    ?assertEqual([9981, 8082, 8532, 6174], p07_kaprekar:secuencia(9981)),
    ?assertEqual(3, p07_kaprekar:iteraciones(9981)).

%%%-------------------------------------------------------------------
%% Casos límite
%%%-------------------------------------------------------------------

constante_test() ->
    ?assertEqual([6174], p07_kaprekar:secuencia(6174)),
    ?assertEqual(0, p07_kaprekar:iteraciones(6174)).

cero_test() ->
    ?assertEqual([0], p07_kaprekar:secuencia(0)),
    ?assertEqual(0, p07_kaprekar:iteraciones(0)).

ceros_a_la_izquierda_test() ->
    %% 1000 -> 0999 -> 8991 -> 8082 -> 8532 -> 6174
    ?assertEqual([1000, 999, 8991, 8082, 8532, 6174],
                 p07_kaprekar:secuencia(1000)),
    ?assertEqual(5, p07_kaprekar:iteraciones(1000)).

siguiente_test() ->
    ?assertEqual(3087, p07_kaprekar:siguiente(1234)),
    %% 0999: 9990 - 0999 = 8991
    ?assertEqual(8991, p07_kaprekar:siguiente(999)),
    ?assertEqual(0, p07_kaprekar:siguiente(1111)).

formatear_test() ->
    ?assertEqual("0000", p07_kaprekar:formatear(0)),
    ?assertEqual("0999", p07_kaprekar:formatear(999)),
    ?assertEqual("6174", p07_kaprekar:formatear(6174)).

%%%-------------------------------------------------------------------
%% Dígitos iguales: llegan a 0000
%%%-------------------------------------------------------------------

repdigits_test() ->
    Repdigits = [0, 1111, 2222, 3333, 4444, 5555, 6666, 7777, 8888, 9999],
    lists:foreach(
      fun(Repdigit) ->
              Secuencia = p07_kaprekar:secuencia(Repdigit),
              ?assertEqual(0, lists:last(Secuencia))
      end,
      Repdigits),
    ?assertEqual([1111, 0], p07_kaprekar:secuencia(1111)).

%%%-------------------------------------------------------------------
%% Todos los números válidos llegan a 6174 en <= 7 iteraciones
%%%-------------------------------------------------------------------

todos_llegan_a_6174_test() ->
    Repdigits = [0, 1111, 2222, 3333, 4444, 5555, 6666, 7777, 8888, 9999],
    lists:foreach(
      fun(Numero) ->
              case lists:member(Numero, Repdigits) of
                  true ->
                      ok;
                  false ->
                      Secuencia = p07_kaprekar:secuencia(Numero),
                      Pasos = p07_kaprekar:iteraciones(Numero),
                      ?assertEqual(6174, lists:last(Secuencia)),
                      ?assert(Pasos =< 7)
              end
      end,
      lists:seq(0, 9999)).

%%%-------------------------------------------------------------------
%% Entradas inválidas
%%%-------------------------------------------------------------------

invalidos_test() ->
    ?assertError({numero_invalido, -1}, p07_kaprekar:secuencia(-1)),
    ?assertError({numero_invalido, 10000}, p07_kaprekar:secuencia(10000)),
    ?assertError({numero_invalido, 3.14}, p07_kaprekar:secuencia(3.14)),
    ?assertError({numero_invalido, "1234"}, p07_kaprekar:secuencia("1234")),
    ?assertError({numero_invalido, atomo}, p07_kaprekar:siguiente(atomo)),
    ?assertError({numero_invalido, -5}, p07_kaprekar:formatear(-5)).

%%%-------------------------------------------------------------------
%% Demo
%%%-------------------------------------------------------------------

demo_test() ->
    ?assertEqual(ok, p07_kaprekar:demo()).
