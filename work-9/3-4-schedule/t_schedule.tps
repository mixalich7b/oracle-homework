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