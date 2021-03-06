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
