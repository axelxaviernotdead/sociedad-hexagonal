# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Proyecto en castellano rioplatense: código, nombres, comentarios, textos de interfaz y commits van en castellano. Mantener ese idioma.

## Comandos

```sh
cp .env.example .env   # PUBLIC_SUPABASE_URL y PUBLIC_SUPABASE_ANON_KEY (Settings > API)
npm install
npm run dev            # http://localhost:5173
npm run check          # svelte-kit sync + svelte-check (tipos). Es la única verificación automática.
npm run build
```

No hay tests ni linter configurados. El esquema se aplica a mano: `supabase/migrations/0001_esquema.sql` se ejecuta completo en el SQL Editor de Supabase. `supabase/ejemplo.sql` carga datos de prueba (nunca en producción).

## Arquitectura

SvelteKit 2 + Svelte 5 (runes) + Supabase, adaptador de Vercel. Zona horaria fija `America/Argentina/Buenos_Aires` (`src/lib/formato.ts`).

### La seguridad vive en la base, no en el sitio

Principio central del proyecto: el sitio usa solo la clave anon con la sesión del usuario. **No hay clave de servicio y no se debe agregar.** Todo permiso se expresa en Postgres (RLS, `grant` por columna y funciones `security definer`). El código del servidor confía en que una consulta que la base no permite devuelve vacío o error; las comprobaciones en SvelteKit son redundantes, no la barrera.

Consecuencias al tocar el esquema:
- Funciones auxiliares de políticas: `es_miembro()` (miembro con estado `activo`) y `tiene_titulo(t)`.
- `miembros`: los demás solo ven `id` y `alias` (grant por columna). El mail nunca se expone salvo a uno mismo vía `mi_registro()`.
- Lecturas que combinan tablas o filtran por visibilidad se hacen con RPC `security definer`: `archivo()`, `presentacion(n)`, `datos_publicos()`, `mi_registro()`, `confirmados()`, `abrir_hilo()`. El libro de actas (`actas`) solo se lee/escribe con `consultar_actas` / `registrar_acta`, que exigen cargo `secretario` y registran cada acceso en `actas_bitacora`.
- `utopia_lugar` solo es visible para quien confirmó asistencia y desde 48 h antes (política RLS).
- Storage: bucket privado `archivo`; la política de `storage.objects` repite la regla de visibilidad de `presentaciones`. El servidor firma URLs de 3 h (`src/routes/p/[numero]/+page.server.ts`) y no envía las rutas crudas al cliente.
- Grants explícitos al final de la migración: una tabla nueva necesita RLS habilitado, políticas y `grant` propios.

### Acceso

Sin contraseñas: OTP por mail (`/entrar` → `signInWithOtp` → `/auth/confirm` con `verifyOtp`). El trigger `portal()` sobre `auth.users` aborta la creación si el mail no está en `lista_admision` y, si está, crea la fila en `miembros` con el alias de la lista. `/entrar` responde igual exista o no el mail: no revelar quién es miembro.

### Servidor y rutas

- `src/hooks.server.ts`: crea el cliente Supabase por request (`locals.supabase`) y `locals.getUser()` (usa `getUser`, que valida el token; no usar `getSession` en servidor). También pone cabeceras de seguridad, `noindex` y `no-store` según prefijo de ruta (listas `PRIVADAS` y `SIN_CACHE`: actualizarlas al agregar rutas de miembros).
- `src/routes/+layout.server.ts` resuelve `alias` (o `null`); el grupo `src/routes/(m)/` redirige a `/entrar` si no hay alias. Rutas de miembros van dentro de `(m)`.
- Rutas públicas: `/` (sitio público y archivo público) y `/p/[numero]` (presentación; muestra lo que la RPC permita según sesión).
- Mutaciones mediante form actions de SvelteKit, nunca desde el cliente directo a Supabase.
- CSP estricta en `svelte.config.js` (solo `self` y `*.supabase.co`): no agregar scripts, fuentes ni recursos externos.

### Foro

`mensajes.numero` lo asigna el trigger `numerar_mensaje` (máximo del hilo + 1; el `numero: 0` que mandan los inserts es solo relleno y se sobrescribe). `actividad_hilo` actualiza `hilos.actividad` y `respuestas = numero - 1`. Un hilo se abre con la RPC `abrir_hilo`, que crea el hilo y su primer mensaje (número 1). Las citas `>>n` se parsean a partes en `src/lib/citas.ts` sin interpretar HTML (no usar `{@html}` con contenido de usuarios). La política permite editar el `cuerpo` 30 minutos, pero aún no hay interfaz.

### Reproductor

Estado global en `src/lib/reproductor.svelte.ts` (clase con `$state`), montado una vez en `src/routes/+layout.svelte` para que el audio siga sonando al navegar. Solo se modifica en el navegador por acción del usuario.

## Sistema visual (`src/app.css`)

Un tamaño de letra, un peso, dos valores (negro para contenido y estado actual, gris `.g` para metadatos y opciones). Retícula `.L` con columna de rótulos de 200 px; espaciado vertical en múltiplos del interlineado (`.e1`–`.e3`). **No agregar colores, tamaños ni pesos.**

## Pendiente (según README)

Panel del núcleo para cargar utopías, eventos y presentaciones; envíos masivos por mail; interfaz del libro de actas; RSS privado; reproducción aleatoria; edición de mensajes. Hoy el contenido se carga desde el Table Editor de Supabase.
