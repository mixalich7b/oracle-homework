create or replace package supplier_api_pack
is

  c_splr_ss_id_new_disabled constant supplier_status.ss_id%type  := 1;
  c_splr_ss_id_enabled      constant supplier_status.ss_id%type  := 2;
  c_splr_ss_id_blocked      constant supplier_status.ss_id%type  := 3;
  c_splr_stf_id_default     constant supplier_tariff.stf_id%type := 1;

  procedure add_supplier (
    pi_splr_name in supplier.splr_name%type,
    pi_splr_legal_name in supplier.splr_legal_name%type,
    pi_splr_agreement_number in supplier.splr_agreement_number%type,
    pi_stf_id in supplier.stf_id%type,
    pi_splr_agreement_date in supplier.splr_agreement_date%type := null,
    po_splr_id out supplier.splr_id%type
  );

  procedure enable_supplier (
    pi_splr_id in supplier.splr_id%type
  );

  procedure disable_supplier (
    pi_splr_id in supplier.splr_id%type
  );

  procedure change_tariff (
    pi_splr_id in supplier.splr_id%type,
    pi_stf_id in supplier.stf_id%type
  );

  function is_api return  boolean;
end;
/
