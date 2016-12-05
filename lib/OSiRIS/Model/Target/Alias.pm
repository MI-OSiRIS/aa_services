package OSiRIS::Model::Target::Alias;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('osiris_aa_target_alias');

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
    common_name => {
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
__PACKAGE__->add_unique_constraint(common_name  => ['common_name']);
__PACKAGE__->belongs_to(target => 'OSiRIS::Model::Target');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    $sqlt_table->add_index(
        name   => 'osiris_aa_common_name',
        fields => ['common_name'],
    );
}

1;