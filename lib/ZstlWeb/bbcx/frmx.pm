package ZstlWeb::bbcx::frmx;

use Mojo::Base 'Mojolicious::Controller';
use boolean;

sub list {
	my $self  = shift;
	my $page  = $self->param('page');
	my $limit = $self->param('limit');

	# mid
	my $mid = $self->param('mid');

	# mname
	my $mname = $self->param('mname');

	#sdate
	my $sdate_from = $self->param('sdate_from');
	my $sdate_to   = $self->param('sdate_to');

	#utype, itype
	my $utype = $self->session->{utype};
	my $itype = $self->session->{itype};

	my $sql = '';

	my $excondition = '';
	if ($mname) {
		$excondition = "and mcht_inf.mname like \'%$mname%\'";
	}

	# 技术服务商
	if ( $itype == 2 ) {
		my $par = {
			'dtl.p_tech' => $utype,
			'dtl.mid'    => $mid,
			'dtl.sdate'  => [
				0,
				$sdate_from && $self->quote($sdate_from),
				$sdate_to   && $self->quote($sdate_to)
			],
		};
		my $p         = $self->params($par);
		my $condition = $p->{condition};

		$sql = "SELECT
	mname,
    mid,
    sdate,
    tdt,
    ssn,
    tamt,
    pft,
    lfee,
    je,
    rownumber() over() AS rowid
FROM
    (
        SELECT
            mcht_inf.mname 				AS mname,
            dtl.mid 					AS mid,
            dtl.sdate 					AS sdate,
            dtl.tdt 					AS tdt,
            dtl.ssn 					AS ssn,
            dtl.tamt 					AS tamt,
            dtl.pft_tech 				AS pft,
            dtl.lfee_tech 				AS lfee,
            dtl.pft_tech - dtl.lfee_tech 	AS je
        FROM
            dtl
        JOIN 
       		mcht_inf
       	ON
       		dtl.mid = mcht_inf.mid $condition $excondition)";
	}

	# 渠道
	elsif ( $itype == 1 ) {
		my $par = {
			'dtl.p_chnl' => $utype,
			'dtl.mid'    => $mid,
			'dtl.sdate'  => [
				0,
				$sdate_from && $self->quote($sdate_from),
				$sdate_to   && $self->quote($sdate_to)
			],
		};
		my $p         = $self->params($par);
		my $condition = $p->{condition};

		$sql = "SELECT
	mname,
    mid,
    sdate,
    tdt,
    ssn,
    tamt,
    pft,
    lfee,
    je,
    rownumber() over() AS rowid
FROM
    (
        SELECT
           mcht_inf.mname 				AS mname,
            dtl.mid 					AS mid,
            dtl.sdate 					AS sdate,
            dtl.tdt 					AS tdt,
            dtl.ssn 					AS ssn,
            dtl.tamt 					AS tamt,
            dtl.pft_chnl 				AS pft,
            dtl.lfee_chnl 				AS lfee,
            dtl.pft_chnl - dtl.lfee_chnl 	AS je
        FROM
            dtl
        JOIN 
       		mcht_inf
       	ON
       		dtl.mid = mcht_inf.mid $condition $excondition)";
	}

	# 运营
	elsif ( $itype == 0 ) {
		my $par = {
			'dtl.mid'   => $mid,
			'dtl.sdate' => [
				0,
				$sdate_from && $self->quote($sdate_from),
				$sdate_to   && $self->quote($sdate_to)
			],
		};
		my $p         = $self->params($par);
		my $condition = $p->{condition};

		$sql = "SELECT
	mname,
    mid,
    sdate,
    tdt,
    ssn,
    tamt,
    pft,
    lfee,
    je,
    rownumber() over() AS rowid
FROM
    (
        SELECT
        	mcht_inf.mname 				AS mname,
            dtl.mid 					AS mid,
            dtl.sdate 					AS sdate,
            dtl.tdt 					AS tdt,
            dtl.ssn 					AS ssn,
            dtl.tamt 					AS tamt,
            dtl.pft_self 				AS pft,
            dtl.lfee_self 				AS lfee,
            dtl.pft_self - dtl.lfee_self 	AS je
        FROM
            dtl
       	JOIN 
       		mcht_inf
       	ON
       		dtl.mid = mcht_inf.mid $condition $excondition)";
	}
	my $data = $self->page_data( $sql, $page, $limit );
	$data->{success} = true;
	$self->render( json => $data );
}

sub detail {
	my $self = shift;
	my $ssn  = $self->param('ssn');
	my $tdt  = $self->param('tdt');
	my $sql  = "SELECT
				    mid,
				    tamt,
				    pft_1,
				    pft_2,
				    pft_3,
				    pft_4,
				    pft_5,
				    p_1,
				    p_2,
				    p_3,
				    p_4,
				    p_5,
				    lfee_1,
				    lfee_2,
				    lfee_3,
				    lfee_4,
				    lfee_5
				FROM
				    dtl
				WHERE
				    ssn = \'$ssn\'
				AND tdt = \'$tdt\'";
	my $data = $self->select($sql)->[0];
	$data->{tamt} = $self->nf( $data->{tamt} / 100 );
	for ( 1 .. 5 ) {

		if ( $data->{"p_$_"} ) {
			$data->{"je_$_"} =
			  $self->nf( ( $data->{"pft_$_"} - $data->{"lfee_$_"} ) / 100 );
			$data->{"pft_$_"}  = $self->nf( $data->{"pft_$_"} / 100 );
			$data->{"lfee_$_"} = $self->nf( $data->{"lfee_$_"} / 100 );
		}
	}
	$data->{success} = true;
	$self->render( json => $data );
}

1;
