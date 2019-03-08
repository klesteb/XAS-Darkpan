package XAS::Model::Database::Darkpan::Result::Permissions;

our $VERSION = '0.01';

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'DBIx::Class::Core',
  mixin   => 'XAS::Model::DBM',
;

__PACKAGE__->load_components(qw/ InflateColumn::DateTime OptimisticLocking /);
__PACKAGE__->table('permissions');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'bigint',
        is_auto_imcrement => 1,
        is_nullable       => 0,
        sequence          => 'perms_id_seq',
    },
    pauseid => {
        data_type     => 'varchar',
        size          => 32,
        is_nullable   => 0,
    },
    module => {
        data_type     => 'varchar',
        size          => 255,
        is_nullable   => 0,
    },
    perms => {
        data_type     => 'varchar',
        size          => 1,
        is_nullable   => 0,
    },
    mirror => {
        data_type     => 'varchar',
        size          => 255,
        default_value => 'http://www.cpan.org',
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
__PACKAGE__->add_unique_constraint(permissions_pauseid_mirror_module_idx => ['pauseid','module','mirror']);

__PACKAGE__->optimistic_locking_strategy('version');
__PACKAGE__->optimistic_locking_version_column('revision');

__PACKAGE__->has_one( 
    mirrors => 'XAS::Model::Database::Darkpan::Result::Mirrors', 
    { 'foreign.mirror' => 'self.mirror' },
    { 'cascade_delete' => 0 },
);

__PACKAGE__->has_one( 
    packages => 'XAS::Model::Database::Darkpan::Result::Provides', 
    { 'foreign.module' => 'self.module' },
    { 'cascade_delete' => 0 },
);

__PACKAGE__->has_one( 
    packages => 'XAS::Model::Database::Darkpan::Result::Authors', 
    { 'foreign.pauseid' => 'self.pauseid' },
    { 'cascade_delete' => 0 },
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
   
}

sub table_name {
    return __PACKAGE__;
}

1;

