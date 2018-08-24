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
    dbms_utility.comma_to_table(list => v_list, tablen => v_len, tab => v_tbl);

    for i in 1 .. v_len
    loop
        dbms_output.put_line('=== Enable constraints for ' || v_tbl(i));

        for c in (select *
                    from (select owner
                                ,table_name
                                ,constraint_name
                                ,constraint_type
                            from dba_constraints
                           where owner = v_tbl(i)
                          minus
                          select owner
                                ,table_name
                                ,constraint_name
                                ,constraint_type
                            from save_consts_state)
                   order by decode(constraint_type, 'P', 1, 'U', 2, 'R', 3, 4))
        loop
            begin
                v_sql := 'alter table ' || c.owner || '.' || c.table_name || ' enable constraint ' || c.constraint_name;
                execute immediate v_sql;
            exception
                when others then
                    begin
                        v_sql := 'alter table ' || c.owner || '.' || c.table_name || ' enable novalidate constraint ' || c.constraint_name;
                        execute immediate v_sql;
                    exception
                        when others then
                            dbms_output.put_line(v_sql);
                            dbms_output.put_line(sqlerrm);
                    end;
            end;
        end loop;

        dbms_output.put_line('=== Enable indexes for ' || v_tbl(i));
        for c in (select i.owner
                        ,i.index_name
                        ,p.partition_name
                    from dba_indexes        i
                        ,dba_ind_partitions p
                   where i.owner = v_tbl(i)
                     and i.owner = p.index_owner(+)
                     and i.index_name = p.index_name(+)
                     and i.uniqueness = 'NONUNIQUE'
                     and i.index_type <> 'LOB')
        loop
            begin
                v_sql := 'alter index ' || c.owner || '.' || c.index_name || ' rebuild';
                if c.partition_name is not null then
                    v_sql := v_sql || ' partition ' || c.partition_name;
                end if;
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
                dbms_output.put_line('=== Enable job ' || c.j);
                dbms_scheduler.enable(c.j);
            exception
                when others then
                    dbms_output.put_line(sqlerrm);
            end;
        end loop;
    end loop;
end;
/
