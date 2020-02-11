-- drop table some_table;
create table some_table (
  some_column varchar2(5 char)
);

declare
  v_some_table_size number(1, 0);
  v_our_log_count number(1, 0);
  v_log_message varchar2(50 char) := 'inserted into some_table';
begin
  insert into some_table(some_column) values ('1');
  log_pack.log_error('near some_table', v_log_message);
  rollback;

  select count(*)
    into v_some_table_size
    from some_table;

  select count(*)
    into v_our_log_count
    from application_log
  where al_timestamp > systimestamp - 1/24/60/60
    and al_level = 'ERROR'
    and al_message = v_log_message;

  if v_some_table_size > 0 or v_our_log_count <= 0 then
    raise_application_error(-20002, 'Something went wrong, v_some_table_size: ' || v_some_table_size || ', v_our_log_count: ' || v_our_log_count);
  end if;
end;
/
