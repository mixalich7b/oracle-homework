-- t_numbers.tps
create or replace type t_numbers force as table of number(2, 0);
/

-- t_schedule.tps
-- расписание состоит из коллекции для каждой единицы:
-- месяц года, день месяца и тд.
create or replace type t_schedule force as object(
  -- если минута есть в расписании, то её номер будет в коллекции
  minutes t_numbers,
  -- если месяц есть в расписании, то его номер будет в коллекции
  hours t_numbers,
  -- и тд
  weekdays t_numbers,
  days t_numbers,
  months t_numbers
);
/

-- date_utils_pack.pks
create or replace package date_utils_pack
is

  e_not_valid_day_of_month exception;

  -- извлекает номер года из даты
  function extract_year(p_date in date)
    return number;

  -- извлекает номер месяца из даты
  function extract_month(p_date in date)
    return number;

  -- извлекает номер дня недели из даты
  function extract_weekday(p_date in date)
    return number;

  -- извлекает номер дня из даты
  function extract_day(p_date in date)
    return number;

  -- извлекает номер часа из даты
  function extract_hour(p_date in date)
    return number;

  -- возвращает ближайшую круглую минуту в рамках текущего часа
  -- возвращает -1 если такой минуты в рамках текущего часа нет (например в 15:59:01)
  function extract_nearest_minute(p_date in date)
    return number;

  -- возвращает дату соответствующую началу указанного года
  function start_of_year(p_year in number)
    return date;

  -- возвращает дату соответствующую началу указанного месяца p_month
  -- сохраняя год
  function start_of_month(p_date in date, p_month in number)
    return date;

  -- возвращает дату соответствующую началу указанного дня,
  -- сохраняя год и месяц
  -- если заданный день не существует в этом месяце,
  -- то будет  выброшено исключение e_not_valid_day_of_month
  function start_of_day(p_date in date, p_day in number)
    return date;

  -- возвращает дату соответствующую началу указанного часа
  -- сохраняя день
  function start_of_hour(p_date in date, p_hour in number)
    return date;

  -- возвращает дату соответствующую началу указанной минуты
  -- сохраняя час
  function start_of_minute(p_date in date, p_minute in number)
    return date;

end;
/

-- date_utils_pack.pkb
create or replace package body date_utils_pack
is

  function extract_year(p_date in date)
    return number
  is
  begin
    return extract(year from p_date);
  end;

  function extract_month(p_date in date)
    return number
  is
  begin
    return extract(month from p_date);
  end;

  function extract_weekday(p_date in date)
    return number
  is
  begin
    return to_number(to_char(p_date, 'd'));
  end;

  function extract_day(p_date in date)
    return number
  is
  begin
    return extract(day from p_date);
  end;

  function extract_hour(p_date in date)
    return number
  is
  begin
    return extract(hour from cast(p_date as timestamp));
  end;

  function extract_nearest_minute(p_date in date)
    return number
  is
    v_nearest_minute number;
    v_timestamp timestamp;
  begin
    v_timestamp := cast(p_date as timestamp);
    -- текущую минуту не берём, если она уже началась
    -- считаем, что ближайший запуск должен быть в 00 секунд
    if extract (second from v_timestamp) = 0 then
      return extract(minute from v_timestamp);
    end if;
    v_nearest_minute := extract(minute from cast(v_timestamp+1/24/60 as timestamp));
    -- получим 0, если ближайшая минута будет уже в следующем часе
    if v_nearest_minute = 0 then
      return -1;
    else
      return v_nearest_minute;
    end if;
  end;

  function start_of_year(p_year in number)
    return date
  is
  begin
    return to_date(p_year || '0101', 'YYYYMMDD');
  end;

  function start_of_month(p_date in date, p_month in number)
    return date
  is
    v_current_year number;
    v_current_month number;
  begin
    v_current_year := date_utils_pack.extract_year(p_date);
    v_current_month := date_utils_pack.extract_month(p_date);
    return trunc(add_months(p_date, p_month-v_current_month), 'MM');
  end;

  function start_of_day(p_date in date, p_day in number)
    return date
  is
    v_current_year number;
    v_current_month varchar2(2 char);

    e_not_valid_date_for_month exception;
    pragma exception_init(e_not_valid_date_for_month, -01839);
  begin
    v_current_year := date_utils_pack.extract_year(p_date);
    v_current_month := to_char(p_date, 'MM');
    return to_date(v_current_year || v_current_month || p_day, 'YYYYMMDD');
  exception
    when e_not_valid_date_for_month then
      raise e_not_valid_day_of_month;
  end;

  function start_of_hour(p_date in date, p_hour in number)
    return date
  is
    v_current_year number;
    v_current_month varchar2(2 char);
    v_current_day varchar2(2 char);
  begin
    v_current_year := date_utils_pack.extract_year(p_date);
    v_current_month := to_char(p_date, 'MM');
    v_current_day := to_char(p_date, 'DD');
    return to_date(v_current_year || v_current_month || v_current_day || p_hour, 'YYYYMMDDHH24');
  end;

  function start_of_minute(p_date in date, p_minute in number)
    return date
  is
    v_current_year number;
    v_current_month varchar2(2 char);
    v_current_day varchar2(2 char);
    v_current_hour varchar2(2 char);
  begin
    v_current_year := date_utils_pack.extract_year(p_date);
    v_current_month := to_char(p_date, 'MM');
    v_current_day := to_char(p_date, 'DD');
    v_current_hour := to_char(p_date, 'HH24');
    return to_date(v_current_year || v_current_month || v_current_day || v_current_hour || p_minute, 'YYYYMMDDHH24MI');
  end;

