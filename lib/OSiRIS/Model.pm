package OSiRIS::Model;

# install the schema
# dbic-migration -S OSiRIS::Model --dsn dbi:SQLite:dbname=$AA_HOME/var/aa_services.dat --target_dir /tmp/migration prepare
# dbic-migration -S OSiRIS::Model --dsn dbi:SQLite:dbname=$AA_HOME/var/aa_services.dat --target_dir /tmp/migration install

use base qw/DBIx::Class::Schema/;

# versioned schemas.
our $VERSION = 1;
__PACKAGE__->load_classes();

sub version {
    my ($self) = @_;
    return $VERSION;
}

1;