%%%-------------------------------------------------------------------
%% @doc Pruebas EUnit para `p10_calificaciones`.
%%
%% Cada prueba usa un archivo temporal único y detiene el servidor al
%% terminar para no dejar procesos ni archivos.
%% @end
%%%-------------------------------------------------------------------

-module(p10_calificaciones_tests).

-include_lib("eunit/include/eunit.hrl").

-define(TIMEOUT_ESPERA, 30000).

%%%-------------------------------------------------------------------
%% Operaciones básicas
%%%-------------------------------------------------------------------

iniciar_vacio_test() ->
    con_servidor(
      fun(Pid, _Ruta) ->
              ?assertEqual(0, p10_calificaciones:cantidad(Pid)),
              ?assertEqual([], p10_calificaciones:listar(Pid)),
              ?assertEqual({error, sin_calificaciones},
                           p10_calificaciones:promedio(Pid))
      end).

registrar_consultar_test() ->
    con_servidor(
      fun(Pid, _Ruta) ->
              ?assertEqual(ok, p10_calificaciones:registrar(Pid, "Ana", 85)),
              ?assertEqual({ok, 85}, p10_calificaciones:consultar(Pid, "Ana")),
              ?assertEqual(1, p10_calificaciones:cantidad(Pid))
      end).

duplicado_test() ->
    con_servidor(
      fun(Pid, _Ruta) ->
              ok = p10_calificaciones:registrar(Pid, "Ana", 85),
              ?assertEqual({error, {ya_existe, "Ana"}},
                           p10_calificaciones:registrar(Pid, "Ana", 90)),
              ?assertEqual({ok, 85}, p10_calificaciones:consultar(Pid, "Ana"))
      end).

modificar_test() ->
    con_servidor(
      fun(Pid, _Ruta) ->
              ok = p10_calificaciones:registrar(Pid, "Ana", 85),
              ?assertEqual(ok, p10_calificaciones:modificar(Pid, "Ana", 92)),
              ?assertEqual({ok, 92}, p10_calificaciones:consultar(Pid, "Ana")),
              ?assertEqual({error, no_encontrado},
                           p10_calificaciones:modificar(Pid, "Luis", 70))
      end).

eliminar_test() ->
    con_servidor(
      fun(Pid, _Ruta) ->
              ok = p10_calificaciones:registrar(Pid, "Ana", 85),
              ?assertEqual(ok, p10_calificaciones:eliminar(Pid, "Ana")),
              ?assertEqual({error, no_encontrado},
                           p10_calificaciones:consultar(Pid, "Ana")),
              ?assertEqual({error, no_encontrado},
                           p10_calificaciones:eliminar(Pid, "Ana"))
      end).

listar_ordenado_test() ->
    con_servidor(
      fun(Pid, _Ruta) ->
              ok = p10_calificaciones:registrar(Pid, "Luis", 70),
              ok = p10_calificaciones:registrar(Pid, "Ana", 90),
              ok = p10_calificaciones:registrar(Pid, "Carlos", 80),
              ?assertEqual([{"Ana", 90}, {"Carlos", 80}, {"Luis", 70}],
                           p10_calificaciones:listar(Pid))
      end).

promedio_test() ->
    con_servidor(
      fun(Pid, _Ruta) ->
              ok = p10_calificaciones:registrar(Pid, "Ana", 80),
              ok = p10_calificaciones:registrar(Pid, "Luis", 90),
              ok = p10_calificaciones:registrar(Pid, "Carlos", 100),
              ?assertEqual({ok, 90.0}, p10_calificaciones:promedio(Pid))
      end).

%%%-------------------------------------------------------------------
%% Datos inválidos
%%%-------------------------------------------------------------------

