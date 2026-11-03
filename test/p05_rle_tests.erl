%%%-------------------------------------------------------------------
%% @doc Pruebas EUnit para `p05_rle`.
%% @end
%%%-------------------------------------------------------------------

-module(p05_rle_tests).

-include_lib("eunit/include/eunit.hrl").

%%%-------------------------------------------------------------------
%% Compresión: ejemplo del enunciado y casos básicos
%%%-------------------------------------------------------------------

comprimir_ejemplo_test() ->
    ?assertEqual("5A3B2C", p05_rle:comprimir("AAAAABBBCC")).

comprimir_vacia_test() ->
    ?assertEqual("", p05_rle:comprimir("")).

comprimir_un_caracter_test() ->
    ?assertEqual("1A", p05_rle:comprimir("A")).

comprimir_todos_distintos_test() ->
    ?assertEqual("1A1B1C", p05_rle:comprimir("ABC")).

comprimir_secuencia_larga_test() ->
    ?assertEqual("12A", p05_rle:comprimir("AAAAAAAAAAAA")).

comprimir_runs_separados_test() ->
    ?assertEqual("2A2B2A2B", p05_rle:comprimir("AABBAABB")).

comprimir_minusculas_test() ->
    ?assertEqual("3a3b", p05_rle:comprimir("aaabbb")).

%%%-------------------------------------------------------------------
%% Descompresión
%%%-------------------------------------------------------------------

descomprimir_ejemplo_test() ->
    ?assertEqual("AAAAABBBCC", p05_rle:descomprimir("5A3B2C")).

descomprimir_vacia_test() ->
    ?assertEqual("", p05_rle:descomprimir("")).

descomprimir_todos_distintos_test() ->
    ?assertEqual("ABC", p05_rle:descomprimir("1A1B1C")).

descomprimir_secuencia_larga_test() ->
    ?assertEqual(lists:duplicate(12, $A), p05_rle:descomprimir("12A")).

descomprimir_conteo_grande_test() ->
    ?assertEqual(lists:duplicate(1000, $x), p05_rle:descomprimir("1000x")).

%%%-------------------------------------------------------------------
%% Ida y vuelta
%%%-------------------------------------------------------------------

ida_y_vuelta_test() ->
    Cadenas = ["AAAAABBBCC",
               "",
               "A",
               "ABC",
               "AABBAABB",
               "aaabbbcccd",
               lists:duplicate(500, $Z)],
    lists:foreach(
      fun(Cadena) ->
              Comprimida = p05_rle:comprimir(Cadena),
              ?assertEqual(Cadena, p05_rle:descomprimir(Comprimida))
      end,
      Cadenas).

%%%-------------------------------------------------------------------
%% Porcentaje de compresión
%%%-------------------------------------------------------------------

porcentaje_ejemplo_test() ->
    %% 10 caracteres -> 6 caracteres: (10 - 6) * 100 / 10 = 40.0
    ?assertEqual(40.0, p05_rle:porcentaje_compresion("AAAAABBBCC")).

porcentaje_vacia_test() ->
    ?assertEqual(0.0, p05_rle:porcentaje_compresion("")).

porcentaje_sin_compresion_test() ->
    %% "ABC" -> "1A1B1C": el resultado es más largo, porcentaje negativo.
    ?assertEqual(-100.0, p05_rle:porcentaje_compresion("ABC")).

%%%-------------------------------------------------------------------
%% Entradas inválidas
%%%-------------------------------------------------------------------

comprimir_digito_invalido_test() ->
    ?assertError({caracter_invalido, $1}, p05_rle:comprimir("A1B")).

comprimir_no_lista_test() ->
    ?assertError({entrada_invalida, 123}, p05_rle:comprimir(123)).

descomprimir_sin_conteo_test() ->
    ?assertError({formato_invalido, "A"}, p05_rle:descomprimir("A")).

descomprimir_sin_caracter_test() ->
    ?assertError({formato_invalido, "5"}, p05_rle:descomprimir("5")).

descomprimir_conteo_cero_test() ->
    ?assertError({formato_invalido, "0A"}, p05_rle:descomprimir("0A")).

descomprimir_cero_a_la_izquierda_test() ->
    ?assertError({formato_invalido, "05A"}, p05_rle:descomprimir("05A")).

descomprimir_fragmento_incompleto_test() ->
    ?assertError({formato_invalido, "B"}, p05_rle:descomprimir("5AB")).

descomprimir_no_lista_test() ->
    ?assertError({entrada_invalida, 123}, p05_rle:descomprimir(123)).
