-- посмотрим, что партиции нарежутся после вставки рандомных данных
declare
  v_sid number(10, 0);
  v_pid number(10, 0);
  v_osuser varchar(200);
  v_oracle_user varchar(200);
begin

  v_sid := sys_context('USERENV', 'SID');
  v_pid := get_pid();
  v_osuser := sys_context('USERENV', 'OS_USER');
  v_oracle_user := sys_context('USERENV', 'CURRENT_USER');

  insert into dev.application_log (
    al_timestamp,
    al_level,
    al_stack_trace,
    al_caller,
    al_message,
    al_sid,
    al_pid,
    al_osuser,
    al_oracle_user
  )
  select 
    systimestamp + round(dbms_random.value(-40, 40)), -- al_timestamp
    case round(dbms_random.value(1, 3))
      when 1 then 'INFO'
      when 2 then 'WARN'
      else 'ERROR'
    end, -- al_level
    null, -- al_stack_trace
    dbms_random.string('L',trunc(dbms_random.value(3, 30))), -- al_caller
    dbms_random.string('L',trunc(dbms_random.value(3, 300))), -- al_message
    v_sid,
    v_pid,
    v_osuser,
    v_oracle_user
  from dual
  connect by level < 100000;
end;
/



select * from user_tab_partitions t where t.table_name = 'APPLICATION_LOG';
