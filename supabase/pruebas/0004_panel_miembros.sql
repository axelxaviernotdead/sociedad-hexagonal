\set N '''00000000-0000-0000-0000-000000000001'''
\set C '''00000000-0000-0000-0000-000000000002'''
\set X '''00000000-0000-0000-0000-000000000003'''
begin;
-- Quién no es núcleo no usa ninguna función.
select prueba.como(:C, $$select * from nucleo_miembros()$$, false, 'común no lista miembros');
select prueba.como(:C, $$select * from nucleo_admision()$$, false, 'común no ve la admisión');
select prueba.como(:C, $$select * from admitir('a@b.com')$$, false, 'común no admite');
select prueba.como(:C, $$select dar_titulo('00000000-0000-0000-0000-000000000002', 'nucleo')$$, false, 'común no se da núcleo');
select prueba.como(:C, $$select cambiar_estado('00000000-0000-0000-0000-000000000001', 'expulsado')$$, false, 'común no expulsa');
select prueba.como(:X, $$select * from admitir('a@b.com')$$, false, 'expulsado con cargo no admite');
select prueba.como(:X, $$select cambiar_estado('00000000-0000-0000-0000-000000000003', 'activo')$$, false, 'expulsado no se readmite');
select prueba.como(null, $$select * from nucleo_miembros()$$, false, 'anónimo no lista miembros');
select prueba.como(null, $$select * from admitir('a@b.com')$$, false, 'anónimo no admite');
select prueba.como(:C, $$insert into miembro_titulos values ('00000000-0000-0000-0000-000000000002', 'nucleo')$$, false, 'común no se da núcleo por tabla');
select prueba.como(:N, $$insert into nucleo_bitacora (accion, objetivo) values ('x', 'y')$$, false, 'nadie escribe la bitácora a mano');
select prueba.como(:C, $$select anotar('x', 'y')$$, false, 'nadie llama a anotar');
select prueba.como(:N, $$select * from lista_admision$$, false, 'núcleo no lee la lista entera directo');

-- Lecturas del núcleo, sin mails de miembros.
select prueba.como(:N, $$select * from nucleo_miembros()$$, true, 'núcleo lista miembros');
select case when not exists (select 1 from information_schema.routines r join information_schema.parameters p
         on p.specific_name = r.specific_name where r.routine_name = 'nucleo_miembros' and p.parameter_name = 'email')
       then 'OK   ' else 'FALLA' end || ' nucleo_miembros no devuelve mails';
select prueba.como(:N, $$select * from nucleo_admision() where email in ('nucleo@x.com', 'comun@x.com')$$, false, 'la admisión no muestra mails de miembros');

-- Admisión en lote.
update miembros set alias = 'juan' where alias = 'comun';  -- un miembro ya usa "juan"
select prueba.como(:N, $$select * from admitir(E'Juan@a.com, juan@A.com\njuan@b.com; no-es-mail  a@x.com nucleo@x.com')$$, true, 'núcleo admite una lista');
select case when (select count(*) from lista_admision where email in ('juan@a.com', 'juan@b.com', 'a@x.com')) = 3
             and not exists (select 1 from lista_admision where email ilike 'no-es-mail%')
            then 'OK   ' else 'FALLA' end || ' entran los válidos, sin repetidos ni basura';
select case when (select alias from lista_admision where email = 'juan@a.com') = 'juan2'
             and (select alias from lista_admision where email = 'juan@b.com') = 'juan3'
             and (select alias from lista_admision where email = 'a@x.com') = 'miembroa'
            then 'OK   ' else 'FALLA' end || ' alias libres: no pisa el de un miembro ni entre sí';
select case when (select count(*) from nucleo_bitacora where accion = 'admisión' and objetivo = '3 mails') = 1
            then 'OK   ' else 'FALLA' end || ' la admisión queda en la bitácora';

-- Portal: alias de la lista tomado por un miembro que se lo cambió.
insert into lista_admision values ('nuevo@x.com', 'tomado');
update miembros set alias = 'tomado' where alias = 'juan';
insert into auth.users (id, email) values ('00000000-0000-0000-0000-000000000009', 'nuevo@x.com');
select case when (select alias from miembros where email = 'nuevo@x.com') = 'tomado2'
            then 'OK   ' else 'FALLA' end || ' entra aunque su alias lo use otro';

select prueba.como(:N, $$select quitar_admision('juan@b.com')$$, true, 'quita de la admisión a quien no entró');
select prueba.como(:N, $$select quitar_admision('comun@x.com')$$, false, 'no quita de la lista a un miembro');

-- Títulos y cargos.
select prueba.como(:N, $$select dar_titulo('00000000-0000-0000-0000-000000000002', 'utopico')$$, false, 'no da títulos derivados');
select prueba.como(:N, $$select dar_titulo('00000000-0000-0000-0000-000000000002', 'inventado')$$, false, 'no da títulos inexistentes');
select prueba.como(:N, $$select dar_titulo('00000000-0000-0000-0000-000000000002', 'musico')$$, true, 'da un título asignado');
select prueba.como(:N, $$select dar_titulo('00000000-0000-0000-0000-000000000002', 'nucleo')$$, true, 'da el cargo de núcleo');
select prueba.como(:C, $$select * from nucleo_miembros()$$, true, 'con el cargo, el otro ya usa el panel');
select prueba.como(:C, $$select sacar_titulo('00000000-0000-0000-0000-000000000001', 'nucleo')$$, true, 'núcleo saca el cargo a otro');
select prueba.como(:N, $$select * from nucleo_miembros()$$, false, 'sin el cargo, ya no usa el panel');
select prueba.como(:C, $$select sacar_titulo('00000000-0000-0000-0000-000000000002', 'nucleo')$$, false, 'nadie se saca su propio cargo de núcleo');
select case when (select count(*) from nucleo_bitacora where accion in ('dio musico', 'dio nucleo', 'sacó nucleo')) = 3
            then 'OK   ' else 'FALLA' end || ' los cambios de cargo quedan en la bitácora';

-- Expulsión (ahora el núcleo es C).
select prueba.como(:C, $$select cambiar_estado('00000000-0000-0000-0000-000000000002', 'expulsado')$$, false, 'nadie se expulsa a sí mismo');
select prueba.como(:C, $$select cambiar_estado('00000000-0000-0000-0000-000000000001', 'revision')$$, false, 'solo activo o expulsado');
select prueba.como(:C, $$select cambiar_estado('00000000-0000-0000-0000-000000000001', 'expulsado')$$, true, 'núcleo expulsa');
select prueba.como(:N, $$select * from eventos$$, false, 'el expulsado pierde el acceso');
select prueba.como(:C, $$select cambiar_estado('00000000-0000-0000-0000-000000000001', 'activo')$$, true, 'núcleo readmite');
select prueba.como(:N, $$select * from eventos$$, true, 'el readmitido vuelve a ver');
select prueba.como(:N, $$select * from nucleo_bitacora$$, false, 'un miembro común no ve la bitácora');
select prueba.como(:C, $$select * from nucleo_bitacora$$, true, 'el núcleo ve la bitácora');
rollback;
