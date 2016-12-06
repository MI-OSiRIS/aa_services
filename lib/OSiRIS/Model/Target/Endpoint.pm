package OSiRIS::Model::Target::Endpoint;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('osiris_aa_target_endpoint');

__PACKAGE__->add_columns(
    id => {
        is_auto_increment => 1,
        data_type         => 'integer',
        is_numeric        => 1,
    },
    target => {
        data_type => 'integer',
        is_numeric => 1,
        is_foreign_key => 1,
    },
    endpoint_url => {
        data_type => 'text',
    },
    encryption_key => {
        data_type => 'integer',
        is_numeric => 1,
        is_foreign_key => 1,
        is_nullable => 1,
    },
    encryption_certificate => {
        data_type => 'integer',
        is_numeric => 1,
        is_foreign_key => 1,
        is_nullable => 1,
    },
    signing_key => {
        data_type => 'integer',
        is_numeric => 1,
        is_foreign_key => 1,
        is_nullable => 1,
    },
    signing_certificate => {
        data_type => 'integer',
        is_numeric => 1,
        is_foreign_key => 1,
        is_nullable => 1,
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
__PACKAGE__->add_unique_constraint(endpoint_url  => ['endpoint_url']);
__PACKAGE__->belongs_to(target => 'OSiRIS::Model::Target');
__PACKAGE__->might_have(encryption_key => 'OSiRIS::Model::Target::Key');
__PACKAGE__->might_have(encryption_certificate => 'OSiRIS::Model::Target::Certificate');
__PACKAGE__->might_have(signing_key => 'OSiRIS::Model::Target::Key');
__PACKAGE__->might_have(signing_certificate => 'OSiRIS::Model::Target::Certificate');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

}

1;