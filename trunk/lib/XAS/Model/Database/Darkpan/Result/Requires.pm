package XAS::Model::Database::Darkpan::Result::Requires;

our $VERSION = '0.01';

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'DBIx::Class::Core',
  mixin   => 'XAS::Model::DBM',
;

__PACKAGE__->load_components(qw/ InflateColumn::DateTime OptimisticLocking /);
__PACKAGE__->table('requires');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'bigint',
        is_auto_imcrement => 1,
        sequence          => 'requires_id_seq',
    },
    package_id => {
        data_type     => 'bigint',
        is_nullable   => 0,
    },
    module => {
        data_type     => 'varchar',
        size          => 255,
        is_nullable   => 0,
    },
    version => {
        data_type     => 'varchar',
        size          => 8,
        is_nullable   => 0,
    },
    phase => {
        data_type     => 'varchar',
        size          => 16,
        is_nullable   => 0,
    },
    relation => {
        data_type     => 'varchar',
        size          => 16,
        is_nullable   => 0,
    },
    datetime => {
        data_type     => 'datetime',
        is_nullable   => 0,
    },
    revision => {
        data_type     => 'integer',
        default_value => 1,
    }
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->optimistic_locking_strategy('version');
__PACKAGE__->optimistic_locking_version_column('revision');

__PACKAGE__->has_one( 
    packages => 'XAS::Model::Database::Darkpan::Result::Packages', 
    { 'foreign.id' => 'self.package_id' },
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
   
}

sub table_name {
    return __PACKAGE__;
}

1;

