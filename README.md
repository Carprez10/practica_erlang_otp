# Práctica de Erlang/OTP: diez problemas resueltos

## Objetivo

Resolver diez problemas de la colección *Problemas resolver por computadora* usando Erlang/OTP y Rebar3, aplicando pattern matching, recursión, funciones puras, estructuras de datos inmutables y, en el último programa, un servidor `gen_server` con persistencia en disco.

Cada programa vive en su propio módulo dentro de `src/` y tiene pruebas EUnit en `test/`.

## Tecnologías y requisitos

- **Erlang/OTP 23 o superior** (probado con OTP 27, ERTS 15.2.7.4, y con
  OTP 23 en Raspberry Pi OS 11 / Arm Virtual Hardware).
- **Rebar3 3.21.0** o compatible.
- No se requieren dependencias externas: `rebar.config` declara `{deps, []}`.

> ¿Vas a correr la práctica en Arm Virtual Hardware? Sigue
> [`README-AVH.md`](README-AVH.md): ahí está el paso a paso para la
> Raspberry Pi 5 virtual y la ruta opcional con OTP 27 + JIT.

## Estructura del proyecto

```text
practica_erlang_otp/
├── src/
│   ├── p01_nucleo.erl
│   ├── p02_mcd.erl
│   ├── p03_pascal.erl
│   ├── p04_pila.erl
│   ├── p05_rle.erl
│   ├── p06_bst.erl
│   ├── p07_kaprekar.erl
│   ├── p08_frecuencias.erl
│   ├── p09_evaluador.erl
│   ├── p10_calificaciones.erl
│   ├── practica_erlang_otp_app.erl
│   └── practica_erlang_otp_sup.erl
├── test/
│   ├── p01_nucleo_tests.erl
│   ├── p01_nucleo_bench_tests.erl
│   ├── p02_mcd_tests.erl
│   ├── p03_pascal_tests.erl
│   ├── p04_pila_tests.erl
│   ├── p05_rle_tests.erl
│   ├── p06_bst_tests.erl
│   ├── p07_kaprekar_tests.erl
│   ├── p08_frecuencias_tests.erl
│   ├── p09_evaluador_tests.erl
│   └── p10_calificaciones_tests.erl
├── scripts/
│   └── p01_nucleo_stress_10m.erl
├── rebar.config
├── rebar.lock
└── README.md
```

Todos los módulos `p01`–`p10` pertenecen a la misma aplicación Rebar3, `practica_erlang_otp`.

## Compilación

```bash
rebar3 compile
```

## Ejecutar todas las pruebas

```bash
rebar3 eunit
```

## Ejecutar las pruebas de un módulo individual

```bash
rebar3 eunit --module=p04_pila_tests
```

El nombre del módulo es el del archivo de pruebas sin la extensión `.erl`. Por ejemplo:

```bash
rebar3 eunit --module=p07_kaprekar_tests
rebar3 eunit --module=p10_calificaciones_tests
```

Para el benchmark del programa 1:

```bash
rebar3 eunit --module=p01_nucleo_bench_tests
```

La tabla de tiempos del benchmark se imprime al ejecutar su función `run/0` fuera de EUnit:

```bash
erl -noshell \
  -pa _build/test/lib/practica_erlang_otp/ebin \
  -pa _build/test/lib/practica_erlang_otp/test \
  -eval 'p01_nucleo_bench_tests:run(), halt().'
```

## Descripción de los diez programas y su API

Los ejemplos se ejecutan dentro de `rebar3 shell` o con los módulos ya compilados.

### 1. Núcleo funcional — capítulo 13, problema 9

`p01_nucleo` implementa operaciones sobre listas sin usar el módulo `lists`: suma, máximo, filtrado, mapeo y reducción (fold izquierdo).

