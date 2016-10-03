package OSiRIS::AccessAsssertion::Target;
use Mojo::Base -base;
use Mojo::UserAgent;
use Mojo::URL;
use Data::Dumper;
use OSiRIS::AccessAssertion::Certificate;
use OSiRIS::AccessAsssertion::Util qw/slurp spurt unarmor/;
use Carp qw/croak/;

has target_dir => sub {
    return "$ENV{AA_HOME}/var/known_targets";
}

has [qw/provides thumbprint cert/];

sub new {
    my ($class, %opts) = @_;

    # see if we already have this target 🎯 on file, start from there if so...
    if (exists $opts{thumbprint} && $opts{thumbprint}) {
        if (__PACKAGE__->find($opts{thumbprint})) {
            croak "🎯 configuration for $opts{thumbprint} already exists, use find() method instead\n";
        }
    }

    my $self = bless(\%opts, $class);
    unless (ref $self->{provides} eq "ARRAY" && scalar @{$self->{provides}}) {
        croak "New target cannot provide nothing, please specify 'provides' e.g. provides => ['ceph', 'xen_vm']\n";
    }

    if (my $pem = delete $self->{cert_pem}) {
        $self->{cert} = OSiRIS::AccessAssertion::Certificate->new(\$pem);
    } elsif (my $url = delete $self->{cert_url}) {
        my $ua = Mojo::UserAgent->new();
        $url = Mojo::URL->new($url);
        if ($url->scheme && $url->host) {
            my $pem = $ua->get($url)->tx->res->content;
            $self->{cert} = OSiRIS::AccessAssertion::Certificate->new(\$pem);
        }
    }

    if ($self->{cert}) {
        $self->{thumbprint} = $self->{cert}->thumbprint;
    } else {
        croak "New target did not provide cert_pem or valid cert_url, one or the other is required\n";
    }

    $self->save;
    return $self;
}

sub find {
    my ($class, $thumbprint) = @_;

    my $file = "$ENV{AA_HOME}/var/known_targets/$thumbprint.conf";

    if (-e $file) {
        if (my $hr = load($file)) {
            return bless $hr, $class;
        }
    }

    return undef;
}

# sandboxed hashref eval
sub load {
    my ($file) = @_;
    
    my $content = slurp($file);
    # Run Perl code in sandbox
    my $config = eval 'package OSiRIS::AccessAssertion::Target::Sandbox; no warnings;'
        . "use Mojo::Base -strict; $content";

    die qq{Can't load configuration from file "$file": $@} if $@;

    die qq{Configuration file "$file" did not return a hash reference.\n}
    unless ref $config eq 'HASH';
}

# simple hashref write
sub save {
    my ($self) = @_;
    unless (-d $self->target_dir) {
        system(qw/mkdir -p/, $self->target_dir);
    }
    my $file = "@{[$self->target_dir]}/@{[$self->thumbprint]}.conf";
    local $Data::Dumper::Terse = 1;
    spurt (Dumper($hr), $file);
}

1;