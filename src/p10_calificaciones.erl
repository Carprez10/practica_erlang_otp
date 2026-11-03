%%%-------------------------------------------------------------------
%% @doc Servidor OTP de calificaciones del TecNM.
%%
%% Mantiene un mapa `Alumno => Calificacion` dentro de un `gen_server`,
%% de modo que todas las operaciones se serializan y no hay condiciones
%% de carrera.
%%
%% Consultas y modificaciones síncronas usan `handle_call/3`; las
%% actualizaciones asíncronas usan `handle_cast/2` (los datos inválidos
%% o duplicados se ignoran en ese caso; para recibir el error se usa la
%% versión síncrona).
%%
%% `terminate/2` persiste el mapa en disco y `init/1` lo recupera al
%% arrancar. El formato es un término Erlang binario; si el archivo no
%% existe se empieza vacío y si está corrupto el servidor no arranca.
%% @end
%%%-------------------------------------------------------------------

-module(p10_calificaciones).

-behaviour(gen_server).

-export([iniciar/0, iniciar/1, detener/1,
         registrar/3, registrar_async/3, consultar/2, modificar/3,
         eliminar/2, listar/1, promedio/1, cantidad/1, guardar/1,
         sincronizar/1]).

-export([init/1, handle_call/3, handle_cast/2, terminate/2]).

-define(TIMEOUT, 30000).
-define(ARCHIVO_POR_DEFECTO, "p10_calificaciones.dat").

-record(estado, {
    ruta :: file:filename(),
    calificaciones = #{} :: #{string() => number()}
}).

%%%-------------------------------------------------------------------
%% API
%%%-------------------------------------------------------------------

%% @doc Inicia el servidor con el archivo de persistencia por defecto.
-spec iniciar() -> {ok, pid()} | {error, term()}.
iniciar() ->
    iniciar(?ARCHIVO_POR_DEFECTO).

%% @doc Inicia el servidor usando `Ruta` para persistir el estado.
%%
%% Se inicia sin enlace para que un fallo de arranque (por ejemplo, un
%% archivo corrupto) se devuelva como `{error, Razon}` en lugar de
%% terminar el proceso que llama. El servidor se detiene con
%% `detener/1`.
-spec iniciar(file:filename()) -> {ok, pid()} | {error, term()}.
iniciar(Ruta) ->
    gen_server:start(?MODULE, Ruta, []).

%% @doc Detiene el servidor; `terminate/2` guarda el estado.
-spec detener(pid()) -> ok.
detener(Pid) ->
    gen_server:stop(Pid).

%% @doc Registra un alumno de forma síncrona.
-spec registrar(pid(), string(), number()) -> ok | {error, term()}.
registrar(Pid, Alumno, Calificacion) ->
    gen_server:call(Pid, {registrar, Alumno, Calificacion}, ?TIMEOUT).

%% @doc Registra un alumno de forma asíncrona.
%%
%% Los datos inválidos o los alumnos ya existentes se ignoran.
-spec registrar_async(pid(), string(), number()) -> ok.
registrar_async(Pid, Alumno, Calificacion) ->
    gen_server:cast(Pid, {registrar, Alumno, Calificacion}).

%% @doc Consulta la calificación de un alumno.
-spec consultar(pid(), string()) -> {ok, number()} | {error, no_encontrado}.
consultar(Pid, Alumno) ->
    gen_server:call(Pid, {consultar, Alumno}, ?TIMEOUT).

%% @doc Modifica la calificación de un alumno existente.
-spec modificar(pid(), string(), number()) -> ok | {error, term()}.
modificar(Pid, Alumno, Calificacion) ->
    gen_server:call(Pid, {modificar, Alumno, Calificacion}, ?TIMEOUT).

%% @doc Elimina a un alumno.
-spec eliminar(pid(), string()) -> ok | {error, no_encontrado}.
eliminar(Pid, Alumno) ->
    gen_server:call(Pid, {eliminar, Alumno}, ?TIMEOUT).

%% @doc Lista `{Alumno, Calificacion}` ordenado por alumno.
-spec listar(pid()) -> [{string(), number()}].
listar(Pid) ->
    gen_server:call(Pid, listar, ?TIMEOUT).

%% @doc Promedio de las calificaciones registradas.
-spec promedio(pid()) -> {ok, float()} | {error, sin_calificaciones}.
promedio(Pid) ->
    gen_server:call(Pid, promedio, ?TIMEOUT).

%% @doc Número de alumnos registrados.
-spec cantidad(pid()) -> non_neg_integer().
cantidad(Pid) ->
    gen_server:call(Pid, cantidad, ?TIMEOUT).

%% @doc Fuerza la escritura del estado en disco.
-spec guardar(pid()) -> ok | {error, term()}.
guardar(Pid) ->
    gen_server:call(Pid, guardar, ?TIMEOUT).

%% @doc Barrera de sincronización: al volver, todos los `cast` enviados
%% antes por el mismo proceso ya se procesaron.
-spec sincronizar(pid()) -> ok.
sincronizar(Pid) ->
    gen_server:call(Pid, sincronizar, ?TIMEOUT).

%%%-------------------------------------------------------------------
%% Callbacks de gen_server
%%%-------------------------------------------------------------------