| Función | Descripción |
|---|---|
| `suma(Lista)` | Suma todos los elementos. `suma([])` devuelve `0`. |
| `maximo(Lista)` | Máximo de una lista no vacía; con `[]` lanza `lista_vacia`. |
| `filtrar(Predicado, Lista)` | Conserva los elementos que cumplen el predicado, en orden. |
| `mapear(Funcion, Lista)` | Aplica la función a cada elemento, en orden. |
| `reducir(Funcion, Acumulador, Lista)` | Fold izquierdo: `Funcion(Elemento, Acumulador)`. |

```erlang
1> p01_nucleo:suma([1, 2, 3]).
6
2> p01_nucleo:maximo([3, 9, 1, 7]).
9
3> p01_nucleo:filtrar(fun(X) -> X rem 2 =:= 0 end, [1, 2, 3, 4]).
[2,4]
4> p01_nucleo:mapear(fun(X) -> X * 2 end, [1, 2, 3]).
[2,4,6]
5> p01_nucleo:reducir(fun(X, Acc) -> X + Acc end, 0, [1, 2, 3]).
6
```

`p01_nucleo:maximo([])` lanza la excepción `lista_vacia`.

Además existe `scripts/p01_nucleo_stress_10m.erl`, una prueba de estrés separada con 10,000,000 de elementos que **no** forma parte de EUnit. Se compila y ejecuta manualmente:

```bash
mkdir -p /tmp/opencode/p01_stress
erlc -o /tmp/opencode/p01_stress scripts/p01_nucleo_stress_10m.erl
erl -noshell \
  -pa _build/default/lib/practica_erlang_otp/ebin \
  -pa /tmp/opencode/p01_stress \
  -eval 'p01_nucleo_stress_10m:run().'
```

### 2. Máximo común divisor — capítulo 2, problema 124

`p02_mcd` implementa el algoritmo de Euclides con recursión de cola y pattern matching.

| Función | Descripción |
|---|---|
| `mcd(A, B)` | MCD de dos enteros no negativos. |

Contrato:

- `mcd(A, 0) = A`, `mcd(0, B) = B`, `mcd(0, 0) = 0`.
- Entradas negativas o no enteras lanzan `{entrada_invalida, A, B}`.

```erlang
1> p02_mcd:mcd(252, 105).
21
2> p02_mcd:mcd(1071, 462).
21
3> p02_mcd:mcd(100, 75).
25
```

### 3. Triángulo de Pascal — capítulo 7, problema 30

`p03_pascal` genera las filas del triángulo de Pascal y las imprime centradas.

| Función | Descripción |
|---|---|
| `filas(N)` | Primeras `N` filas, desde `[[1]]`. |
| `fila(N)` | Fila `N`; la fila 1 es `[1]`. |
| `siguiente_fila(Fila)` | Siguiente fila sumando vecinos. |
| `imprimir()` | Imprime las primeras 15 filas centradas. |
| `imprimir(N)` | Imprime las primeras `N` filas centradas. |

```erlang
1> p03_pascal:fila(5).
[1,4,6,4,1]
2> p03_pascal:filas(3).
[[1],[1,1],[1,2,1]]
3> p03_pascal:imprimir(3).
   1
  1 1
 1 2 1
ok
```

`filas/1` y `fila/1` lanzan `{numero_de_filas_invalido, N}` si `N` no es un entero positivo. `siguiente_fila([])` lanza `{fila_invalida, []}`.

### 4. Pila y delimitadores — capítulo 12, problema 6

`p04_pila` usa una lista de Erlang como pila, con el tope en la cabeza.

| Función | Descripción |
|---|---|
| `push(Elemento, Pila)` | Apila al tope. |
| `pop(Pila)` | `{ok, Elemento, Resto}` o `{error, pila_vacia}`. |
| `peek(Pila)` | `{ok, Elemento}` o `{error, pila_vacia}`. |
| `is_empty(Pila)` | `true` / `false`. |
| `balanceada(Cadena)` | Verifica `()`, `[]` y `{}`; ignora otros caracteres. |