datos_invalidos_test() ->
    con_servidor(
      fun(Pid, _Ruta) ->
              ?assertEqual({error, {alumno_invalido, ""}},
                           p10_calificaciones:registrar(Pid, "", 80)),
              ?assertEqual({error, {alumno_invalido, 123}},
                           p10_calificaciones:registrar(Pid, 123, 80)),
              ?assertEqual({error, {calificacion_invalida, -1}},
                           p10_calificaciones:registrar(Pid, "Ana", -1)),
              ?assertEqual({error, {calificacion_invalida, 101}},
                           p10_calificaciones:registrar(Pid, "Ana", 101)),
              ?assertEqual({error, {calificacion_invalida, mal}},
                           p10_calificaciones:registrar(Pid, "Ana", mal)),
              ?assertEqual(0, p10_calificaciones:cantidad(Pid))
      end).

%%%-------------------------------------------------------------------
%% Actualizaciones asíncronas (handle_cast)
%%%-------------------------------------------------------------------

cast_test() ->
    con_servidor(
      fun(Pid, _Ruta) ->
              ok = p10_calificaciones:registrar_async(Pid, "Ana", 90),
              ok = p10_calificaciones:registrar_async(Pid, "Luis", 80),
              ok = p10_calificaciones:registrar_async(Pid, "Carlos", 70),
              ok = p10_calificaciones:sincronizar(Pid),
              ?assertEqual(3, p10_calificaciones:cantidad(Pid)),
              %% Duplicado e inválidos se ignoran en el cast.
              ok = p10_calificaciones:registrar_async(Pid, "Ana", 50),
              ok = p10_calificaciones:registrar_async(Pid, "Beto", 200),
              ok = p10_calificaciones:registrar_async(Pid, 123, 80),
              ok = p10_calificaciones:sincronizar(Pid),
              ?assertEqual({ok, 90}, p10_calificaciones:consultar(Pid, "Ana")),
              ?assertEqual(3, p10_calificaciones:cantidad(Pid))
      end).

%%%-------------------------------------------------------------------
%% Persistencia
%%%-------------------------------------------------------------------

persistencia_test() ->
    Ruta = ruta_temporal(),
    Pid1 = abrir(Ruta),
    try
        ok = p10_calificaciones:registrar(Pid1, "Ana", 88),
        ok = p10_calificaciones:registrar(Pid1, "Luis", 76),
        ok = p10_calificaciones:detener(Pid1),
        ?assert(filelib:is_file(Ruta)),
        Pid2 = abrir(Ruta),
        try
            ?assertEqual(2, p10_calificaciones:cantidad(Pid2)),
            ?assertEqual({ok, 88}, p10_calificaciones:consultar(Pid2, "Ana")),
            ?assertEqual({ok, 76}, p10_calificaciones:consultar(Pid2, "Luis"))
        after
            cerrar(Pid2)
        end
    after
        cerrar(Pid1),
        file:delete(Ruta)
    end.

