create or replace package body schedule_pack
is

  e_not_valid_day_of_month exception;

  type t_minutes is table of number(2, 0);
  type t_hours is table of number(2, 0);
  type t_weekdays is table of number(1, 0);
  type t_days is table of number(2, 0);
  type t_months is table of number(2, 0);

  -- расписание состоит из коллекции для каждой единицы:
  -- месяц года, день месяца и тд.
  type t_schedule is record  (
    -- если минута есть в расписании, то её номер будет в коллекции
    minutes t_minutes,
    -- если месяц есть в расписании, то его номер будет в коллекции
    hours t_hours,
    -- и тд
    weekdays t_weekdays,
    days t_days,
    months t_months
  );

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

  -- возвращает ближайшую круглую минуту в рамках текущего часа
  -- возвращает -1 если такой минуты в рамках текущего часа нет (например в 15:59:01)
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

  -- проверяет, есть ли  месяц в расписании
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

  function contains_day_of_week(p_day_of_week in number, p_schedule in t_schedule)
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

  -- находит следующий ближайший месяц по расписанию
  -- возвращает номер месяца либо -1 если больше подходящих месяцев в расписании нет
  function next_month(p_current_month in number, p_schedule in t_schedule)
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

  -- находит следующий ближайший день по расписанию
  -- возвращает номер дня либо -1 если больше подходящих дней в расписании нет
  function next_day(p_current_day in number, p_schedule in t_schedule)
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

  -- находит следующий ближайший час по расписанию
  -- возвращает номер часа либо -1 если больше подходящих часов в расписании нет
  function next_hour(p_current_hour in number, p_schedule in t_schedule)
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

  -- находит следующую ближайшую минуту по расписанию
  -- возвращает номер минуты либо -1 если больше подходящих минут в расписании нет
  function next_minute(p_current_minute in number, p_schedule in t_schedule)
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

  -- возвращает дату соответствующую началу указанного года
  function start_of_year(p_year in number)
    return date
  is
  begin
    return to_date(p_year || '0101', 'YYYYMMDD');
  end;

  -- возвращает дату соответствующую началу указанного месяца p_month
  -- не изменяя год
  function start_of_month(p_month in number, p_date in date)
    return date
  is
    v_current_year number;
    v_current_month number;
  begin
    v_current_year := extract_year(p_date);
    v_current_month := extract_month(p_date);
    return trunc(add_months(p_date, p_month-v_current_month), 'MM');
  end;

  -- возвращает дату соответствующую началу указанного дня,
  -- не изменяя год и месяц
  -- если заданный день не существует в этом месяце,
  -- то будет  выброшено исключение e_not_valid_day_of_month
  function start_of_day(p_day in number, p_date in date)
    return date
  is
    v_current_year number;
    v_current_month varchar2(2 char);

    e_not_valid_date_for_month exception;
    pragma exception_init(e_not_valid_date_for_month, -01839);
  begin
    v_current_year := extract_year(p_date);
    v_current_month := to_char(p_date, 'MM');
    return to_date(v_current_year || v_current_month || p_day, 'YYYYMMDD');
  exception
    when e_not_valid_date_for_month then
      raise e_not_valid_day_of_month;
  end;

  function start_of_hour(p_hour in number, p_date in date)
    return date
  is
    v_current_year number;
    v_current_month varchar2(2 char);
    v_current_day varchar2(2 char);
  begin
    v_current_year := extract_year(p_date);
    v_current_month := to_char(p_date, 'MM');
    v_current_day := to_char(p_date, 'DD');
    return to_date(v_current_year || v_current_month || v_current_day || p_hour, 'YYYYMMDDHH24');
  end;

  function start_of_minute(p_minute in number, p_date in date)
    return date
  is
    v_current_year number;
    v_current_month varchar2(2 char);
    v_current_day varchar2(2 char);
    v_current_hour varchar2(2 char);
  begin
    v_current_year := extract_year(p_date);
    v_current_month := to_char(p_date, 'MM');
    v_current_day := to_char(p_date, 'DD');
    v_current_hour := to_char(p_date, 'HH24');
    return to_date(v_current_year || v_current_month || v_current_day || v_current_hour || p_minute, 'YYYYMMDDHH24MI');
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
    v_current_month := extract_month(v_date);
    -- если текущий месяц есть в расписании - оставляем его
    if contains_month(v_current_month, p_schedule) then
      dbms_output.put_line('Found month at date: ' || v_date);
      return v_date;
    else
      -- иначе ищем следующий по расписанию
      v_current_month := next_month(v_current_month, p_schedule);
      if v_current_month = -1 then
        v_current_year := extract_year(v_date);
        -- возможно он будет уже в следующем году
        dbms_output.put_line('Move to year: ' || (v_current_year+1)  || ' at date: ' || v_date);
        v_date := start_of_year(v_current_year + 1);
        return find_month(v_date, p_schedule);
      else
        dbms_output.put_line('Move to month: ' || v_current_month || ' at date: '|| v_date);
        return start_of_month(v_current_month, v_date);
      end if;
    end if;
  end;

  function find_next_day(p_from in date, p_schedule in t_schedule)
    return date;

  -- находит ближайшую дату относительно заданной
  -- день которой будет находиться в расписании
  -- с учетом ограничения по дням месяца и дням недели
  function find_day(p_from in date, p_schedule in t_schedule)
    return date
  is
    v_date date;
    v_current_day number;
    v_day_of_week number;
  begin
    v_date := p_from;
    v_current_day := extract_day(v_date);
    if contains_day_of_month(v_current_day, p_schedule) then
      v_day_of_week := to_number(to_char(v_date, 'd'));
      if contains_day_of_week(v_day_of_week, p_schedule) then
        dbms_output.put_line('Found day at date: ' || v_date);
        return v_date;
      else
        -- если текущий день не подходит под расписание, то начинаем искать следующий
        return find_next_day(v_date, p_schedule);
      end if;
    else
      return find_next_day(v_date, p_schedule);
    end if;
  end;

  -- находит ближайшую дату начиная со следующего дня относительно заданной
  -- день которой будет находиться в расписании
  -- с учетом ограничения по дням месяца и дням недели
  function find_next_day(p_from in date, p_schedule in t_schedule)
    return date 
  is
    v_date date;
    v_current_day number;
    v_current_month number;
  begin
    v_date := p_from;
    v_current_day := extract_day(v_date);
    v_current_day := next_day(v_current_day, p_schedule);
    if v_current_day = -1 then
      v_current_month := extract_month(v_date);
      -- возможно он будет уже в следующем месяце
      dbms_output.put_line('Move to month: ' || (v_current_month+1) || ' at date: '|| v_date);
      v_date := start_of_month(v_current_month+1, v_date);
      v_date := find_month(v_date, p_schedule);
      -- рекурсивно продолжаем со следующего месяца
      return find_day(v_date, p_schedule);
    else
      dbms_output.put_line('Move to day: ' || v_current_day || ' at date: '|| v_date);
      v_date := start_of_day(v_current_day, v_date);
      -- рекурсивно продолжаем со следующего дня
      -- ведь проверка на день недели происходит в find_day
      return find_day(v_date, p_schedule);
    end if;
  exception
    -- если подходящий день не существует в текущем месяце
    -- то переходим к следующему месяцу
    when e_not_valid_day_of_month then
      v_current_month := extract_month(v_date);
      dbms_output.put_line('Move to month: ' || (v_current_month+1) || ' at date: '|| v_date);
      v_date := start_of_month(v_current_month+1, v_date);
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
    v_current_hour := extract_hour(v_date);
    -- если текущий час есть в расписании - оставляем его
    if contains_hour(v_current_hour, p_schedule) then
      dbms_output.put_line('Found hour at date: ' || v_date);
      return v_date;
    else
      -- иначе ищем следующий по расписанию
      v_current_hour := next_hour(v_current_hour, p_schedule);
      if v_current_hour = -1 then
        -- возможно он будет уже в следующем дне
        v_date := find_next_day(v_date, p_schedule);
        -- рекурсивно продолжаем со следующего дня
        return find_hour(v_date, p_schedule);
      else
        dbms_output.put_line('Move to hour: ' || v_current_hour || ' at date: '|| v_date);
        return start_of_hour(v_current_hour, v_date);
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
    v_current_minute := extract_nearest_minute(v_date);
    -- если ближайшая минута есть в расписании - оставляем её
    if contains_minute(v_current_minute, p_schedule) then
      dbms_output.put_line('Move to minute: ' || v_current_minute || ' at date: '|| v_date);
      return start_of_minute(v_current_minute, v_date);
    else
      -- иначе ищем следующую по расписанию
      v_current_minute := next_minute(v_current_minute, p_schedule);
      if v_current_minute = -1 then
        v_current_hour := extract_hour(v_date);
        -- возможно она будет уже в следующем часе
        dbms_output.put_line('Move to hour: ' || (v_current_hour+1) || ' at date: '|| v_date);
        v_date := start_of_hour(v_current_hour + 1, v_date);
        v_date := find_hour(v_date, p_schedule);
        -- рекурсивно продолжаем со следующего часа
        return find_minute(v_date, p_schedule);
      else
        dbms_output.put_line('Move to minute: ' || v_current_minute || ' at date: '|| v_date);
        return start_of_minute(v_current_minute, v_date);
      end if;
    end if;
  end;

  function parse_numbers(p_numbers_raw in varchar2)
    return table of number
  is
    type t_numbers is table of number(2);
    v_numbers t_numbers;
    -- v_idx pls_integer;
  begin
    -- v_numbers := t_numbers();
    -- v_idx := 1;
    -- while regex_instr(p_numbers_raw, '([0-9]{1,2})[,;]', 1, v_idx, 'x', 1) > 0
    -- loop
      -- v_numbers.extend(1);
      -- v_numbers(idx) := regex_substr(p_numbers_raw, '([0-9]{1,2})[,;]', 1, level, 'x', 1);
      -- v_idx := v_idx + 1;
    -- end loop;
    select distinct regex_substr(p_numbers_raw, '([0-9]{1,2})[,;]', 1, level, 'x', 1) n
      bulk collect into v_numbers
    from dual
    connect by regex_instr(p_numbers_raw, '([0-9]{1,2})[,;]', 1, level, 'x', 1) > 0
    order by n;

    return v_numbers;
  end;

  function parse_minutes(p_minutes_raw in varchar2)
    return t_minutes
  is
    v_minutes t_minutes;
  begin
    v_minutes := cast(parse_numbers(p_minutes_raw) as t_minutes);
    for idx in v_minutes.first .. v_minutes.last
    loop
      if v_minutes(idx) NOT IN (0, 15, 30, 45) then
        raise_application_error(-20001, 'Wrong minute number: ' || v_minutes(idx));
      end if;
    end loop;
    return v_minutes;
  end;

  function parse_hours(p_hours_raw in varchar2)
    return t_hours
  is
    v_hours t_hours;
  begin
    v_hours := cast(parse_numbers(p_hours_raw) as t_hours);
    for idx in v_hours.first .. v_hours.last
    loop
      if v_hours(idx) > 23 OR v_hours(idx) < 0 then
        raise_application_error(-20001, 'Wrong hour number: ' || v_hours(idx));
      end if;
    end loop;
    return v_hours;
  end;

  function parse_weekdays(p_weekdays_raw in varchar2)
    return t_weekdays
  is
    v_weekdays t_weekdays;
  begin
    v_weekdays := cast(parse_numbers(p_weekdays_raw) as t_weekdays);
    for idx in v_weekdays.first .. v_weekdays.last
    loop
      if v_weekdays(idx) > 7 OR v_weekdays(idx) < 1 then
        raise_application_error(-20001, 'Wrong weekday number: ' || v_weekdays(idx));
      end if;
    end loop;
    return v_weekdays;
  end;

  function parse_days(p_days_raw in varchar2)
    return t_days
  is
    v_days t_days;
  begin
    v_days := cast(parse_numbers(p_days_raw) as t_days);
    for idx in v_days.first .. v_days.last
    loop
      if v_days(idx) > 31 OR v_days(idx) < 1 then
        raise_application_error(-20001, 'Wrong day number: ' || v_days(idx));
      end if;
    end loop;
    return v_days;
  end;

  function parse_months(p_months_raw in varchar2)
    return t_months
  is
    v_months t_months;
  begin
    v_months := cast(parse_numbers(p_months_raw) as t_months);
    for idx in v_months.first .. v_months.last
    loop
      if v_months(idx) > 12 OR v_months(idx) < 1 then
        raise_application_error(-20001, 'Wrong month number: ' || v_months(idx));
      end if;
    end loop;
    return v_months;
  end;

  function find_max_possible_day(p_months t_months)
    return number
  is
    v_max_day number := 0;
  begin
    for idx in p_months.first .. p_months.last
    loop
      v_max_day := case p_months(idx)
       when 1 then max(v_max_day, 31)
       when 2 then max(v_max_day, 29)
       when 3 then max(v_max_day, 31)
       when 4 then max(v_max_day, 30)
       when 5 then max(v_max_day, 31)
       when 6 then max(v_max_day, 30)
       when 7 then max(v_max_day, 31)
       when 8 then max(v_max_day, 31)
       when 9 then max(v_max_day, 30)
       when 10 then max(v_max_day, 31)
       when 11 then max(v_max_day, 30)
       when 12 then max(v_max_day, 31)
      end;
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
    v_schedule t_schedule;
  begin
    v_minutes_raw := regex_substr(p_schedule_raw, '([0-9]{1,2},?)+;', 1, 1, 'x');
    v_hours_raw := regex_substr(p_schedule_raw, '([0-9]{1,2},?)+;', 1, 2, 'x');
    v_weekdays_raw := regex_substr(p_schedule_raw, '([0-9],?)+;', 1, 3, 'x');
    v_days_raw := regex_substr(p_schedule_raw, '([0-9]{1,2},?)+;', 1, 4, 'x');
    v_months_raw := regex_substr(p_schedule_raw, '([0-9]{1,2},?)+;', 1, 5, 'x');

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
