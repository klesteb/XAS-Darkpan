package XAS::Model::Database::Darkpan::Result::Mirrors;

our $VERSION = '0.01';

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'DBIx::Class::Core',
  mixin   => 'XAS::Model::DBM',
;

__PACKAGE__->load_components(qw/ InflateColumn::DateTime OptimisticLocking /);
__PACKAGE__->table('mirrors');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'bigint',
        is_auto_imcrement => 1,
        is_nullable       => 0,
        sequence          => 'mirrors_id_seq',
    },
    mirror => {
        data_type     => 'varchar',
        size          => 255,
        is_nullable   => 0,
    },
    type => {
        data_type     => 'varchar',
        size          => 32,
        is_nullable   => 0,
    },
    datetime => {
        data_type     => 'datetime',
        is_nullable   => 0
    },
    revision => {
        data_type     => 'integer',
        default_value => 1,
    }
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->optimistic_locking_strategy('version');
__PACKAGE__->optimistic_locking_version_column('revision');

__PACKAGE__->belongs_to( 
    packages => 'XAS::Model::Database::Darkpan::Result::Packages', 
    { 'foreign.mirror' => 'self.mirror' } 
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
   
}

sub table_name {
    return __PACKAGE__;
}

1;

