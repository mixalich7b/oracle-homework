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
