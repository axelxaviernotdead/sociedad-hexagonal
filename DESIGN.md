# Sistema visual

El sitio se parece a la web temprana y a Wikipedia: información clara, directa, sin relleno. Técnico y estéril.
No busca captar gente ni ser simpático. Todo lo que no informa, sobra.

Los valores están definidos en `src/app.css`. No se agregan colores, tamaños, pesos, sombras ni bordes nuevos.
Si una pantalla parece necesitar uno, el problema está en la estructura, no en el estilo.

## Tipografía

- Familia: `'Helvetica Neue', Helvetica, Arial, sans-serif`. Sin fuentes web externas.
- Un solo tamaño: 15 px. Un solo interlineado: 22 px (`--linea`). Un solo peso: 500.
- Tracking: `-0.01em` en todo el sitio.
- Números tabulares en todas partes (`font-variant-numeric: tabular-nums`), para que las columnas de fechas,
  números y duraciones queden alineadas.
- `h1`, `h2` y `h3` existen por semántica y accesibilidad, pero se ven igual que el texto corrido.
- Sin mayúsculas sostenidas, sin cursiva, sin negrita.

## Color

Dos valores para el texto, nada más:

| Valor | Variable | Uso |
|---|---|---|
| Negro `#000` | `--negro` | Contenido, título de lo que se está viendo, estado actual, lo elegido, lo que sí pasó |
| Gris `#8f8f8f` | `--gris`, clase `.g` | Metadatos, rótulos, opciones no elegidas, lo que no pasó |

Ejemplos de la regla aplicada:

- Menú: la sección actual en negro, las demás en gris.
- Archivo: título en negro; número, autor, utopía, formato y duración en gris.
- Calendario: la utopía en negro, las demás actividades en gris.
- Asistencia en el registro: utopías a las que fuiste en negro, a las que no, en gris.
- Filtros del foro: el tema y el orden elegidos en negro, el resto en gris.

Superficies, siempre sin borde:

| Variable | Valor | Uso |
|---|---|---|
| `--fondo` | `#fff` | Fondo de todas las páginas |
| `--pastilla` | `#f3f3f3` | Fondo de botones |
| `--campo` | `#f6f6f6` | Fondo de campos de texto |
| `--subrayado` | `#d2d2d2` | Subrayado de enlaces |

El sitio no tiene modo oscuro ni color de acento.

## Jerarquía

Como tamaño, peso y color están fijos, la jerarquía sale de tres cosas y solo de esas:

1. **Valor:** negro o gris, con la regla de arriba.
2. **Posición:** lo que va en la columna de rótulos es rótulo; lo que va en la columna de contenido es contenido.
   El orden vertical también ordena: lo más importante va primero.
3. **Espacio:** cuánto aire hay antes de un bloque dice si es parte del anterior o una sección nueva.

Si algo no se distingue con esto, se reordena la pantalla. No se agranda nada.

## Retícula

Clase `.L`: dos columnas.

- Columna de rótulos: 200 px (`--rotulo`), a la izquierda, en gris por defecto. Lleva el nombre de la sección,
  la ruta (`foro / energía`), el número y autor de un mensaje, los temas del foro.
- Columna de contenido: el resto del ancho.
- Separación entre columnas y margen lateral: 40 px (`--margen`).
- `.L.negro` pone el rótulo en negro, para el encabezado de una página (`Registro`, `Acceso`).

Todo el texto alineado a la izquierda. Las únicas excepciones son columnas numéricas dentro de tablas
(respuestas, duraciones, antigüedad), alineadas a la derecha con `td.d`, y la portada de acceso sin sesión
(nombre, campo de mail y botón centrados en la pantalla, sin cabecera).

Párrafos con un ancho máximo de 760 px (`.texto`).

## Espacio vertical

Solo en múltiplos del interlineado:

| Clase | Espacio | Uso |
|---|---|---|
| `.e1` | 22 px, una línea | Entre elementos relacionados: mensajes de un hilo, campos de un formulario |
| `.e2` | 44 px, dos líneas | Entre secciones de una página |
| `.e3` | 66 px, tres líneas | Entre la cabecera del sitio y el contenido |

Nada de márgenes arbitrarios. Si hace falta media línea (por ejemplo, entre un campo y su botón), se usa 11 px,
y solo ahí.

## Sin líneas

No hay reglas, bordes, separadores, cajas ni sombras. Ni en tablas, ni en la cabecera, ni en el reproductor,
ni en los formularios. Tampoco fondos de color para destacar filas: la fila activa se marca en negro sobre gris
o con un `▶` delante.

