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

  --%test(Включение существующего поставщика)
  --%beforetest(add_test_supplier)
  --%aftertest(delete_test_supplier)
  procedure enable_supplier;

  --%test(Включение несуществующего поставщика)
  --%throws(-2291)
  procedure enable_non_existing_supplier;

  --%test(Выключение существующего поставщика)
  --%beforetest(add_test_supplier)
  --%aftertest(delete_test_supplier)
  procedure disable_supplier;

  --%test(Выключение несуществующего поставщика)
  --%throws(-2291)
  procedure disable_non_existing_supplier;

  --%test(Переключение поставщика на существующий тариф)
  --%beforetest(add_test_tariff)
  --%beforetest(add_test_supplier)
  --%aftertest(delete_test_supplier)
  --%aftertest(delete_test_tariff)
  procedure change_tariff;

  --%test(Переключение поставщика на несуществующий тариф)
  --%beforetest(add_test_supplier)
  --%aftertest(delete_test_supplier)
  --%throws(-2291)
  procedure change_to_non_existing_tariff;

  -- utils
  procedure add_test_supplier;
  procedure delete_test_supplier;

end;
/
