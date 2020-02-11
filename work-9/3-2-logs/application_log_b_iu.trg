create or replace trigger application_log_b_iu
  before insert or update
  on application_log
  for each row
begin
  if updating then
    raise_application_error(-20001, 'Logs are not modifiable');
  end if;
  if not log_pack.is_api then
    raise_application_error(-20002, 'Use log_pack');
  end if;
end;
/