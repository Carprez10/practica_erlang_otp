%%%-------------------------------------------------------------------
%% @doc Triángulo de Pascal.
%%
%% La fila 1 es `[1]`. Cada fila siguiente se obtiene sumando los
%% vecinos de la fila anterior y añadiendo un 1 en cada extremo.
%%
%% Todo se resuelve con pattern matching, recursión y acumuladores,
%% sin usar la biblioteca `lists`.
%% @end
%%%-------------------------------------------------------------------

-module(p03_pascal).

-export([filas/1, fila/1, siguiente_fila/1, imprimir/0, imprimir/1]).

-define(FILAS_POR_DEFECTO, 15).

%%%-------------------------------------------------------------------
%% @doc Devuelve las primeras `N` filas, en orden.
%%
%% `filas(3)` devuelve `[[1], [1,1], [1,2,1]]`.
%% @end
%%%-------------------------------------------------------------------
-spec filas(pos_integer()) -> [[pos_integer()]].
filas(N) when is_integer(N), N >= 1 ->
    generar(N, [[1]]);
filas(N) ->
    erlang:error({numero_de_filas_invalido, N}).

generar(1, Acc) ->
    invertir(Acc, []);
generar(N, [Ultima | _] = Acc) ->
    generar(N - 1, [siguiente_fila(Ultima) | Acc]).

%%%-------------------------------------------------------------------
%% @doc Devuelve la fila `N` (la fila 1 es `[1]`).
%% @end
%%%-------------------------------------------------------------------
-spec fila(pos_integer()) -> [pos_integer()].
fila(N) when is_integer(N), N >= 1 ->
    fila(N, [1]);
fila(N) ->
    erlang:error({numero_de_filas_invalido, N}).

fila(1, Fila) ->
    Fila;
fila(N, Fila) ->
    fila(N - 1, siguiente_fila(Fila)).

%%%-------------------------------------------------------------------
%% @doc Calcula la fila siguiente a partir de una fila no vacía.
%%
%% `siguiente_fila([1,3,3,1])` devuelve `[1,4,6,4,1]`.
%% @end
%%%-------------------------------------------------------------------
-spec siguiente_fila([integer()]) -> [integer()].
siguiente_fila([_ | _] = Fila) ->
    [1 | sumas_adyacentes(Fila, [])];
siguiente_fila(Fila) ->
    erlang:error({fila_invalida, Fila}).

%% Suma cada par de vecinos y termina con el 1 del extremo derecho.
%% El acumulador queda en orden inverso y se voltea al final.
sumas_adyacentes([A, B | Resto], Acc) ->
    sumas_adyacentes([B | Resto], [A + B | Acc]);
sumas_adyacentes([_Ultimo], Acc) ->
    invertir([1 | Acc], []).

%%%-------------------------------------------------------------------
%% @doc Imprime las primeras 15 filas centradas.
%% @end
%%%-------------------------------------------------------------------
-spec imprimir() -> ok.
imprimir() ->
    imprimir(?FILAS_POR_DEFECTO).

%%%-------------------------------------------------------------------
%% @doc Imprime las primeras `N` filas centradas.
%% @end
%%%-------------------------------------------------------------------
-spec imprimir(pos_integer()) -> ok.
imprimir(N) when is_integer(N), N >= 1 ->
    Ancho = ancho_celda(fila(N)),
    imprimir_filas(filas(N), N, Ancho);
imprimir(N) ->
    erlang:error({numero_de_filas_invalido, N}).

imprimir_filas([], _N, _Ancho) ->
    ok;
imprimir_filas([Fila | Resto], N, Ancho) ->
    Sangria = (Ancho * (N - longitud(Fila))) div 2,
    io:format("~s", [espacios(Sangria)]),
    imprimir_celdas(Fila, Ancho),
    io:format("~n", []),
    imprimir_filas(Resto, N, Ancho).

imprimir_celdas([], _Ancho) ->
    ok;
imprimir_celdas([Valor | Resto], Ancho) ->
    io:format("~*w", [Ancho, Valor]),
    imprimir_celdas(Resto, Ancho).

%% Ancho uniforme por celda: dígitos del mayor valor más un espacio.
ancho_celda(Fila) ->
    digitos(maximo_fila(Fila)) + 1.

maximo_fila([X]) ->
    X;
maximo_fila([X | Resto]) ->
    max(X, maximo_fila(Resto)).

digitos(N) when N < 10 ->
    1;
digitos(N) ->
    1 + digitos(N div 10).

longitud(Lista) ->
    longitud(Lista, 0).

longitud([], Acc) ->
    Acc;
longitud([_ | Resto], Acc) ->
    longitud(Resto, Acc + 1).

espacios(0) ->
    [];
espacios(N) ->
    [$\s | espacios(N - 1)].

invertir([], Acc) ->
    Acc;
invertir([Cabeza | Resto], Acc) ->
    invertir(Resto, [Cabeza | Acc]).
