use Test::More;
use File::Path qw(make_path remove_tree);

my $test_schema_dir = "/var/tmp/"
my $test_dsn = "dbi:SQLite:dbname=/var/tmp/aa_services_test.@{[time]}.dat"

use_ok("DBIx::Class::Migration");
use_ok('OSiRIS::Model');

my $m = OSiRIS::Model->connect($test_dsn);




# my $aa = OSiRIS::AccessAssertion->new({

# });

done_testing();