end;
/


-- schedule_utils_pack.pks
create or replace package schedule_utils_pack
is

  -- проверяет, есть ли месяц в расписании
  function contains_month(p_month in number, p_schedule in t_schedule)
    return boolean;

  -- проверяет, есть ли день в расписании
  function contains_day_of_month(p_day_of_month in number,  p_schedule in t_schedule)
    return boolean;

  -- проверяет, есть ли день недели в расписании
  function contains_weekday(p_day_of_week in number, p_schedule in t_schedule)
    return boolean;

  -- проверяет, есть ли час в расписании
  function contains_hour(p_hour in number, p_schedule in t_schedule)
    return boolean;

  -- проверяет, есть ли минута в расписании
  function contains_minute(p_minute in number, p_schedule in t_schedule)
    return boolean;

  -- находит следующий ближайший месяц по расписанию
  -- возвращает номер месяца либо -1 если больше подходящих месяцев в расписании нет
  function next_month_in_schedule(p_current_month in number, p_schedule in t_schedule)
    return number;

  -- находит следующий ближайший день по расписанию
  -- возвращает номер дня либо -1 если больше подходящих дней в расписании нет
  function next_day_in_schedule(p_current_day in number, p_schedule in t_schedule)
    return number;

  -- находит следующий ближайший час по расписанию
  -- возвращает номер часа либо -1 если больше подходящих часов в расписании нет
  function next_hour_in_schedule(p_current_hour in number, p_schedule in t_schedule)
    return number;

  -- находит следующую ближайшую минуту по расписанию
  -- возвращает номер минуты либо -1 если больше подходящих минут в расписании нет
  function next_minute_in_schedule(p_current_minute in number, p_schedule in t_schedule)
    return number;

end;
/

