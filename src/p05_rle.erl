%%%-------------------------------------------------------------------
%% @doc Compresión RLE (Run-Length Encoding).
%%
%% Formato: `<conteo><carácter>` con el conteo en decimal, mayor o
%% igual a 1 y sin ceros a la izquierda. Ejemplo:
%%
%%   "AAAAABBBCC"  ->  "5A3B2C"
%%
%% Para que el formato no sea ambiguo, el texto a comprimir no puede
%% contener dígitos: un dígito se confundiría con un conteo. En tal
%% caso se lanza `erlang:error({caracter_invalido, Caracter})`.
%%
%% Al descomprimir, una cadena mal formada lanza
%% `erlang:error({formato_invalido, Resto})`. Un argumento que no sea
%% lista lanza `erlang:error({entrada_invalida, Valor})`.
%%
%% El porcentaje de compresión es
%%   (longitud_original - longitud_comprimida) * 100 / longitud_original
%% y vale 0.0 para la cadena vacía. Un valor negativo indica que el
%% texto "comprimido" es más largo que el original.
%% @end
%%%-------------------------------------------------------------------

-module(p05_rle).

-export([comprimir/1, descomprimir/1, porcentaje_compresion/1]).

%%%-------------------------------------------------------------------
%% @doc Comprime una cadena con RLE.
%% @end
%%%-------------------------------------------------------------------
-spec comprimir(string()) -> string().
comprimir(Cadena) when is_list(Cadena) ->
    comprimir(Cadena, []);
comprimir(Otro) ->
    erlang:error({entrada_invalida, Otro}).

comprimir([], Acc) ->
    invertir(Acc, []);
comprimir([Caracter | Resto], Acc) ->
    validar_caracter(Caracter),
    {Conteo, Resto2} = contar(Caracter, Resto, 1),
    comprimir(Resto2, agregar(fragmento(Conteo, Caracter), Acc)).

%% Añade los caracteres de un fragmento al acumulador invertido.
agregar([Caracter | Resto], Acc) ->
    agregar(Resto, [Caracter | Acc]);
agregar([], Acc) ->
    Acc.

%% Cuenta cuántas veces se repite `Caracter` al inicio de la lista.
contar(Caracter, [Caracter | Resto], Conteo) ->
    contar(Caracter, Resto, Conteo + 1);
contar(_Caracter, Resto, Conteo) ->
    {Conteo, Resto}.

%% Fragmento "NC": dígitos del conteo en orden normal y luego el carácter.
fragmento(Conteo, Caracter) ->
    invertir([Caracter | digitos_reversos(Conteo)], []).

digitos_reversos(0) ->
    [];
digitos_reversos(N) ->
    [N rem 10 + $0 | digitos_reversos(N div 10)].

%% Los dígitos no se permiten en la entrada porque romperían el formato.
validar_caracter(Caracter) when Caracter >= $0, Caracter =< $9 ->
    erlang:error({caracter_invalido, Caracter});
validar_caracter(_Caracter) ->
    ok.

%%%-------------------------------------------------------------------
%% @doc Descomprime una cadena en formato RLE.
%% @end
%%%-------------------------------------------------------------------
-spec descomprimir(string()) -> string().
descomprimir(Cadena) when is_list(Cadena) ->
    descomprimir(Cadena, []);
descomprimir(Otro) ->
    erlang:error({entrada_invalida, Otro}).

descomprimir([], Acc) ->
    invertir(Acc, []);
descomprimir(Cadena, Acc) ->
    {Conteo, Caracter, Resto} = leer_fragmento(Cadena),
    descomprimir(Resto, repetir(Caracter, Conteo, Acc)).

%% Lee "<conteo><carácter>" del inicio y devuelve el resto.
leer_fragmento([Digito | _] = Cadena) when Digito >= $0, Digito =< $9 ->
    {Digitos, Resto} = tomar_digitos(Cadena, []),
    case Resto of
        [Caracter | Resto2] when Caracter < $0; Caracter > $9 ->
            Conteo = valor(Digitos, 0),
            case Conteo >= 1 andalso sin_cero_inicial(Digitos) of
                true ->
                    {Conteo, Caracter, Resto2};
                false ->
                    erlang:error({formato_invalido, Cadena})
            end;
        _ ->
            erlang:error({formato_invalido, Cadena})
    end;
leer_fragmento(Cadena) ->
    erlang:error({formato_invalido, Cadena}).

%% Un conteo canónico no lleva ceros a la izquierda ("05A" es inválido).
sin_cero_inicial([$0 | _]) ->
    false;
sin_cero_inicial(_) ->
    true.

tomar_digitos([Digito | Resto], Acc) when Digito >= $0, Digito =< $9 ->
    tomar_digitos(Resto, [Digito | Acc]);
tomar_digitos(Resto, Acc) ->
    {invertir(Acc, []), Resto}.

valor([], Acc) ->
    Acc;
valor([Digito | Resto], Acc) ->
    valor(Resto, Acc * 10 + (Digito - $0)).

repetir(_Caracter, 0, Acc) ->
    Acc;
repetir(Caracter, Conteo, Acc) ->
    repetir(Caracter, Conteo - 1, [Caracter | Acc]).

%%%-------------------------------------------------------------------
%% @doc Porcentaje de compresión obtenido sobre la cadena original.
%%
%% La cadena vacía devuelve 0.0.
%% @end
%%%-------------------------------------------------------------------
-spec porcentaje_compresion(string()) -> float().
porcentaje_compresion([]) ->
    0.0;
porcentaje_compresion(Cadena) when is_list(Cadena) ->
    Original = longitud(Cadena),
    Comprimido = longitud(comprimir(Cadena)),
    (Original - Comprimido) * 100 / Original;
porcentaje_compresion(Otro) ->
    erlang:error({entrada_invalida, Otro}).

%%%-------------------------------------------------------------------
%% Auxiliares
%%%-------------------------------------------------------------------

longitud(Lista) ->
    longitud(Lista, 0).

longitud([], Acc) ->
    Acc;
longitud([_ | Resto], Acc) ->
    longitud(Resto, Acc + 1).

invertir([], Acc) ->
    Acc;
invertir([Cabeza | Resto], Acc) ->
    invertir(Resto, [Cabeza | Acc]).
