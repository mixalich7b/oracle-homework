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

  v_date := schedule_pack.get_next_run_date(
    v_from,
    '45;12;1,2,6;29;2;'
  ); -- найдёт високосный год
  dbms_output.put_line(to_char(v_date, 'DD-MM-YYYY HH24:MI:SS'));

  v_date := schedule_pack.get_next_run_date(
    v_from,
    '0,45;12;1,2,6;31;2,4;'
  ); -- бросит исключение, так как 31 дня нет ни в феврале, ни в апреле
end;
/
