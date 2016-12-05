package OSiRIS::Model;

use base qw/DBIx::Class::Schema/;

# versioned schemas.
our $VERSION = 1;
__PACKAGE__->load_classes();

sub version {
    my ($self) = @_;
    return $VERSION;
}

1;