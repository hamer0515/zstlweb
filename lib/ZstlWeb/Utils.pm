package ZstlWeb::Utils;

use base qw/Exporter/;
our @ISA = qw(Exporter);
our @EXPORT =
  qw(_transform _updateUsers _updateRoutes _uf _nf _initDict _decode_ch _page_data _select _update _errhandle _params)
  ;    #要输出给外部调用的函数或者变量，以空格分隔

sub _uf {
	my $number = shift;
	my $flag   = 0;
	$number = 0.00 unless ( defined $number );
	$number =~ s/,//g;
	return $number;
}

sub _nf {
	my $num = shift || 0;
	my $minus = 1;
	if ( $num < 0 ) {
		$num   = abs($num);
		$minus = -1;
	}
	$num = sprintf "%.2f", $num;
	my ( $p1, $p2 ) = split '\.', $num;

	my $len = length $p1;

	my $grp = int( $len / 3 );
	my $res = $len % 3;

	my $format;
	if ( $res == 0 ) {
		$format = "A3" x $grp;
	}
	else {
		$format = "A$res" . ( "A3" x $grp );
	}

	$p1 = join ',', unpack $format, $p1;

	if ( $minus > 0 ) {
		return "$p1.$p2";
	}
	else {
		return "-$p1.$p2";
	}
}

sub _initDict {
	my $self = shift;
	my $dict = $self->dict;
	my $data =
	  $self->select("select id, itype, name from pft_inst order by id");
	for my $row (@$data) {
		$dict->{pft_inst}{ $row->{id} } = [ $row->{itype}, $row->{name} ];
	}
	$self->updateUsers;
	$self->updateRoutes;
}

# 更新角色路由信息
sub _updateRoutes {
	my $self   = shift;
	my $routes = {};
	my $data   = $self->select(
		"select route.route_regex as route_regex, role_route.role_id as id
    	    from tbl_route_inf route 
    	    join tbl_role_route_map role_route 
    	    on role_route.route_id=route.route_id
            order by id"
	);
	for my $row (@$data) {
		$routes->{ $row->{id} } = [] unless exists $routes->{ $row->{id} };
		push @{ $routes->{ $row->{id} } }, $row->{route_regex}
		  if $row->{route_regex} ne '';
	}
	$self->memd->set( 'routes', $routes );
}

# 更新用户角色信息
sub _updateUsers {
	my $self      = shift;
	my $users     = {};
	my $usernames = {};
	my $uids      = {};
	my $data      = $self->select(
"select user.username as username, user.user_id as user_id, user_role.role_id as role_id
    	    from tbl_user_inf user 
    	    join tbl_user_role_map user_role 
    	    on user.user_id=user_role.user_id
            order by user_id"
	);
	for my $row (@$data) {
		$users->{ $row->{user_id} } = []
		  unless exists $users->{ $row->{user_id} };
		$usernames->{ $row->{user_id} } = $row->{username};
		$uids->{ $row->{username} }     = $row->{user_id};
		push @{ $users->{ $row->{user_id} } }, $row->{role_id};
	}
	$self->memd->set( 'users',     $users );
	$self->memd->set( 'usernames', $usernames );
	$self->memd->set( 'uids',      $uids );
}

sub _decode_ch {
	my $self = shift;
	my $row  = shift;

	# chinese decode
	for (
		qw/name memo text
		/
	  )
	{
		$row->{$_} = $self->my_decode( $row->{$_} ) if $row->{$_};
	}
}

sub _transform {
	my $self = shift;
	my $row  = shift;

}

sub _page_data {
	my $self  = shift;
	my $sql   = shift;
	my $page  = shift;
	my $limit = shift;
	my @data;

	my $start = ( $page - 1 ) * $limit + 1;
	my $end   = ( $start + $limit );

	my $sql_data  = "select * from ($sql) where rowid>=$start and rowid < $end";
	my $sql_count = "select count(*) from ($sql)";
	my $dbh       = $self->dbh;
	my $dh        = $dbh->prepare($sql_data);
	my $ch        = $dbh->prepare($sql_count);

	$dh->execute;
	while ( my $row = $dh->fetchrow_hashref ) {
		$self->decode_ch($row);
		push @data, $row;
	}
	$dh->finish;

	$ch->execute;
	my $count = $ch->fetchrow_arrayref->[0];

	return {
		data       => \@data,
		totalCount => $count,
	};
}

sub _select {
	my $self = shift;
	my $sql  = shift;
	my $data;
	$sql = $self->dbh->prepare($sql);
	$sql->execute;
	while ( my $row = $sql->fetchrow_hashref ) {
		$self->decode_ch($row);
		push @$data, $row;
	}
	$sql->finish;
	return $data;
}

sub _errhandle {
	my $self = shift;
	my $sql  = shift;
	$self->dbh->rollback;
	die "can't do [$sql]:" . $self->dbh->errstr;
	return 0;
}

sub _params {
	my $self      = shift;
	my $params    = shift;
	my $condition = '';

	for my $key ( keys %$params ) {
		my $type = ref $params->{$key};
		if ( $type eq 'ARRAY' ) {

			#
			# 0: >= and <=
			#
			my $data = $params->{$key};
			if ( $data->[0] == 0 ) {
				if ( $data->[1] ) {
					$condition .= " and $key>=$data->[1]";
				}
				if ( $data->[2] ) {
					$condition .= " and $key<=$data->[2]";
				}
			}
		}
		else {
			if ( defined $params->{$key} && $params->{$key} ne '' ) {
				$condition .= " and $key=$params->{$key}";
			}
		}
	}

	#	$condition =~ s/^ and // if $condition;
	return { condition => $condition };
}

1;

