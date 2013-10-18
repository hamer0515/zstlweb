-- ----------------------------
-- Table structure for tbl_user_role_map
-- ----------------------------
drop table tbl_user_role_map;

create table tbl_user_role_map (
  user_id integer not null,
  role_id integer not null,
  primary key(user_id, role_id)
) in tbs_dat index in tbs_idx;

-- ----------------------------
-- Records of tbl_user_role_map
-- ----------------------------
insert into tbl_user_role_map(user_id, role_id) values(1, 1);