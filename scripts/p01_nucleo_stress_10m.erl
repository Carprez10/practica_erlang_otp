%%%-------------------------------------------------------------------
%% @doc Prueba de estrés de `p01_nucleo` con 10,000,000 de elementos.
%%
%% Se ejecuta fuera de EUnit, en un proceso de Erlang independiente:
%%
%%   erlc -o /tmp/opencode/p01_stress scripts/p01_nucleo_stress_10m.erl
%%   erl -noshell -pa _build/default/lib/practica_erlang_otp/ebin \
%%       -pa /tmp/opencode/p01_stress \
%%       -eval 'p01_nucleo_stress_10m:run().'
%%
%% Para `filtrar` y `mapear` no se conservan simultáneamente los
%% resultados de `p01_nucleo` y de `lists`. Cada resultado se verifica
%% contra la entrada, se resume en longitud + hash y se libera antes de
%% calcular el siguiente.
%% @end
%%%-------------------------------------------------------------------

-module(p01_nucleo_stress_10m).

-export([run/0]).

-define(N, 10000000).
-define(REPS, 5).
-define(TIMEOUT, 300000).

run() ->
    Parent = self(),
    {Pid, Ref} = spawn_monitor(fun() -> stress(Parent) end),
    receive
        {Pid, Resultados} ->
            imprimir(Resultados),
            halt(0);
        {'DOWN', Ref, process, Pid, Razon} ->
            io:format("ERROR: el proceso de estres termino: ~p~n", [Razon]),
            halt(1)
    after ?TIMEOUT ->
        exit(Pid, kill),
        io:format("ERROR: timeout de ~w ms~n", [?TIMEOUT]),
        halt(1)
    end.

stress(Parent) ->
    Datos = lists:seq(1, ?N),
    Predicado = fun(X) -> X rem 2 =:= 0 end,
    Duplicar = fun(X) -> X * 2 end,
    Sumar = fun(X, Acc) -> X + Acc end,
    Resultados =
        [bench_escalar(suma,
                       fun() -> p01_nucleo:suma(Datos) end,
                       fun() -> lists:sum(Datos) end),
         bench_escalar(maximo,
                       fun() -> p01_nucleo:maximo(Datos) end,
                       fun() -> lists:max(Datos) end),
         bench_lista(filtrar,
                     Datos,
                     fun() -> p01_nucleo:filtrar(Predicado, Datos) end,
                     fun() -> lists:filter(Predicado, Datos) end,
                     fun(Resultado, Entrada) ->
                         verificar_filtro(Resultado, Entrada)
                     end),
         bench_lista(mapear,
                     Datos,
                     fun() -> p01_nucleo:mapear(Duplicar, Datos) end,
                     fun() -> lists:map(Duplicar, Datos) end,
                     fun(Resultado, Entrada) ->
                         verificar_mapa(Resultado, Entrada)
                     end),
         bench_escalar(reducir,
                       fun() -> p01_nucleo:reducir(Sumar, 0, Datos) end,
                       fun() -> lists:foldl(Sumar, 0, Datos) end)],
    Parent ! {self(), Resultados}.

%% Funciones con resultado escalar: la comparación directa no conserva
%% listas grandes.
bench_escalar(Nombre, FunP01, FunLists) ->
    ResultadoP01 = FunP01(),
    ResultadoLists = FunLists(),
    case ResultadoP01 =:= ResultadoLists of
        true ->
            ok;
        false ->
            error({resultado_distinto, Nombre, ResultadoP01, ResultadoLists})
    end,
    TiemposP01 = medir_repeticiones(FunP01, ?REPS),
    TiemposLists = medir_repeticiones(FunLists, ?REPS),
    {Nombre, mediana(TiemposP01), mediana(TiemposLists), ResultadoP01}.

%% Funciones con resultado de lista: se verifica y resume un resultado,
%% se libera, y solo después se calcula el otro.
bench_lista(Nombre, Datos, FunP01, FunLists, Verificador) ->
    ResumenP01 = ejecutar_y_resumir(FunP01, Datos, Verificador),
    erlang:garbage_collect(),
    ResumenLists = ejecutar_y_resumir(FunLists, Datos, Verificador),
    erlang:garbage_collect(),
    case ResumenP01 =:= ResumenLists of
        true ->
            ok;
        false ->
            error({resumen_distinto, Nombre, ResumenP01, ResumenLists})
    end,
    TiemposP01 = medir_repeticiones(FunP01, ?REPS),
    erlang:garbage_collect(),
    TiemposLists = medir_repeticiones(FunLists, ?REPS),
    erlang:garbage_collect(),
    {Nombre, mediana(TiemposP01), mediana(TiemposLists), ResumenP01}.

ejecutar_y_resumir(Fun, Datos, Verificador) ->
    Resultado = Fun(),
    ok = Verificador(Resultado, Datos),
    {length(Resultado), erlang:phash2(Resultado)}.

%% Verificación exacta de filtrar sin construir una lista esperada.
%% El resultado debe contener exactamente los elementos pares de la
%% entrada, en el mismo orden.
verificar_filtro([], []) ->
    ok;
verificar_filtro(Resultado, [X | Resto]) ->
    case X rem 2 of
        0 ->
            case Resultado of
                [X | RestoResultado] ->
                    verificar_filtro(RestoResultado, Resto);
                _ ->
                    error({filtro_incorrecto, X})
            end;
        1 ->
            verificar_filtro(Resultado, Resto)
    end;
verificar_filtro(_, _) ->
    error(filtro_longitud_incorrecta).

%% Verificación exacta de mapear sin construir una lista esperada.
%% Cada elemento del resultado debe ser el doble del elemento de entrada.
verificar_mapa([], []) ->
    ok;
verificar_mapa([Y | RestoResultado], [X | RestoDatos]) when Y =:= X * 2 ->
    verificar_mapa(RestoResultado, RestoDatos);
verificar_mapa(_, _) ->
    error(mapa_incorrecto).

medir_repeticiones(Fun, Reps) ->
    medir_repeticiones(Fun, Reps, []).

medir_repeticiones(_Fun, 0, Tiempos) ->
    Tiempos;
medir_repeticiones(Fun, Reps, Tiempos) ->
    erlang:garbage_collect(),
    {Tiempo, _Resultado} = timer:tc(Fun),
    medir_repeticiones(Fun, Reps - 1, [Tiempo | Tiempos]).

%% Con ?REPS = 5, la mediana es el tercer elemento al ordenar.
mediana(Tiempos) ->
    [_Primero, _Segundo, Mediana, _Cuarto, _Quinto] = lists:sort(Tiempos),
    Mediana.

imprimir(Resultados) ->
    io:format("~nN = ~w~n", [?N]),
    io:format("Mediana de ~w repeticiones; tiempos en microsegundos.~n", [?REPS]),
    io:format("~-12s | ~12s | ~12s | ~10s | ~-24s~n",
              ["Operacion", "p01 (us)", "lists (us)", "p01/lists", "Resumen"]),
    lists:foreach(fun imprimir_fila/1, Resultados),
    ok.

imprimir_fila({Nombre, TiempoP01, TiempoLists, Resumen}) ->
    io:format("~-12s | ~12w | ~12w | ~10s | ~p~n",
              [Nombre, TiempoP01, TiempoLists,
               razon(TiempoP01, TiempoLists), Resumen]).

razon(_TiempoP01, 0) ->
    "n/a";
razon(TiempoP01, TiempoLists) ->
    lists:flatten(io_lib:format("~.2f", [TiempoP01 / TiempoLists])).
