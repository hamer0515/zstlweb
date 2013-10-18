-- ----------------------------
-- Table structure for tbl_user_inf
-- ----------------------------
drop table tbl_user_inf;
drop sequence seq_user_id;

create table tbl_user_inf (
  user_id integer primary key not null,
  username varchar(100) default null,
  user_pwd varchar(255) not null,
  pwd_chg_date date default null,
  eff_date date default null,
  exp_date date default null,
  oper_staff integer default null,
  oper_date date default null,
  utype integer not null,
  itype integer not null,
  status integer not null
) in tbs_dat index in tbs_idx;

create sequence seq_user_id as integer start with 1 increment by 1 no cache order; 
-- ----------------------------
-- Records of tbl_user_inf
-- ----------------------------
insert into tbl_user_inf(user_id, username, user_pwd, pwd_chg_date, eff_date, exp_date, oper_staff, oper_date, utype, itype, status) 
    values(nextval for seq_user_id, 'admin', '0192023a7bbd73250516f069df18b500', '2012-11-01', '2012-11-01', '2050-01-01',0 , '2012-11-01', 0, 0, 1 );