## Enlaces

Mismo color que el texto que los rodea (negro o gris), subrayado en `--subrayado` con 3 px de separación.
Al pasar el mouse, el subrayado toma el color del texto. Sin flechas, sin íconos de enlace externo.

Un enlace que lleva a otra página es un enlace. Una acción que cambia algo (guardar, confirmar, publicar)
es un botón. Si una acción tiene que verse como texto (`responder`, `cambiar`, `salir`), es un `button`
con estilo de enlace, nunca un `a`.

## Botones

Pastilla gris claro: fondo `--pastilla`, texto en gris, radio de 8 px, alto de una línea (22 px), 12 px a los lados.
Pasan desapercibidos a propósito. Al pasar el mouse, el texto se pone negro.

Un botón elegido (`asistiré` cuando ya confirmaste) lleva la clase `.activo`: texto negro, mismo fondo.

Texto del botón en minúscula y con el verbo de lo que hace: `asistiré`, `publicar`, `enviar enlace`, `guardar`.
Nunca "enviar" a secas cuando se puede decir qué se envía.

## Campos

Fondo `--campo`, sin borde, radio de 8 px, 6 px de alto y 12 px de lado. Ancho máximo 640 px.
El placeholder, en gris, describe el formato esperado (`nombre@dominio.com`, `Texto plano. Para citar: >>número.`).
Las etiquetas van en la columna de rótulos o, si no hay lugar, ocultas para pantalla y presentes para lectores
de pantalla (`.oculto`).

## Tablas y listas

Casi todo el contenido son listas: archivo, foro, calendario, actas. Se arman como tablas sin encabezados
visibles cuando el contenido se explica solo, y con la primera columna gris para números o fechas.

- Separación entre columnas: 32 px.
- Números con ceros a la izquierda: presentaciones con tres cifras (`023`), mensajes con cuatro (`0002`),
  utopías con dos (`N°07`).
- Fechas `05.12.2026`, día abreviado `sáb`, horas `19:00`. Duraciones `00:42:07`. Antigüedad `5 h`, `3 d`.
- Una tabla que no entra en pantalla se desplaza horizontalmente dentro de `.tabla`, no rompe la página.

## Textos

- Descriptivos y secos. Dicen qué es o qué pasa. Sin adjetivos de venta, sin tono cálido, sin signos de exclamación.
- Minúscula en navegación, botones, filtros y rótulos de datos (`archivo`, `foro`, `nuevo hilo`, `miembro desde`).
  Mayúscula inicial en oraciones y en títulos de página.
- Vacíos y errores dicen qué pasa y, si corresponde, qué hacer: `No hay hilos sobre música.`,
  `Ese alias ya está en uso.` Sin disculpas.
- El sitio no habla de sí mismo ni del sistema por dentro: "enlace de acceso", no "magic link".

## Lo que no hay

Íconos, imágenes decorativas, ilustraciones, logos gráficos, animaciones, transiciones, modales, toasts,
tooltips, avatares, contadores de "me gusta", insignias, colores de estado, perfiles públicos de usuario.

El nombre "Sociedad Hexagonal" en texto es la única marca.

## Teléfono

Por debajo de 760 px:

- La retícula pasa a una columna: el rótulo queda arriba del contenido, separado por una línea.
- Margen lateral de 20 px.
- Columnas secundarias de las tablas (formato, tema, autor) se ocultan con `.solo-ancho`.
- La lista de temas del foro pasa de columna a fila.

Probar cada pantalla nueva a 375 px de ancho antes de darla por terminada.

## Accesibilidad

- Foco visible: contorno negro de 2 px en todo elemento enfocable. No quitarlo.
- `aria-current="page"` en la sección actual del menú.
- Todo campo con etiqueta, visible u oculta.
- El gris sobre blanco tiene un contraste de 3,3:1. Se acepta para metadatos; el contenido principal va siempre en negro.

## Al agregar una pantalla

1. Partir de la retícula `.L`: qué va en la columna de rótulos, qué en la de contenido.
2. Decidir qué es contenido (negro) y qué es metadato u opción (gris).
3. Separar con `.e1`, `.e2`, `.e3`.
4. Usar las clases existentes. Si hace falta CSS nuevo, va en un `<style>` del componente y solo para posición
   o tamaño de layout, nunca para tipografía ni color.
5. Revisar a 1440 px y a 375 px.
