package ZstlWeb::User::User;

use Mojo::Base 'Mojolicious::Controller';
use utf8;
use DateTime;
use JSON::XS;
use boolean;

use constant { DEBUG => $ENV{SYSTEM_DEBUG} || 0, };

BEGIN {
	require Data::Dump if DEBUG;
}

################################
# show user list
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
	my $index = $self->param('index') || 1;
	my $sql =
"select user_id, utype, itype, username, status, pwd_chg_date, rownumber() over($s_str) as rowid from tbl_user_inf";
	my $data = $self->page_data( $sql, $page, $limit, $sort );
	$data->{index}   = $index;
	$data->{success} = 1;
	$self->render( json => $data );
}

################################
# add a new user
################################
sub add {
	my $self = shift;
	my $data;
	my $username = $self->param('username');
	my $password = $self->param('password');
	my $utype    = $self->param('utype');
	my $itype    = $self->param('itype');
	if ( $utype eq '请选择渠道' ) {
		$utype = 0;
	}
	$password = Digest::MD5->new->add($password)->hexdigest;
	my @roles = split ',', $self->param('roles');
	my $dt        = DateTime->now( time_zone => 'local' );
	my $oper_date = $dt->ymd('-');
	my $uid       = $self->dbh->selectall_arrayref(
		"select count(*) from tbl_user_inf where username=\'$username\'");

	if ( $uid->[0]->[0] ) {
		$self->render( json => { success => false } );
		return;
	}
	$self->dbh->begin_work;
	my $user_sql =
'insert into tbl_user_inf(user_id, username, user_pwd, pwd_chg_date, itype, utype, status) values (nextval for seq_user_id, \''
	  . $username
	  . '\', \''
	  . $password
	  . '\', \''
	  . $oper_date
	  . "\', $itype, $utype, " . '1)';
	$self->dbh->do($user_sql) or $self->errhandle($user_sql);
	my $user_id = $self->dbh->selectall_arrayref(
		"select user_id from tbl_user_inf where username=\'$username\'");

	for my $role (@roles) {
		my $sql =
"insert into tbl_user_role_map(user_id, role_id) values($user_id->[0]->[0], $role)";
		$self->dbh->do($sql) or $self->errhandle($sql);
	}
	$self->dbh->commit;
	$self->updateUsers;
	$self->render( json => { success => true } );
}

################################
# the json method to comfirm user name
################################
sub check {
	my $self   = shift;
	my $name   = $self->param('name');
	my $id     = $self->param('id');
	my $result = false;
	my $sql =
	    "select count(*) as count from tbl_user_inf where username=\'" 
	  . $name
	  . "\' and user_id <> $id";
	my $key = $self->dbh->selectrow_hashref($sql);
	$result = true if $key->{count} == 0;
	$self->render( json => { success => $result } );
}

################################
# update user information
################################
sub update {
	my $self = shift;
	my $data;
	my $username = $self->param('username');
	my $status   = $self->param('status');
	my $user_id  = $self->param('user_id');
	my $utype    = $self->param('utype');
	my $itype    = $self->param('itype');
	if ( $utype eq '请选择渠道' ) {
		$utype = 0;
	}
	my $password = $self->param('password') || '';
	my @roles = split ',', $self->param('roles');
	$self->dbh->begin_work;
	my $user_sql;

	if ( $password eq '' ) {
		$user_sql =
		    'update tbl_user_inf set username = \''
		  . $username
		  . "\' , status = \'$status\', utype = $utype, itype = $itype where user_id = $user_id";
	}
	else {
		$password = Digest::MD5->new->add($password)->hexdigest;
		$user_sql =
		    'update tbl_user_inf set username = \''
		  . $username
		  . '\', user_pwd = \''
		  . $password
		  . "' , status = \'$status\', utype = $utype, itype = $itype where user_id = $user_id";
	}
	$self->dbh->do($user_sql) or $self->errhandle($user_sql);

	my $sql = "delete from tbl_user_role_map where user_id = $user_id";
	$self->dbh->do($sql) or $self->err_handle;

	for my $role (@roles) {
		my $sql =
"insert into tbl_user_role_map(user_id, role_id) values($user_id, $role)";
		$self->dbh->do($sql) or $self->errhandle($sql);
	}
	$self->dbh->commit;
	$self->updateUsers;
	$self->render( json => { success => true } );
}

1;
