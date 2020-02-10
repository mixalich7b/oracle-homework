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
