%%%-------------------------------------------------------------------
%% @doc Pruebas EUnit para `p06_bst`.
%% @end
%%%-------------------------------------------------------------------

-module(p06_bst_tests).

-include_lib("eunit/include/eunit.hrl").

%%%-------------------------------------------------------------------
%% Árbol vacío
%%%-------------------------------------------------------------------

vacio_test() ->
    ?assertEqual(nil, p06_bst:vacio()),
    ?assertEqual(0, p06_bst:altura(p06_bst:vacio())),
    ?assertEqual([], p06_bst:inorden(p06_bst:vacio())),
    ?assertNot(p06_bst:buscar(a, p06_bst:vacio())),
    ?assertEqual(nil, p06_bst:eliminar(a, p06_bst:vacio())).

%%%-------------------------------------------------------------------
%% Inserción y búsqueda
%%%-------------------------------------------------------------------

insertar_buscar_test() ->
    Arbol = p06_bst:desde_lista([5, 3, 8, 1, 4, 7, 9]),
    lists:foreach(
      fun(Valor) -> ?assert(p06_bst:buscar(Valor, Arbol)) end,
      [5, 3, 8, 1, 4, 7, 9]),
    lists:foreach(
      fun(Valor) -> ?assertNot(p06_bst:buscar(Valor, Arbol)) end,
      [0, 2, 6, 10, 100]).

inorden_ascendente_test() ->
    Arbol = p06_bst:desde_lista([5, 3, 8, 1, 4, 7, 9]),
    ?assertEqual([1, 3, 4, 5, 7, 8, 9], p06_bst:inorden(Arbol)).

altura_test() ->
    ?assertEqual(1, p06_bst:altura(p06_bst:desde_lista([42]))),
    ?assertEqual(2, p06_bst:altura(p06_bst:desde_lista([5, 3, 8]))),
    ?assertEqual(3, p06_bst:altura(p06_bst:desde_lista([5, 3, 8, 1]))).

%%%-------------------------------------------------------------------
%% Elementos repetidos
%%%-------------------------------------------------------------------

repetidos_test() ->
    Arbol = p06_bst:desde_lista([5, 3, 3, 8, 5, 8, 5]),
    ?assertEqual([3, 5, 8], p06_bst:inorden(Arbol)),
    ?assertEqual(2, p06_bst:altura(Arbol)),
    ?assert(p06_bst:buscar(5, Arbol)).

%%%-------------------------------------------------------------------
%% Eliminación
%%%-------------------------------------------------------------------

eliminar_hoja_test() ->
    Arbol = p06_bst:desde_lista([5, 3, 8, 1, 4, 7, 9]),
    Nuevo = p06_bst:eliminar(1, Arbol),
    ?assertNot(p06_bst:buscar(1, Nuevo)),
    ?assertEqual([3, 4, 5, 7, 8, 9], p06_bst:inorden(Nuevo)).

eliminar_un_hijo_test() ->
    Arbol = p06_bst:desde_lista([5, 3, 8, 1, 4, 7, 9]),
    %% El nodo 3 solo tiene hijos izquierdos en este árbol: 1.
    Nuevo = p06_bst:eliminar(3, Arbol),
    ?assertNot(p06_bst:buscar(3, Nuevo)),
    ?assertEqual([1, 4, 5, 7, 8, 9], p06_bst:inorden(Nuevo)).

eliminar_un_hijo_derecho_test() ->
    Arbol = p06_bst:desde_lista([5, 3, 8, 4, 7, 9]),
    %% El nodo 3 solo tiene hijo derecho: 4.
    Nuevo = p06_bst:eliminar(3, Arbol),
    ?assertNot(p06_bst:buscar(3, Nuevo)),
    ?assertEqual([4, 5, 7, 8, 9], p06_bst:inorden(Nuevo)).

eliminar_dos_hijos_test() ->
    Arbol = p06_bst:desde_lista([5, 3, 8, 1, 4, 7, 9]),
    Nuevo = p06_bst:eliminar(5, Arbol),
    ?assertNot(p06_bst:buscar(5, Nuevo)),
    ?assertEqual([1, 3, 4, 7, 8, 9], p06_bst:inorden(Nuevo)).

eliminar_inexistente_test() ->
    Arbol = p06_bst:desde_lista([5, 3, 8]),
    ?assertEqual(Arbol, p06_bst:eliminar(100, Arbol)).

eliminar_unico_nodo_test() ->
    ?assertEqual(nil, p06_bst:eliminar(42, p06_bst:desde_lista([42]))).

%%%-------------------------------------------------------------------
%% Los 32 estados de México
%%%-------------------------------------------------------------------

estados_son_32_test() ->
    Estados = p06_bst:estados(),
    ?assertEqual(32, length(Estados)),
    ?assertEqual(Estados, lists:sort(Estados)).

alfabetico_es_degenerado_test() ->
    Estados = p06_bst:estados(),
    Arbol = p06_bst:desde_lista(Estados),
    ?assertEqual(32, p06_bst:altura(Arbol)),
    ?assertEqual(Estados, p06_bst:inorden(Arbol)),
    lists:foreach(
      fun(Estado) -> ?assert(p06_bst:buscar(Estado, Arbol)) end,
      Estados).

aleatorio_es_mas_bajo_test() ->
    rand:seed(exsss, {7, 11, 13}),
    Estados = p06_bst:estados(),
    Arbol = p06_bst:desde_lista(p06_bst:barajar(Estados)),
    Altura = p06_bst:altura(Arbol),
    ?assert(Altura < 32),
    ?assert(Altura > 0),
    ?assertEqual(Estados, p06_bst:inorden(Arbol)),
    lists:foreach(
      fun(Estado) -> ?assert(p06_bst:buscar(Estado, Arbol)) end,
      Estados).

barajar_conserva_elementos_test() ->
    rand:seed(exsss, {1, 2, 3}),
    Estados = p06_bst:estados(),
    ?assertEqual(Estados, lists:sort(p06_bst:barajar(Estados))).

demo_test() ->
    {AlturaAlfabetico, AlturaAleatorio} = p06_bst:demo(),
    ?assertEqual(32, AlturaAlfabetico),
    ?assert(AlturaAleatorio < 32).
