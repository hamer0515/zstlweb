-- ----------------------------
-- Table structure for tbl_role_route_map
-- ----------------------------
drop table tbl_role_route_map;

create table tbl_role_route_map (
  role_id integer not null,
  route_id integer not null,
  primary key (role_id, route_id)
) in tbs_dat index in tbs_idx;

-- ----------------------------
-- Records of tbl_role_route_map
-- ----------------------------
insert into tbl_role_route_map(role_id, route_id) values
(1, 1),
(1, 2),
(1, 3),
(1, 4),

(1, 20),
(1, 21),

(1, 30),
(1, 31),
(1, 32),

(1, 40),
(1, 41),
(1, 42),
(1, 43),
(1, 44),

(1, 50),
(1, 51),
(1, 52),
(1, 53),

(1, 60),
(1, 61),
(1, 62),
(1, 63);
