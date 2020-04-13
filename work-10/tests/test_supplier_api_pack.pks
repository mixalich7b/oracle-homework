create or replace package test_supplier_api_pack
is
  --%suite(Test supplier_api_pack)
  --%suitepath(supplier)

  --%test(Создание поставщика с валидными параметрами API)
  --%aftertest(delete_test_supplier)
  procedure create_supplier;

  procedure delete_test_supplier;

end;
/
