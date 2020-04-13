create or replace package body supplier_api_pack
is
  g_is_api boolean := FALSE;

  procedure add_supplier (
    pi_splr_name in supplier.splr_name%type,
    pi_splr_legal_name in supplier.splr_legal_name%type,
    pi_splr_agreement_number in supplier.splr_agreement_number%type,
    pi_stf_id in supplier.stf_id%type,
    pi_splr_agreement_date in supplier.splr_agreement_date%type := null,
    po_splr_id out supplier.splr_id%type
  )
  is
  begin
    g_is_api := TRUE;
    insert into supplier (splr_id, splr_name, splr_legal_name,
    	                  splr_agreement_number, splr_agreement_date,
    	                  ss_id, stf_id)
      values (supplier_seq.nextval, pi_splr_name, pi_splr_legal_name,
      	      pi_splr_agreement_number, trunc(nvl(pi_splr_agreement_date, sysdate)),
      	      c_splr_ss_id_new_disabled, pi_stf_id)
      returning splr_id into po_splr_id;
    g_is_api := FALSE;
  exception
    when others then
      g_is_api := FALSE;
      raise;
  end;

  procedure change_supplier_status (
    pi_splr_id in supplier.splr_id%type,
    pi_ss_id in supplier.ss_id%type
  )
  is
  begin
    g_is_api := TRUE;
    update supplier set ss_id = pi_ss_id
      where splr_id = pi_splr_id;
    if sql%rowcount = 0 then
      raise NO_DATA_FOUND;
    end if;
    g_is_api := FALSE;
  exception
    when others then
      g_is_api := FALSE;
      raise;
  end;

  procedure enable_supplier (
    pi_splr_id in supplier.splr_id%type
  )
  is
  begin
    change_supplier_status(pi_splr_id, c_splr_ss_id_enabled);
  end;

  procedure disable_supplier (
    pi_splr_id in supplier.splr_id%type
  )
  is
  begin
    change_supplier_status(pi_splr_id, c_splr_ss_id_blocked);
  end;

  procedure change_tariff (
    pi_splr_id in supplier.splr_id%type,
    pi_stf_id in supplier.stf_id%type
  )
  is
  begin
    g_is_api := TRUE;
    update supplier set stf_id = pi_stf_id
      where splr_id = pi_splr_id;
    if sql%rowcount = 0 then
      raise NO_DATA_FOUND;
    end if;
    g_is_api := FALSE;
  exception
    when others then
      g_is_api := FALSE;
      raise;
  end;

  function is_api
    return  boolean
  is
  begin
    return g_is_api;
  end;

end;
/
