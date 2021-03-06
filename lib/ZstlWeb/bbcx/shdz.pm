package ZstlWeb::bbcx::shdz;

use Mojo::Base 'Mojolicious::Controller';
use boolean;

sub list {
	my $self = shift;

	my $page  = $self->param('page');
	my $limit = $self->param('limit');

	# mid
	my $mid = $self->param('mid');

	# refnum
	my $refnum = $self->param('refnum');

	# cno
	my $cno = $self->param('cno');

	# ctype
	my $ctype = $self->param('ctype');

	#sdate
	my $sdate_from = $self->param('sdate_from');
	my $sdate_to   = $self->param('sdate_to');

	#utype, itype
	my $utype = $self->session->{utype};
	my $itype = $self->session->{itype};

	my $par = {};
	my $sql = '';
	if ( $itype == 2 ) {
		$par = {
			'bms_log.refnum' => $refnum && $self->quote($refnum),
			'bms_log.cno'    => $cno    && $self->quote($cno),
			'dtl.p_tech'     => $utype,
			'dtl.mid'        => $mid,
			'dtl.sdate'      => [
				0,
				$sdate_from && $self->quote($sdate_from),
				$sdate_to   && $self->quote($sdate_to)
			],
		};
	}
	else {
		$par = {
			'bms_log.refnum' => $refnum && $self->quote($refnum),
			'bms_log.cno'    => $cno    && $self->quote($cno),
			'dtl.p_chnl'     => $utype,
			'dtl.mid'        => $mid,
			'dtl.sdate'      => [
				0,
				$sdate_from && $self->quote($sdate_from),
				$sdate_to   && $self->quote($sdate_to)
			],
		};
	}
	if ($ctype) {
		if ( $ctype == 1 ) {
			$par->{'bms_log.ctype'} = $self->quote($ctype);
		}
		else {
			$par->{'bms_log.ctype'} = [ 0, $self->quote($ctype) ];
		}
	}
	my $p = $self->params($par);
	$sql =
"select mid, mname, refnum, sdate, tid, tdt, ctype, ssn, cno, tcode, tamt, mfee, bj, rownumber() over() as rowid from (
	select dtl.mid as mid, bms_log.mname as mname,
	    dtl.sdate as sdate, bms_log.tid as tid, 
	    dtl.tdt as tdt, bms_log.ctype as ctype, 
	    dtl.ssn as ssn, bms_log.cno as cno,
	    dtl.tcode as tcode, dtl.tamt as tamt,
	    dtl.mfee as mfee, dtl.bj as bj,
	    bms_log.refnum as refnum
		from dtl
		join bms_log
		on dtl.tdt = bms_log.tdt and dtl.ssn = bms_log.ssn $p->{condition}) ";
	my $condition = $p->{condition};
	$condition =~ s/^ and // if $condition;
	$condition = 'where ' . $condition if $condition;
	my $sql_sum =
"select sum(tamt) as tamt, sum(mfee) as mfee, sum(bj) as bj from dtl $condition";
	my $sum = $self->select($sql_sum);
	my $data = $self->page_data( $sql, $page, $limit );
	$data->{data}[0]{sum} = $sum;
	$data->{success} = true;
	$self->render( json => $data );
}

1;
