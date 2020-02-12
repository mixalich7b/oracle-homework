create or replace package body log_pack
is

  g_is_api boolean := FALSE;

  procedure add_log_entry (
    pi_level in varchar2,
    pi_caller in application_log.al_caller%type,
    pi_message in application_log.al_message%type,
    pi_stack_trace in application_log.al_stack_trace%type default null
  )
  is
    pragma autonomous_transaction;
    v_sid number(10, 0);
    v_pid number(10, 0);
  begin
    g_is_api := TRUE;

    v_sid := sys_context('USERENV', 'SID');
    select p.spid
    into v_pid
      from v$session s
      join v$process p on p.addr = s.paddr
    where s.sid = v_sid;

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
    values (
      systimestamp,
      pi_level,
      substr(pi_stack_trace, 1, 4000),
      substr(pi_caller, 1, 500),
      substr(pi_message, 1, 1000),
      v_sid,
      v_pid
      sys_context('USERENV', 'OS_USER'),
      sys_context('USERENV', 'CURRENT_USER')
    );
    g_is_api := FALSE;
    commit;
  exception
    when other then
      g_is_api := FALSE;
  end;

  procedure log_info (
    pi_caller in application_log.al_caller%type,
    pi_message in application_log.al_message%type
  )
  is
  begin
    add_log_entry('INFO', pi_caller, pi_message);
  end;

  procedure log_warn (
    pi_caller in application_log.al_caller%type,
    pi_message in application_log.al_message%type,
  )
  is
  begin
    add_log_entry('WARN', pi_caller, pi_message, dbms_utility.format_error_stack || dbms_utility.format_error_backtrace);
  end;

  procedure log_error (
    pi_caller in application_log.al_caller%type,
    pi_message in application_log.al_message%type,
  )
  is
  begin
    add_log_entry('ERROR', pi_caller, pi_message, dbms_utility.format_error_stack || dbms_utility.format_error_backtrace);
  end;

  function is_api
    return  boolean
  is
  begin
    return g_is_api;
  end;

  procedure clear_old_logs
  is
    v_partition_max_timestamp timestamp;
  begin
    for v_p in (
      select partition_name, high_value
        from user_tab_partitions
      where table_name = 'APPLICATION_LOG'
        and partition_name <> 'APPLICATION_LOG_BEFORE_2020')
    loop
      -- парсим timestamp исполняя его запись как динамический SQL
      execute immediate 'select ' || v_p.high_value || ' from dual' into v_partition_max_timestamp;
      if v_partition_max_timestamp <= systimestamp - 30 then
        execute immediate 'alter table APPLICATION_LOG drop partition ' || v_p.partition_name;
      end if;
    end loop;
  end;

end;
/
