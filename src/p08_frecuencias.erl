%%%-------------------------------------------------------------------
%% @doc Análisis de frecuencia de letras en un texto.
%%
%% Se normaliza el texto a mayúsculas y se eliminan los diacríticos:
%% á/à/ä/â/ã -> A, é/è/ë/ê -> E, í/ì/ï/î -> I, ó/ò/ö/ô/õ -> O,
%% ú/ù/ü/û -> U, ñ -> N, ç -> C. Se descartan espacios, dígitos,
%% signos de puntuación y cualquier otro símbolo.
%%
%% `frecuencias/1` devuelve solo las letras presentes como
%% `{Letra, Absoluta, Relativa}`, ordenadas de mayor a menor frecuencia
%% absoluta (en empate, alfabéticamente). `frecuencias_alfabeto/1`
%% devuelve las 26 letras, incluidas las de frecuencia cero.
%%
%% Un texto que no sea lista lanza `erlang:error({texto_invalido, X})`.
%% @end
%%%-------------------------------------------------------------------

-module(p08_frecuencias).

-export([normalizar/1, frecuencias/1, frecuencias_alfabeto/1,
         total_letras/1, histograma/1, imprimir/1, demo/0]).

-define(ANCHO_MAXIMO, 40).

-type frecuencia() :: {char(), non_neg_integer(), float()}.

%%%-------------------------------------------------------------------
%% @doc Normaliza el texto a letras mayúsculas A-Z.
%% @end
%%%-------------------------------------------------------------------
-spec normalizar(string()) -> string().
normalizar(Texto) when is_list(Texto) ->
    normalizar(Texto, []);
normalizar(Otro) ->
    erlang:error({texto_invalido, Otro}).

normalizar([], Acc) ->
    invertir(Acc, []);
normalizar([Caracter | Resto], Acc) ->
    case normalizar_caracter(Caracter) of
        ignorar ->
            normalizar(Resto, Acc);
        Letra ->
            normalizar(Resto, [Letra | Acc])
    end.

