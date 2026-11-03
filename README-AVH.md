# Práctica en Raspberry Pi virtual (Arm Virtual Hardware)

Esta guía conecta lo que viste en el video del profesor (Arm Virtual Hardware)
con el gist de Erlang/OTP 27 y con el proyecto `practica_erlang_otp` que ya
tienes resuelto.

> **Resumen:** el video enseña a entrar a **Arm Virtual Hardware (AVH)**, que
> presta una **Raspberry Pi 5 virtual** por 30 días. El gist está escrito para
> un **CM5 físico con Debian 13**. No son lo mismo, así que algunos comandos
> del gist se tienen que adaptar. Esta guía trae las dos rutas: la rápida y la
> fiel al gist (OTP 27 con JIT).

---

## 1. Lo que vas a hacer

1. Crear tu cuenta de ARM Developer.
2. Entrar a AVH y crear una Raspberry Pi 5 virtual.
3. Entrar a su consola (usuario `pi`, contraseña `raspberry`).
4. Copiar el proyecto `practica_erlang_otp` a la Pi virtual.
5. Instalar Erlang y rebar3.
6. Compilar y correr las 165 pruebas.
7. Tomar evidencia y **apagar** la instancia.

---

## 2. Diferencias entre el gist y AVH (importante)

| Tema | Gist del profesor | AVH real |
|---|---|---|
| Equipo | Raspberry Pi **CM5** físico | Raspberry Pi **5** virtual |
| SO | Debian **13** (trixie) | Raspberry Pi OS **11.2** = Debian **11** (bullseye) |
| Erlang de apt | OTP 27 | OTP **23** |
| JIT ARM64 | Sí (`emu_flavor = jit`) | No con el Erlang de apt |
| Paquete `rebar3` en apt | Sí (o se descarga) | **No existe en Debian 11** |
| Paquete wxWidgets | `libwxgtk3.2-dev` | No se necesita (compilamos `--without-wx`) |
| Núcleos | 4 | 4 |
| RAM | 8 GB | 8 GB |

AVH **no ofrece un CM5** en su catálogo; la placa más parecida es la
**Raspberry Pi 5**, que usa la misma familia de CPU Cortex-A76. Para esta
práctica sirve perfectamente. Si el profesor exige específicamente un CM5,
tendrías que usar hardware físico o una imagen personalizada.

El proyecto ya está escrito para funcionar desde OTP 23; no usa funciones
exclusivas de OTP 27. Por eso la **ruta rápida** (OTP 23) es válida para
entregar. La **ruta OTP 27** es solo si el profesor pide ver el JIT.

---

## 3. Crear la cuenta y entrar a AVH

1. Crea una cuenta de ARM Developer:
   <https://www.arm.com/account>
   - Usa un correo que puedas verificar.
   - Verifica el correo antes de continuar.

2. Entra a Arm Virtual Hardware:
   <https://app.avh.corellium.com>
   - Elige **Sign in with Arm** (SSO).
   - Si es tu primera vez, AVH te inscribe automáticamente en el trial:
     **30 días, 100 core-hours, hasta 15 núcleos activos**.
   - Con una Pi de 4 núcleos, 100 core-hours equivalen a **25 horas de reloj**
     con la instancia encendida. Apágala cuando termines.

3. Crea el dispositivo:
   - Pulsa **CREATE DEVICE**.
   - Selecciona tu proyecto (normalmente **Default Project**).
   - En **Select Device**, elige **Raspberry Pi 5** (está en la categoría
     **IOT** o **ALL**).
   - En **Select an example firmware**, elige
     **Raspberry Pi OS Desktop (11.2.0)**.
   - Pulsa **SELECT** y luego **CREATE DEVICE**.
   - Espera unos minutos a que arranque.

4. Entra a la consola:
   - Abre la pestaña **Console**.
   - Usuario: `pi`
   - Contraseña: `raspberry`
   - Debes ver un prompt como `pi@raspberrypi:~ $`.

5. Verifica el entorno:

   ```bash
   uname -a
   uname -m          # debe decir aarch64
   nproc             # 4
   free -h           # ~8 GB
   cat /etc/os-release
   ```

   Si `uname -m` dice `aarch64`, estás en la arquitectura correcta.

---

## 4. Dónde va el código

El proyecto debe quedar en el home del usuario `pi`:

```text
/home/pi/practica_erlang_otp/
├── src/
├── test/
├── scripts/
├── rebar.config
└── README.md
```

Tienes tres formas de subirlo. La más cómoda para editar después es SSH/SCP;
la más sencilla para una sola entrega es subir un `.tar.gz` con el visor de
archivos.

### Opción A — Visor de archivos de AVH (la más simple)

1. En tu máquina local, empaqueta el proyecto:

   ```bash
   cd /home/carprez/practica-erlang-otp/practica_erlang_otp
   ./scripts/empaquetar_avh.sh ~/practica_erlang_otp_avh.tar.gz
   ```

2. En AVH, abre la pestaña **Files** del dispositivo (si tu instancia la
   muestra) y sube `practica_erlang_otp_avh.tar.gz` a `/home/pi/`.
   - Si no ves **Files**, usa la opción B o C.