-- schedule_utils_pack.pkb
create or replace package body schedule_utils_pack
is

  function contains_month(p_month in number, p_schedule in t_schedule)
    return boolean
  is
  begin
    if p_month member of p_schedule.months then
      return TRUE;
    else
      return FALSE;
    end if;
  end;

  function contains_day_of_month(p_day_of_month in number,  p_schedule in t_schedule)
    return boolean
  is
  begin
    if p_day_of_month member of p_schedule.days then
      return TRUE;
    else
      return FALSE;
    end if;
  end;

  function contains_weekday(p_day_of_week in number, p_schedule in t_schedule)
    return boolean
  is
  begin
    if p_day_of_week member of p_schedule.weekdays then
      return TRUE;
    else
      return FALSE;
    end if;
  end;

  function contains_hour(p_hour in number, p_schedule in t_schedule)
    return boolean
  is
  begin
    if p_hour member of p_schedule.hours then
      return TRUE;
    else
      return FALSE;
    end if;
  end;

  function contains_minute(p_minute in number, p_schedule in t_schedule)
    return boolean
  is
  begin
    if p_minute member of p_schedule.minutes then
      return TRUE;
    else
      return FALSE;
    end if;
  end;

  function next_month_in_schedule(p_current_month in number, p_schedule in t_schedule)
    return number
  is
  begin
    for idx in p_schedule.months.first .. p_schedule.months.last
    loop
      if p_schedule.months(idx) > p_current_month then
        return p_schedule.months(idx);
      end if;
    end loop;

    return -1;
  end;

  function next_day_in_schedule(p_current_day in number, p_schedule in t_schedule)
    return  number
  is
  begin
    for idx in p_schedule.days.first .. p_schedule.days.last
    loop
      if p_schedule.days(idx) > p_current_day then
        return p_schedule.days(idx);
      end if;
    end loop;

    return -1;
  end;

  function next_hour_in_schedule(p_current_hour in number, p_schedule in t_schedule)
    return number
  is
  begin
    for idx in p_schedule.hours.first .. p_schedule.hours.last
    loop
      if p_schedule.hours(idx) > p_current_hour then
        return p_schedule.hours(idx);
      end if;
    end loop;

    return -1;
  end;

  function next_minute_in_schedule(p_current_minute in number, p_schedule in t_schedule)
    return number
  is
  begin
    for idx in p_schedule.minutes.first .. p_schedule.minutes.last
    loop
      if p_schedule.minutes(idx) > p_current_minute then
        return p_schedule.minutes(idx);
      end if;
    end loop;

    return -1;
  end;
end;
/

-- schedule_pack.pks
create or replace package schedule_pack
is
  
  function get_next_run_date(p_from in date, p_schedule_raw in  varchar2)
    return date;

  procedure enable_debug;
  procedure disable_debug;

end;
/

