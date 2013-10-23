package ZstlWeb::jycx::ssjycx;

use Mojo::Base 'Mojolicious::Controller';
use boolean;

sub list {
	my $self = shift;

	my $page  = $self->param('page');
	my $limit = $self->param('limit');

	# mid
	my $mid = $self->param('mid');

	# ptid
	my $ptid = $self->param('ptid');

	# cno
	my $cno = $self->param('cno');

	# refnum
	my $refnum = $self->param('refnum');

	# tsn
	my $tsn = $self->param('tsn');

	#ptdt
	my $ptdt_from = $self->param('ptdt_from');
	my $ptdt_to   = $self->param('ptdt_to');

	#utype, itype
	my $utype = $self->session->{utype};
	my $itype = $self->session->{itype};

	my $par = {
		mid    => $mid    && $self->quote($mid),
		ptid   => $ptid   && $self->quote($ptid),
		cno    => $cno    && $self->quote($cno),
		refnum => $refnum && $self->quote($refnum),
		tsn    => $tsn    && $self->quote($tsn),
		ptdt   => [
			0,
			$ptdt_from && $self->quote($ptdt_from),
			$ptdt_to   && $self->quote($ptdt_to)
		],
	};
	my $p         = $self->params($par);
	my $condition = $p->{condition};
	my $sql       = '';
	if ( $itype == 2 ) {
		$sql = "SELECT
	resp_code,
	rev_flag,
	mname,
    refnum,
    tsn,
    mid,
    ptid,
    ptdt,
    tcode,
    cno,
    ctype,
    tamt,
    rownumber() over() AS rowid
FROM
    (
        SELECT
        	resp_code,
        	rev_flag,
        	mname,
        	refnum,
        	tsn,
            mid,
            ptid,
            ptdt,
            tcode,
            cno,
            ctype,
            tamt
        FROM
            txn_log_cardsv
        WHERE
            mid IN
            (
                SELECT
                    mid
                FROM
                    mcht_inf
                WHERE
                    tech_id = $utype ) $condition
            order by ptdt desc)"
		  ;
	}
	elsif ( $itype == 1 ) {
		$sql = "SELECT
	resp_code,
	rev_flag,
	mname,
    refnum,
    tsn,
    mid,
    ptid,
    ptdt,
    tcode,
    cno,
    ctype,
    tamt,
    rownumber() over() AS rowid
FROM
    (
        SELECT
        	resp_code,
        	rev_flag,
        	mname,
        	refnum,
        	tsn,
            mid,
            ptid,
            ptdt,
            tcode,
            cno,
            ctype,
            tamt
        FROM
            txn_log_cardsv
        WHERE
            mid IN
            (
                SELECT
                    mid
                FROM
                    mcht_inf
                WHERE
                    chnl_id = $utype ) $condition
            order by ptdt desc)"
		  ;
	}
	elsif ( $itype == 0 ) {
		$condition =~ s/^ and // if $condition;
		$condition = 'where ' . $condition if $condition;
		$sql = "SELECT
	resp_code,
	rev_flag,
	mname,
    refnum,
    tsn,
    mid,
    ptid,
    ptdt,
    tcode,
    cno,
    ctype,
    tamt,
    rownumber() over() AS rowid
FROM
    (
        SELECT
        	resp_code,
       		rev_flag,
        	mname,
		    refnum,
		    tsn,
            mid,
            ptid,
            ptdt,
            tcode,
            cno,
            ctype,
            tamt
        FROM
            txn_log_cardsv
            $condition
        order by ptdt desc)"
		  ;
	}
	my $data = $self->page_data( $sql, $page, $limit );
	$data->{success} = true;
	$self->render( json => $data );
}

1;
