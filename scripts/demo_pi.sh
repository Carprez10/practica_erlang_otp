#!/usr/bin/env bash
# Ejecuta una demostración no interactiva de los 10 programas.
# Sirve para tomar evidencia (captura de pantalla) en la Raspberry Pi o AVH.
#
# Uso, desde la raíz del proyecto:
#   chmod +x scripts/demo_pi.sh
#   ./scripts/demo_pi.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

EBIN="_build/default/lib/practica_erlang_otp/ebin"
if [ ! -d "${EBIN}" ]; then
    echo "[..] Compilando el proyecto..."
    rebar3 compile
fi

DEMO_CODE='
  io:format("=== Entorno de ejecución ===~n"),
  io:format("OTP: ~s | ERTS: ~s | emu_flavor: ~p | schedulers: ~p~n",
            [erlang:system_info(otp_release),
             erlang:system_info(version),
             erlang:system_info(emu_flavor),
             erlang:system_info(schedulers_online)]),
  io:format("Arquitectura: ~s~n", [erlang:system_info(system_architecture)]),

  io:format("~n=== p01_nucleo ===~n"),
  io:format("suma([1,2,3,4])          = ~p~n", [p01_nucleo:suma([1,2,3,4])]),
  io:format("maximo([3,9,1,7])        = ~p~n", [p01_nucleo:maximo([3,9,1,7])]),
  io:format("mapear(x2, [1,2,3])      = ~p~n", [p01_nucleo:mapear(fun(X) -> X * 2 end, [1,2,3])]),

  io:format("~n=== p02_mcd ===~n"),
  io:format("mcd(1071, 462)           = ~p~n", [p02_mcd:mcd(1071, 462)]),

  io:format("~n=== p03_pascal ===~n"),
  p03_pascal:imprimir(6),

  io:format("~n=== p04_pila ===~n"),
  io:format("balanceada {[()]}        = ~p~n", [p04_pila:balanceada("{[()]}")]),
  io:format("balanceada ([)]          = ~p~n", [p04_pila:balanceada("([)]")]),

  io:format("~n=== p05_rle ===~n"),
  io:format("comprimir AAAAABBBCC     = ~ts~n", [p05_rle:comprimir("AAAAABBBCC")]),
  io:format("descomprimir 5A3B2C      = ~ts~n", [p05_rle:descomprimir("5A3B2C")]),

  io:format("~n=== p06_bst ===~n"),
  Arbol = p06_bst:desde_lista([5, 3, 8, 1, 4, 7, 9]),
  io:format("inorden                  = ~p~n", [p06_bst:inorden(Arbol)]),
  p06_bst:demo(),

  io:format("~n=== p07_kaprekar ===~n"),
  p07_kaprekar:demo(),

  io:format("~n=== p08_frecuencias ===~n"),
  p08_frecuencias:demo(),

  io:format("~n=== p09_evaluador ===~n"),
  io:format("evaluar 3 + 4 * (2 - 1)  = ~p~n", [p09_evaluador:evaluar("3 + 4 * (2 - 1)")]),

  io:format("~n=== p10_calificaciones (gen_server) ===~n"),
  Ruta = "/tmp/p10_demo_" ++ integer_to_list(erlang:unique_integer([positive])) ++ ".dat",
  {ok, Pid} = p10_calificaciones:iniciar(Ruta),
  ok = p10_calificaciones:registrar(Pid, "Ana", 85),
  ok = p10_calificaciones:registrar(Pid, "Luis", 92),
  {ok, 85} = p10_calificaciones:consultar(Pid, "Ana"),
  io:format("listar()                 = ~p~n", [p10_calificaciones:listar(Pid)]),
  io:format("promedio()               = ~p~n", [p10_calificaciones:promedio(Pid)]),
  ok = p10_calificaciones:detener(Pid),
  ok = file:delete(Ruta),
  io:format("servidor detenido y archivo temporal eliminado~n"),

  io:format("~n=== Fin de la demostración ===~n"),
  halt().
'

erl -noshell -pa "${EBIN}" -eval "${DEMO_CODE}"
