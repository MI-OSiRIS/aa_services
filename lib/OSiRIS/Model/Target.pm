package OSiRIS::Model::Target;

use OSiRIS::AccessAssertion::RSA::Certificate;
use OSiRIS::AccessAssertion::RSA::Key;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('osiris_aa_target');

__PACKAGE__->add_columns(
    id => {
        is_auto_increment => 1,
        data_type         => 'integer',
        is_numeric        => 1,
    },
    entity_id => {
        data_type => 'varchar',
        size => 255,
    },
    create_time => {
        data_type  => 'integer',
        is_numeric => 1,
    },
    modify_time => {
        data_type  => 'integer',
        is_numeric => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint(entity_id  => ['entity_id']);

__PACKAGE__->has_many(certificates => 'OSiRIS::Model::Target::Certificate', 'target');
__PACKAGE__->has_many(keys => 'OSiRIS::Model::Target::Key', 'target');
__PACKAGE__->has_many(aliases => 'OSiRIS::Model::Target::Alias', 'target');

sub current_encryption_certificate {
    my ($self) = @_;

    if (my $row = $self->_most_current('certificate', 'encryption')) {
        return OSiRIS::AccessAssertion::RSA::Certificate->new(\$row->pem_string);    
    }
    
    return undef;
}

sub current_encryption_key {
    my ($self) = @_;
    
    if (my $row = $self->_most_current('key', 'encryption')) {
        return OSiRIS::AccessAssertion::RSA::Key->new({
            string => $row->pem_string,
            cert => $self->current_encryption_certificate,
        });    
    }
    
    return undef;
}

sub current_signing_certificate {
    my ($self) = @_;
    
    if (my $row = $self->_most_current('certificate', 'signing')) {
        return OSiRIS::AccessAssertion::RSA::Certificate->new(\$row->pem_string);    
    }
    
    return undef;
}

sub current_signing_key {
    my ($self) = @_;
    
    if (my $row = $self->_most_current('key', 'signing')) {
        return OSiRIS::AccessAssertion::RSA::Key->new({
            string => $row->pem_string,
            cert => $self->current_signing_certificate,
        });    
    }
    
    return undef;
}

sub _most_current {
    my ($self, $what, $type) = @_;
    unless ($what =~ /s$/o) {
        $what .= "s";
    }
    
    $type = 'signing' unless $type;
    
    return $self->$what->find({ type => $type }, {
        order_by => { -desc => 'create_time' },
        limit => 1,  
    });
}

# do this extra stuff on insert
sub insert {
    my ($self, @args) = @_;
    $self->create_time(time);
    $self->modify_time(time);
    $self->next::method(@args);
}

sub update {
    my ($self, @args) = @_;
    $self->modify_time(time);
    $self->next::method(@args);
}

1;