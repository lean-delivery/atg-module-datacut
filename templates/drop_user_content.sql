declare
stringa varchar2(100);

cursor cur is
select *
from user_objects where object_name not in (@SAVED_TABLES@) and object_type not in ('INDEX');

cursor ind is
select * from user_indexes where table_name not in (@SAVED_TABLES@);

begin
for c in cur loop
begin
stringa := '';

if c.object_type = 'VIEW' then

stringa := 'drop view ' || c.object_name;
EXECUTE immediate stringa; 

elsif c.object_type = 'TABLE' then

stringa := 'drop table "' || c.object_name || '" cascade constraints'; 
EXECUTE immediate stringa; 
     
elsif c.object_type = 'SEQUENCE' then

stringa := 'drop sequence ' || c.object_name; 
EXECUTE immediate stringa; 
elsif c.object_type = 'PACKAGE' then

stringa := 'drop package ' || c.object_name; 
EXECUTE immediate stringa;      

elsif c.object_type = 'TRIGGER' then

stringa := 'drop trigger ' || c.object_name; 
EXECUTE immediate stringa;      

elsif c.object_type = 'PROCEDURE' then

stringa := 'drop procedure ' || c.object_name; 
EXECUTE immediate stringa; 

elsif c.object_type = 'FUNCTION' then

stringa := 'drop function ' || c.object_name; 
EXECUTE immediate stringa;      
elsif c.object_type = 'SYNONYM' then

stringa := 'drop synonym ' || c.object_name; 
EXECUTE immediate stringa; 
elsif c.object_type = 'PACKAGE BODY' then

stringa := 'drop PACKAGE BODY ' || c.object_name; 
EXECUTE immediate stringa;      
elsif c.object_type = 'DATABASE LINK' then

stringa := 'drop database link ' || c.object_name; 
EXECUTE immediate stringa;      
end if;
     
     exception
when others then
null;
end; 
end loop;

for c in ind loop
begin
stringa := 'drop index "' || c.index_name || '"';
EXECUTE immediate stringa; 
end; 
end loop;

begin
EXECUTE immediate 'purge recyclebin';
end;
end;
/
