-- set serveroutput on size unlimited
-- set linesize 120
-- set timing on
-- set verify off

declare
    v_tbl  dbms_utility.uncl_array;
    v_len  binary_integer;
    v_list varchar2(32000) := '@DB_USER@';
    v_sql  varchar2(32000);
begin
    dbms_output.put_line('=== Save constraints state');
    for c in (select 1 from user_tables where table_name = 'SAVE_CONSTS_STATE')
    loop
        execute immediate 'drop table save_consts_state purge';
    end loop;
    execute immediate q'[create table save_consts_state as
    select t.owner, t.constraint_name,t.table_name, t.constraint_type from dba_constraints t where status = 'DISABLED']';

    dbms_utility.comma_to_table(list => v_list, tablen => v_len, tab => v_tbl);
    for i in 1 .. v_len
    loop
        dbms_output.put_line('=== Disable constraints for ' || v_tbl(i));
        for c in (select c.owner
                        ,c.table_name
                        ,c.constraint_name
                    from dba_constraints c
                        ,dba_tables      t
                   where c.owner = v_tbl(i)
                     and t.owner = v_tbl(i)
                     and t.table_name = c.table_name
                     and t.temporary = 'N'
                   order by decode(c.constraint_type, 'R', 1, 'P', 2, 'U', 3, 4))
        loop
            begin
                v_sql := 'alter table ' || c.owner || '."' || c.table_name || '" disable constraint "' || c.constraint_name || '"';
                execute immediate v_sql;
            exception
                when others then
                    dbms_output.put_line(v_sql);
                    dbms_output.put_line(sqlerrm);
            end;
        end loop;
        dbms_output.put_line('=== Unusable indexes for ' || v_tbl(i));
        for c in (select owner
                        ,index_name
                    from dba_indexes
                   where owner = v_tbl(i)
                     and uniqueness = 'NONUNIQUE'
                     and index_type <> 'LOB')
        loop
            begin
                v_sql := 'alter index ' || c.owner || '."' || c.index_name || '" unusable';
                execute immediate v_sql;
            exception
                when others then
                    dbms_output.put_line(v_sql);
                    dbms_output.put_line(sqlerrm);
            end;
        end loop;

        for c in (select t.owner || '.' || t.job_name j from dba_scheduler_jobs t where t.owner = v_tbl(i))
        loop
            begin
                dbms_output.put_line('=== Disable job ' || c.j);
                begin
                    dbms_scheduler.stop_job(c.j,true);
                exception
                    when others then null;
                end;
                dbms_scheduler.disable(c.j,true);
            exception
                when others then
                    dbms_output.put_line(sqlerrm);
            end;
        end loop;
    end loop;
end;
/
