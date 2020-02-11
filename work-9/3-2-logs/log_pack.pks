create or replace package log_pack
is

  procedure log_info (
    pi_caller in varchar2,
    pi_message in varchar2,
    pi_stack_trace in varchar2 default null
  );

  procedure log_warn (
    pi_caller in varchar2,
    pi_message in varchar2,
    pi_stack_trace in varchar2 default null
  );

  procedure log_error (
    pi_caller in varchar2,
    pi_message in varchar2,
    pi_stack_trace in varchar2 default null
  );

  function is_api
    return  boolean;

end;
/
