create or replace package log_pack
is

  procedure log_info (
    pi_caller in application_log.al_caller%type,
    pi_message in application_log.al_message%type,
    pi_stack_trace in application_log.al_stack_trace%type default null
  );

  procedure log_warn (
    pi_caller in application_log.al_caller%type,
    pi_message in application_log.al_message%type,
    pi_stack_trace in application_log.al_stack_trace%type default null
  );

  procedure log_error (
    pi_caller in application_log.al_caller%type,
    pi_message in application_log.al_message%type,
    pi_stack_trace in application_log.al_stack_trace%type default null
  );

  function is_api
    return  boolean;

end;
/