guardar_test() ->
    con_servidor(
      fun(Pid, Ruta) ->
              ok = p10_calificaciones:registrar(Pid, "Ana", 88),
              ?assertEqual(ok, p10_calificaciones:guardar(Pid)),
              {ok, Binario} = file:read_file(Ruta),
              ?assertEqual(#{ "Ana" => 88 }, binary_to_term(Binario))
      end).

archivo_corrupto_test() ->
    Ruta = ruta_temporal(),
    ok = file:write_file(Ruta, <<"esto no es un termino Erlang">>),
    try
        ?assertEqual({error, {archivo_corrupto, Ruta}},
                     p10_calificaciones:iniciar(Ruta))
    after
        file:delete(Ruta)
    end.

archivo_no_mapa_test() ->
    Ruta = ruta_temporal(),
    ok = file:write_file(Ruta, term_to_binary([1, 2, 3])),
    try
        ?assertEqual({error, {archivo_corrupto, Ruta}},
                     p10_calificaciones:iniciar(Ruta))
    after
        file:delete(Ruta)
    end.

ruta_invalida_test() ->
    ?assertEqual({error, {ruta_invalida, 123}},
                 p10_calificaciones:iniciar(123)),
    ?assertEqual({error, {ruta_invalida, ""}},
                 p10_calificaciones:iniciar("")).

%%%-------------------------------------------------------------------
%% 1000 llamadas concurrentes
%%%-------------------------------------------------------------------

concurrencia_1000_test_() ->
    {timeout, 120, fun concurrencia_1000/0}.

concurrencia_1000() ->
    con_servidor(
      fun(Pid, _Ruta) ->
              Resultados =
                  ejecutar_concurrente(
                    fun(N) ->
                            p10_calificaciones:registrar(
                              Pid, nombre(N), N rem 101)
                    end),
              ?assertEqual(lists:duplicate(1000, ok), Resultados),
              ?assertEqual(1000, p10_calificaciones:cantidad(Pid)),
              Lista = p10_calificaciones:listar(Pid),
              ?assertEqual(1000, length(Lista)),
              Mapa = maps:from_list(Lista),
              lists:foreach(
                fun(N) ->
                        ?assertEqual(N rem 101,
                                     maps:get(nombre(N), Mapa))
                end,
                lists:seq(1, 1000)),
              Esperado =
                  lists:sum([N rem 101 || N <- lists:seq(1, 1000)]) / 1000,
              ?assertEqual({ok, Esperado},
                           p10_calificaciones:promedio(Pid))
      end).

concurrencia_cast_1000_test_() ->
    {timeout, 120, fun concurrencia_cast_1000/0}.

concurrencia_cast_1000() ->
    con_servidor(
      fun(Pid, _Ruta) ->
              Resultados =
                  ejecutar_concurrente(
                    fun(N) ->
                            ok = p10_calificaciones:registrar_async(
                                   Pid, nombre(N), N rem 101),
                            p10_calificaciones:sincronizar(Pid)
                    end),
              ?assertEqual(lists:duplicate(1000, ok), Resultados),
              ?assertEqual(1000, p10_calificaciones:cantidad(Pid)),
              Lista = p10_calificaciones:listar(Pid),
              Mapa = maps:from_list(Lista),
              lists:foreach(
                fun(N) ->
                        ?assertEqual(N rem 101,
                                     maps:get(nombre(N), Mapa))
                end,
                lists:seq(1, 1000))
      end).

%%%-------------------------------------------------------------------
%% Auxiliares
%%%-------------------------------------------------------------------

ruta_temporal() ->
    Base = case os:getenv("TMPDIR") of
               false -> "/tmp";
               Directorio -> Directorio
           end,
    Nombre = "p10_calificaciones_"
        ++ integer_to_list(erlang:unique_integer([positive, monotonic]))
        ++ ".dat",
    filename:join(Base, Nombre).

abrir(Ruta) ->
    {ok, Pid} = p10_calificaciones:iniciar(Ruta),
    Pid.

cerrar(Pid) ->
    case is_process_alive(Pid) of
        true ->
            catch p10_calificaciones:detener(Pid),
            ok;
        false ->
            ok
    end.

con_servidor(Fun) ->
    Ruta = ruta_temporal(),
    Pid = abrir(Ruta),
    try
        Fun(Pid, Ruta)
    after
        cerrar(Pid),
        file:delete(Ruta)
    end.

nombre(N) ->
    "Alumno" ++ integer_to_list(N).

%% Lanza 1000 procesos, cada uno ejecuta `Fun(N)` y envía el resultado.
ejecutar_concurrente(Fun) ->
    Parent = self(),
    Monitores = [spawn_monitor(fun() -> Parent ! {self(), Fun(N)} end)
                 || N <- lists:seq(1, 1000)],
    [esperar(Monitor) || Monitor <- Monitores].

esperar({Pid, Ref}) ->
    receive
        {Pid, Resultado} ->
            receive
                {'DOWN', Ref, process, Pid, _Razon} -> ok
            after ?TIMEOUT_ESPERA ->
                {error, timeout_down}
            end,
            Resultado;
        {'DOWN', Ref, process, Pid, Razon} ->
            {error, {proceso_terminado, Razon}}
    after ?TIMEOUT_ESPERA ->
        exit(Pid, kill),
        {error, timeout}
    end.
