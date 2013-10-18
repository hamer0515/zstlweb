-- ----------------------------
-- Table structure for tbl_route_inf
-- ----------------------------
drop table tbl_route_inf;

create table tbl_route_inf (
  route_id integer primary key not null,
  parent_id integer default null,
  route_name varchar(100) not null,
  route_value varchar(500) default null,
  route_regex varchar(500) default null,
  view_order integer default null,
  oper_staff integer not null,
  oper_date date not null,
  status integer not null,
  memo varchar(255) default null
) in tbs_dat index in tbs_idx;

-- ----------------------------
-- Records of tbl_route_inf
-- ----------------------------

insert into tbl_route_inf(route_id, parent_id, route_name, route_value, route_regex, view_order, oper_staff, oper_date, status, memo) 

values
    (1, 0, '系统管理' , '', '',  1, 0, '2012-11-01', 1, '系统菜单'),
    (2, 1, '密码设置' ,'passwordreset' ,'^/login/passwordreset/$' , 1, 0, '2012-11-01', 1, '密码设置菜单项'),
    (3, 1, '用户管理' , 'userlist', '^/user/.*$', 2, 0, '2012-11-01', 1, '用户管理菜单项'),
    (4, 1, '角色管理' , 'rolelist', '^/role/.*$', 3, 0, '2012-11-01', 1, '角色管理菜单项'),
    
    (20, 0, '交易查询' , '', '',  2, 0, '2012-11-01', 1, '交易查询菜单'),
    (21, 20, '实时交易查询' , 'jycxssjycx', '^/ssjycx/list$', 1, 0, '2012-11-01', 1, '实时交易查询菜单项'),
    
    (30, 0, '结算管理' , '', '',  3, 0, '2012-11-01', 1, '结算管理菜单'),
    (31, 30, '批次查询' , 'pccx', '^/pccx/.*$', 1, 0, '2012-11-01', 1, '批次查询菜单项'),
    (32, 30, '批次明细' , 'pcmx', '^/pcmx/list$', 2, 0, '2012-11-01', 1, '批次明细菜单项'),
    
    (40, 0, '账户管理' , '', '',  4, 0, '2012-11-01', 1, '账户管理菜单'),
    (41, 40, '账户查询' , 'zhcx', '^/zhcx/.*$', 1, 0, '2012-11-01', 1, '账户查询菜单项'),
    (42, 40, '批量冻结' , 'pldj', '^/pldj/.*$', 2, 0, '2012-11-01', 1, '批量冻结菜单项'),
    (43, 40, '批量解冻' , 'pljd', '^/zhcx/.*$', 3, 0, '2012-11-01', 1, '批量解冻菜单项'),
    (44, 40, '生成出款批次' , 'scckpz', '^/scckpz/.*$', 4, 0, '2012-11-01', 1, '生成出款批次菜单项'),
    
    (50, 0, '报表查询' , '', '',  5, 0, '2012-11-01', 1, '报表查询菜单'),
    (51, 50, '商户对账' , 'bbcxshdz', '^/shdz/list$', 1, 0, '2012-11-01', 1, '商户对账菜单项'),
    (52, 50, '商户出款' , 'bbcxshck', '^/shck/list$', 2, 0, '2012-11-01', 1, '商户出款菜单项'),
    (53, 50, '分润明细' , 'bbcxfrmx', '^/frmx/(list|detail)$', 3, 0, '2012-11-01', 1, '分润明细菜单项'),
    
    (60, 0, '风险管理' , '', '',  6, 0, '2012-11-01', 1, '风险管理菜单'),
    (61, 60, '风险提示' , 'fxts', '^/fxts/list$', 1, 0, '2012-11-01', 1, '风险提示菜单项'),
    (62, 60, '风险冻结' , 'fxdj', '^/fxdj/(list|pldj)$', 2, 0, '2012-11-01', 1, '风险冻结菜单项'),
    (63, 60, '交易波动' , 'jybd', '^/jybd/(?:list|ckbdt)$', 3, 0, '2012-11-01', 1, '交易波动菜单项');