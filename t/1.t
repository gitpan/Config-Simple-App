# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use diagnostics;
use Test::More qw/no_plan/;
use_ok('Config::Simple::App');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

{
    package Test::Config;
    use base qw( Config::Simple::App );

    sub _init {
        my $self = shift;
        $self->define("Path", "./");
        $self->define("TemplatePath", $self->Path . 'tmpl');
        $self->define("URL");
        $self->define("CGIPath", $self->URL . 'cgi-bin/');
        $self->define("Trace", 2);
        
    }
}


my $config = Test::Config->new( 't/config.ini' );
ok($config);

ok($config->can("CGIPath") && $config->can('URL') && $config->can('Path'));
ok($config->URL eq 'http://author.handalak.com/', "URL: " . $config->URL);
ok($config->CGIPath eq 'http://author.handalak.com/cgi-bin/', "CGIPath: " . $config->CGIPath);
ok($config->Path eq '/home/sherzodr/public_html/author/', "Path: " . $config->Path );
ok($config->Trace == 2);

my $hashref = $config->as_hashref();
ok($hashref->{URL} eq $config->URL);
ok($hashref->{CGIPath} eq $config->CGIPath);
ok($hashref->{Path} eq $config->Path);
ok($hashref->{Trace} == $config->Trace);

ok( $Test::Config::_config_instance, "Configuration class instance exists: " . $Test::Config::_config_instance);

$config->teardown();

ok( !$Test::Config::_config_instance, "Configuration class instance DOES NOT exists");
ok( !$config->can("CGIPath"));
ok( !$config->can("URL")  );
ok( !$config->can("Path") );