```erlang
1> p04_pila:push(1, []).
[1]
2> p04_pila:pop([3, 2, 1]).
{ok,3,[2,1]}
3> p04_pila:peek([3, 2, 1]).
{ok,3}
4> p04_pila:is_empty([]).
true
5> p04_pila:balanceada("{[()]}").
true
6> p04_pila:balanceada("([)]").
false
7> p04_pila:pop([]).
{error,pila_vacia}
```

### 5. Compresión RLE — capítulo 11, problema 43

`p05_rle` comprime y descomprime cadenas con *Run-Length Encoding*.

| Función | Descripción |
|---|---|
| `comprimir(Cadena)` | Comprime en formato `<conteo><carácter>`. |
| `descomprimir(Cadena)` | Recupera la cadena original. |
| `porcentaje_compresion(Cadena)` | Porcentaje de reducción; `0.0` para `""`. |

```erlang
1> p05_rle:comprimir("AAAAABBBCC").
"5A3B2C"
2> p05_rle:descomprimir("5A3B2C").
"AAAAABBBCC"
3> p05_rle:porcentaje_compresion("AAAAABBBCC").
40.0
```

El conteo es decimal, mayor o igual a 1 y sin ceros a la izquierda. El texto a comprimir no puede contener dígitos (`{caracter_invalido, C}`); una cadena RLE mal formada lanza `{formato_invalido, Resto}`.

### 6. Árbol binario de búsqueda — capítulo 12, problema 11

`p06_bst` implementa un BST con `nil` como árbol vacío y `{Valor, Izq, Der}` como nodo.

| Función | Descripción |
|---|---|
| `vacio()` | Devuelve `nil`. |
| `insertar(Valor, Arbol)` | Inserta; los duplicados se ignoran. |
| `buscar(Valor, Arbol)` | `true` / `false`. |
| `eliminar(Valor, Arbol)` | Elimina hoja, nodo con un hijo o con dos hijos. |
| `altura(Arbol)` | `0` para vacío, `1` para hoja. |
| `inorden(Arbol)` | Recorrido ascendente. |
| `desde_lista(Lista)` | Construye el árbol insertando los elementos. |
| `estados()` | Los 32 estados de México en orden alfabético. |
| `barajar(Lista)` | Orden aleatorio (reproducible fijando la semilla de `rand`). |
| `demo()` | Compara alturas con los estados en orden alfabético y aleatorio. |

```erlang
1> A = p06_bst:desde_lista([5, 3, 8, 1, 4, 7, 9]).
{5,{3,{1,nil,nil},{4,nil,nil}},{8,{7,nil,nil},{9,nil,nil}}}
2> p06_bst:inorden(A).
[1,3,4,5,7,8,9]
3> p06_bst:altura(A).
3
4> p06_bst:buscar(4, A).
true
5> p06_bst:buscar(6, A).
false
6> p06_bst:inorden(p06_bst:eliminar(5, A)).
[1,3,4,7,8,9]
7> p06_bst:demo().
Estados insertados:          32
Altura en orden alfabetico:  32
Altura en orden aleatorio:   12
{32,12}
```

### 7. Proceso de Kaprekar — capítulo 7, problema 88

`p07_kaprekar` aplica el proceso de Kaprekar a números de cuatro dígitos.

| Función | Descripción |
|---|---|
| `siguiente(Numero)` | Un paso: mayor − menor con los cuatro dígitos. |
| `secuencia(Numero)` | Lista desde el inicio hasta `6174` o `0000`. |
| `iteraciones(Numero)` | Número de pasos. |
| `formatear(Numero)` | Cadena de cuatro dígitos con ceros a la izquierda. |
| `demo()` | Imprime las secuencias de 1234, 5678 y 9981. |

Dominio: `0..9999`. Los números con los cuatro dígitos iguales llegan a `0000`; el resto llega a `6174` en siete iteraciones o menos.

