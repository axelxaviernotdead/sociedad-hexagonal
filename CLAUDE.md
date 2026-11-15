# Sociedad Hexagonal

Sitio de la Sociedad Hexagonal: calendario de utopías, asistencia, archivo de presentaciones grabadas y foro.
Acceso cerrado por lista de admisión. Interfaz y textos en español rioplatense.

Producción: https://www.sociedadhexagonal.com (el dominio sin www redirige ahí).

Antes de tocar cualquier pantalla, leer `DESIGN.md`. Las reglas visuales son tan estrictas como las de seguridad.

## Stack

- SvelteKit 2 con Svelte 5 (runes: `$state`, `$derived`, `$props`, `$effect`). No usar la sintaxis de Svelte 4.
- Supabase: Postgres, autenticación por enlace mágico, almacenamiento. Proyecto `qmxstttbgsqkvytpbhkv`.
- Vercel, despliegue automático en cada push a `main`.
- Mail: Resend como SMTP de Supabase. El sitio no envía mails por su cuenta.

## Comandos

- `npm run dev`: servidor local en http://localhost:5173
- `npm run check`: chequeo de tipos. Correr antes de cada commit; tiene que dar 0 errores.
- `npm run build`: compilación de producción.

## Estructura

- `src/routes/+page.svelte`: portada sin sesión. Nombre y campo de mail centrados en la pantalla, sin cabecera; sin menú,
  sin textos. Con sesión redirige a `/inicio`. `entrar` redirige a `/` (enlaces viejos).
- `src/routes/auth/confirm`, `salir`: acceso.
- `src/routes/(m)/`: rutas solo para miembros. El `+layout.server.ts` del grupo redirige a `/` sin sesión.
  - `inicio`: calendario del mes en celdas, siguiente evento con la asistencia a la próxima utopía, cinco hilos del
    foro y el libro de visitas (`src/lib/components/LibroVisitas.svelte`).
  - `archivo`: archivo completo de presentaciones.
  - `foro`, `foro/[id]`, `foro/nuevo`. La lista no muestra filtros por tema (solo "todos"); `?tema=` sigue filtrando.
  - `registro`: datos propios, asistencia, presentaciones.
- `src/routes/p/[numero]`: presentación. Pública o privada según su visibilidad, la decide la base.
- `src/lib/components/Reproductor.svelte`: reproductor fijo al pie, persiste al navegar.
- `src/hooks.server.ts`: cliente de Supabase por request y cabeceras de seguridad. Al agregar una ruta de miembros,
  sumar su prefijo a `PRIVADAS` y `SIN_CACHE`; si no, sale sin `noindex` ni `no-store` aunque el grupo `(m)` la proteja.
- `supabase/migrations/`: esquema. `supabase/plantillas/`: mail de acceso.

## Base de datos

Tablas principales: `lista_admision`, `miembros`, `titulos`, `miembro_titulos`, `utopias`, `utopia_lugar`,
`eventos`, `asistencias` (confirmación previa), `actas` (asistencia real, bajo llave), `actas_bitacora`,
`presentaciones`, `hilos`, `mensajes`.

- Migraciones nuevas: `supabase/migrations/0003_nombre.sql`, `0004_...`. Nunca editar una migración ya aplicada.
  Se aplican a mano en el SQL Editor de Supabase; avisar al usuario cuando haya una nueva para correr.
- Pruebas de permisos: `supabase/pruebas/correr.sh` contra un Postgres local (no contra Supabase). Cada migración
  con permisos nuevos lleva su archivo `supabase/pruebas/0NNN_nombre.sql`, con casos que deben fallar. Toda línea
  tiene que dar `OK`.
- Libro de visitas (`libro_notas`, migración 0003): cada miembro mueve, edita y borra solo lo suyo (hasta 20 notas);
  el núcleo borra cualquiera. Fuente y color son claves de listas cerradas (`src/lib/libro.ts` y el `check` de la
  tabla deben coincidir); nunca guardar ni aplicar CSS que venga del usuario.
- Títulos derivados: `utopico` (presentó al menos una vez) y `testigo` (asistió al menos una vez) se calculan en
  `mi_registro()`, no se guardan. `fundador`, `operador`, `musico` los asigna el núcleo. `nucleo` y `secretario` son cargos con permisos.
- La numeración de presentaciones es global (001, 002...), no por utopía.
- El número de cada mensaje del foro lo asigna el trigger `numerar_mensaje` (máximo del hilo + 1). El valor que
  mande el código se sobrescribe; no calcularlo a mano.
