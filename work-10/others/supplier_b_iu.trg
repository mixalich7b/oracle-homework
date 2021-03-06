create or replace trigger supplier_b_iu
  before insert or update or delete
  on supplier
  for each row
begin
  if not (supplier_api_pack.is_api or
  	nvl(sys_context('clientcontext', 'force_dml'), 'false') = 'true')
  then
    raise_application_error(-20002, 'Use supplier_api_pack');
  end if;
end;
/