init(Ruta) ->
    process_flag(trap_exit, true),
    case validar_ruta(Ruta) of
        ok ->
            case cargar(Ruta) of
                {ok, Mapa} ->
                    {ok, #estado{ruta = Ruta, calificaciones = Mapa}};
                {error, Razon} ->
                    {stop, Razon}
            end;
        {error, Razon} ->
            {stop, Razon}
    end.

handle_call({registrar, Alumno, Calificacion}, _From, Estado) ->
    case validar_datos(Alumno, Calificacion) of
        ok ->
            Mapa = Estado#estado.calificaciones,
            case maps:is_key(Alumno, Mapa) of
                true ->
                    {reply, {error, {ya_existe, Alumno}}, Estado};
                false ->
                    Nuevo = Mapa#{Alumno => Calificacion},
                    {reply, ok, Estado#estado{calificaciones = Nuevo}}
            end;
        {error, Razon} ->
            {reply, {error, Razon}, Estado}
    end;
handle_call({consultar, Alumno}, _From, Estado) ->
    case maps:find(Alumno, Estado#estado.calificaciones) of
        {ok, Calificacion} ->
            {reply, {ok, Calificacion}, Estado};
        error ->
            {reply, {error, no_encontrado}, Estado}
    end;
handle_call({modificar, Alumno, Calificacion}, _From, Estado) ->
    case validar_datos(Alumno, Calificacion) of
        ok ->
            Mapa = Estado#estado.calificaciones,
            case maps:is_key(Alumno, Mapa) of
                true ->
                    Nuevo = Mapa#{Alumno => Calificacion},
                    {reply, ok, Estado#estado{calificaciones = Nuevo}};
                false ->
                    {reply, {error, no_encontrado}, Estado}
            end;
        {error, Razon} ->
            {reply, {error, Razon}, Estado}
    end;
handle_call({eliminar, Alumno}, _From, Estado) ->
    Mapa = Estado#estado.calificaciones,
    case maps:is_key(Alumno, Mapa) of
        true ->
            Nuevo = maps:remove(Alumno, Mapa),
            {reply, ok, Estado#estado{calificaciones = Nuevo}};
        false ->
            {reply, {error, no_encontrado}, Estado}
    end;
handle_call(listar, _From, Estado) ->
    {reply, lists:sort(maps:to_list(Estado#estado.calificaciones)), Estado};
handle_call(promedio, _From, #estado{calificaciones = Mapa} = Estado) ->
    case map_size(Mapa) of
        0 ->
            {reply, {error, sin_calificaciones}, Estado};
        Cantidad ->
            Suma = maps:fold(fun(_Alumno, Calificacion, Acc) ->
                                     Acc + Calificacion
                             end,
                             0,
                             Mapa),
            {reply, {ok, Suma / Cantidad}, Estado}
    end;
handle_call(cantidad, _From, Estado) ->
    {reply, map_size(Estado#estado.calificaciones), Estado};
handle_call(guardar, _From, Estado) ->
    case guardar_estado(Estado) of
        ok ->
            {reply, ok, Estado};
        {error, Razon} ->
            {reply, {error, {error_escritura, Razon}}, Estado}
    end;
handle_call(sincronizar, _From, Estado) ->
    {reply, ok, Estado};
handle_call(_Otro, _From, Estado) ->
    {reply, {error, mensaje_desconocido}, Estado}.

handle_cast({registrar, Alumno, Calificacion}, Estado) ->
    case validar_datos(Alumno, Calificacion) of
        ok ->
            Mapa = Estado#estado.calificaciones,
            case maps:is_key(Alumno, Mapa) of
                true ->
                    {noreply, Estado};
                false ->
                    Nuevo = Mapa#{Alumno => Calificacion},
                    {noreply, Estado#estado{calificaciones = Nuevo}}
            end;
        {error, _Razon} ->
            {noreply, Estado}
    end;
handle_cast(_Otro, Estado) ->
    {noreply, Estado}.

terminate(_Razon, Estado) ->
    _ = guardar_estado(Estado),
    ok.

%%%-------------------------------------------------------------------
%% Persistencia
%%%-------------------------------------------------------------------

validar_ruta(Ruta) when is_list(Ruta), Ruta =/= [] ->
    ok;
validar_ruta(Ruta) when is_binary(Ruta), Ruta =/= <<>> ->
    ok;
validar_ruta(Otro) ->
    {error, {ruta_invalida, Otro}}.

cargar(Ruta) ->
    case file:read_file(Ruta) of
        {ok, Binario} ->
            try binary_to_term(Binario, [safe]) of
                Mapa when is_map(Mapa) ->
                    {ok, Mapa};
                _Otro ->
                    {error, {archivo_corrupto, Ruta}}
            catch
                _:_ ->
                    {error, {archivo_corrupto, Ruta}}
            end;
        {error, enoent} ->
            {ok, #{}};
        {error, Razon} ->
            {error, {error_lectura, Ruta, Razon}}
    end.

guardar_estado(#estado{ruta = Ruta, calificaciones = Mapa}) ->
    file:write_file(Ruta, term_to_binary(Mapa)).

%%%-------------------------------------------------------------------
%% Validación
%%%-------------------------------------------------------------------

validar_datos(Alumno, Calificacion) ->
    case validar_alumno(Alumno) of
        ok ->
            validar_calificacion(Calificacion);
        {error, Razon} ->
            {error, Razon}
    end.

validar_alumno(Alumno) when is_list(Alumno), Alumno =/= [] ->
    ok;
validar_alumno(Alumno) ->
    {error, {alumno_invalido, Alumno}}.

validar_calificacion(Calificacion)
  when is_number(Calificacion), Calificacion >= 0, Calificacion =< 100 ->
    ok;
validar_calificacion(Calificacion) ->
    {error, {calificacion_invalida, Calificacion}}.
