package OSiRIS::AccessAsssertion::Target;
use Mojo::Base -base;
use Mojo::UserAgent;
use Mojo::Collection;
use Mojo::URL;
use Data::Dumper;
use OSiRIS::AccessAssertion::RSA::Certificate;
use OSiRIS::AccessAsssertion::Util qw/slurp spurt unarmor/;
use Carp qw/croak/;

my $known_targets = {};

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
        $self->{cert} = OSiRIS::AccessAssertion::RSA::Certificate->new(\$pem);
    } elsif (my $url = delete $self->{cert_url}) {
        my $ua = Mojo::UserAgent->new();
        $url = Mojo::URL->new($url);
        if ($url->scheme && $url->host) {
            my $pem = $ua->get($url)->tx->res->content;
            $self->{cert} = OSiRIS::AccessAssertion::RSA::Certificate->new(\$pem);
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

# returns a Mojo::Collection of all known targets
sub all_known_targets {
    my $kt_dir = "$ENV{AA_HOME}/var/known_targets";

    unless (-d $kt_dir) {
        system("mkdir -p $kt_dir");
    }

    opendir my $dir, $kt_dir or $self->app->log->error("error: can't open directory $kt_dir") && return undef;

    my $c = Mojo::Collection->new;
    while (my $file = readdir($dir)) {
        next if $file =~ /^\./;
        if (my $target = $known_targets->{"$kt_dir/$file"}) {
            # cached...
            push(@$c, $target->{_config}); 
        } else {
            # gotta load..
            my $loaded_target = {
                _config => load("$kt_dir/$file"),
                _load_time => time,
            };
        
            # cache
            $known_targets->{"$kt_dir/$file"} = $known_targets->{$loaded_target}->{_config}->{entity_id}} = $loaded_target;
        
            push(@$c, $loaded_target->{_config});
        }
    }

    return $c;
}

# render and save the thumbprint index
sub _build_thumbprint_index {
    my ($c) = @_;
    my $idx = {};
    foreach my $fed (@{$c->saml2->all_federations}) {
        my $count = 0;
        if (ref($fed) eq "HASH") {
            if (ref($fed->{entity_certificates}) eq "HASH") {
                if (ref($fed->{entity_certificates}->{signing}) eq "ARRAY") {
                    foreach my $key (@{$fed->{entity_certificates}->{signing}}) {
                        my $tp = $c->thumbprint(b64_decode($key));
                        unless (grep($fed->{entity_id}, @{$idx->{$tp}})) {
                            push(@{$idx->{$tp}}, $fed->{entity_id});
                            $count++;
                        }
                    }
                }
                if (ref($fed->{entity_certificates}->{encryption}) eq "ARRAY") {
                    foreach my $key (@{$fed->{entity_certificates}->{encryption}}) {
                        my $tp = $c->thumbprint(b64_decode($key));
                        unless (grep($fed->{entity_id}, @{$idx->{$tp}})) {
                            push(@{$idx->{$tp}}, $fed->{entity_id});
                            $count++;
                        }
                    }
                }
            }
        }
        if ($ENV{ACADEMICA_DEBUG}) {
            if ($count) {
                print "[saml2] build_thumbprint_index - $fed->{entity_id} has $count signing and/or encryption key(s)\n";
            } else {
                print "[saml2] build_thumbprint_index - $fed->{entity_id} has no signing and/or encryption keys\n";
            }
        }
    }
    print "[saml2] built new key thumbprint index containing @{[scalar keys %$idx]} records\n" if $ENV{ACADEMICA_DEBUG};
    $c->save_hashref($idx, "$ENV{ACADEMICA_HOME}/../var/plugins/saml2/thumbprint.idx");
    return $idx;
}

# load and retrieve thumbprint index
sub _thumbprint_index {
    my ($c) = @_;

    my $idx_file = "$ENV{ACADEMICA_HOME}/../var/plugins/saml2/thumbprint.idx";

    unless (keys %$tp_idx) {
        if (-e $idx_file) {
            print "[saml2] thumbprint_index - loading previously built key thumbprint index\n" if $ENV{ACADEMICA_DEBUG};
            $c->app->log->info("saml2 - thumbprint_index - loading previously built key thumbprint index");
            # file exists, just load it
            $tp_idx = $c->app->plugin('Academica::Config', { file => $idx_file, just_parse => 1 });
        } else {
            # file doesn't exist yet, build it and return it.
            print "[saml2] thumbprint_index - key thumbprint index doesn't exist, building...\n" if $ENV{ACADEMICA_DEBUG};
            $c->app->log->error("saml2 - thumbprint_index - thumbprint index doesn't exist, building one...");
            $tp_idx = $c->saml2->build_thumbprint_index;
        }
    }

    return $tp_idx;
}

sub _thumbprint_to_entity_id {
    my ($c, $thumbprint) = @_;
    if (my $ar = $c->saml2->thumbprint_index->{$thumbprint}) {
        if (ref $ar eq "ARRAY") {
            if (scalar(@$ar) > 1) {
                $c->log->warn("saml2 - $thumbprint resolves to more than one entity_id, returning first.  entities: " . join(', ', @$ar));
            }
            return $ar->[0];
        }
    }
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