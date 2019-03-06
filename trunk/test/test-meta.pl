use strict;
use warnings;

use CPAN::Meta;
use Data::Dumper;

my $meta = CPAN::Meta->load_file('META.yml');
my $prereq = $meta->effective_prereqs();

foreach my $data ($prereq->requirements_for('build','requires')) {
    
    warn Dumper($data->as_string_hash);
    
}

foreach my $data ($prereq->requirements_for('test','requires')) {
    
    warn Dumper($data->as_string_hash);
    
}

foreach my $data ($prereq->requirements_for('runtime','requires')) {
    
    warn Dumper($data->as_string_hash);
    
}

foreach my $data ($prereq->requirements_for('runtime','recommends')) {
    
    warn Dumper($data->as_string_hash);
    
}

