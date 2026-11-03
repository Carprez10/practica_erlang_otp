%%%-------------------------------------------------------------------
%% @doc Núcleo funcional: operaciones básicas sobre listas.
%%
%% Implementación deliberadamente sin las funciones de la biblioteca
%% estándar para listas, sin operadores de concatenación y sin acceso
%% directo a cabeza o cola. Todo se resuelve con pattern matching,
%% recursión y acumuladores.
%% @end
%%%-------------------------------------------------------------------

-module(p01_nucleo).

-export([suma/1, maximo/1, filtrar/2, mapear/2, reducir/3]).

%%%-------------------------------------------------------------------
%% @doc Suma todos los elementos de una lista.
%%
%% Es una recursión de cola: el acumulador `Acc` guarda la suma parcial
%% y la llamada recursiva es lo último que se evalúa.
%% @end
%%%-------------------------------------------------------------------
-spec suma([number()]) -> number().
suma(Lista) ->
    suma(Lista, 0).

suma([], Acc) ->
    Acc;
suma([Cabeza | Resto], Acc) ->
    suma(Resto, Acc + Cabeza).

%%%-------------------------------------------------------------------
%% @doc Devuelve el máximo de una lista no vacía.
%%
%% Si la lista está vacía se lanza `erlang:error(lista_vacia)`. El
%% acumulador `Max` evita tener que comparar dos veces al volver de la
%% recursión.
%% @end
%%%-------------------------------------------------------------------
-spec maximo([number()]) -> number().
maximo([]) ->
    erlang:error(lista_vacia);
maximo([Cabeza | Resto]) ->
    maximo(Resto, Cabeza).

maximo([], Max) ->
    Max;
maximo([Cabeza | Resto], Max) when Cabeza > Max ->
    maximo(Resto, Cabeza);
maximo([_Cabeza | Resto], Max) ->
    maximo(Resto, Max).

%%%-------------------------------------------------------------------
%% @doc Filtra los elementos para los que `Predicado` devuelve `true`.
%%
%% Se acumulan los elementos aceptados en orden inverso y al final se
%% invierte la lista con `invertir/2`. Así la recursión es de cola y se
%% conserva el orden original.
%% @end
%%%-------------------------------------------------------------------
-spec filtrar(fun((term()) -> boolean()), [term()]) -> [term()].
filtrar(Predicado, Lista) ->
    filtrar(Predicado, Lista, []).

filtrar(_Predicado, [], Acc) ->
    invertir(Acc, []);
filtrar(Predicado, [Cabeza | Resto], Acc) ->
    case Predicado(Cabeza) of
        true ->
            filtrar(Predicado, Resto, [Cabeza | Acc]);
        false ->
            filtrar(Predicado, Resto, Acc)
    end.

%%%-------------------------------------------------------------------
%% @doc Aplica `Funcion` a cada elemento y conserva el orden.
%%
%% Igual que `filtrar/2`, acumula en orden inverso y luego invierte.
%% @end
%%%-------------------------------------------------------------------
-spec mapear(fun((A) -> B), [A]) -> [B].
mapear(Funcion, Lista) ->
    mapear(Funcion, Lista, []).

mapear(_Funcion, [], Acc) ->
    invertir(Acc, []);
mapear(Funcion, [Cabeza | Resto], Acc) ->
    mapear(Funcion, Resto, [Funcion(Cabeza) | Acc]).

%%%-------------------------------------------------------------------
%% @doc Fold izquierdo equivalente a la operación estándar de fold izquierdo.
%%
%% `Funcion(Elemento, Acumulador)` se evalúa de izquierda a derecha:
%%   reducir(F, Acc0, [A, B, C]) = F(C, F(B, F(A, Acc0)))
%%
%% El orden importa cuando la función no es conmutativa; por eso la
%% prueba de `reducir/3` usa una operación no conmutativa.
%% @end
%%%-------------------------------------------------------------------
-spec reducir(fun((Elemento, Acumulador) -> Acumulador), Acumulador, [Elemento]) ->
    Acumulador.
reducir(_Funcion, Acc, []) ->
    Acc;
reducir(Funcion, Acc, [Cabeza | Resto]) ->
    reducir(Funcion, Funcion(Cabeza, Acc), Resto).

%%%-------------------------------------------------------------------
%% Funciones auxiliares
%%%-------------------------------------------------------------------

%% Invierte una lista con recursión de cola, sin la función estándar de inversión.
-spec invertir([term()], [term()]) -> [term()].
invertir([], Acc) ->
    Acc;
invertir([Cabeza | Resto], Acc) ->
    invertir(Resto, [Cabeza | Acc]).
