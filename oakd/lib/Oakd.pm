package Oakd;

# oakd - The OSiRIS Access Keyring Daemon
# Authored by: Michael Gregorowicz
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

use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;

    # Router
    my $r = $self->routes;

    # only allow requests to /oak from localhost (cos we are trusting apache and mod_shib24 in that
    # context)
    my $oak = $r->under('/oak' => sub {
        my ($c) = @_;
        if ($c->tx->remote_address eq '127.0.0.1') {
            return 1;
        } else {
            $c->render(text => 'Access Denied', status => 403);
            return undef;
        }
    });

    # Normal route to controller
    $oak->get('/env')->to('test#env');
}

1;
