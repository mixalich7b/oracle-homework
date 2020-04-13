insert into supplier_status(ss_id, ss_description)
                    values (1, 'Новый (выключен)');
insert into supplier_status(ss_id, ss_description)
                    values (2, 'Включен');
insert into supplier_status(ss_id, ss_description)
                    values (3, 'Временно заблокирован');

insert into supplier_tariff (stf_id, stf_description, sft_commission_percent, sft_commission_fix)
                     values (1, 'Базовый тариф', 1.5, 10);