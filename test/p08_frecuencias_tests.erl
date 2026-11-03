%%%-------------------------------------------------------------------
%% @doc Pruebas EUnit para `p08_frecuencias`.
%% @end
%%%-------------------------------------------------------------------

-module(p08_frecuencias_tests).

-include_lib("eunit/include/eunit.hrl").

%%%-------------------------------------------------------------------
%% Normalización
%%%-------------------------------------------------------------------

normalizar_mayusculas_test() ->
    ?assertEqual("HOLAMUNDO", p08_frecuencias:normalizar("Hola, Mundo")).

normalizar_acentos_test() ->
    ?assertEqual("AEIOUUNAEIOUUN",
                 p08_frecuencias:normalizar("áéíóúüñ ÁÉÍÓÚÜÑ")).

normalizar_ignora_numeros_y_signos_test() ->
    ?assertEqual("ABC", p08_frecuencias:normalizar("A1 B2-C3. ¿¡!?")).

%%%-------------------------------------------------------------------
%% Cadenas vacías
%%%-------------------------------------------------------------------

vacia_test() ->
    ?assertEqual([], p08_frecuencias:frecuencias("")),
    ?assertEqual(0, p08_frecuencias:total_letras("")),
    ?assertEqual("", p08_frecuencias:histograma("")),
    ?assertEqual(26, length(p08_frecuencias:frecuencias_alfabeto(""))),
    lists:foreach(
      fun({_Letra, Absoluta, Relativa}) ->
              ?assertEqual(0, Absoluta),
              ?assertEqual(0.0, Relativa)
      end,
      p08_frecuencias:frecuencias_alfabeto("")).

%%%-------------------------------------------------------------------
%% Letras repetidas, mayúsculas y minúsculas
%%%-------------------------------------------------------------------

repetidas_test() ->
    ?assertEqual([{$A, 3, 1.0}], p08_frecuencias:frecuencias("AAA")).

mayusculas_y_minusculas_test() ->
    ?assertEqual([{$A, 4, 1.0}], p08_frecuencias:frecuencias("aAaA")).

acentos_cuentan_como_base_test() ->
    ?assertEqual([{$A, 4, 1.0}], p08_frecuencias:frecuencias("áÁaA")).

enye_test() ->
    %% "pingüino": P I N G U I N O
    ?assertEqual([{$I, 2, 0.25},
                  {$N, 2, 0.25},
                  {$G, 1, 0.125},
                  {$O, 1, 0.125},
                  {$P, 1, 0.125},
                  {$U, 1, 0.125}],
                 p08_frecuencias:frecuencias("pingüino")).

%%%-------------------------------------------------------------------
%% Signos, espacios y dígitos
%%%-------------------------------------------------------------------

signos_ignorados_test() ->
    %% "¡Hola, mundo!" -> H O L A M U N D O
    ?assertEqual([{$O, 2, 2 / 9},
                  {$A, 1, 1 / 9},
                  {$D, 1, 1 / 9},
                  {$H, 1, 1 / 9},
                  {$L, 1, 1 / 9},
                  {$M, 1, 1 / 9},
                  {$N, 1, 1 / 9},
                  {$U, 1, 1 / 9}],
                 p08_frecuencias:frecuencias("¡Hola, mundo!")).

digitos_ignorados_test() ->
    ?assertEqual(3, p08_frecuencias:total_letras("A1B2C3")),
    ?assertEqual([{$A, 1, 1 / 3}, {$B, 1, 1 / 3}, {$C, 1, 1 / 3}],
                 p08_frecuencias:frecuencias("A1B2C3")).

%%%-------------------------------------------------------------------
%% Orden y frecuencias relativas
%%%-------------------------------------------------------------------

orden_descendente_test() ->
    ?assertEqual([{$A, 3, 0.6}, {$B, 2, 0.4}],
                 p08_frecuencias:frecuencias("AAABB")).

empate_alfabetico_test() ->
    ?assertEqual([{$A, 2, 0.5}, {$B, 2, 0.5}],
                 p08_frecuencias:frecuencias("BBAA")).

relativas_suman_uno_test() ->
    Filas = p08_frecuencias:frecuencias("AAB"),
    Suma = lists:sum([Rel || {_L, _A, Rel} <- Filas]),
    ?assert(abs(Suma - 1.0) < 1.0e-9),
    ?assertEqual(3, p08_frecuencias:total_letras("AAB")).

alfabeto_completo_test() ->
    Filas = p08_frecuencias:frecuencias_alfabeto("AAB"),
    ?assertEqual(26, length(Filas)),
    ?assertEqual({$A, 2, 2 / 3}, hd(Filas)),
    ?assertEqual(24, length([F || {_L, Abs, _} = F <- Filas, Abs =:= 0])).

%%%-------------------------------------------------------------------
%% Histograma e impresión
%%%-------------------------------------------------------------------

histograma_test() ->
    Histograma = p08_frecuencias:histograma("AAB"),
    ?assertNotEqual(nomatch, string:find(Histograma, "A | ")),
    ?assertNotEqual(nomatch, string:find(Histograma, "B | ")),
    Lineas = string:split(Histograma, "\n", all),
    ?assertEqual(2, length(Lineas)),
    %% La barra más frecuente mide 40 asteriscos.
    ?assertNotEqual(nomatch, string:find(Histograma, lists:duplicate(40, $*))).

imprimir_test() ->
    ?assertEqual(ok, p08_frecuencias:imprimir("¡Hola, mundo! 123")).

demo_test() ->
    ?assertEqual(ok, p08_frecuencias:demo()).

%%%-------------------------------------------------------------------
%% Entradas inválidas
%%%-------------------------------------------------------------------

texto_invalido_test() ->
    ?assertError({texto_invalido, 123}, p08_frecuencias:normalizar(123)),
    ?assertError({texto_invalido, atomo}, p08_frecuencias:frecuencias(atomo)).
