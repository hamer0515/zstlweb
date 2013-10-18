package ZstlWeb::Role::Role;

use Mojo::Base 'Mojolicious::Controller';
use DateTime;
use JSON::XS;
use boolean;

################################
# show role list
################################
sub list {
	my $self  = shift;
	my $page  = $self->param('page');
	my $limit = $self->param('limit');
	my $sort  = $self->param('sort');
	my $s_str = '';
	if ($sort) {
		$s_str = 'order by ';
		$sort  = decode_json $sort;
		for my $s (@$sort) {
			$s_str .= $s->{property} . ' ' . $s->{direction};
		}
	}
	my $sql =
"select role_id, role_name as name, remark as memo, rownumber() over($s_str) as rowid from tbl_role_inf";
	my $data = $self->page_data( $sql, $page, $limit, $sort );
	$data->{success} = true;
	$self->render( json => $data );
}

################################
# add a new role
################################
sub add {
	my $self       = shift;
	my $role_name  = $self->param('name');
	my $memo       = $self->param('memo');
	my @limits     = $self->param('limits');
	my $dt         = DateTime->now( time_zone => 'local' );
	my $oper_date  = $dt->ymd('-');
	my $oper_staff = $self->session->{uid};
	my $rid        = $self->dbh->selectall_arrayref(
		    "select count(*) from tbl_role_inf where role_name=\'"
		  . $role_name
		  . "\'" );

	if ( $rid->[0]->[0] ) {
		$self->render( json => { success => false } );
		return 1;
	}
	$self->dbh->begin_work;

	my $role_sql =
'insert into tbl_role_inf(role_id, role_name, remark, oper_staff, oper_date, status) values (nextval for seq_role_id, \''
	  . $role_name
	  . '\', \''
	  . $memo
	  . "\',$oper_staff, \'$oper_date\', 1 )";
	$self->dbh->do($role_sql) or $self->errhandle($role_sql);

	my $role_id = $self->dbh->selectall_arrayref(
		    "select role_id from tbl_role_inf where role_name=\'"
		  . $role_name
		  . "\'" );
	for my $limit (@limits) {
		my $sql =
"insert into tbl_role_route_map(role_id, route_id) values($role_id->[0]->[0], $limit)";
		$self->dbh->do($sql) or $self->errhandle($sql);
	}
	$self->dbh->commit;
	$self->updateRoutes;
	$self->render( json => { success => true } );
}

################################
# the json method to comfir the role name
################################
sub check {
	my $self   = shift;
	my $name   = $self->param('name');
	my $id     = $self->param('id');
	my $result = false;
	my $sql =
	    "select count(*) as count from tbl_role_inf where role_name=\'" 
	  . $name
	  . "\' and role_id <> $id";
	my $key = $self->dbh->selectrow_hashref($sql);
	$result = true if $key->{count} == 0;
	$self->render( json => { success => $result } );
}

################################
# update role information
################################
sub update {
	my $self = shift;
	my $data;
	my $role_name = $self->param('name');
	my $role_id   = $self->param('role_id');
	my $memo      = $self->param('memo');
	my @limits    = $self->param('limits');

	$self->dbh->begin_work;
	my $role_sql =
	    'update tbl_role_inf set role_name = \''
	  . $role_name
	  . '\', remark = \''
	  . $memo
	  . "' where role_id = $role_id";
	$self->dbh->do($role_sql) or $self->errhandle($role_sql);

	my $sql = "delete from tbl_role_route_map where role_id = $role_id";
	$self->dbh->do($sql) or $self->errhandle($sql);

	for my $limit (@limits) {
		my $sql =
"insert into tbl_role_route_map(role_id, route_id) values($role_id, $limit)";
		$self->dbh->do($sql) or $self->errhandle($sql);
	}
	$self->dbh->commit;
	$self->updateRoutes;
	$self->render( json => { success => true } );
}

sub delete {
	my $self = shift;
	my $id   = $self->param('id');
	my $sql  = "delete from tbl_role_route_map where role_id=$id";
	my $sql_ = "delete from tbl_role_inf where role_id = $id";
	$self->dbh->begin_work;
	$self->dbh->do($sql)  or $self->errhandle($sql);
	$self->dbh->do($sql_) or $self->errhandle($sql_);
	$self->render( json => { success => true } );
}

1;
