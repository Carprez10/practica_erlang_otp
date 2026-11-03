%%%-------------------------------------------------------------------
%% @doc Proceso de Kaprekar para números de cuatro dígitos.
%%
%% En cada paso se ordenan los cuatro dígitos de mayor a menor y de
%% menor a mayor, y se resta el menor del mayor. Los ceros a la
%% izquierda se conservan: el número 999 se trata como 0999.
%%
%% Todo número de 0 a 9999 llega a 6174 en siete iteraciones o menos,
%% salvo los que tienen los cuatro dígitos iguales, que llegan a 0000.
%%
%% Entradas fuera de 0..9999 o que no son enteros lanzan
%% `erlang:error({numero_invalido, Valor})`.
%% @end
%%%-------------------------------------------------------------------

-module(p07_kaprekar).

-export([secuencia/1, iteraciones/1, siguiente/1, formatear/1, demo/0]).

-define(CONSTANTE, 6174).

%%%-------------------------------------------------------------------
%% @doc Secuencia completa desde `Numero` hasta 6174 o 0000.
%%
%% Incluye el número inicial y el final.
%% @end
%%%-------------------------------------------------------------------
-spec secuencia(integer()) -> [integer()].
secuencia(Numero) ->
    validar(Numero),
    secuencia(Numero, []).

secuencia(?CONSTANTE, Acc) ->
    invertir([?CONSTANTE | Acc], []);
secuencia(0, Acc) ->
    invertir([0 | Acc], []);
secuencia(Numero, Acc) ->
    Siguiente = siguiente(Numero),
    case Siguiente of
        Numero ->
            %% Punto fijo inesperado: se detiene para no repetir.
            invertir([Numero | Acc], []);
        _ ->
            secuencia(Siguiente, [Numero | Acc])
    end.

%%%-------------------------------------------------------------------
%% @doc Número de pasos necesarios para llegar al final.
%% @end
%%%-------------------------------------------------------------------
-spec iteraciones(integer()) -> non_neg_integer().
iteraciones(Numero) ->
    contar(secuencia(Numero)) - 1.

%%%-------------------------------------------------------------------
%% @doc Aplica un solo paso de Kaprekar.
%% @end
%%%-------------------------------------------------------------------
-spec siguiente(integer()) -> integer().
siguiente(Numero) ->
    validar(Numero),
    Digitos = digitos(Numero),
    Ascendente = ordenar(Digitos),
    Descendente = invertir(Ascendente, []),
    numero(Descendente) - numero(Ascendente).

%%%-------------------------------------------------------------------
%% @doc Formatea un número como cuatro dígitos con ceros a la izquierda.
%% @end
%%%-------------------------------------------------------------------
-spec formatear(integer()) -> string().
formatear(Numero) ->
    validar(Numero),
    [Digito + $0 || Digito <- digitos(Numero)].

%%%-------------------------------------------------------------------
%% @doc Imprime las secuencias de 1234, 5678 y 9981.
%% @end
%%%-------------------------------------------------------------------
-spec demo() -> ok.
demo() ->
    lists:foreach(
      fun(Numero) ->
              io:format("~s~n",
                        [lists:flatten(
                           lists:join(" -> ",
                                      [formatear(N) || N <- secuencia(Numero)]))])
      end,
      [1234, 5678, 9981]),
    ok.

%%%-------------------------------------------------------------------
%% Auxiliares
%%%-------------------------------------------------------------------

validar(Numero) when is_integer(Numero), Numero >= 0, Numero =< 9999 ->
    ok;
validar(Numero) ->
    erlang:error({numero_invalido, Numero}).

%% Cuatro dígitos, con ceros a la izquierda incluidos.
digitos(Numero) ->
    [Numero div 1000,
     (Numero div 100) rem 10,
     (Numero div 10) rem 10,
     Numero rem 10].

numero(Digitos) ->
    numero(Digitos, 0).

numero([], Acc) ->
    Acc;
numero([Digito | Resto], Acc) ->
    numero(Resto, Acc * 10 + Digito).

%% Orden ascendente por inserción.
ordenar([]) ->
    [];
ordenar([Digito | Resto]) ->
    insertar_ordenado(Digito, ordenar(Resto)).

insertar_ordenado(Digito, []) ->
    [Digito];
insertar_ordenado(Digito, [Otro | Resto]) when Digito =< Otro ->
    [Digito, Otro | Resto];
insertar_ordenado(Digito, [Otro | Resto]) ->
    [Otro | insertar_ordenado(Digito, Resto)].

invertir([], Acc) ->
    Acc;
invertir([Cabeza | Resto], Acc) ->
    invertir(Resto, [Cabeza | Acc]).

contar(Lista) ->
    contar(Lista, 0).

contar([], Acc) ->
    Acc;
contar([_ | Resto], Acc) ->
    contar(Resto, Acc + 1).
