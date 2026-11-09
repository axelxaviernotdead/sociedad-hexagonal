# Sociedad Hexagonal

Sitio de la Sociedad Hexagonal: calendario, asistencia, archivo de presentaciones y foro.
Código abierto. SvelteKit + Supabase, desplegado en Vercel.

## Estado

Hecho: acceso por enlace de un solo uso con lista de admisión, calendario, confirmación de asistencia,
lugar revelado 48 h antes a quienes confirman, archivo con audio y video en almacenamiento privado,
foro con citas, registro personal, libro de actas con bitácora (solo base de datos), sitio público.

Pendiente: panel del núcleo para cargar utopías, eventos y presentaciones sin entrar a Supabase;
envíos masivos por mail; interfaz del libro de actas; RSS privado; reproducción aleatoria; edición de mensajes.

## Puesta en marcha

### 1. Supabase

1. Crear un proyecto en supabase.com. Región: São Paulo.
2. SQL Editor: ejecutar completo `supabase/migrations/0001_esquema.sql`.
3. Authentication > URL Configuration
   - Site URL: `https://sociedadhexagonal.com`
   - Redirect URLs: `https://sociedadhexagonal.com/auth/confirm`, `http://localhost:5173/auth/confirm`
4. Authentication > Email Templates: en "Magic Link" y en "Confirm signup", pegar `supabase/plantillas/acceso.html`.
5. Authentication > SMTP Settings: configurar un proveedor propio (por ejemplo Resend) con un remitente de
   `sociedadhexagonal.com`. El envío incluido en Supabase está muy limitado y es solo para pruebas.
6. Authentication > Providers: dejar solo Email. Desactivar los demás.

### 2. Lista de admisión

Solo puede entrar quien figure en `lista_admision`. Cada fila define mail y alias inicial:

```sql
insert into lista_admision (email, alias) values
  ('persona@dominio.com', 'alias'),
  ('otra@dominio.com', 'otro');
```

Si alguien pide acceso con un mail que no está, no se crea la cuenta y la pantalla responde lo mismo que
para un mail admitido: el sitio no revela quién es miembro.

Cargos y títulos asignados, una vez que la persona entró al menos una vez:

```sql
insert into miembro_titulos (miembro_id, titulo)
select id, 'fundador' from miembros where alias in ('alias1', 'alias2');
-- títulos: fundador, operador, musico. cargos: nucleo, secretario.
-- utópico y testigo se otorgan solos (primera presentación, primera asistencia en actas).
```

### 3. Contenido

Hasta que exista el panel del núcleo, se carga desde Table Editor:

- `utopias`: número, fecha, estado (`anunciada` o `realizada`).
- `utopia_lugar`: dirección de cada utopía. Solo la ven quienes confirmaron, desde 48 h antes.
- `eventos`: calendario. Si un evento es la utopía, completar `utopia_id`.
- `presentaciones`: número global, utopía, autor, título, resumen, duración en segundos, temas,
  visibilidad (`miembros` o `publico`), capítulos (`[{"t": 252, "titulo": "..."}]`).

Archivos: Storage > bucket `archivo` (privado). Convención: `020/audio.m4a`, `020/video.mp4`,
`020/diapositivas.pdf`. Después, completar `audio_path`, `video_path` y `diapositivas_path` con esas rutas.
Los enlaces que ve cada persona son firmados y vencen a las 3 horas.

El plan gratuito de Supabase tiene límites de almacenamiento y de tamaño por archivo que un video de
40 minutos supera. Para video hace falta el plan pago o un servicio de video aparte.

Asistencia real (libro de actas), desde SQL con un usuario con cargo `secretario`, o por ahora directo:

```sql
insert into actas (utopia_id, miembro_id)
select u.id, m.id from utopias u, miembros m where u.numero = 7 and m.alias in ('alias1', 'alias2');
```

### 4. Desarrollo local

```sh
cp .env.example .env   # completar con Settings > API del proyecto
npm install
npm run dev            # http://localhost:5173
npm run check
```

`supabase/ejemplo.sql` carga datos de prueba. No usar en producción.

### 5. Despliegue

1. Subir el repositorio a GitHub.
2. En vercel.com: importar el repositorio. Variables de entorno: las dos de `.env.example`.
3. Vercel > Domains: agregar `sociedadhexagonal.com` y cargar en el registrador los registros DNS que indique.

## Seguridad

- No hay contraseñas. Acceso por enlace de un solo uso, solo para mails de la lista de admisión.
- Todos los permisos están en la base de datos (Row Level Security). El código del sitio usa solo la clave
  pública; aunque tuviera un error, no puede leer lo que la base no permite. No hay clave de servicio en el sitio.
- Los mails de los miembros no son legibles por otros miembros. Solo se exponen alias.
- El libro de actas no se lee directo: solo con cargo `secretario`, por función, y cada lectura queda registrada.
- Archivos en un bucket privado con la misma regla de visibilidad que las presentaciones.
- Cabeceras: CSP estricta, HSTS, sin iframes, sin caché ni indexación en páginas de miembros.
- `robots.txt` excluye crawlers de entrenamiento de IA.
- Sin analítica ni cookies de terceros. La única cookie es la de sesión.

## Sistema visual

Ver `src/app.css`. Un tamaño, un peso, dos valores (negro y gris), columna de rótulos de 200 px,
espaciado en múltiplos del interlineado. No agregar colores, tamaños ni pesos.

## Licencia

AGPL-3.0. Agregar el texto completo como `LICENSE` desde GitHub (Add file > Create new file > LICENSE > Choose a license template).
