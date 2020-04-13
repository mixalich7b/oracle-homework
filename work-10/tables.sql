alter session set current_schema=k_tupitsin_study;

-- drop table supplier; 
-- drop table supplier_status; 
-- drop table supplier_tariff;
-- drop sequence supplier_seq;

create table supplier_status (
  ss_id number(3, 0) not null
);
alter table supplier_status add constraint supplier_status_ss_id_pk primary key (ss_id);

create table supplier_tariff (
  stf_id number(3, 0) not null,
  stf_description varchar2 (200 char) not null,
  sft_commission_percent number(3, 7) not null,
  sft_commission_fix number (20, 2) not null
);
alter table supplier_tariff add constraint supplier_tariff_stf_id_pk primary key (stf_id);
alter table supplier_tariff add constraint sft_commission_percent_ck check (sft_commission_percent between 0 and 99.99);
alter table supplier_tariff add constraint sft_commission_fix_ck check (sft_commission_fix >= 0);

create table supplier(
  splr_id number (10, 0) not null,
  splr_name varchar2(200 char) not null,
  splr_legal_name varchar2(1000 char) not null,
  splr_agreement_number varchar2(100 char) not null,
  splr_agreement_date date not null,
  ss_id number(3, 0) not null,
  stf_id number(3, 0) not null
);

alter table supplier add constraint supplier_splr_id_pk primary key (splr_id);
create sequence  supplier_seq  minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 nocache nocycle;

create index splr_ss_id_i on supplier (ss_id);
alter table supplier add constraint splr_ss_id_fk foreign key (ss_id) references supplier_status(ss_id);

create index splr_stf_id_i on supplier (stf_id);
alter table supplier add constraint splr_stf_id_fk foreign key (stf_id) references supplier_tariff(stf_id);
