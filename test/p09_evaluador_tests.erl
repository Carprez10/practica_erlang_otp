%%%-------------------------------------------------------------------
%% @doc Pruebas EUnit para `p09_evaluador`.
%%%-------------------------------------------------------------------

-module(p09_evaluador_tests).

-include_lib("eunit/include/eunit.hrl").

%%%-------------------------------------------------------------------
%% Ejemplo del enunciado y operaciones simples
%%%-------------------------------------------------------------------

ejemplo_enunciado_test() ->
    ?assertEqual(7, p09_evaluador:evaluar("3 + 4 * (2 - 1)")).

suma_test() ->
    ?assertEqual(5, p09_evaluador:evaluar("2 + 3")).

resta_test() ->
    ?assertEqual(6, p09_evaluador:evaluar("10 - 4")).

multiplicacion_test() ->
    ?assertEqual(42, p09_evaluador:evaluar("6 * 7")).

division_test() ->
    ?assertEqual(4.0, p09_evaluador:evaluar("8 / 2")),
    ?assertEqual(3.5, p09_evaluador:evaluar("7 / 2")).

%%%-------------------------------------------------------------------
%% Precedencia y paréntesis
%%%-------------------------------------------------------------------

precedencia_test() ->
    ?assertEqual(14, p09_evaluador:evaluar("2 + 3 * 4")),
    ?assertEqual(10, p09_evaluador:evaluar("2 * 3 + 4")),
    ?assertEqual(4, p09_evaluador:evaluar("10 - 2 * 3")),
    ?assertEqual(5.0, p09_evaluador:evaluar("2 + 6 / 2")).

parentesis_test() ->
    ?assertEqual(20, p09_evaluador:evaluar("(2 + 3) * 4")),
    ?assertEqual(2, p09_evaluador:evaluar("((2))")),
    ?assertEqual(12, p09_evaluador:evaluar("2 * (3 + (4 - 1))")),
    ?assertEqual(7, p09_evaluador:evaluar("(3 + 4) * (2 - 1)")).

%%%-------------------------------------------------------------------
%% Números negativos y unarios
%%%-------------------------------------------------------------------

negativos_test() ->
    ?assertEqual(-2, p09_evaluador:evaluar("-5 + 3")),
    ?assertEqual(-6, p09_evaluador:evaluar("3 * -2")),
    ?assertEqual(-5, p09_evaluador:evaluar("-(2 + 3)")),
    ?assertEqual(5, p09_evaluador:evaluar("3 - -2")),
    ?assertEqual(5, p09_evaluador:evaluar("+5")).

%%%-------------------------------------------------------------------
%% Espacios y decimales
%%%-------------------------------------------------------------------

espacios_test() ->
    ?assertEqual(7, p09_evaluador:evaluar("  3   +   4 * ( 2 - 1 )  ")),
    ?assertEqual(5, p09_evaluador:evaluar("\t2 + 3\n")).

decimales_test() ->
    ?assertEqual(5.0, p09_evaluador:evaluar("3.5 + 1.5")),
    ?assertEqual(3.0, p09_evaluador:evaluar("1.5 * 2")),
    ?assertEqual(0.25, p09_evaluador:evaluar("0.5 / 2")).

%%%-------------------------------------------------------------------
%% División entre cero
%%%-------------------------------------------------------------------

division_entre_cero_test() ->
    ?assertError({error_aritmetico, division_entre_cero},
                 p09_evaluador:evaluar("5 / 0")),
    ?assertError({error_aritmetico, division_entre_cero},
                 p09_evaluador:evaluar("1 / (3 - 3)")),
    ?assertError({error_aritmetico, division_entre_cero},
                 p09_evaluador:evaluar("5 / 0.0")).

%%%-------------------------------------------------------------------
%% Expresiones incompletas o mal formadas
%%%-------------------------------------------------------------------

incompletas_test() ->
    ?assertError({error_sintaxis, []}, p09_evaluador:evaluar("")),
    ?assertError({error_sintaxis, []}, p09_evaluador:evaluar("3 +")),
    ?assertError({error_sintaxis, []}, p09_evaluador:evaluar("(1 + 2")),
    ?assertError({error_sintaxis, "2"}, p09_evaluador:evaluar("1 2")),
    ?assertError({error_sintaxis, ")"}, p09_evaluador:evaluar("()")),
    ?assertError({error_sintaxis, []}, p09_evaluador:evaluar("3.")).

%%%-------------------------------------------------------------------
%% Caracteres inválidos
%%%-------------------------------------------------------------------

caracteres_invalidos_test() ->
    ?assertError({caracter_invalido, $a}, p09_evaluador:evaluar("abc")),
    ?assertError({caracter_invalido, $a}, p09_evaluador:evaluar("2 + a")),
    ?assertError({caracter_invalido, $&}, p09_evaluador:evaluar("3 & 4")).

%%%-------------------------------------------------------------------
%% Entrada inválida
%%%-------------------------------------------------------------------

entrada_invalida_test() ->
    ?assertError({entrada_invalida, 123}, p09_evaluador:evaluar(123)),
    ?assertError({entrada_invalida, atomo}, p09_evaluador:evaluar(atomo)).
