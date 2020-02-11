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
  begin
    g_is_api := TRUE;
    insert into dev.application_log (
      al_timestamp,
      al_level,
      al_stack_trace,
      al_caller,
      al_message,
      al_sid,
      al_osuser,
      al_oracle_user
    )
    values (
      systimestamp,
      pi_level,
      substr(pi_stack_trace, 1, 4000),
      substr(pi_caller, 1, 500),
      substr(pi_message, 1, 1000),
      sys_context('USERENV', 'SID'),
      sys_context('USERENV', 'OS_USER'),
      sys_context('USERENV', 'CURRENT_USER')
    );
    g_is_api := FALSE;
    commit;
  end;

  procedure log_info (
    pi_caller in application_log.al_caller%type,
    pi_message in application_log.al_message%type,
    pi_stack_trace in application_log.al_stack_trace%type default null
  )
  is
  begin
    add_log_entry('INFO', pi_caller, pi_message, pi_stack_trace);
  end;

  procedure log_warn (
    pi_caller in application_log.al_caller%type,
    pi_message in application_log.al_message%type,
    pi_stack_trace in application_log.al_stack_trace%type default null
  )
  is
  begin
    add_log_entry('WARN', pi_caller, pi_message, pi_stack_trace);
  end;

  procedure log_error (
    pi_caller in application_log.al_caller%type,
    pi_message in application_log.al_message%type,
    pi_stack_trace in application_log.al_stack_trace%type default null
  )
  is
  begin
    add_log_entry('ERROR', pi_caller, pi_message, pi_stack_trace);
  end;

  function is_api
    return  boolean
  is
  begin
    return g_is_api;
  end;

end;
/
