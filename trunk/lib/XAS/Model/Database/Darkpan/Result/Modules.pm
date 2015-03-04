package XAS::Model::Database::Darkpan::Result::Modules;

our $VERSION = '0.01';

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'DBIx::Class::Core',
  mixin   => 'XAS::Model::DBM',
;

__PACKAGE__->load_components(qw/ InflateColumn::DateTime OptimisticLocking /);
__PACKAGE__->table('modules');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'bigint',
        is_auto_imcrement => 1,
        sequence          => 'moduless_id_seq',
    },
    module => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0,
    },
    version => {
        data_type   => 'varchar',
        size        => 8,
        is_nullable => 0,
    },
    pauseid => {
        data_type   => 'varchar',
        size        => 32,
        is_nullable => 0,
    },
    package => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0,
    },
    location => {
        data_type     => 'varchar',
        size          => 16,
        default_value => 'remote',
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
__PACKAGE__->add_unique_constraint(modules_unique_idx => ['module','version','pauseid','package','location']);

__PACKAGE__->optimistic_locking_strategy('version');
__PACKAGE__->optimistic_locking_version_column('revision');

__PACKAGE__->has_one( 
    packages => 'XAS::Model::Database::Darkpan::Result::Packages', 
    { 'foreign.name' => 'self.package' },
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
   
}

sub table_name {
    return __PACKAGE__;
}

1;