%%%-------------------------------------------------------------------
%% @doc Frecuencias de las letras presentes, de mayor a menor.
%% @end
%%%-------------------------------------------------------------------
-spec frecuencias(string()) -> [frecuencia()].
frecuencias(Texto) ->
    Letras = normalizar(Texto),
    Total = longitud(Letras),
    Mapa = contar_letras(Letras, #{}),
    Lista = [{Letra, Conteo, relativa(Conteo, Total)}
             || {Letra, Conteo} <- maps:to_list(Mapa)],
    ordenar(Lista).

%%%-------------------------------------------------------------------
%% @doc Frecuencias de las 26 letras A-Z, incluidas las que no aparecen.
%% @end
%%%-------------------------------------------------------------------
-spec frecuencias_alfabeto(string()) -> [frecuencia()].
frecuencias_alfabeto(Texto) ->
    Letras = normalizar(Texto),
    Total = longitud(Letras),
    Mapa = contar_letras(Letras, #{}),
    Lista = [{Letra, maps:get(Letra, Mapa, 0), relativa(maps:get(Letra, Mapa, 0), Total)}
             || Letra <- "ABCDEFGHIJKLMNOPQRSTUVWXYZ"],
    ordenar(Lista).

%%%-------------------------------------------------------------------
%% @doc Total de letras consideradas (sin espacios ni signos).
%% @end
%%%-------------------------------------------------------------------
-spec total_letras(string()) -> non_neg_integer().
total_letras(Texto) ->
    longitud(normalizar(Texto)).

%%%-------------------------------------------------------------------
%% @doc Histograma ASCII horizontal, una línea por letra presente.
%%
%% La barra más larga mide 40 asteriscos; las demás son proporcionales.
%% Un texto sin letras devuelve la cadena vacía.
%% @end
%%%-------------------------------------------------------------------
-spec histograma(string()) -> string().
histograma(Texto) ->
    Filas = frecuencias(Texto),
    case Filas of
        [] ->
            "";
        _ ->
            Maximo = maximo_absoluto(Filas),
            Lineas = [linea_histograma(Fila, Maximo) || Fila <- Filas],
            lists:flatten(lists:join("\n", Lineas))
    end.

%%%-------------------------------------------------------------------
%% @doc Imprime la tabla de frecuencias y el histograma.
%% @end
%%%-------------------------------------------------------------------
-spec imprimir(string()) -> ok.
imprimir(Texto) ->
    io:format("Letra  Absoluta  Relativa~n"),
    lists:foreach(fun imprimir_fila/1, frecuencias(Texto)),
    io:format("~n"),
    io:format("~s~n", [histograma(Texto)]),
    ok.

%%%-------------------------------------------------------------------
%% @doc Ejemplo con acentos, mayúsculas, dígitos y puntuación.
%% @end
%%%-------------------------------------------------------------------
-spec demo() -> ok.
demo() ->
    Texto = "¡Hola, mundo! El pingüino añil come 3 piñas y sueña con México; ¿qué tal?",
    io:format("Texto: ~ts~n~n", [Texto]),
    imprimir(Texto).

%%%-------------------------------------------------------------------
%% Normalización de caracteres
%%%-------------------------------------------------------------------

normalizar_caracter(Caracter) when Caracter >= $a, Caracter =< $z ->
    Caracter - 32;
normalizar_caracter(Caracter) when Caracter >= $A, Caracter =< $Z ->
    Caracter;
%% Vocales acentuadas: A
normalizar_caracter(Caracter)
  when Caracter =:= 16#E1; Caracter =:= 16#E0; Caracter =:= 16#E4;
       Caracter =:= 16#E2; Caracter =:= 16#E3;
       Caracter =:= 16#C1; Caracter =:= 16#C0; Caracter =:= 16#C4;
       Caracter =:= 16#C2; Caracter =:= 16#C3 ->
    $A;
%% Vocales acentuadas: E
normalizar_caracter(Caracter)
  when Caracter =:= 16#E9; Caracter =:= 16#E8; Caracter =:= 16#EB;
       Caracter =:= 16#EA;
       Caracter =:= 16#C9; Caracter =:= 16#C8; Caracter =:= 16#CB;
       Caracter =:= 16#CA ->
    $E;
%% Vocales acentuadas: I
normalizar_caracter(Caracter)
  when Caracter =:= 16#ED; Caracter =:= 16#EC; Caracter =:= 16#EF;
       Caracter =:= 16#EE;
       Caracter =:= 16#CD; Caracter =:= 16#CC; Caracter =:= 16#CF;
       Caracter =:= 16#CE ->
    $I;
%% Vocales acentuadas: O
normalizar_caracter(Caracter)
  when Caracter =:= 16#F3; Caracter =:= 16#F2; Caracter =:= 16#F6;
       Caracter =:= 16#F4; Caracter =:= 16#F5;
       Caracter =:= 16#D3; Caracter =:= 16#D2; Caracter =:= 16#D6;
       Caracter =:= 16#D4; Caracter =:= 16#D5 ->
    $O;
%% Vocales acentuadas: U (incluye diéresis)
normalizar_caracter(Caracter)
  when Caracter =:= 16#FA; Caracter =:= 16#F9; Caracter =:= 16#FC;
       Caracter =:= 16#FB;
       Caracter =:= 16#DA; Caracter =:= 16#D9; Caracter =:= 16#DC;
       Caracter =:= 16#DB ->
    $U;
%% Ñ y Ç
normalizar_caracter(Caracter) when Caracter =:= 16#F1; Caracter =:= 16#D1 ->
    $N;
normalizar_caracter(Caracter) when Caracter =:= 16#E7; Caracter =:= 16#C7 ->
    $C;
normalizar_caracter(_Otro) ->
    ignorar.

%%%-------------------------------------------------------------------
%% Conteo y orden
%%%-------------------------------------------------------------------

contar_letras([], Mapa) ->
    Mapa;
contar_letras([Letra | Resto], Mapa) ->
    contar_letras(Resto, maps:update_with(Letra, fun(N) -> N + 1 end, 1, Mapa)).

relativa(_Conteo, 0) ->
    0.0;
relativa(Conteo, Total) ->
    Conteo / Total.

%% Orden: absoluta descendente y, en empate, letra ascendente.
ordenar(Lista) ->
    lists:sort(
      fun({L1, A1, _}, {L2, A2, _}) ->
              case A1 =:= A2 of
                  true -> L1 < L2;
                  false -> A1 > A2
              end
      end,
      Lista).

maximo_absoluto([{_L, Abs, _} | Resto]) ->
    maximo_absoluto(Resto, Abs).

maximo_absoluto([], Maximo) ->
    Maximo;
maximo_absoluto([{_L, Abs, _} | Resto], Maximo) ->
    maximo_absoluto(Resto, max(Abs, Maximo)).

%%%-------------------------------------------------------------------
%% Histograma
%%%-------------------------------------------------------------------

linea_histograma({Letra, Absoluta, Relativa}, Maximo) ->
    Ancho = ancho_barra(Absoluta, Maximo),
    lists:flatten(
      io_lib:format("~c | ~s ~w (~.2f%)",
                    [Letra, estrellas(Ancho), Absoluta, Relativa * 100])).

ancho_barra(_Absoluta, 0) ->
    0;
ancho_barra(Absoluta, Maximo) ->
    max(1, round(Absoluta * ?ANCHO_MAXIMO / Maximo)).

estrellas(0) ->
    [];
estrellas(N) ->
    [$* | estrellas(N - 1)].

imprimir_fila({Letra, Absoluta, Relativa}) ->
    io:format("~c      ~4w    ~6.2f%~n", [Letra, Absoluta, Relativa * 100]).

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
