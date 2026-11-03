%%%-------------------------------------------------------------------
%% @doc Máximo común divisor por el algoritmo de Euclides.
%%
%% Contrato:
%%   - Acepta enteros no negativos.
%%   - mcd(A, 0) = A y mcd(0, B) = B.
%%   - mcd(0, 0) = 0.
%%   - Cualquier entrada negativa o no entera lanza
%%     `erlang:error({entrada_invalida, A, B})`.
%%
%% La implementación usa pattern matching y recursión de cola:
%%   mcd(A, B) = mcd(B, A rem B)
%% @end
%%%-------------------------------------------------------------------

-module(p02_mcd).

-export([mcd/2]).

-spec mcd(integer(), integer()) -> non_neg_integer().
mcd(A, B) when is_integer(A), A >= 0, is_integer(B), B >= 0 ->
    euclides(A, B);
mcd(A, B) ->
    erlang:error({entrada_invalida, A, B}).

%% Caso base: cuando el segundo argumento llega a cero, el primero es el MCD.
euclides(A, 0) ->
    A;
euclides(A, B) ->
    euclides(B, A rem B).
