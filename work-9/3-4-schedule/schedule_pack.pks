create or replace package schedule_pack
is
  
  function get_next_run_date(p_from in date, p_schedule_raw in  varchar2)
    return date;

  procedure enable_debug;
  procedure disable_debug;

end;
/
