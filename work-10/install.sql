set verify off
@@services/patch_ver.sql
spool install_&patch_num..log replace

whenever sqlerror exit failure

set define off

prompt >>>> others/_before.sql
prompt 
@@others/_before.sql

prompt >>>> tables/_tables.sql
prompt 
@@tables/_tables.sql

prompt >>>> packages/_packages.sql
prompt 
@@packages/_packages.sql

prompt >>>> data/_data.sql
prompt 
@@data/_data.sql

prompt >>>> others/_after.sql
@@others/_after.sql

prompt >>>> tests/_install.sql
prompt 
@@tests/_install.sql

prompt ================
prompt 
prompt Patch was successfull installed!

prompt ================
prompt 
prompt Now will run tests

prompt >>>> tests/_run.sql
prompt 
@@tests/_run.sql

prompt ================
prompt 
prompt Tests run finished!

spool off

exit;
