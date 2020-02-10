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