3. En la consola de la Pi:

   ```bash
   cd ~
   tar -xzf practica_erlang_otp_avh.tar.gz
   cd practica_erlang_otp
   ls
   ```

### Opción B — SSH + SCP (recomendada para trabajar cómodo)

AVH tiene una función **Quick Connect** que te deja entrar por SSH desde tu
computadora sin VPN.

1. Genera una llave SSH en tu máquina local (si no tienes):

   ```bash
   ssh-keygen -t ed25519
   cat ~/.ssh/id_ed25519.pub
   ```

2. En AVH, agrega esa llave pública al proyecto:
   - Busca **ADMIN** o la configuración del proyecto.
   - Entra a **Projects** → **Authorized Keys** → **Add an authorized key**.
   - Pega el contenido completo de `id_ed25519.pub`.

3. En el dispositivo, abre **Connect** → **Quick Connect** y copia el comando
   que empieza con `ssh -J ...`. Se parece a:

   ```bash
   ssh -J 4ca0caa7-xxxx-xxxx-xxxx-xxxxxxxxxxxx@proxy.app.avh.arm.com pi@10.11.0.1
   ```

4. Desde tu máquina local, copia el paquete (reemplaza el `-J` y la IP por los
   de tu comando):

   ```bash
   scp -J 4ca0caa7-xxxx-xxxx-xxxx-xxxxxxxxxxxx@proxy.app.avh.arm.com \
       ~/practica_erlang_otp_avh.tar.gz pi@10.11.0.1:~/
   ```

   La primera vez te pedirá aceptar la huella del servidor y la contraseña
   `raspberry`.

5. Entra por SSH y descomprime:

   ```bash
   ssh -J 4ca0caa7-xxxx-xxxx-xxxx-xxxxxxxxxxxx@proxy.app.avh.arm.com pi@10.11.0.1
   tar -xzf ~/practica_erlang_otp_avh.tar.gz
   cd ~/practica_erlang_otp
   ```

   Con SSH puedes editar desde tu editor local (por ejemplo VS Code Remote
   SSH) o usar `nano`/`vim` dentro de la Pi.

### Opción C — GitHub

Si prefieres Git:

```bash
# En tu máquina local, dentro del proyecto:
git init
git add .
git commit -m "Práctica Erlang/OTP"
git remote add origin https://github.com/TU_USUARIO/practica_erlang_otp.git
git push -u origin main
```

En la Pi:

```bash
sudo apt-get update
sudo apt-get install -y git
git clone https://github.com/TU_USUARIO/practica_erlang_otp.git
cd practica_erlang_otp
```

---

## 5. Ruta rápida: Erlang de Debian + rebar3 (recomendada para entregar)

Ya dejamos el script corregido para AVH. Instala lo que trae Debian
(OTP 23 en bullseye) y un rebar3 compatible descargado de GitHub.

```bash
cd ~/practica_erlang_otp
chmod +x scripts/preparar_pi.sh
./scripts/preparar_pi.sh
```

El script hace:

1. `apt-get update`.
2. Instala `erlang-nox`, `git`, `curl`.
3. Descarga **rebar3 3.21.0** en `~/.local/bin` (porque en Debian 11 no hay
   paquete `rebar3`).
4. Compila el proyecto con `rebar3 compile`.
5. Corre `rebar3 eunit`.

La salida correcta termina así:

```text
165 tests, 0 failures
```

Si aparece esa línea, la práctica ya funciona en la Pi virtual.

> **Nota sobre OTP:** en AVH (Debian 11) este camino instala **OTP 23** y
> `emu_flavor = emu` (sin JIT). El proyecto es compatible y las 165 pruebas
> pasan. Si el profesor pide OTP 27 con JIT, usa la ruta de la sección 6.

---

## 6. Ruta fiel al gist: OTP 27 con JIT (opcional)

Solo si necesitas demostrar `emu_flavor = jit`. Compila OTP 27 desde fuente.
En una Pi de 4 núcleos tarda aproximadamente **30–90 minutos** y consume horas
del trial. El script intenta primero con JIT y, si el compilador de Debian 11
no puede, reintenta sin JIT.

```bash
cd ~/practica_erlang_otp
chmod +x scripts/instalar_otp27.sh

# Opción interactiva (pregunta antes de empezar):
./scripts/instalar_otp27.sh

# O sin pregunta:
OTP27_YES=1 ./scripts/instalar_otp27.sh

# Al terminar, recarga el PATH:
source ~/.bashrc
```

Verifica:

```bash
erl -noshell -eval '
  io:format("OTP: ~s~n", [erlang:system_info(otp_release)]),
  io:format("JIT: ~p~n", [erlang:system_info(emu_flavor)]),
  io:format("Arch: ~s~n", [erlang:system_info(system_architecture)]),
  halt().' -noshell
```

Salida esperada:

```text
OTP: 27
JIT: jit
Arch: aarch64-unknown-linux-gnu
```

