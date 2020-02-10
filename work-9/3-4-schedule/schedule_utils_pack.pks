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
