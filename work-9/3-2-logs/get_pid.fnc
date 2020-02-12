-- as DBA

create or replace function get_pid
  return number
is
  v_pid number(10, 0);
begin
  select p.spid
  into v_pid
    from v$session s
    join v$process p on p.addr = s.paddr
  where s.sid = sys_context('USERENV', 'SID');
  return v_pid;
end;
/

grant execute on get_pid to dev;
