package ZstlWeb::zhgl::zhcx;

use Mojo::Base 'Mojolicious::Controller';
use boolean;

sub list {
	my $self  = shift;
	my $page  = $self->param('page');
	my $limit = $self->param('limit');

	# mid
	my $mid = $self->param('mid');

	#utype, itype
	my $utype = $self->session->{utype};
	my $itype = $self->session->{itype};

	my $sql = '';

	my $par = { mid => $mid };

	# 渠道
	if ( $itype == 1 ) {
		$par->{chnl_id} = $utype;
	}
	elsif ( $itype == 2 ) {
		$self->render( json => { success => 'forbidden' } );
		return;
	}
	my $p         = $self->params($par);
	my $condition = $p->{condition};
	$condition =~ s/^ and // if $condition;

	#	$condition = 'where ' . $condition if $condition;
	$sql = "SELECT
	ts_u,
    mid,
    mname,
    r_0,
    r_1,
    rownumber() over() AS rowid
FROM
    (
        SELECT
         	mcht_acct.ts_u 	AS ts_u,
            mcht_acct.mid 	AS mid,
            mcht_inf.mname  AS mname,
            mcht_acct.r_0 	AS r_0,
            mcht_acct.r_1 	AS r_1
        FROM
            mcht_acct 
        JOIN 
        	mcht_inf
        ON
        	mcht_inf.mid = mcht_acct.mid $condition)";
	my $data = $self->page_data( $sql, $page, $limit );
	$data->{success} = true;
	$self->render( json => $data );
}

sub history {
	my $self = shift;
	my $mid  = $self->param('mid');
	my $sql  = "SELECT
    IN,
    OUT,
    balance,
    memo,
    ts_c
FROM
    mcht_alog
WHERE
    mid = \'$mid\'
ORDER BY
    ts_c DESC";
	my $data = $self->select($sql);
	$self->render( json => { data => $data, success => true } );
}

1;