-- schedule_pack.pkb
create or replace package body schedule_pack
is

  g_is_debug boolean := FALSE;

  procedure enable_debug
  is
  begin
    g_is_debug := TRUE;
  end;

  procedure disable_debug
  is
  begin
    g_is_debug := FALSE;
  end;

  procedure debug_println(p_line in varchar2)
  is
  begin
    if g_is_debug then
      dbms_output.put_line(p_line);
    end if;
  end;

  -- находит ближайшую дату относительно заданной
  -- месяц которой будет находится в расписании
  function find_month(p_from in date, p_schedule in t_schedule)
    return date
  is
    v_date date;
    v_current_month number;
    v_current_year number;
  begin
    v_date := p_from;
    v_current_month := date_utils_pack.extract_month(v_date);
    -- если текущий месяц есть в расписании - оставляем его
    if schedule_utils_pack.contains_month(v_current_month, p_schedule) then
      debug_println('Found month at date: ' || v_date);
      return v_date;
    else
      -- иначе ищем следующий по расписанию
      v_current_month := schedule_utils_pack.next_month_in_schedule(v_current_month, p_schedule);
      if v_current_month = -1 then
        v_current_year := date_utils_pack.extract_year(v_date);
        -- возможно он будет уже в следующем году
        debug_println('Move to year: ' || (v_current_year+1)  || ' at date: ' || v_date);
        v_date := date_utils_pack.start_of_year(v_current_year + 1);
        return find_month(v_date, p_schedule);
      else
        debug_println('Move to month: ' || v_current_month || ' at date: '|| v_date);
        return date_utils_pack.start_of_month(v_date, v_current_month);
      end if;
    end if;
  end;

  function find_next_day_in_schedule(p_from in date, p_schedule in t_schedule)
    return date;

  -- находит ближайшую дату относительно заданной
  -- день которой будет находиться в расписании
  -- с учетом ограничения по дням месяца и дням недели
  function find_day(p_from in date, p_schedule in t_schedule)
    return date
  is
    v_date date;
    v_current_day number;
    v_weekday number;
  begin
    v_date := p_from;
    v_current_day := date_utils_pack.extract_day(v_date);
    if schedule_utils_pack.contains_day_of_month(v_current_day, p_schedule) then
      v_weekday := date_utils_pack.extract_weekday(v_date);
      if schedule_utils_pack.contains_weekday(v_weekday, p_schedule) then
        debug_println('Found day at date: ' || v_date);
        return v_date;
      else
        -- если текущий день не подходит под расписание, то начинаем искать следующий
        return find_next_day_in_schedule(v_date, p_schedule);
      end if;
    else
      return find_next_day_in_schedule(v_date, p_schedule);
    end if;
  end;

  -- находит ближайшую дату начиная со следующего дня относительно заданной
  -- день которой будет находиться в расписании
  -- с учетом ограничения по дням месяца и дням недели
  function find_next_day_in_schedule(p_from in date, p_schedule in t_schedule)
    return date 
  is
    v_date date;
    v_current_day number;
    v_current_month number;
  begin
    v_date := p_from;
    v_current_day := date_utils_pack.extract_day(v_date);
    v_current_day := schedule_utils_pack.next_day_in_schedule(v_current_day, p_schedule);
    if v_current_day = -1 then
      v_current_month := date_utils_pack.extract_month(v_date);
      -- возможно он будет уже в следующем месяце
      debug_println('Move to month: ' || (v_current_month+1) || ' at date: '|| v_date);
      v_date := date_utils_pack.start_of_month(v_date, v_current_month+1);
      v_date := find_month(v_date, p_schedule);
      -- рекурсивно продолжаем со следующего месяца
      return find_day(v_date, p_schedule);
    else
      debug_println('Move to day: ' || v_current_day || ' at date: '|| v_date);
      v_date := date_utils_pack.start_of_day(v_date, v_current_day);
      -- рекурсивно продолжаем со следующего дня
      -- ведь проверка на день недели происходит в find_day
      return find_day(v_date, p_schedule);
    end if;
  exception
    -- если подходящий день не существует в текущем месяце
    -- то переходим к следующему месяцу
    when date_utils_pack.e_not_valid_day_of_month then
      v_current_month := date_utils_pack.extract_month(v_date);
      debug_println('Move to month: ' || (v_current_month+1) || ' at date: '|| v_date);
      v_date := date_utils_pack.start_of_month(v_date, v_current_month+1);
      v_date := find_month(v_date, p_schedule);
      return find_day(v_date, p_schedule);
  end;

  -- находит ближайшую дату относительно заданной
  -- час в которой будет находится в расписании
  function find_hour(v_from in date, p_schedule in t_schedule)
    return date
  is
    v_date date;
    v_current_hour number;
  begin
    v_date := v_from;
    v_current_hour := date_utils_pack.extract_hour(v_date);
    -- если текущий час есть в расписании - оставляем его
    if schedule_utils_pack.contains_hour(v_current_hour, p_schedule) then
      debug_println('Found hour at date: ' || v_date);
      return v_date;
    else
      -- иначе ищем следующий по расписанию
      v_current_hour := schedule_utils_pack.next_hour_in_schedule(v_current_hour, p_schedule);
      if v_current_hour = -1 then
        -- возможно он будет уже в следующем дне
        v_date := find_next_day_in_schedule(v_date, p_schedule);
        -- рекурсивно продолжаем со следующего дня
        return find_hour(v_date, p_schedule);
      else
        debug_println('Move to hour: ' || v_current_hour || ' at date: '|| v_date);
        return date_utils_pack.start_of_hour(v_date, v_current_hour);
      end if;
    end if;
  end;

  -- находит ближайшую дату относительно заданной
  -- минута в которой будет находится в расписании
  function find_minute(p_from in date, p_schedule in t_schedule)
    return date
  is
    v_date date;
    v_current_hour number;
    v_current_minute number;
  begin
    v_date := p_from;
    v_current_minute := date_utils_pack.extract_nearest_minute(v_date);
    -- если ближайшая минута есть в расписании - оставляем её
    if schedule_utils_pack.contains_minute(v_current_minute, p_schedule) then
      debug_println('Move to minute: ' || v_current_minute || ' at date: '|| v_date);
      return date_utils_pack.start_of_minute(v_date, v_current_minute);
    else
      -- иначе ищем следующую по расписанию
      v_current_minute := schedule_utils_pack.next_minute_in_schedule(v_current_minute, p_schedule);
      if v_current_minute = -1 then
        v_current_hour := date_utils_pack.extract_hour(v_date);
        -- возможно она будет уже в следующем часе
        debug_println('Move to hour: ' || (v_current_hour+1) || ' at date: '|| v_date);
        v_date := date_utils_pack.start_of_hour(v_date, v_current_hour + 1);
        v_date := find_hour(v_date, p_schedule);
        -- рекурсивно продолжаем со следующего часа
        return find_minute(v_date, p_schedule);
      else
        debug_println('Move to minute: ' || v_current_minute || ' at date: '|| v_date);
        return date_utils_pack.start_of_minute(v_date, v_current_minute);
      end if;
    end if;
  end;

  function parse_numbers(p_numbers_raw in varchar2)
    return t_numbers
  is
    v_numbers t_numbers;
  begin
    select distinct cast(regexp_substr(p_numbers_raw, '([0-9]{1,2})[,;]', 1, level, 'x', 1) as number(2, 0)) n
      bulk collect into v_numbers
    from dual
    connect by regexp_instr(p_numbers_raw, '([0-9]{1,2})[,;]', 1, level, 0, 'x', 1) > 0
    order by n;

    return v_numbers;
  end;

  function parse_minutes(p_minutes_raw in varchar2)
    return t_numbers
  is
    v_minutes t_numbers;
  begin
    v_minutes := parse_numbers(p_minutes_raw);
    for idx in v_minutes.first .. v_minutes.last
    loop
      if v_minutes(idx) NOT IN (0, 15, 30, 45) then
        raise_application_error(-20001, 'Wrong minute number: ' || v_minutes(idx));
      end if;
    end loop;
    return v_minutes;
  end;

  function parse_hours(p_hours_raw in varchar2)
    return t_numbers
  is
    v_hours t_numbers;
  begin
    v_hours := parse_numbers(p_hours_raw);
    for idx in v_hours.first .. v_hours.last
    loop
      if v_hours(idx) > 23 OR v_hours(idx) < 0 then
        raise_application_error(-20001, 'Wrong hour number: ' || v_hours(idx));
      end if;
    end loop;
    return v_hours;
  end;

  function parse_weekdays(p_weekdays_raw in varchar2)
    return t_numbers
  is
    v_weekdays t_numbers;
  begin
    v_weekdays := parse_numbers(p_weekdays_raw);
    for idx in v_weekdays.first .. v_weekdays.last
    loop
      if v_weekdays(idx) > 7 OR v_weekdays(idx) < 1 then
        raise_application_error(-20001, 'Wrong weekday number: ' || v_weekdays(idx));
      end if;
    end loop;
    return v_weekdays;
  end;

  function parse_days(p_days_raw in varchar2)
    return t_numbers
  is
    v_days t_numbers;
  begin
    v_days := parse_numbers(p_days_raw);
    for idx in v_days.first .. v_days.last
    loop
      if v_days(idx) > 31 OR v_days(idx) < 1 then
        raise_application_error(-20001, 'Wrong day number: ' || v_days(idx));
      end if;
    end loop;
    return v_days;
  end;

  function parse_months(p_months_raw in varchar2)
    return t_numbers
  is
    v_months t_numbers;
  begin
    v_months := parse_numbers(p_months_raw);
    for idx in v_months.first .. v_months.last
    loop
      if v_months(idx) > 12 OR v_months(idx) < 1 then
        raise_application_error(-20001, 'Wrong month number: ' || v_months(idx));
      end if;
    end loop;
    return v_months;
  end;

  function find_max_possible_day(p_months t_numbers)
    return number
  is
    v_max_day number(2, 0) := 0;
    v_day number(2, 0);
  begin
    for idx in p_months.first .. p_months.last
    loop
      v_day := case p_months(idx)
       when 1 then 31
       when 2 then 29
       when 3 then 31
       when 4 then 30
       when 5 then 31
       when 6 then 30
       when 7 then 31
       when 8 then 31
       when 9 then 30
       when 10 then 31
       when 11 then 30
       when 12 then 31
      end;
      if v_day > v_max_day then
        v_max_day := v_day;
      end if;
    end loop;
    return v_max_day;
  end;

  -- разбирает входную строку с расписанием
  -- и создаёт объект типа t_schedule
  function parse_schedule(p_schedule_raw in varchar2)
    return t_schedule
  is
    v_minutes_raw varchar2(10 char);
    v_hours_raw varchar2(100 char);
    v_weekdays_raw varchar2(20 char);
    v_days_raw varchar2(100 char);
    v_months_raw varchar2(50 char);

    v_max_possible_day number(2, 0);
    v_min_day_in_schedule number(2, 0);

    v_schedule t_schedule;
  begin
    v_minutes_raw := regexp_substr(p_schedule_raw, '([0-9]{1,2},?)+;', 1, 1, 'x');
    v_hours_raw := regexp_substr(p_schedule_raw, '([0-9]{1,2},?)+;', 1, 2, 'x');
    v_weekdays_raw := regexp_substr(p_schedule_raw, '([0-9],?)+;', 1, 3, 'x');
    v_days_raw := regexp_substr(p_schedule_raw, '([0-9]{1,2},?)+;', 1, 4, 'x');
    v_months_raw := regexp_substr(p_schedule_raw, '([0-9]{1,2},?)+;', 1, 5, 'x');

    v_schedule := t_schedule(
      parse_minutes(v_minutes_raw),
      parse_hours(v_hours_raw),
      parse_weekdays(v_weekdays_raw),
      parse_days(v_days_raw),
      parse_months(v_months_raw)
    );

    -- проверим, что минимальный заданный номер дня
    -- есть хотя бы в одном из заданных месяцев
    v_max_possible_day := find_max_possible_day(v_schedule.months);
    v_min_day_in_schedule := v_schedule.days(v_schedule.days.first);
    if (v_min_day_in_schedule > v_max_possible_day) then
      raise_application_error(-20002, 'Impossible schedule');
    end if;

    return v_schedule;
  end;

  function find_next_run_date(p_from in date, p_schedule in t_schedule)
   return date
  is
    v_current date;
  begin
    v_current := p_from;

    v_current := find_month(v_current, p_schedule);
    v_current := find_day(v_current, p_schedule);
    v_current := find_hour(v_current, p_schedule);
    return find_minute(v_current,  p_schedule);
  end;

  function get_next_run_date(p_from in date, p_schedule_raw in varchar2)
    return date
  is
    v_schedule t_schedule;
  begin
    v_schedule := parse_schedule(p_schedule_raw);
    return find_next_run_date(p_from, v_schedule);
  end;

