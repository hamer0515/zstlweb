package ZstlWeb::bbcx::shck;

use Mojo::Base 'Mojolicious::Controller';
use boolean;

sub list {
	my $self = shift;

	my $page  = $self->param('page');
	my $limit = $self->param('limit');

	# mid
	my $mid = $self->param('mid');

	#cdate
	my $cdate_from = $self->param('cdate_from');
	my $cdate_to   = $self->param('cdate_to');

	#utype, itype
	my $utype = $self->session->{utype};
	my $itype = $self->session->{itype};

	my $par = {
		'clearing_log.mid'     => $mid,
		'clearing_batch.cdate' => [
			0,
			$cdate_from && $self->quote($cdate_from),
			$cdate_to   && $self->quote($cdate_to)
		],
	};
	my $p         = $self->params($par);
	my $condition = $p->{condition};
	my $sql       = '';
	if ( $itype == 2 ) {
		$sql = "SELECT
    mid,
    fbatch,
    amt,
    cdate,
    status,
    rownumber() over() AS rowid
FROM
    (
        SELECT
            clearing_log.mid      AS mid,
            clearing_log.fbatch   AS fbatch,
            clearing_log.amt      AS amt,
            clearing_batch.cdate  AS cdate,
            clearing_batch.status AS status
        FROM
            (
                SELECT
                    mid,
                    fbatch,
                    SUM(amt) AS amt
                FROM
                    clearing_log
                GROUP BY
                    mid,
                    fbatch
                HAVING
                    mid IN
                    (
                        SELECT
                            mid
                        FROM
                            mcht_inf
                        WHERE
                            tech_id = $utype ) ) clearing_log
        JOIN
            clearing_batch
        ON
            clearing_log.fbatch = clearing_batch.fbatch $condition )"
		  ;
	}
	elsif ( $itype == 1 ) {
		$sql = "SELECT
    mid,
    fbatch,
    amt,
    cdate,
    status,
    rownumber() over() AS rowid
FROM
    (
        SELECT
            clearing_log.mid      AS mid,
            clearing_log.fbatch   AS fbatch,
            clearing_log.amt      AS amt,
            clearing_batch.cdate  AS cdate,
            clearing_batch.status AS status
        FROM
            (
                SELECT
                    mid,
                    fbatch,
                    SUM(amt) AS amt
                FROM
                    clearing_log
                GROUP BY
                    mid,
                    fbatch
                HAVING
                    mid IN
                    (
                        SELECT
                            mid
                        FROM
                            mcht_inf
                        WHERE
                            chnl_id = $utype ) ) clearing_log
        JOIN
            clearing_batch
        ON
            clearing_log.fbatch = clearing_batch.fbatch $condition )"
		  ;
	}
	elsif ( $itype == 0 ) {
		$sql = "SELECT
    mid,
    fbatch,
    amt,
    cdate,
    status,
    rownumber() over() AS rowid
FROM
    (
        SELECT
            clearing_log.mid      AS mid,
            clearing_log.fbatch   AS fbatch,
            clearing_log.amt      AS amt,
            clearing_batch.cdate  AS cdate,
            clearing_batch.status AS status
        FROM
            (
                SELECT
                    mid,
                    fbatch,
                    SUM(amt) AS amt
                FROM
                    clearing_log
                GROUP BY
                    mid,
                    fbatch
             ) clearing_log
        JOIN
            clearing_batch
        ON
            clearing_log.fbatch = clearing_batch.fbatch $condition )"
		  ;
	}
	my $data = $self->page_data( $sql, $page, $limit );
	$data->{success} = true;
	$self->render( json => $data );
}

1;