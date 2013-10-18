package ZstlWeb::Login::Login;

use Mojo::Base 'Mojolicious::Controller';
use Digest::MD5;
use JSON::XS;
use DateTime;
use boolean;
use Encode qw/decode/;

sub login {
	my $self      = shift;
	my $username  = $self->param('username') || '';
	my $user_data = $self->dbh->selectrow_hashref(
		"select * from tbl_user_inf where status=1 and username=\'$username\'");
	unless ($user_data) {
		$self->render( json => { success => false } );
	}
	else {
		my $pwd = $self->param('password');
		$pwd = Digest::MD5->new->add($pwd)->hexdigest;
		if ( $user_data->{user_pwd} eq $pwd ) {
			$self->session->{uid}   = $user_data->{user_id};
			$self->session->{utype} = $user_data->{utype};
			$self->session->{utype} = ''
			  if $self->session->{utype} == 0;
			$self->session->{itype} = $user_data->{itype};
			$self->render( json => { success => true } );
		}
		else {
			$self->render( json => { success => false } );
		}
	}
}

sub menu {
	my $self = shift;
	my $uid  = $self->session->{uid};
	unless ($uid) {
		$self->render( json => { success => false } );
		return;
	}
	my $rdata = $self->select(
"select distinct route.route_name as text, route.route_value as url , route.parent_id, route.route_id 
	from tbl_route_inf route
	join tbl_role_route_map role_route
	on route.status = 1 and route.route_id = role_route.route_id
	join tbl_user_role_map user_role
	on user_role.role_id = role_route.role_id and user_role.user_id = $uid"
	);
	my $parents = [ grep { $_->{parent_id} == 0 } @$rdata ];
	for my $parent (@$parents) {
		my $children =
		  [ grep { $_->{parent_id} && $_->{parent_id} == $parent->{route_id} }
			  @$rdata ];
		map {
			delete $_->{route_id};
			delete $_->{parent_id};
			$_->{leaf} = true;
		} @$children;
		delete $parent->{route_id};
		delete $parent->{parent_id};
		$parent->{children} = $children;
	}
	$self->render( json => $parents );
}

sub passwordreset {
	my $self             = shift;
	my $old_password     = $self->param('oldpassword');
	my $new_password     = $self->param('newpassword');
	my $confirm_password = $self->param('confirmpassword');
	unless ( $old_password && $new_password && $confirm_password ) {
		$self->render(
			json => { success => false, msg => '密码不能为空' } );
		return 1;
	}
	my $uid = $self->session->{uid};
	$old_password = Digest::MD5->new->add($old_password)->hexdigest;
	my $sql =
"select * from tbl_user_inf where user_id=$uid and user_pwd=\'$old_password\'";
	my $user_data = $self->dbh->selectall_arrayref($sql);

	unless ( scalar @$user_data ) {
		$self->render(
			json => { success => false, msg => '旧密码不正确' } );
		return 1;
	}
	$self->dbh->begin_work;
	$new_password = Digest::MD5->new->add($new_password)->hexdigest;
	my $dt = DateTime->now( time_zone => 'local' );
	my $oper_date = $dt->ymd('-');
	$sql =
	    "update tbl_user_inf set pwd_chg_date = \'$oper_date\', user_pwd = '"
	  . $new_password
	  . "' where user_id = $uid";
	$self->dbh->do($sql) or die "can't do $sql:$self->dbh->errstr/n";
	$self->dbh->commit;
	$self->render( json => { success => true } );
}

sub logout {
	my $self = shift;
	delete $self->session->{uid};
	delete $self->session->{sid};
	$self->render( json => { success => true } );
}

sub show {
	my $self = shift;
	$self->render_static('index.html');
}

1;
