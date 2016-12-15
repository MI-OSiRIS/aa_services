package OSiRIS::Model::Entity::Certificate;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('osiris_aa_entity_certificate');

__PACKAGE__->add_columns(
    id => {
        is_auto_increment => 1,
        data_type         => 'integer',
        is_numeric        => 1,
    },
    entity => {
        data_type => 'integer',
        is_numeric => 1,
        is_foreign_key => 1,
    },
    # jwk thumbprint
    thumbprint => {
        data_type => 'varchar',
        size => 64,
    },
    # the jwk thumprint of the current signing public key of this entity.
    set_id => {
        data_type => 'varchar',
        size => 64,
    },
    pem_string => {
        data_type => 'text',
    },
    secret_key => {
        data_type => 'integer',
        is_numeric => 1,
        is_foreign_key => 1,
        is_nullable => 1,
    },
    is_primary => {
        data_type => 'integer',
        default_value => 0,
    },
    type => {
        is_enum   => 1,
        extra     => {
            list => [qw/encryption signing/],
        },
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
__PACKAGE__->add_unique_constraint(thumbprint  => ['thumbprint']);
__PACKAGE__->belongs_to(entity => 'OSiRIS::Model::Entity');
__PACKAGE__->might_have(secret_key => 'OSiRIS::Model::Entity::Key');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    $sqlt_table->add_index(
        name   => 'osiris_aa_thumbprint',
        fields => ['thumbprint'],
    );

    $sqlt_table->add_index(
        name   => 'osiris_aa_set_id',
        fields => ['set_id'],
    );

    $sqlt_table->add_index(
        name   => 'osiris_aa_type_idx',
        fields => ['type'],
    );
}

1;