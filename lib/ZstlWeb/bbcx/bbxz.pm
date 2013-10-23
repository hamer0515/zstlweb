package ZstlWeb::bbcx::bbxz;

use Mojo::Base 'Mojolicious::Controller';
use boolean;
use Env qw/ZSTLWEB_HOME/;

sub download {
	my $self = shift;
	my $date = $self->param('date');
	$date =~ s/\-//g;
	my ( $Y, $m, $d ) = unpack( 'A4A2A2', $date );
	my $y = substr $Y, 2;

	#utype, itype
	my $utype = $self->session->{utype};
	my $itype = $self->session->{itype};

	my $uname = $self->dict->{pft_inst}{$utype}[1];
	my $file  = '';
	if ( $itype == 1 ) {
		$file =
		  "data/rpt/chnl/$utype/$y$m/$d/$Y-$m-$d-渠道报表-${uname}.xls";
	}
	elsif ( $itype == 2 ) {
		$file =
		  "data/rpt/tech/$utype/$y$m/$d/$Y-$m-$d-服务商报表-${uname}.xls";
	}
	else {
		$self->render( json => { success => 'forbidden' } );
		return;
	}
	if ( -e "$ZSTLWEB_HOME/public/$file" ) {
		$self->render( json => { success => true, path => $file } );
	}
	else {
		$self->render( json => { success => 'none' } );
	}

}

1;
