-- Tres usuarios de prueba: núcleo activo, miembro común, y expulsado que conserva el cargo.
insert into lista_admision values ('nucleo@x.com','nucleo'),('comun@x.com','comun'),('expulsado@x.com','expulsado');
insert into auth.users (id,email) values
 ('00000000-0000-0000-0000-000000000001','nucleo@x.com'),
 ('00000000-0000-0000-0000-000000000002','comun@x.com'),
 ('00000000-0000-0000-0000-000000000003','expulsado@x.com');
insert into miembro_titulos values ('00000000-0000-0000-0000-000000000001','nucleo'),('00000000-0000-0000-0000-000000000003','nucleo');
update miembros set estado='expulsado' where alias='expulsado';
