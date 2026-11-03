%%%-------------------------------------------------------------------
%% @doc Benchmark reproducible de `p01_nucleo` contra `lists`.
%%
%% Este módulo es de pruebas/medición: aquí sí se permite usar `lists`.
%% La implementación `p01_nucleo.erl` permanece sin llamadas a `lists`.
%%
%% Cada operación se mide con `timer:tc/1`. Se hacen cinco repeticiones
%% y se reporta la mediana en microsegundos. Antes de medir se comprueba
%% que ambas implementaciones devuelvan el mismo resultado.
%%
%% No se ejecuta la prueba de diez millones de elementos.
%% @end
%%%-------------------------------------------------------------------

-module(p01_nucleo_bench_tests).

-export([run/0]).

-include_lib("eunit/include/eunit.hrl").

-define(REPS, 5).
-define(TIMEOUT, 180).
-define(SIZES, [1000, 10000, 100000, 1000000]).

benchmark_test_() ->
    {timeout, ?TIMEOUT, fun run/0}.

run() ->
    benchmark().

benchmark() ->
    code:ensure_loaded(p01_nucleo),
    io:format("~nBenchmark p01_nucleo vs lists~n"),
    io:format("Mediana de ~w repeticiones; tiempos en microsegundos.~n", [?REPS]),
    io:format("Se ejecuta garbage_collect antes de cada medicion.~n", []),
    lists:foreach(fun bench_size/1, ?SIZES),
    ok.

bench_size(N) ->
    Datos = lists:seq(1, N),
    Predicado = fun(X) -> X rem 2 =:= 0 end,
    Duplicar = fun(X) -> X * 2 end,
    Sumar = fun(X, Acc) -> X + Acc end,
    io:format("~nN = ~w~n", [N]),
    io:format("~-12s | ~12s | ~12s | ~10s~n",
              ["Operacion", "p01 (us)", "lists (us)", "p01/lists"]),
    bench_pair("suma",
               fun() -> p01_nucleo:suma(Datos) end,
               fun() -> lists:sum(Datos) end),
    bench_pair("maximo",
               fun() -> p01_nucleo:maximo(Datos) end,
               fun() -> lists:max(Datos) end),
    bench_pair("filtrar",
               fun() -> p01_nucleo:filtrar(Predicado, Datos) end,
               fun() -> lists:filter(Predicado, Datos) end),
    bench_pair("mapear",
               fun() -> p01_nucleo:mapear(Duplicar, Datos) end,
               fun() -> lists:map(Duplicar, Datos) end),
    bench_pair("reducir",
               fun() -> p01_nucleo:reducir(Sumar, 0, Datos) end,
               fun() -> lists:foldl(Sumar, 0, Datos) end),
    ok.

bench_pair(Nombre, FunP01, FunLists) ->
    verificar_iguales(FunP01, FunLists),
    {TiemposP01, TiemposLists} = medir_repeticiones(FunP01, FunLists, ?REPS),
    MedianaP01 = mediana(TiemposP01),
    MedianaLists = mediana(TiemposLists),
    io:format("~-12s | ~12w | ~12w | ~10s~n",
              [Nombre, MedianaP01, MedianaLists,
               razon(MedianaP01, MedianaLists)]).

verificar_iguales(FunP01, FunLists) ->
    ResultadoLists = FunLists(),
    ResultadoP01 = FunP01(),
    ?assertEqual(ResultadoLists, ResultadoP01).

medir_repeticiones(FunP01, FunLists, Reps) ->
    medir_repeticiones(FunP01, FunLists, Reps, [], []).

medir_repeticiones(_FunP01, _FunLists, 0, TiemposP01, TiemposLists) ->
    {TiemposP01, TiemposLists};
medir_repeticiones(FunP01, FunLists, Reps, TiemposP01, TiemposLists) ->
    TiempoP01 = medir_una(FunP01),
    TiempoLists = medir_una(FunLists),
    medir_repeticiones(FunP01, FunLists, Reps - 1,
                       [TiempoP01 | TiemposP01],
                       [TiempoLists | TiemposLists]).

medir_una(Fun) ->
    erlang:garbage_collect(),
    {Tiempo, _Resultado} = timer:tc(Fun),
    Tiempo.

%% Con ?REPS = 5, la mediana es el tercer elemento al ordenar.
mediana(Tiempos) ->
    [_Primero, _Segundo, Mediana, _Cuarto, _Quinto] = lists:sort(Tiempos),
    Mediana.

razon(_TiempoP01, 0) ->
    "n/a";
razon(TiempoP01, TiempoLists) ->
    lists:flatten(io_lib:format("~.2f", [TiempoP01 / TiempoLists])).