- Fechas en `timestamptz`. Al escribir SQL a mano, siempre con zona: `'2026-12-05 19:00-03'`. En la interfaz se
  muestran en `America/Argentina/Buenos_Aires` con las funciones de `src/lib/formato.ts`.

## Seguridad: reglas que no se rompen

- Todos los permisos viven en la base (Row Level Security). El sitio usa solo la URL y la clave publishable.
- Nunca usar en el sitio la clave secreta, `service_role`, `SUPABASE_JWT_SECRET` ni las credenciales de Postgres,
  aunque existan en Vercel. Si algo falla por permisos, la solución es una política o una función en una migración,
  nunca saltear RLS. No pedirle esas claves al usuario.
- Cada tabla nueva: `enable row level security`, políticas explícitas y `grant` explícitos a `anon`/`authenticated`.
- Funciones `security definer` siempre con `set search_path = public` y control de permisos al inicio.
- En el servidor, identificar al usuario con `locals.getUser()` (valida el token contra Supabase), nunca con `getSession()`.
- Los mails de los miembros nunca se exponen a otros miembros. Solo alias. El núcleo ve únicamente los mails de la lista
  de admisión que todavía no entraron (`nucleo_admision()`), nunca los de miembros.
- Cambios de admisión, títulos, cargos y estado: solo por las funciones de 0004, que exigen núcleo y anotan en
  `nucleo_bitacora`. Nadie se saca su propio cargo de núcleo ni cambia su propio estado.
- `actas` solo se lee con `consultar_actas()`, que registra cada lectura en `actas_bitacora`.
- Archivos en el bucket privado `archivo`, servidos con URLs firmadas de vida corta.
- El texto de los usuarios nunca se renderiza con `{@html}`. Las citas `>>0002` se parsean en `src/lib/citas.ts`.
- Sin analítica, cookies de terceros ni scripts o fuentes externas. Respetar la CSP de `svelte.config.js`.
- El login responde igual exista o no el mail: el sitio no revela quién es miembro.
- Toda lógica de permisos nueva se prueba con casos que deben fallar, no solo con los que deben funcionar.

## Configuración (ya resuelta, no romper)

- Variables en Vercel y en `.env`: `PUBLIC_SUPABASE_URL` (solo la base, `https://xxx.supabase.co`, sin `/rest/v1`)
  y `PUBLIC_SUPABASE_ANON_KEY` (la clave publishable, `sb_publishable_...`). Tipo Config, no Sensitive.
  Cambiar una variable en Vercel no tiene efecto hasta redesplegar.
- Supabase, Authentication → URL Configuration: Site URL `https://www.sociedadhexagonal.com`; Redirect URLs con
  `/auth/confirm` para www, sin www y `http://localhost:5173`.
- Las plantillas "Magic link" y "Confirm sign up" usan `supabase/plantillas/acceso.html`. La de por defecto de
  Supabase no funciona con este sitio: deja la sesión en el fragmento de la URL, que el servidor no lee.
- Plan gratuito de Supabase: 50 MB por archivo. Audio en AAC/M4A mono 64 kbps. Video recién con plan pago.

## Carga de contenido (hasta que exista el panel)

Utopías, lugar y eventos: desde `/nucleo`. Lo demás, así:

Archivos en Storage → `archivo` → carpeta con el número en tres cifras: `001/audio.m4a`, `001/diapositivas.pdf`.
Fichas por SQL; ver README. Una utopía necesita su fila en `eventos` con `utopia_id` para aparecer en el calendario
con los botones de asistencia: `guardar_utopia()` la crea sola; si se carga una utopía por SQL, hay que crearla a mano.

## Pendiente, en orden

1. Panel del núcleo (cargo `nucleo`, ruta `/nucleo`). Hecho: utopías, eventos y lugar (0002); miembros, admisión
   en lote, títulos, cargos, expulsión y bitácora (0004, `/nucleo/miembros`). Falta: presentaciones con subida de archivos.
2. Envíos masivos segmentados: todos, asistentes de la última, utópicos, operadores y músicos, selección manual.
   Texto plano, desde la misma cuenta de Resend.
3. Interfaz del libro de actas para `secretario`, usando `consultar_actas` y `registrar_acta`.
4. RSS privado de audio por miembro, revocable.
5. Reproducción aleatoria del archivo.
6. Edición de mensajes propios durante 30 minutos (la política ya existe).

Trabajar en partes chicas, una por commit, con `npm run check` limpio.
