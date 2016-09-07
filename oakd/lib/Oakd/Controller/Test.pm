package Oakd::Controller::Test;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub env {
  my $self = shift;

  $self->render(text => "<pre>" . 
    "Request from IP: @{[$self->tx->remote_address]}\n" .
    "Environment: @{[$self->dumper(\%ENV)]}\n" .
    "Headers:\n@{[$self->req->headers->to_string]}\n" .
    "</pre>");
}

1;
