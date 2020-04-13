create or replace package body test_supplier_api_pack
is

  c_test_supplier_name constant supplier.splr_name%type := 'Test supplier';

  procedure create_supplier_with_valid_params
  is
    v_splr_legal_name in supplier.splr_legal_name%type =: 'Test supplier PLC';
    v_splr_agreement_number in supplier.splr_agreement_number%type := 'test_12345/01-01';
    v_stf_id in supplier.stf_id%type := supplier_api_pack.c_splr_stf_id_default;
    v_splr_id supplier.splr_id%type;
    v_supplier_row supplier%rowtype;
  begin
    supplier_api_pack.add_supplier(
      pi_splr_name => c_test_supplier_name,
      pi_splr_legal_name => v_splr_legal_name,
      pi_splr_agreement_number => v_splr_agreement_number,
      pi_stf_id => v_stf_id,
      po_splr_id => v_splr_id
    );

    select *
      into v_supplier_row
      from supplier
    where splr_id = v_splr_id;

    ut.expect(v_supplier_row.splr_name).to_equal(c_test_supplier_name);
    ut.expect(v_supplier_row.splr_legal_name).to_equal(v_splr_legal_name);
    ut.expect(v_supplier_row.splr_agreement_number).to_equal(v_splr_agreement_number);
    ut.expect(v_supplier_row.ss_id).to_equal(supplier_api_pack.c_splr_ss_id_new_disabled);
    ut.expect(v_supplier_row.stf_id).to_equal(v_stf_id);
    ut.expect(v_supplier_row.splr_agreement_date).to_equal(trunc(sysdate));
  end;

  procedure delete_test_supplier
  is
  begin
    dbms_session.set_context('clientcontext', 'force_dml', 'true');
    delete supplier where splr_name = c_test_supplier_name;
    dbms_session.set_context('clientcontext', 'force_dml', 'false');
  end;

end;
/
