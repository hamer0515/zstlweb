package ZstlWeb::bbcx::frmx;

use Mojo::Base 'Mojolicious::Controller';
use boolean;

sub list {
	my $self  = shift;
	my $page  = $self->param('page');
	my $limit = $self->param('limit');

	# mid
	my $mid = $self->param('mid');

	#sdate
	my $sdate_from = $self->param('sdate_from');
	my $sdate_to   = $self->param('sdate_to');

	#utype, itype
	my $utype = $self->session->{utype};
	my $itype = $self->session->{itype};

	my $sql = '';

	# 技术服务商
	if ( $itype == 2 ) {
		my $par = {
			p_tech => $utype,
			mid    => $mid,
			sdate  => [
				0,
				$sdate_from && $self->quote($sdate_from),
				$sdate_to   && $self->quote($sdate_to)
			],
		};
		my $p         = $self->params($par);
		my $condition = $p->{condition};

		if ($condition) {
			$condition =~ s/^ and //;
			$condition = 'where ' . $condition;
		}
		$sql = "SELECT
    mid,
    sdate,
    tdt,
    ssn,
    tamt,
    pft_tech,
    lfee_tech,
    je,
    rownumber() over() AS rowid
FROM
    (
        SELECT
            mid,
            sdate,
            tdt,
            ssn,
            tamt,
            pft_tech,
            lfee_tech,
            pft_tech - lfee_tech AS je
        FROM
            dtl
        $condition)";
	}

	# 渠道
	elsif ( $itype == 1 ) {
		my $par = {
			p_chnl => $utype,
			mid    => $mid,
			sdate  => [
				0,
				$sdate_from && $self->quote($sdate_from),
				$sdate_to   && $self->quote($sdate_to)
			],
		};
		my $p         = $self->params($par);
		my $condition = $p->{condition};

		if ($condition) {
			$condition =~ s/^ and //;
			$condition = 'where ' . $condition;
		}
		$sql = "SELECT
    mid,
    sdate,
    tdt,
    ssn,
    tamt,
    pft_chnl,
    lfee_chnl,
    je,
    rownumber() over() AS rowid
FROM
    (
        SELECT
            mid,
            sdate,
            tdt,
            ssn,
            tamt,
            pft_chnl,
            lfee_chnl,
            pft_chnl - lfee_chnl AS je
        FROM
            dtl
        $condition )";
	}

	# 运营
	elsif ( $itype == 0 ) {
		my $par = {
			mid   => $mid,
			sdate => [
				0,
				$sdate_from && $self->quote($sdate_from),
				$sdate_to   && $self->quote($sdate_to)
			],
		};
		my $p         = $self->params($par);
		my $condition = $p->{condition};

		if ($condition) {
			$condition =~ s/^ and //;
			$condition = 'where ' . $condition;
		}
		$sql = "SELECT
    mid,
    sdate,
    tdt,
    ssn,
    tamt,
    pft_self,
    lfee_self,
    je,
    rownumber() over() AS rowid
FROM
    (
        SELECT
            mid,
            sdate,
            tdt,
            ssn,
            tamt,
            pft_self,
            lfee_self,
            pft_self - lfee_self AS je
        FROM
            dtl
        $condition )";
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
	for ( 1 .. 5 ) {
		if ( $data->{"p_$_"} ) {
			$data->{"je_$_"} =
			  $self->nf( $data->{"pft_$_"} - $data->{"lfee_$_"} );
			$data->{"pft_$_"}  = $self->nf( $data->{"pft_$_"} );
			$data->{"lfee_$_"} = $self->nf( $data->{"lfee_$_"} );
		}
	}
	$data->{success} = true;
	$self->render( json => $data );
}

1;
