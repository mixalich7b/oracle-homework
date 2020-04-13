set verify off
@services/patch_ver.sql
spool uninstall_&patch_num..log replace

whenever sqlerror continue

prompt drop package test_supplier_api_pack;
drop package test_supplier_api_pack;

prompt drop trigger supplier_b_iu;
drop trigger supplier_b_iu;

prompt drop package supplier_api_pack
drop package supplier_api_pack;

prompt drop sequence supplier_seq;
drop sequence supplier_seq;

prompt drop table supplier;
drop table supplier;

prompt drop table supplier_status;
drop table supplier_status;

prompt drop table supplier_tariff
drop table supplier_tariff;

prompt ================
prompt 
prompt Patch was successfull uninstalled!

spool off

exit;
