%%%-------------------------------------------------------------------
%% @doc Pruebas EUnit para `p03_pascal`.
%% @end
%%%-------------------------------------------------------------------

-module(p03_pascal_tests).

-include_lib("eunit/include/eunit.hrl").

%%%-------------------------------------------------------------------
%% Primeras filas
%%%-------------------------------------------------------------------

fila_1_test() ->
    ?assertEqual([1], p03_pascal:fila(1)).

fila_6_test() ->
    ?assertEqual([1, 5, 10, 10, 5, 1], p03_pascal:fila(6)).

filas_1_test() ->
    ?assertEqual([[1]], p03_pascal:filas(1)).

filas_5_test() ->
    ?assertEqual([[1],
                  [1, 1],
                  [1, 2, 1],
                  [1, 3, 3, 1],
                  [1, 4, 6, 4, 1]],
                 p03_pascal:filas(5)).

siguiente_fila_test() ->
    ?assertEqual([1, 4, 6, 4, 1], p03_pascal:siguiente_fila([1, 3, 3, 1])).

siguiente_fila_desde_primera_test() ->
    ?assertEqual([1, 1], p03_pascal:siguiente_fila([1])).

%%%-------------------------------------------------------------------
%% Quince filas
%%%-------------------------------------------------------------------

quince_filas_test() ->
    Filas = p03_pascal:filas(15),
    ?assertEqual(15, lists:foldl(fun(_Fila, Acc) -> Acc + 1 end, 0, Filas)),
    ?assertEqual([1, 14, 91, 364, 1001, 2002, 3003, 3432,
                  3003, 2002, 1001, 364, 91, 14, 1],
                 lists:last(Filas)).

%%%-------------------------------------------------------------------
%% Simetría de cada fila
%%%-------------------------------------------------------------------

simetria_test() ->
    Filas = p03_pascal:filas(15),
    lists:foreach(
      fun(Fila) ->
              ?assertEqual(Fila, lists:reverse(Fila))
      end,
      Filas).

%%%-------------------------------------------------------------------
%% Suma de la fila n = 2^(n-1)
%%%-------------------------------------------------------------------

suma_filas_test() ->
    Filas = p03_pascal:filas(15),
    Indexadas = lists:zip(lists:seq(1, 15), Filas),
    lists:foreach(
      fun({N, Fila}) ->
              ?assertEqual(1 bsl (N - 1), lists:sum(Fila))
      end,
      Indexadas).

%%%-------------------------------------------------------------------
%% Bordes: cada fila empieza y termina en 1
%%%-------------------------------------------------------------------

bordes_test() ->
    Filas = p03_pascal:filas(15),
    lists:foreach(
      fun([1 | _] = Fila) ->
              ?assertEqual(1, lists:last(Fila))
      end,
      Filas).

%%%-------------------------------------------------------------------
%% Impresión y entradas inválidas
%%%-------------------------------------------------------------------

imprimir_test() ->
    ?assertEqual(ok, p03_pascal:imprimir(3)).

filas_invalidas_test() ->
    ?assertError({numero_de_filas_invalido, 0}, p03_pascal:filas(0)),
    ?assertError({numero_de_filas_invalido, -2}, p03_pascal:filas(-2)),
    ?assertError({numero_de_filas_invalido, 2.5}, p03_pascal:filas(2.5)).

fila_invalida_test() ->
    ?assertError({numero_de_filas_invalido, 0}, p03_pascal:fila(0)).

siguiente_fila_invalida_test() ->
    ?assertError({fila_invalida, []}, p03_pascal:siguiente_fila([])).
