create or replace package supplier_api_pack
is

  c_splr_ss_id_new_disabled := 1;
  c_splr_stf_id_default := 1;

  procedure add_supplier (
    pi_splr_name in varchar2,
    pi_splr_legal_name in varchar2,
    pi_splr_agreement_number in varchar2,
    pi_stf_id in number,
    pi_splr_agreement_date in date := null,
    po_splr_id out number
  );

  procedure enable_supplier (
    pi_splr_id in number
  );

  procedure disable_supplier (
    pi_splr_id in number
  );

  procedure change_tariff (
    pi_splr_id in number,
    pi_stf_id in number
  );

  function is_api return  boolean;
end;
/