```erlang
1> p07_kaprekar:secuencia(1234).
[1234,3087,8352,6174]
2> p07_kaprekar:iteraciones(1234).
3
3> p07_kaprekar:formatear(999).
"0999"
4> p07_kaprekar:demo().
1234 -> 3087 -> 8352 -> 6174
5678 -> 3087 -> 8352 -> 6174
9981 -> 8082 -> 8532 -> 6174
ok
```

### 8. Frecuencia de letras — capítulo 11, problema 40

`p08_frecuencias` cuenta letras ignorando mayúsculas, acentos, espacios, dígitos y signos.

| Función | Descripción |
|---|---|
| `normalizar(Texto)` | Mayúsculas A–Z sin acentos; descarta todo lo demás. |
| `frecuencias(Texto)` | `{Letra, Absoluta, Relativa}` de las letras presentes, ordenadas de mayor a menor. |
| `frecuencias_alfabeto(Texto)` | Las 26 letras, incluidas las de frecuencia cero. |
| `total_letras(Texto)` | Letras consideradas. |
| `histograma(Texto)` | Histograma ASCII horizontal (máximo 40 `*`). |
| `imprimir(Texto)` | Imprime tabla y histograma. |
| `demo()` | Ejemplo con acentos, dígitos y puntuación. |

```erlang
1> p08_frecuencias:normalizar("¡Hola, Mundo!").
"HOLAMUNDO"
2> p08_frecuencias:frecuencias("AAABB").
[{$A,3,0.6},{$B,2,0.4}]
3> p08_frecuencias:total_letras("A1B2C3").
3
4> io:format("~s~n", [p08_frecuencias:histograma("AAB")]).
A | **************************************** 2 (66.67%)
B | ******************** 1 (33.33%)
ok
```

Normalización: `á/à/ä/â/ã→A`, `é/è/ë/ê→E`, `í/ì/ï/î→I`, `ó/ò/ö/ô/õ→O`, `ú/ù/ü/û→U`, `ñ→N`, `ç→C`.

### 9. Evaluador de expresiones — capítulo 13, problema 8

`p09_evaluador` evalúa expresiones con números, `+`, `-`, `*`, `/` y paréntesis mediante un analizador descendente recursivo puro.

| Función | Descripción |
|---|---|
| `evaluar(Texto)` | Devuelve el valor numérico de la expresión. |

Gramática:

```text
expr   := term (('+' | '-') term)*
term   := factor (('*' | '/') factor)*
factor := numero | '(' expr ')' | '-' factor | '+' factor
numero := digitos ('.' digitos)?
```

```erlang
1> p09_evaluador:evaluar("3 + 4 * (2 - 1)").
7
2> p09_evaluador:evaluar("(2 + 3) * 4").
20
3> p09_evaluador:evaluar("-(2 + 3)").
-5
```

Errores: `{error_sintaxis, Resto}`, `{caracter_invalido, Caracter}`, `{error_aritmetico, division_entre_cero}` y `{entrada_invalida, Valor}`. Por ejemplo, `p09_evaluador:evaluar("5 / 0")` lanza `{error_aritmetico, division_entre_cero}` y `p09_evaluador:evaluar("abc")` lanza `{caracter_invalido, $a}`.

### 10. Servidor de calificaciones — capítulo 13, problema 11

`p10_calificaciones` es un `gen_server` que mantiene un mapa `Alumno => Calificacion` y persiste el estado en disco.

