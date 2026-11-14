\set N '''00000000-0000-0000-0000-000000000001'''
\set C '''00000000-0000-0000-0000-000000000002'''
\set X '''00000000-0000-0000-0000-000000000003'''
begin;
select prueba.como(:N, $$insert into utopias (numero, fecha) values (10, '2027-01-01 19:00-03')$$, true,  'núcleo crea utopía');
select prueba.como(:C, $$insert into utopias (numero, fecha) values (11, '2027-01-01 19:00-03')$$, false, 'común no crea utopía');
select prueba.como(:X, $$insert into utopias (numero, fecha) values (12, '2027-01-01 19:00-03')$$, false, 'expulsado con cargo no crea utopía');
select prueba.como(null, $$insert into utopias (numero, fecha) values (13, '2027-01-01 19:00-03')$$, false, 'anónimo no crea utopía');
select prueba.como(:C, $$update utopias set estado = 'realizada' where numero = 3$$, false, 'común no edita utopía');
select prueba.como(:N, $$update utopias set id = 999 where numero = 3$$, false, 'núcleo no cambia el id');
select prueba.como(:C, $$insert into eventos (fecha, titulo) values (now(), 'x')$$, false, 'común no crea evento');
select prueba.como(:C, $$update eventos set titulo = 'x'$$, false, 'común no edita eventos');
select prueba.como(:C, $$delete from eventos$$, false, 'común no borra eventos');
select prueba.como(:N, $$insert into eventos (fecha, titulo) values (now(), 'x')$$, true, 'núcleo crea evento');
select prueba.como(:N, $$update eventos set titulo = 'y' where titulo = 'x'$$, true, 'núcleo edita evento');
select prueba.como(:N, $$delete from eventos where titulo = 'y'$$, true, 'núcleo borra evento');
select prueba.como(:C, $$select * from utopia_lugar$$, false, 'común no ve lugar sin confirmar');
select prueba.como(:N, $$select * from utopia_lugar$$, true, 'núcleo ve el lugar');
select prueba.como(:C, $$update utopia_lugar set lugar = 'x'$$, false, 'común no edita lugar');
select prueba.como(:C, $$insert into utopia_lugar values ((select id from utopias where numero = 10), 'x')$$, false, 'común no carga lugar');
select prueba.como(:C, $$select guardar_utopia(null, 20, now(), 'anunciada', 'x')$$, false, 'común no usa guardar_utopia');
select prueba.como(:X, $$select guardar_utopia(null, 21, now(), 'anunciada', 'x')$$, false, 'expulsado no usa guardar_utopia');
select prueba.como(null, $$select guardar_utopia(null, 22, now(), 'anunciada', 'x')$$, false, 'anónimo no usa guardar_utopia');
select prueba.como(:N, $$delete from utopias where numero = 1$$, false, 'núcleo no borra utopía realizada');
select prueba.como(:N, $$update utopias set estado = 'anunciada' where numero = 1$$, true, 'núcleo la vuelve anunciada');
select prueba.como(:N, $$delete from utopias where numero = 1$$, false, 'igual no la borra: tiene presentaciones');
select prueba.como(:N, $$delete from utopias where numero = 10$$, true, 'núcleo borra utopía anunciada vacía');
select prueba.como(:C, $$delete from utopias where numero = 3$$, false, 'común no borra utopía');
rollback;

-- guardar_utopia: crea el evento, la fecha del evento sigue a la utopía, el detalle se conserva,
-- el título cambia solo con el número, el lugar vacío se borra.
begin;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);
set local role authenticated;
select guardar_utopia(null, 9, '2027-03-06 19:00-03', 'anunciada', '  Calle 1  ') as id \gset
select case when (select count(*) from eventos where utopia_id = :id) = 1
             and (select titulo from eventos where utopia_id = :id) = 'Utopía N°09'
             and (select lugar from utopia_lugar where utopia_id = :id) = 'Calle 1'
            then 'OK   ' else 'FALLA' end || ' alta crea evento y lugar';
update eventos set detalle = '2 presentaciones' where utopia_id = :id;
select guardar_utopia(:id, 9, '2027-03-13 19:00-03', 'anunciada', '');
select case when (select fecha from eventos where utopia_id = :id) = '2027-03-13 19:00-03'
             and (select detalle from eventos where utopia_id = :id) = '2 presentaciones'
             and not exists (select 1 from utopia_lugar where utopia_id = :id)
            then 'OK   ' else 'FALLA' end || ' edición mueve el evento, conserva el detalle y borra el lugar vacío';
select guardar_utopia(:id, 19, '2027-03-13 19:00-03', 'anunciada', null);
select case when (select titulo from eventos where utopia_id = :id) = 'Utopía N°19'
            then 'OK   ' else 'FALLA' end || ' cambio de número renombra el evento';
rollback;
