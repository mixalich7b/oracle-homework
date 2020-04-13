create or replace package test_supplier_api_pack
is
  --%suite(Test supplier_api_pack)
  --%suitepath(supplier)

  --%test(Создание поставщика с валидными параметрами API)
  --%aftertest(delete_test_supplier)
  procedure add_supplier;

  --%test(Создание поставщика с указанием даты договора)
  --%aftertest(delete_test_supplier)
  procedure add_splr_with_agr_date;

  --%test(Создание поставщика не через API приведёт к ошибке)
  --%throws(-20002)
  procedure add_splr_without_api;

  --%test(Создание поставщика с несуществующим тарифом приведёт к ошибке)
  --%throws(-2291)
  procedure add_splr_with_wrong_tariff;


  -- utils
  procedure delete_test_supplier;

end;
/
