-- Datos de ejemplo para probar el sitio. No usar en producción.
insert into public.utopias (numero, fecha, estado) values
  (1, '2025-10-18 19:00-03', 'realizada'),
  (2, '2025-12-13 19:00-03', 'realizada'),
  (3, '2026-12-05 19:00-03', 'anunciada');
insert into public.utopia_lugar values ((select id from public.utopias where numero = 3), 'Dirección a definir');
insert into public.eventos (fecha, titulo, detalle, utopia_id) values
  ('2026-11-14 16:00-03', 'Ensayo técnico de grabación', 'operadores y músicos', null),
  ('2026-11-21 12:00-03', 'Cierre de propuestas para N°03', null, null),
  ('2026-12-05 19:00-03', 'Utopía N°03', '3 presentaciones', (select id from public.utopias where numero = 3));
insert into public.presentaciones (numero, utopia_id, titulo, resumen, duracion_s, temas, visibilidad, capitulos) values
  (1, (select id from public.utopias where numero = 1), 'Apertura', 'Presentación de la idea de las utopías.', 482, '{organización}', 'publico', '[]'),
  (2, (select id from public.utopias where numero = 1), 'Qué mundo queremos ver', null, 1188, '{}', 'miembros', '[{"t":0,"titulo":"Inicio"},{"t":600,"titulo":"Preguntas"}]'),
  (3, (select id from public.utopias where numero = 2), 'Escuchar el silencio', null, 1720, '{música,sentidos}', 'miembros', '[]');
