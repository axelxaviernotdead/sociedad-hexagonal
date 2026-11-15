\set N '''00000000-0000-0000-0000-000000000001'''
\set C '''00000000-0000-0000-0000-000000000002'''
\set X '''00000000-0000-0000-0000-000000000003'''
begin;
-- Una nota de cada uno, cargada como administrador.
insert into libro_notas (autor_id, texto) values (:N, 'nota del núcleo'), (:C, 'nota de comun');

select prueba.como(:C, $$insert into libro_notas (texto) values ('hola')$$, true, 'miembro escribe');
select prueba.como(:C, $$insert into libro_notas (autor_id, texto) values ('00000000-0000-0000-0000-000000000001', 'x')$$, false, 'no escribe a nombre de otro');
select prueba.como(:X, $$insert into libro_notas (texto) values ('x')$$, false, 'expulsado no escribe');
select prueba.como(null, $$insert into libro_notas (texto) values ('x')$$, false, 'anónimo no escribe');
select prueba.como(null, $$select * from libro_notas$$, false, 'anónimo no lee');
select prueba.como(:X, $$select * from libro_notas$$, false, 'expulsado no lee');
select prueba.como(:C, $$select * from libro_notas$$, true, 'miembro lee');
select prueba.como(:C, $$insert into libro_notas (texto) values ('   ')$$, false, 'texto vacío');
select prueba.como(:C, $$insert into libro_notas (texto) values (repeat('a', 281))$$, false, 'texto de más de 280');

select prueba.como(:C, $$update libro_notas set x = 0.1, y = 0.9 where texto = 'nota de comun'$$, true, 'mueve la propia');
select prueba.como(:C, $$update libro_notas set x = 0.1 where texto = 'nota del núcleo'$$, false, 'no mueve la ajena');
select prueba.como(:C, $$update libro_notas set texto = 'x' where texto = 'nota del núcleo'$$, false, 'no edita la ajena');
select prueba.como(:N, $$update libro_notas set x = 0.1 where texto = 'nota de comun'$$, false, 'el núcleo tampoco mueve la ajena');
select prueba.como(:C, $$update libro_notas set x = 1.5 where texto = 'nota de comun'$$, false, 'posición fuera del tablero');
select prueba.como(:C, $$update libro_notas set color = '#ff0000' where texto = 'nota de comun'$$, false, 'color fuera de la lista');
select prueba.como(:C, $$update libro_notas set fuente = 'x;} body{display:none' where texto = 'nota de comun'$$, false, 'fuente fuera de la lista');
select prueba.como(:C, $$update libro_notas set color = 'rojo', fuente = 'mono' where texto = 'nota de comun'$$, true, 'cambia color y fuente de la propia');
select prueba.como(:C, $$update libro_notas set autor_id = '00000000-0000-0000-0000-000000000001' where texto = 'nota de comun'$$, false, 'no cambia el autor');
select prueba.como(:C, $$update libro_notas set creado = '2000-01-01' where texto = 'nota de comun'$$, false, 'no cambia la fecha');

select prueba.como(:C, $$delete from libro_notas where texto = 'nota del núcleo'$$, false, 'no borra la ajena');
select prueba.como(:X, $$delete from libro_notas where texto = 'nota de comun'$$, false, 'expulsado con cargo no modera');
select prueba.como(:N, $$delete from libro_notas where texto = 'nota de comun'$$, true, 'el núcleo borra cualquiera');
select prueba.como(:C, $$delete from libro_notas where texto = 'hola'$$, true, 'borra la propia');

-- Tope de 20 notas por miembro.
insert into libro_notas (autor_id, texto) select :C, 'n' || i from generate_series(1, 19) i;
select prueba.como(:C, $$insert into libro_notas (texto) values ('vigésima')$$, true, 'la nota 20 entra');
select prueba.como(:C, $$insert into libro_notas (texto) values ('vigesimoprimera')$$, false, 'la nota 21 no entra');
rollback;
