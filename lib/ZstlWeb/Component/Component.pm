package ZstlWeb::Component::Component;

use Mojo::Base 'Mojolicious::Controller';
use Digest::MD5;
use JSON::XS;
use boolean;

sub roles {
	my $self = shift;
	my $id   = $self->param('id');
	my $data = $self->select(
		"select role_id from tbl_user_role_map where user_id = $id");
	my $result = [];
	for my $d (@$data) {
		push @$result, $d->{role_id};
	}
	$self->render( json => $result );
}

sub allroles {
	my $self = shift;
	my $data = $self->select(
		"select role_id, role_name as name from tbl_role_inf where status = 1");
	$self->render( json => $data );
}

sub routes {
	my $self = shift;
	my $id   = $self->param('id');
	my $sql =
	  "select distinct route_name as text, parent_id as parent_id, route_id
	    from tbl_route_inf where status>=1";
	my $rdata   = $self->select($sql);
	my $checked = {};
	if ($id) {
		my $cdata = $self->select(
			"select route_id from tbl_role_route_map where role_id = $id");
		for my $r (@$cdata) {
			$checked->{ $r->{route_id} } = true;
		}
	}
	my $parents = [ grep { $_->{parent_id} == 0 } @$rdata ];
	for my $parent (@$parents) {
		my $children =
		  [ grep { $_->{parent_id} && $_->{parent_id} == $parent->{route_id} }
			  @$rdata ];
		map {
			delete $_->{parent_id};
			$_->{leaf} = 1;
			$_->{checked} = $checked->{ $_->{route_id} } ||= false;
		} @$children;
		delete $parent->{parent_id};
		$parent->{checked} = $checked->{ $parent->{route_id} } ||= false;
		$parent->{children} = $children;
	}

	$self->render( json => $parents );
}

sub pft_inst {
	my $self   = shift;
	my $utype  = $self->param('utype');
	my $result = [];
	my $inst   = $self->dict->{pft_inst};
	for my $key (
		sort { $inst->{$a}->[2] cmp $inst->{$b}->[2] }
		grep { $inst->{$_}[0] == $utype } keys %$inst
	  )
	{
		push @$result, { id => $key, name => $inst->{$key}[1] };
	}

	$self->render( json => $result );
}

1;
