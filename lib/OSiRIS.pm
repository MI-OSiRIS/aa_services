package OSiRIS;

use Mojo::Base -base;
use Mojo::Log;
use OSiRIS::Config;

unless ($ENV{AA_HOME}) {
    $ENV{AA_HOME} = '/opt/MI-OSiRIS/aa_services';
}

has home => sub { return $ENV{AA_HOME} };
has log => sub { return Mojo::Log->new(path => "$ENV{AA_HOME}/var/log/aa_services.log", level => 'warn') };
has config => sub {
    unless ($config) {
        $config = OSiRIS::Config->parse("$ENV{AA_HOME}/etc/aa_services.conf");
    }
    return $config;
};

1;