| Función | Descripción |
|---|---|
| `iniciar()` | Inicia el servidor con el archivo por defecto. |
| `iniciar(Ruta)` | Inicia el servidor usando `Ruta` para persistir. |
| `detener(Pid)` | Detiene el servidor; `terminate/2` guarda el estado. |
| `registrar(Pid, Alumno, Calificacion)` | Alta síncrona; devuelve `ok` o error. |
| `registrar_async(Pid, Alumno, Calificacion)` | Alta asíncrona (`handle_cast`); ignora inválidos y duplicados. |
| `consultar(Pid, Alumno)` | `{ok, Calificacion}` o `{error, no_encontrado}`. |
| `modificar(Pid, Alumno, Calificacion)` | Modifica un alumno existente. |
| `eliminar(Pid, Alumno)` | Elimina un alumno. |
| `listar(Pid)` | Lista `{Alumno, Calificacion}` ordenada por alumno. |
| `promedio(Pid)` | `{ok, Float}` o `{error, sin_calificaciones}`. |
| `cantidad(Pid)` | Número de alumnos registrados. |
| `guardar(Pid)` | Fuerza la escritura del estado en disco. |
| `sincronizar(Pid)` | Barrera para asegurar que los `cast` previos ya se procesaron. |

Validación: el alumno debe ser una cadena no vacía y la calificación un número entre `0` y `100`.

#### Iniciar, consultar, guardar y recuperar

El servidor no está dentro del árbol de supervisión de la aplicación: se inicia explícitamente. Ejemplo con un archivo temporal:

```erlang
1> Ruta = "/tmp/calificaciones_demo.dat".
"/tmp/calificaciones_demo.dat"
2> {ok, Pid} = p10_calificaciones:iniciar(Ruta).
{ok,<0.…>}
3> p10_calificaciones:registrar(Pid, "Ana", 85).
ok
4> p10_calificaciones:consultar(Pid, "Ana").
{ok,85}
5> p10_calificaciones:modificar(Pid, "Ana", 92).
ok
6> p10_calificaciones:listar(Pid).
[{"Ana",92}]
7> p10_calificaciones:promedio(Pid).
{ok,92.0}
8> p10_calificaciones:guardar(Pid).
ok
9> p10_calificaciones:detener(Pid).
ok
10> {ok, Pid2} = p10_calificaciones:iniciar(Ruta).
{ok,<0.…>}
11> p10_calificaciones:consultar(Pid2, "Ana").
{ok,92}
12> p10_calificaciones:detener(Pid2).
ok
```

El pid concreto varía en cada ejecución.

#### Persistencia y archivo por defecto

- `iniciar()` usa el archivo **`p10_calificaciones.dat`** en el directorio de trabajo actual.
- `iniciar(Ruta)` permite elegir otro archivo.
- El estado se escribe en `terminate/2` al llamar a `detener/1`, y también de forma explícita con `guardar/1`.
- Al arrancar, `init/1` lee el archivo con `binary_to_term(..., [safe])`:
  - si no existe, empieza con el mapa vacío;
  - si está corrupto o no contiene un mapa, `iniciar/1` devuelve `{error, {archivo_corrupto, Ruta}}`.
- El formato es un término Erlang binario, no texto legible.
- Si el proceso se mata de forma abrupta (por ejemplo, con `exit(Pid, kill)`), `terminate/2` no se ejecuta y los cambios no guardados se pierden.
- Las pruebas usan archivos temporales únicos y los eliminan al terminar.

## Resultado de las pruebas

Última ejecución comprobada tras `rebar3 clean` y `rebar3 compile`:

```text
rebar3 compile  -> sin errores, 0 advertencias
rebar3 eunit    -> 165 tests, 0 failures
Finished in 2.912 seconds
```

| Módulo de pruebas | Pruebas |
|---|---:|
| `p01_nucleo_tests` | 21 |
| `p01_nucleo_bench_tests` | 1 |
| `p02_mcd_tests` | 12 |
| `p03_pascal_tests` | 14 |
| `p04_pila_tests` | 17 |
| `p05_rle_tests` | 24 |
| `p06_bst_tests` | 16 |
| `p07_kaprekar_tests` | 12 |
| `p08_frecuencias_tests` | 18 |
| `p09_evaluador_tests` | 14 |
| `p10_calificaciones_tests` | 16 |
| **Total** | **165** |

## Referencia

Problemas originales:

<https://github.com/tectijuana/problemasresolverporcomputadora>
