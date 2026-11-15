\set C '''00000000-0000-0000-0000-000000000002'''
\set X '''00000000-0000-0000-0000-000000000003'''
begin;
select prueba.como(:C, $$select abrir_hilo('Un hilo sin tema', 'Primer mensaje')$$, true, 'miembro abre un hilo con título y cuerpo');
select case when (select tema from hilos where titulo = 'Un hilo sin tema') is null
             and (select count(*) from mensajes m join hilos h on h.id = m.hilo_id where h.titulo = 'Un hilo sin tema') = 1
            then 'OK   ' else 'FALLA' end || ' el hilo queda sin tema y con su primer mensaje';
select prueba.como(:X, $$select abrir_hilo('x', 'y')$$, false, 'expulsado no abre hilos');
select prueba.como(null, $$select abrir_hilo('x', 'y')$$, false, 'anónimo no abre hilos');
select prueba.como(:C, $$select abrir_hilo('xx', 'y')$$, false, 'título de menos de 3 caracteres');
select prueba.como(:C, $$select abrir_hilo('Con tema, como antes', 'energía', 'cuerpo')$$, true, 'la versión de tres argumentos sigue andando');
rollback;
