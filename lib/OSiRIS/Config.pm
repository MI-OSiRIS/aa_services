package OSiRIS::Config;

# Object for parsing config files
#
# Copyright 2016 Wayne State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use OSiRIS::Util qw/slurp/;

sub parse {
    my ($self, $file) = @_;

    my $content = slurp $file;

    # Run Perl code in sandbox
    my $config = eval 'package OSiRIS::Config::Sandbox; no warnings;'
        . "use Mojo::Base -strict; $content";

    die qq{Can't load configuration from file "$file": $@} if $@;

    die qq{Configuration file "$file" did not return a hash reference.\n}
    unless ref $config eq 'HASH';

    return $config;
}

1;