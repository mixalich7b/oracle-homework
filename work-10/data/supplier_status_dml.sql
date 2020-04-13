prompt fill supplier_status tab...

insert into supplier_status(ss_id, ss_description)
                    values (1, 'Новый (выключен)');
insert into supplier_status(ss_id, ss_description)
                    values (2, 'Включен');
insert into supplier_status(ss_id, ss_description)
                    values (3, 'Временно заблокирован');
commit;