Si dice `JIT: emu`, el JIT no compiló; el proyecto funciona igual, pero no
podrás mostrar el JIT. En ese caso necesitarías una imagen más nueva
(Debian 12/13) o un CM5 físico.

Después de instalar OTP 27, vuelve a correr la preparación para compilar y
probar con esa versión:

```bash
cd ~/practica_erlang_otp
./scripts/preparar_pi.sh
```

---

## 7. Demostración y evidencia

Para una demostración no interactiva de los 10 programas:

```bash
cd ~/practica_erlang_otp
./scripts/demo_pi.sh
```

Toma capturas de:

1. `uname -a` y `cat /etc/os-release` (se ve que es aarch64 / Raspberry Pi).
2. `erl -noshell ...` con la versión de OTP y `emu_flavor`.
3. `rebar3 eunit` con `165 tests, 0 failures`.
4. `./scripts/demo_pi.sh` con la salida de los 10 programas.
5. La pantalla de AVH con el dispositivo encendido (opcional).

Comandos útiles para la evidencia:

```bash
uname -a
erl -noshell -eval '
  io:format("OTP ~s, ERTS ~s, flavor ~p, schedulers ~p~n",
            [erlang:system_info(otp_release),
             erlang:system_info(version),
             erlang:system_info(emu_flavor),
             erlang:system_info(schedulers_online)]),
  halt().' -noshell
rebar3 eunit
./scripts/demo_pi.sh
```

---

## 8. Apagar AVH (obligatorio)

El trial se cobra por **core-hour**. Una Pi de 4 núcleos consume 4 core-hours
por cada hora encendida. Si la dejas encendida todo el día, gastas el trial.

1. En AVH, usa el botón de **apagar** (power) del dispositivo.
2. Espera a que el estado cambie a apagado.
3. Cierra la pestaña del navegador; cerrar solo el navegador **no** apaga la
   instancia.

También puedes apagarla desde la consola:

```bash
sudo poweroff
```

Pero lo importante es verificar en el panel de AVH que quedó **apagada**.

---

## 9. Problemas comunes

| Síntoma | Causa / solución |
|---|---|
| `Unable to locate package rebar3` | Debian 11 no tiene ese paquete. Usa `./scripts/preparar_pi.sh`, que descarga rebar3 de GitHub. |
| `rebar3: command not found` | Ejecuta `source ~/.bashrc` o `export PATH="$HOME/.local/bin:$PATH"`. |
| `erlang-nox` no se instala | Revisa Internet con `ping -c 3 deb.debian.org` y corre `sudo apt-get update`. |
| `rebar3 eunit` falla con errores raros | Revisa `erl -version`; si es OTP 23 y el código usara algo nuevo, instala OTP 27 con la sección 6. |
| `libwxgtk3.2-dev` no existe | No lo necesitas: el script de OTP 27 compila con `--without-wx`. |
| La compilación de OTP se queda sin memoria | Usa `JOBS=2 ./scripts/instalar_otp27.sh` o `JOBS=2 make`. |
| `No space left on device` | Revisa `df -h`; borra `~/otp-build` o `_build` y vuelve a intentar. |
| SSH: `Permission denied (publickey)` | Agrega tu llave pública al proyecto en AVH (Authorized Keys) o usa la consola web. |
| SSH: `Connection refused` | El dispositivo está apagado; enciéndelo en AVH. |
| No veo la pestaña **Files** | Usa SCP/Quick Connect o la consola web con `nano`. |
| No sé si el JIT está activo | `erl -noshell -eval 'io:format("~p~n", [erlang:system_info(emu_flavor)]), halt().' -noshell` debe imprimir `jit`. |

---

## 10. Checklist de entrega

- [ ] Cuenta ARM verificada.
- [ ] Dispositivo Raspberry Pi 5 creado en AVH.
- [ ] Consola accesible con `pi` / `raspberry`.
- [ ] Proyecto copiado a `/home/pi/practica_erlang_otp`.
- [ ] `rebar3 compile` sin errores.
- [ ] `rebar3 eunit` con **165 tests, 0 failures**.
- [ ] `./scripts/demo_pi.sh` ejecutado.
- [ ] Capturas de pantalla de la versión de OTP, arquitectura y pruebas.
- [ ] Instancia de AVH **apagada**.

---

## 11. Enlaces

- Video del profesor: <https://www.loom.com/share/55e1cd12cd3a4e21aa19460ac48da509>
- Gist del profesor: <https://gist.github.com/IoTeacher/3c3607e48bce473de9bfa6d400dec6ff>
- Cuenta ARM: <https://www.arm.com/account>
- AVH: <https://app.avh.corellium.com>
- Documentación de AVH: <https://support.avh.corellium.com/>
- Quick Connect (SSH): <https://support.avh.corellium.com/features/connect/quick-connect>
- Raspberry Pi 5 en AVH: <https://support.avh.corellium.com/devices/rpi5/rpi5-quickstart>
- Descargas de Erlang/OTP: <https://www.erlang.org/downloads>
- rebar3: <https://rebar3.org/docs/getting-started/>
