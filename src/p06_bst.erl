%%%-------------------------------------------------------------------
%% @doc Árbol binario de búsqueda (BST) con inserción, búsqueda y
%% eliminación.
%%
%% Representación: `nil` para el árbol vacío y `{Valor, Izq, Der}` para
%% un nodo. La inserción ignora los valores repetidos y la eliminación
%% de un valor ausente devuelve el árbol sin cambios.
%%
%% La altura de un árbol vacío es 0 y la de una hoja es 1.
%% @end
%%%-------------------------------------------------------------------

-module(p06_bst).

-export([vacio/0, insertar/2, buscar/2, eliminar/2, altura/1,
         inorden/1, desde_lista/1, estados/0, barajar/1, demo/0]).

-export_type([arbol/0]).

-type arbol() :: nil | {term(), arbol(), arbol()}.

%%%-------------------------------------------------------------------
%% @doc Árbol vacío.
%% @end
%%%-------------------------------------------------------------------
-spec vacio() -> arbol().
vacio() ->
    nil.

%%%-------------------------------------------------------------------
%% @doc Inserta un valor. Si ya existe, no se duplica.
%% @end
%%%-------------------------------------------------------------------
-spec insertar(term(), arbol()) -> arbol().
insertar(Valor, nil) ->
    {Valor, nil, nil};
insertar(Valor, {Valor, _Izq, _Der} = Arbol) ->
    Arbol;
insertar(Valor, {Raiz, Izq, Der}) when Valor < Raiz ->
    {Raiz, insertar(Valor, Izq), Der};
insertar(Valor, {Raiz, Izq, Der}) ->
    {Raiz, Izq, insertar(Valor, Der)}.

%%%-------------------------------------------------------------------
%% @doc Busca un valor en el árbol.
%% @end
%%%-------------------------------------------------------------------
-spec buscar(term(), arbol()) -> boolean().
buscar(_Valor, nil) ->
    false;
buscar(Valor, {Valor, _Izq, _Der}) ->
    true;
buscar(Valor, {Raiz, Izq, _Der}) when Valor < Raiz ->
    buscar(Valor, Izq);
buscar(Valor, {_Raiz, _Izq, Der}) ->
    buscar(Valor, Der).

%%%-------------------------------------------------------------------
%% @doc Elimina un valor. Si no existe, devuelve el mismo árbol.
%%
%% Nodo con dos hijos: se sustituye por el mínimo del subárbol derecho.
%% @end
%%%-------------------------------------------------------------------
-spec eliminar(term(), arbol()) -> arbol().
eliminar(_Valor, nil) ->
    nil;
eliminar(Valor, {Valor, nil, nil}) ->
    nil;
eliminar(Valor, {Valor, nil, Der}) ->
    Der;
eliminar(Valor, {Valor, Izq, nil}) ->
    Izq;
eliminar(Valor, {Valor, Izq, Der}) ->
    {Minimo, Der2} = extraer_minimo(Der),
    {Minimo, Izq, Der2};
eliminar(Valor, {Raiz, Izq, Der}) when Valor < Raiz ->
    {Raiz, eliminar(Valor, Izq), Der};
eliminar(Valor, {Raiz, Izq, Der}) ->
    {Raiz, Izq, eliminar(Valor, Der)}.

%% Devuelve el mínimo del subárbol y el subárbol sin ese mínimo.
extraer_minimo({Valor, nil, Der}) ->
    {Valor, Der};
extraer_minimo({Valor, Izq, Der}) ->
    {Minimo, Izq2} = extraer_minimo(Izq),
    {Minimo, {Valor, Izq2, Der}}.

%%%-------------------------------------------------------------------
%% @doc Altura del árbol: 0 si está vacío, 1 para una hoja.
%% @end
%%%-------------------------------------------------------------------
-spec altura(arbol()) -> non_neg_integer().
altura(nil) ->
    0;
altura({_Valor, Izq, Der}) ->
    1 + max(altura(Izq), altura(Der)).

%%%-------------------------------------------------------------------
%% @doc Recorrido inorden (ascendente en un BST).
%% @end
%%%-------------------------------------------------------------------
-spec inorden(arbol()) -> [term()].
inorden(Arbol) ->
    inorden(Arbol, []).

inorden(nil, Acc) ->
    Acc;
inorden({Valor, Izq, Der}, Acc) ->
    inorden(Izq, [Valor | inorden(Der, Acc)]).

%%%-------------------------------------------------------------------
%% @doc Construye un árbol insertando los elementos de una lista.
%% @end
%%%-------------------------------------------------------------------
-spec desde_lista([term()]) -> arbol().
desde_lista(Lista) ->
    desde_lista(Lista, nil).

desde_lista([], Arbol) ->
    Arbol;
desde_lista([Valor | Resto], Arbol) ->
    desde_lista(Resto, insertar(Valor, Arbol)).

%%%-------------------------------------------------------------------
%% @doc Los 32 estados de México en orden alfabético.
%% @end
%%%-------------------------------------------------------------------
-spec estados() -> [string()].
estados() ->
    ["Aguascalientes",
     "Baja California",
     "Baja California Sur",
     "Campeche",
     "Chiapas",
     "Chihuahua",
     "Ciudad de México",
     "Coahuila",
     "Colima",
     "Durango",
     "Estado de México",
     "Guanajuato",
     "Guerrero",
     "Hidalgo",
     "Jalisco",
     "Michoacán",
     "Morelos",
     "Nayarit",
     "Nuevo León",
     "Oaxaca",
     "Puebla",
     "Querétaro",
     "Quintana Roo",
     "San Luis Potosí",
     "Sinaloa",
     "Sonora",
     "Tabasco",
     "Tamaulipas",
     "Tlaxcala",
     "Veracruz",
     "Yucatán",
     "Zacatecas"].

%%%-------------------------------------------------------------------
%% @doc Orden aleatorio de una lista (para el experimento del demo).
%%
%% Usa `rand`, así que conviene fijar la semilla antes de llamarla si
%% se requiere reproducibilidad.
%% @end
%%%-------------------------------------------------------------------
-spec barajar([term()]) -> [term()].
barajar(Lista) ->
    Pares = [{rand:uniform(), Elemento} || Elemento <- Lista],
    [Elemento || {_Clave, Elemento} <- lists:sort(Pares)].

%%%-------------------------------------------------------------------
%% @doc Compara la altura del árbol con los estados en orden
%% alfabético y en orden aleatorio, e imprime el resultado.
%% @end
%%%-------------------------------------------------------------------
-spec demo() -> {non_neg_integer(), non_neg_integer()}.
demo() ->
    rand:seed(exsss, {2026, 10, 30}),
    Estados = estados(),
    Alfabetico = desde_lista(Estados),
    Aleatorio = desde_lista(barajar(Estados)),
    AlturaAlfabetico = altura(Alfabetico),
    AlturaAleatorio = altura(Aleatorio),
    io:format("Estados insertados:          ~w~n", [contar(Estados)]),
    io:format("Altura en orden alfabetico:  ~w~n", [AlturaAlfabetico]),
    io:format("Altura en orden aleatorio:   ~w~n", [AlturaAleatorio]),
    {AlturaAlfabetico, AlturaAleatorio}.

contar(Lista) ->
    contar(Lista, 0).

contar([], Acc) ->
    Acc;
contar([_ | Resto], Acc) ->
    contar(Resto, Acc + 1).
