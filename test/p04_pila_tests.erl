%%%-------------------------------------------------------------------
%% @doc Pruebas EUnit para `p04_pila`.
%% @end
%%%-------------------------------------------------------------------

-module(p04_pila_tests).

-include_lib("eunit/include/eunit.hrl").

%%%-------------------------------------------------------------------
%% Pila
%%%-------------------------------------------------------------------

push_test() ->
    ?assertEqual([1], p04_pila:push(1, [])),
    ?assertEqual([3, 2, 1], p04_pila:push(3, [2, 1])).

pop_test() ->
    ?assertEqual({ok, 3, [2, 1]}, p04_pila:pop([3, 2, 1])),
    ?assertEqual({ok, 1, []}, p04_pila:pop([1])).

pop_vacia_test() ->
    ?assertEqual({error, pila_vacia}, p04_pila:pop([])).

peek_test() ->
    ?assertEqual({ok, 3}, p04_pila:peek([3, 2, 1])),
    ?assertEqual({ok, 1}, p04_pila:peek([1])).

peek_vacia_test() ->
    ?assertEqual({error, pila_vacia}, p04_pila:peek([])).

is_empty_test() ->
    ?assert(p04_pila:is_empty([])),
    ?assertNot(p04_pila:is_empty([1])).

orden_lifo_test() ->
    Pila0 = [],
    Pila1 = p04_pila:push(a, Pila0),
    Pila2 = p04_pila:push(b, Pila1),
    Pila3 = p04_pila:push(c, Pila2),
    {ok, c, Pila4} = p04_pila:pop(Pila3),
    {ok, b, Pila5} = p04_pila:pop(Pila4),
    {ok, a, Pila6} = p04_pila:pop(Pila5),
    ?assert(p04_pila:is_empty(Pila6)).

%%%-------------------------------------------------------------------
%% Delimitadores: casos del enunciado
%%%-------------------------------------------------------------------

balanceada_corchetes_llaves_parentesis_test() ->
    ?assert(p04_pila:balanceada("{[()]}")).

balanceada_cruzados_test() ->
    ?assertNot(p04_pila:balanceada("([)]")).

balanceada_aperturas_sin_cerrar_test() ->
    ?assertNot(p04_pila:balanceada("(((")).

%%%-------------------------------------------------------------------
%% Delimitadores: otros casos
%%%-------------------------------------------------------------------

balanceada_vacia_test() ->
    ?assert(p04_pila:balanceada("")).

balanceada_pares_simples_test() ->
    ?assert(p04_pila:balanceada("()")),
    ?assert(p04_pila:balanceada("[]")),
    ?assert(p04_pila:balanceada("{}")),
    ?assert(p04_pila:balanceada("()[]{}")).

balanceada_anidada_test() ->
    ?assert(p04_pila:balanceada("(([]){})")),
    ?assert(p04_pila:balanceada("[{()()}]")).

balanceada_cierres_sin_apertura_test() ->
    ?assertNot(p04_pila:balanceada(")")),
    ?assertNot(p04_pila:balanceada(")(")),
    ?assertNot(p04_pila:balanceada("}")),
    ?assertNot(p04_pila:balanceada("())")).

balanceada_pareja_incorrecta_test() ->
    ?assertNot(p04_pila:balanceada("(]")),
    ?assertNot(p04_pila:balanceada("[}")),
    ?assertNot(p04_pila:balanceada("{)")).

balanceada_con_texto_test() ->
    ?assert(p04_pila:balanceada("a(b[c]{d}e)")),
    ?assertNot(p04_pila:balanceada("a(b[c)]d")).

balanceada_expresion_invalida_test() ->
    ?assertError({expresion_invalida, hola}, p04_pila:balanceada(hola)).
