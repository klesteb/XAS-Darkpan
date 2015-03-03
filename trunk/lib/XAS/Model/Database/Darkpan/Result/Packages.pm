package XAS::Model::Database::Darkpan::Result::Packages;

our $VERSION = '0.01';

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'DBIx::Class::Core',
  mixin   => 'XAS::Model::DBM',
;

__PACKAGE__->load_components(qw/ InflateColumn::DateTime OptimisticLocking /);
__PACKAGE__->table('packages');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'bigint',
        is_auto_imcrement => 1,
        is_nullable       => 0,
        sequence          => 'packages_id_seq',
    },
    name => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0,
    },
    path => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0,
    },
    maturity => {
        data_type   => 'varchar',
        size        => 32,
        is_nullable => 0,
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
__PACKAGE__->add_unique_constraint(packages_name_idx => ['name','mirror']);

__PACKAGE__->optimistic_locking_strategy('version');
__PACKAGE__->optimistic_locking_version_column('revision');

__PACKAGE__->belongs_to( 
    modules => 'XAS::Model::Database::Darkpan::Result::Modules', 
    { 'foreign.package' => 'self.name' },
);

__PACKAGE__->has_one( 
    mirrors => 'XAS::Model::Database::Darkpan::Result::Mirrors', 
    { 'foreign.mirror' => 'self.mirror' },
    { 'cascade_delete' => 0 },
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
   
}

sub table_name {
    return __PACKAGE__;
}

1;

