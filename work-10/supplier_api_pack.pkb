create or replace package body supplier_api_pack
is
  g_is_api boolean := FALSE;

  c_splr_ss_id_enabled := 2;
  c_splr_ss_id_blocked := 3;

  procedure add_supplier (
    pi_splr_name in varchar2,
    pi_splr_legal_name in varchar2,
    pi_splr_agreement_number in varchar2,
    pi_stf_id in number,
    pi_splr_agreement_date in date := null,
    po_splr_id out number
  )
  is
  begin
    g_is_api := TRUE;
    insert into supplier (splr_id, splr_name, splr_legal_name,
    	                  splr_agreement_number, splr_agreement_date,
    	                  ss_id, stf_id)
      values (supplier_seq.next_val, pi_splr_name, pi_splr_legal_name,
      	      pi_splr_agreement_number, trunc(nvl(pi_splr_agreement_date, sysdate)),
      	      c_splr_ss_id_new_disabled, pi_stf_id)
      returnin splr_id into po_splr_id;
    g_is_api := FALSE;
  exception
    when others then
      g_is_api := FALSE;
      raise;
  end;

  procedure enable_supplier (
    pi_splr_id in number
  )
  is
  begin
    change_supplier_status(pi_splr_id, c_splr_ss_id_enabled);
  end;

  procedure disable_supplier (
    pi_splr_id in number
  )
  is
  begin
    change_supplier_status(pi_splr_id, c_splr_ss_id_blocked);
  end;

  procedure change_supplier_status (
    pi_splr_id in number,
    pi_ss_id in number
  )
  is
  begin
    g_is_api := TRUE;
    update supplier set ss_id = pi_ss_id
      where splr_id = pi_splr_id;
    g_is_api := FALSE;
  exception
    when others then
      g_is_api := FALSE;
      raise;
  end;

  procedure change_tariff (
    pi_splr_id in number,
    pi_stf_id in number
  )
  is
  begin
    g_is_api := TRUE;
    update supplier set stf_id = pi_stf_id
      where splr_id = pi_splr_id;
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