end;
/


-- test.sql
alter session set nls_territory = 'america';

begin
  schedule_pack.enable_debug;
end;
/

declare
  v_from date := to_date('09.07.2010 23:36', 'DD.MM.YYYY HH24:MI');
  v_date date;
begin

  v_date := schedule_pack.get_next_run_date(
    v_from,
    '0,45;12;1,2,6;3,6,14,18,21,24,28;1,2,3,4,5,6,7,8,9,10,11,12;'
  ); -- контрольный пример
  dbms_output.put_line(to_char(v_date, 'DD-MM-YYYY HH24:MI:SS'));
  if v_date <> to_date('18-07-2010 12:00:00', 'DD-MM-YYYY HH24:MI:SS') then
    raise_application_error(-20100, 'Test failed: control example');
  end if;

  v_date := schedule_pack.get_next_run_date(
    v_from,
    '45;12;1,2,6;29;2;'
  ); -- найдёт високосный год
  dbms_output.put_line(to_char(v_date, 'DD-MM-YYYY HH24:MI:SS'));
  if v_date <> to_date('29-02-2016 12:45:00', 'DD-MM-YYYY HH24:MI:SS') then
    raise_application_error(-20100, 'Test failed: visokosny year');
  end if;

  v_date := schedule_pack.get_next_run_date(
    v_from,
    '0,45;12;1,2,6;31;2,4;'
  ); -- бросит исключение, так как 31 дня нет ни в феврале, ни в апреле
  raise_application_error(-20100, 'Test failed: wrong calendar');

exception
  when others then
    if SQLCODE <> -20002 then
      raise_application_error(-20100, 'Test failed, with error: ' || SQLCODE || ', ' || SQLERRM);
    end if;
end;
/
