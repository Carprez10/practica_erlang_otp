%%%-------------------------------------------------------------------
%% @doc Pruebas EUnit para `p01_nucleo`.
%%
%% Son pruebas pequeñas y deterministas. La prueba de estrés con diez
%% millones de elementos se dejará para una etapa posterior, tal como se
%% acordó.
%% @end
%%%-------------------------------------------------------------------

-module(p01_nucleo_tests).

-include_lib("eunit/include/eunit.hrl").

%%%-------------------------------------------------------------------
%% suma/1
%%%-------------------------------------------------------------------

suma_lista_vacia_test() ->
    ?assertEqual(0, p01_nucleo:suma([])).

suma_enteros_positivos_test() ->
    ?assertEqual(6, p01_nucleo:suma([1, 2, 3])).

suma_enteros_mixtos_test() ->
    ?assertEqual(2, p01_nucleo:suma([-5, 10, -3])).

suma_flotantes_test() ->
    ?assertEqual(4.0, p01_nucleo:suma([1.5, 2.5])).

%%%-------------------------------------------------------------------
%% maximo/1
%%%-------------------------------------------------------------------

maximo_un_elemento_test() ->
    ?assertEqual(42, p01_nucleo:maximo([42])).

maximo_lista_desordenada_test() ->
    ?assertEqual(9, p01_nucleo:maximo([3, 9, 1, 7])).

maximo_duplicados_test() ->
    ?assertEqual(5, p01_nucleo:maximo([3, 5, 5, 2])).

maximo_negativos_test() ->
    ?assertEqual(-2, p01_nucleo:maximo([-5, -2, -9])).

maximo_lista_vacia_test() ->
    ?assertError(lista_vacia, p01_nucleo:maximo([])).

%%%-------------------------------------------------------------------
%% filtrar/2
%%%-------------------------------------------------------------------

filtrar_pares_test() ->
    Predicado = fun(X) -> X rem 2 =:= 0 end,
    ?assertEqual([2, 4, 6], p01_nucleo:filtrar(Predicado, [1, 2, 3, 4, 5, 6])).

filtrar_conserva_orden_test() ->
    Predicado = fun(X) -> X > 2 end,
    ?assertEqual([3, 4, 5], p01_nucleo:filtrar(Predicado, [1, 2, 3, 4, 5])).

filtrar_ninguno_test() ->
    Predicado = fun(X) -> X > 100 end,
    ?assertEqual([], p01_nucleo:filtrar(Predicado, [1, 2, 3])).

filtrar_todos_test() ->
    Predicado = fun(X) -> X > 0 end,
    ?assertEqual([1, 2, 3], p01_nucleo:filtrar(Predicado, [1, 2, 3])).

filtrar_lista_vacia_test() ->
    Predicado = fun(_X) -> true end,
    ?assertEqual([], p01_nucleo:filtrar(Predicado, [])).

%%%-------------------------------------------------------------------
%% mapear/2
%%%-------------------------------------------------------------------

mapear_duplica_test() ->
    Funcion = fun(X) -> X * 2 end,
    ?assertEqual([2, 4, 6], p01_nucleo:mapear(Funcion, [1, 2, 3])).

mapear_conserva_orden_test() ->
    Funcion = fun(X) -> X + 10 end,
    ?assertEqual([11, 12, 13], p01_nucleo:mapear(Funcion, [1, 2, 3])).

mapear_lista_vacia_test() ->
    Funcion = fun(X) -> X * 2 end,
    ?assertEqual([], p01_nucleo:mapear(Funcion, [])).

%%%-------------------------------------------------------------------
%% reducir/3
%%%-------------------------------------------------------------------

reducir_suma_test() ->
    Funcion = fun(X, Acc) -> X + Acc end,
    ?assertEqual(6, p01_nucleo:reducir(Funcion, 0, [1, 2, 3])).

reducir_es_fold_izquierdo_test() ->
    %% En un fold izquierdo: ((0 - 1) - 2) - 3 = -6.
    %% En un fold derecho sería: 1 - (2 - (3 - 0)) = 2.
    Funcion = fun(X, Acc) -> Acc - X end,
    ?assertEqual(-6, p01_nucleo:reducir(Funcion, 0, [1, 2, 3])).

reducir_orden_de_recorrido_test() ->
    %% Al recorrer de izquierda a derecha y consar cada elemento, el
    %% resultado queda invertido: [3, 2, 1].
    Funcion = fun(X, Acc) -> [X | Acc] end,
    ?assertEqual([3, 2, 1], p01_nucleo:reducir(Funcion, [], [1, 2, 3])).

reducir_lista_vacia_test() ->
    Funcion = fun(X, Acc) -> X + Acc end,
    ?assertEqual(100, p01_nucleo:reducir(Funcion, 100, [])).
