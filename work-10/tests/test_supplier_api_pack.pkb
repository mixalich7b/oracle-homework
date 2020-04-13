create or replace package body test_supplier_api_pack
is

  c_test_supplier_name constant supplier.splr_name%type := 'Test supplier';
  c_test_supplier_legal_name constant supplier.splr_legal_name%type := 'Test supplier PLC';
  c_test_supplier_agrt_number constant supplier.splr_agreement_number%type := 'test_12345/01-01';
  c_test_supplier_tariff_id constant supplier.stf_id%type := supplier_api_pack.c_splr_stf_id_default;

  c_test_tariff_id constant supplier_tariff.stf_id%type := 999;

  c_non_existing_supplier_id constant supplier.splr_id%type := -100500;
  c_non_existing_tariff_id constant supplier_tariff.stf_id%type := -999;

  g_splr_id supplier.splr_id%type;

  procedure add_supplier
  is
    v_supplier_row supplier%rowtype;
  begin
    supplier_api_pack.add_supplier(
      pi_splr_name => c_test_supplier_name,
      pi_splr_legal_name => c_test_supplier_legal_name,
      pi_splr_agreement_number => c_test_supplier_agrt_number,
      pi_stf_id => c_test_supplier_tariff_id,
      po_splr_id => g_splr_id
    );

    select *
      into v_supplier_row
      from supplier
    where splr_id = g_splr_id;

    ut.expect(v_supplier_row.splr_name).to_equal(c_test_supplier_name);
    ut.expect(v_supplier_row.splr_legal_name).to_equal(c_test_supplier_legal_name);
    ut.expect(v_supplier_row.splr_agreement_number).to_equal(c_test_supplier_agrt_number);
    ut.expect(v_supplier_row.ss_id).to_equal(supplier_api_pack.c_splr_ss_id_new_disabled);
    ut.expect(v_supplier_row.stf_id).to_equal(c_test_supplier_tariff_id);
    ut.expect(v_supplier_row.splr_agreement_date).to_equal(trunc(sysdate));
  end;

  procedure add_splr_with_agr_date
  is
    v_splr_agreement_date supplier.splr_agreement_date%type := sysdate - 3;
    v_supplier_row supplier%rowtype;
  begin
    supplier_api_pack.add_supplier(
      pi_splr_name => c_test_supplier_name,
      pi_splr_legal_name => c_test_supplier_legal_name,
      pi_splr_agreement_number => c_test_supplier_agrt_number,
      pi_stf_id => c_test_supplier_tariff_id,
      pi_splr_agreement_date => v_splr_agreement_date,
      po_splr_id => g_splr_id
    );

    select *
      into v_supplier_row
      from supplier
    where splr_id = g_splr_id;

    ut.expect(v_supplier_row.splr_agreement_date).to_equal(trunc(v_splr_agreement_date));
  end;

  procedure add_splr_without_api
  is
  begin
    insert into supplier (splr_id, splr_name, splr_legal_name,
                          splr_agreement_number, splr_agreement_date,
                          ss_id, stf_id)
      values (100500, '', '', '', sysdate, 1, 1);
  end;

  procedure add_splr_with_wrong_tariff
  is
  begin
    supplier_api_pack.add_supplier(
      pi_splr_name => c_test_supplier_name,
      pi_splr_legal_name => c_test_supplier_legal_name,
      pi_splr_agreement_number => c_test_supplier_agrt_number,
      pi_stf_id => c_non_existing_tariff_id,
      po_splr_id => g_splr_id
    );
  end;

  procedure enable_supplier
  is
    v_supplier_row supplier%rowtype;
  begin
    supplier_api_pack.enable_supplier(g_splr_id);

    select *
      into v_supplier_row
      from supplier
    where splr_id = g_splr_id;

    ut.expect(v_supplier_row.ss_id).to_equal(supplier_api_pack.c_splr_ss_id_enabled);
  end;

  procedure enable_non_existing_supplier
  is
  begin
    supplier_api_pack.enable_supplier(c_non_existing_supplier_id);
  end;

  procedure disable_supplier
  is
    v_supplier_row supplier%rowtype;
  begin
    supplier_api_pack.disable_supplier(g_splr_id);

    select *
      into v_supplier_row
      from supplier
    where splr_id = g_splr_id;

    ut.expect(v_supplier_row.ss_id).to_equal(supplier_api_pack.c_splr_ss_id_blocked);
  end;

  procedure disable_non_existing_supplier
  is
  begin
    supplier_api_pack.disable_supplier(c_non_existing_supplier_id);
  end;

  procedure change_tariff
  is
    v_supplier_row supplier%rowtype;
  begin
    supplier_api_pack.change_tariff(g_splr_id, c_test_tariff_id);

    select *
      into v_supplier_row
      from supplier
    where splr_id = g_splr_id;

    ut.expect(v_supplier_row.stf_id).to_equal(c_test_tariff_id);
  end;

  procedure change_to_non_existing_tariff
  is
  begin
    supplier_api_pack.change_tariff(g_splr_id, c_non_existing_tariff_id);
  end;

  -- utils
  procedure add_test_supplier
  is
  begin
    supplier_api_pack.add_supplier(
      pi_splr_name => c_test_supplier_name,
      pi_splr_legal_name => c_test_supplier_legal_name,
      pi_splr_agreement_number => c_test_supplier_agrt_number,
      pi_stf_id => c_test_supplier_tariff_id,
      po_splr_id => g_splr_id
    );
  end;

  procedure delete_test_supplier
  is
  begin
    dbms_session.set_context('clientcontext', 'force_dml', 'true');
    delete supplier where splr_id = g_splr_id;
    dbms_session.set_context('clientcontext', 'force_dml', 'false');
  end;

  procedure add_test_tariff
  is
  begin
    insert into supplier_tariff (stf_id, stf_description, sft_commission_percent, sft_commission_fix)
                         values (c_test_tariff_id, 'Test tariff', 20.45, 13);
  end;

  procedure delete_test_tariff
  is
  begin
    delete supplier_tariff where stf_id = c_test_tariff_id;
  end;

end;
/
