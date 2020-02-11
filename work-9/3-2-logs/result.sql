--  application_log.tbl

-- drop table application_log;
create table application_log (
  al_timestamp timestamp not null,
  al_level varchar2(10 char) not null,
  al_stack_trace varchar2(4000 char),
  al_caller varchar2(500 char) not null,
  al_message varchar2(1000 char) not null,
  al_sid number(10, 0) not null,
  -- al_pid number (10, 0) not null, -- не нашёл, как вытащить pid не имея доступа  к v$process
  al_osuser varchar2(200 char) not null,
  al_oracle_user varchar2(200 char) not null
)
partition  by range (al_timestamp) interval (numtodsinterval(1, 'DAY'))
subpartition by list (al_level) -- предположим, нам  часто требуется искать все сообщения с определённым уровнем
subpartition template (
  subpartition application_log_info values ('INFO'),
  subpartition application_log_warn values ('WARN'),
  subpartition application_log_error values ('ERROR')
)
(partition application_log_before_2020 values less than (to_date('01-01-2020','DD-MM-YYYY'))
);

alter table application_log add constraint al_level_ck check (al_level in ('INFO', 'WARN', 'ERROR'));

create index application_log_timestamp_i on application_log (al_timestamp) local;

comment on table application_log is 'Логи приложения';
comment on column application_log.al_timestamp is 'Время вставки записи в лог';
comment on column application_log.al_level is 'Уровень логирования (тип сообщения) - INFO, WARN, ERROR';
comment on column application_log.al_stack_trace is 'Стек вызова';
comment on column application_log.al_caller is 'Место/название модуля/класса из которого произошла запись сообщения в лог';
comment on column application_log.al_message is 'Сообщение';
comment on column application_log.al_sid is 'Id сессии';
--  comment on column application_log.al_pid is 'Id пользовательского процесса';
comment on column application_log.al_osuser is 'Имя пользователя в операционной системе клиента';
comment on column application_log.al_oracle_user is 'Имя пользователя в БД';


-- test1.sql

-- посмотрим, что партиции нарежутся после вставки рандомных данных
declare
  v_sid number(10, 0);
  v_osuser varchar(200);
  v_oracle_user varchar(200);
begin

  v_sid := sys_context('USERENV', 'SID');
  v_osuser := sys_context('USERENV', 'OS_USER');
  v_oracle_user := sys_context('USERENV', 'CURRENT_USER');

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
    v_osuser,
    v_oracle_user
  from dual
  connect by level < 100000;
end;
/

select * from user_tab_partitions t where t.table_name = 'APPLICATION_LOG';


-- log_pack.pks

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


-- log_pack.pkb

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


-- application_log_b_iu.trg

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


-- test2.sql

-- drop table some_table;
create table some_table (
  some_column varchar2(5 char)
);

declare
  v_some_table_size number(1, 0);
  v_our_log_count number(1, 0);
  v_log_message varchar2(50 char) := 'inserted into some_table';
begin

  -- проверим, что при откате транзакции запись в логе остаётся
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
