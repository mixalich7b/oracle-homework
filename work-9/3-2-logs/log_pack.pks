create or replace package log_pack
is

  procedure log_info (
    pi_caller in application_log.al_caller%type,
    pi_message in application_log.al_message%type,
  );

  procedure log_warn (
    pi_caller in application_log.al_caller%type,
    pi_message in application_log.al_message%type,
  );

  procedure log_error (
    pi_caller in application_log.al_caller%type,
    pi_message in application_log.al_message%type,
  );

  function is_api
    return  boolean;

  procedure clear_old_logs;

end;
/
