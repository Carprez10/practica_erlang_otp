%%%-------------------------------------------------------------------
%% @doc Pila sobre listas de Erlang y verificación de delimitadores.
%%
%% La pila es simplemente una lista: la cabeza es el tope.
%%
%% Contrato para la pila vacía (no se lanzan excepciones):
%%   pop([])  -> {error, pila_vacia}
%%   peek([]) -> {error, pila_vacia}
%%
%% Operaciones con elementos:
%%   push(X, Pila)     -> [X | Pila]
%%   pop([X | Resto])  -> {ok, X, Resto}
%%   peek([X | _])     -> {ok, X}
%% @end
%%%-------------------------------------------------------------------

-module(p04_pila).

-export([push/2, pop/1, peek/1, is_empty/1, balanceada/1]).

%%%-------------------------------------------------------------------
%% @doc Apila un elemento en el tope.
%% @end
%%%-------------------------------------------------------------------
-spec push(term(), [term()]) -> [term()].
push(Elemento, Pila) ->
    [Elemento | Pila].

%%%-------------------------------------------------------------------
%% @doc Desapila el tope.
%%
%% Devuelve `{ok, Elemento, PilaRestante}` o `{error, pila_vacia}`.
%% @end
%%%-------------------------------------------------------------------
-spec pop([term()]) -> {ok, term(), [term()]} | {error, pila_vacia}.
pop([Elemento | Resto]) ->
    {ok, Elemento, Resto};
pop([]) ->
    {error, pila_vacia}.

%%%-------------------------------------------------------------------
%% @doc Consulta el tope sin desapilarlo.
%%
%% Devuelve `{ok, Elemento}` o `{error, pila_vacia}`.
%% @end
%%%-------------------------------------------------------------------
-spec peek([term()]) -> {ok, term()} | {error, pila_vacia}.
peek([Elemento | _]) ->
    {ok, Elemento};
peek([]) ->
    {error, pila_vacia}.

%%%-------------------------------------------------------------------
%% @doc Indica si la pila está vacía.
%% @end
%%%-------------------------------------------------------------------
-spec is_empty([term()]) -> boolean().
is_empty([]) ->
    true;
is_empty([_ | _]) ->
    false.

%%%-------------------------------------------------------------------
%% @doc Indica si los delimitadores `()`, `[]` y `{}` están balanceados.
%%
%% Los caracteres que no son delimitadores se ignoran, así que puede
%% recibir una expresión completa. Una cadena vacía se considera
%% balanceada. Los cierres sin apertura o con apertura distinta, y las
%% aperturas sin cerrar, producen `false`.
%% @end
%%%-------------------------------------------------------------------
-spec balanceada(string()) -> boolean().
balanceada(Cadena) when is_list(Cadena) ->
    balanceada(Cadena, []);
balanceada(Otro) ->
    erlang:error({expresion_invalida, Otro}).

balanceada([], Pila) ->
    is_empty(Pila);
balanceada([Apertura | Resto], Pila)
  when Apertura =:= $(; Apertura =:= $[; Apertura =:= ${ ->
    balanceada(Resto, push(Apertura, Pila));
balanceada([Cierre | Resto], Pila)
  when Cierre =:= $); Cierre =:= $]; Cierre =:= $} ->
    case peek(Pila) of
        {ok, Apertura} ->
            case pareja(Apertura, Cierre) of
                true ->
                    {ok, _Apertura, PilaRestante} = pop(Pila),
                    balanceada(Resto, PilaRestante);
                false ->
                    false
            end;
        {error, pila_vacia} ->
            false
    end;
balanceada([_Otro | Resto], Pila) ->
    balanceada(Resto, Pila).

%% Un cierre solo es válido si corresponde a la apertura del tope.
pareja($(, $)) -> true;
pareja($[, $]) -> true;
pareja(${, $}) -> true;
pareja(_, _) -> false.
