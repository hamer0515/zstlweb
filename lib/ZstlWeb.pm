package ZstlWeb;

use Mojo::Base 'Mojolicious';
use DBI;
use Env qw/ZSTLWEB_HOME/;
use Encode qw/decode/;
use Cache::Memcached;
use ZstlWeb::Utils
  qw/ _transform _updateUsers _updateRoutes _uf _nf _initDict _decode_ch _page_data _select _update _errhandle _params/;

# This method will run once at server start
sub startup {
	my $self   = shift;
	my $dict   = {};
	my $config = do "$ZSTLWEB_HOME/conf/conf.pl";
	my $dbh    = &connect_db($config);
	my $memd   = new Cache::Memcached {
		'servers'            => $config->{mem_server},
		'debug'              => 0,
		'compress_threshold' => 10_000,
	};

# 设置session签名的验证码（随机生成，每次重启后台的时候，session失效）
	my $secret = '';
	for ( 1 .. 10 ) {
		$secret .= ${ $config->{di} }[ rand(62) ];
	}
	$self->secret($secret);

	# 设置session过期时间
	$self->session( expiration => $config->{expire} );

	#	my $logdir = "$ZSTLWEB_HOME/log";
	#	unless ( -e $logdir && -d $logdir ) {
	#		`mkdir $logdir`;
	#	}
	#	my $logfile = "$ZSTLWEB_HOME/log/ZstlWeb.log";
	#	unless ( -e $logfile ) {
	#		`touch $logfile`;
	#	}
	#	my $log = Mojo::Log->new(
	#		path  => "$ZSTLWEB_HOME/log/ZstlWeb.log",
	#		level => 'info'
	#	);

	# hypnoload
	$self->config(
		hypnotoad => { listen => [ 'http://*:' . $config->{port} ] } );

	# plugin
	$self->plugin( Charset => { charset => 'utf-8' } );

	# helper
	#$self->helper( log          => sub { return $log; } );

	$self->helper(
		dbh => sub {
			$dbh = &connect_db( $self->configure )
			  unless $dbh;
			return $dbh;
		}
	);
	$self->helper( memd         => sub { return $memd; } );
	$self->helper( configure    => sub { return $config; } );
	$self->helper( quote        => sub { return $self->dbh->quote( $_[1] ); } );
	$self->helper( dict         => sub { return $dict; } );
	$self->helper( transform    => sub { &_transform(@_); } );
	$self->helper( my_decode    => sub { return &decode( 'utf8', $_[1] ); } );
	$self->helper( decode_ch    => sub { &_decode_ch(@_); } );
	$self->helper( page_data    => sub { &_page_data(@_); } );
	$self->helper( select       => sub { &_select(@_); } );
	$self->helper( update       => sub { &_update(@_); } );
	$self->helper( errhandle    => sub { &_errhandle(@_); } );
	$self->helper( uf           => sub { &_uf( $_[1] ); } );
	$self->helper( nf           => sub { &_nf( $_[1] ); } );
	$self->helper( params       => sub { &_params(@_); } );
	$self->helper( updateUsers  => sub { $self->_updateUsers; } );
	$self->helper( updateRoutes => sub { $self->_updateRoutes; } );
	$self->helper( routes       => sub { $self->memd->get('routes'); } );
	$self->helper( users        => sub { $self->memd->get('users'); } );
	$self->helper( usernames    => sub { $self->memd->get('usernames'); } );
	$self->helper( uids         => sub { $self->memd->get('uids'); } );

	# hook
	$self->hook( before_dispatch => \&_before_dispatch );

	# Router
	$self->set_route;

	# init
	$self->_initDict;
	$self->dbh->rollback;
	$self->dbh->disconnect;
	$dbh = undef;
}

sub _before_dispatch {
	my $self = shift;

	my $path = $self->req->url->path;
	return 1 if $path =~ /^\/$/;                      # 登陆页面可以访问
	return 1 if $path =~ /(js|jpg|gif|css|png|ico)$/; # 静态文件可以访问
	      # return 1 if $path =~ /html$/;              # login

	my $sess = $self->session;

	# 没有登陆不让访问
	return 1 if $path =~ /^\/login/;    # 可以访问主菜单
	return 1 if $path =~ /^\/base/;     # 可以访问主菜单

	#warn $path;
	if ( $path =~ /^index.html$/ ) {
		unless ( exists $sess->{uid} ) {
			$self->redirect_to('/');
			return;
		}
	}
	my $uid  = $sess->{uid};
	my $role = $self->users->{$uid};
	for my $role (@$role) {
		for my $route ( @{ $self->routes->{$role} } ) {
			if ( $path =~ m{$route$} ) {
				return 1;
			}
		}
	}
	$self->render( json => { success => 'forbidden' } );
}

#
#
#
sub connect_db {
	my $config = shift;
	my $dbh;
	$dbh = DBI->connect(
		$config->{dsn},
		$config->{user},
		$config->{pass},
		{
			RaiseError       => 0,
			PrintError       => 0,
			AutoCommit       => 0,
			FetchHashKeyName => 'NAME_lc',
			ChopBlanks       => 1,
		}
	);
	unless ($dbh) {
		die "can not connect $config->{dsn}";
		return;
	}

	$dbh->do("set current schema $config->{schema}")
	  or die "can not set current schema $config->{schema}";

	return $dbh;
}

sub set_route {
	my $self = shift;
	my $r    = $self->routes;

	# 登录页面
	$r->any('/')->to( namespace => 'ZstlWeb::Login::Login', action => 'show' );

	# 基础信息
	$r->any("/base/$_")
	  ->to( namespace => "ZstlWeb::Component::Component", action => $_ )
	  for (qw/routes roles allroles pft_inst/);

	# 登录路由
	$r->any("/login/$_")
	  ->to( namespace => "ZstlWeb::Login::Login", action => $_ )
	  for (qw/menu passwordreset login logout/);

	# 角色管理
	$r->any("/role/$_")->to( namespace => "ZstlWeb::Role::Role", action => $_ )
	  for (qw/list add check update delete/);

	# 用户管理
	$r->any("/user/$_")->to( namespace => "ZstlWeb::User::User", action => $_ )
	  for (qw/list add check update/);

	# 报表查询
	$r->any('/shdz/list')
	  ->to( namespace => 'ZstlWeb::bbcx::shdz', action => 'list' );
	$r->any('/shck/list')
	  ->to( namespace => 'ZstlWeb::bbcx::shck', action => 'list' );
	$r->any('/frmx/list')
	  ->to( namespace => 'ZstlWeb::bbcx::frmx', action => 'list' );
	$r->any('/frmx/detail')
	  ->to( namespace => 'ZstlWeb::bbcx::frmx', action => 'detail' );

	# 交易查询
	$r->any('/ssjycx/list')
	  ->to( namespace => 'ZstlWeb::jycx::ssjycx', action => 'list' );

	# 账户管理
	$r->any('/zhcx/list')
	  ->to( namespace => 'ZstlWeb::zhgl::zhcx', action => 'list' );
	$r->any('/zhcx/history')
	  ->to( namespace => 'ZstlWeb::zhgl::zhcx', action => 'history' )
	  ;
}

1;
