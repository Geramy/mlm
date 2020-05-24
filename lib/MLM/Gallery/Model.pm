package MLM::Gallery::Model;

use strict;
use MLM::Model;
use vars qw($AUTOLOAD @ISA);

@ISA=('MLM::Model');

sub delete {
  my $self = shift;
  my $err = $self->get_args($self->{ARGS},
"SELECT logo, full
FROM product_gallery
WHERE galleryid=?", $self->{ARGS}->{galleryid});
  return $err if $err;

  return $self->SUPER::delete(@_);
}

sub edit {
  my $self = shift;
  my $err = $self->get_args($self->{ARGS},
"SELECT price, bv, description, created, title, full, categoryid, logo, galleryid, status, sh
FROM product_gallery
WHERE galleryid=?", $self->{ARGS}->{galleryid});
  return $err if $err;
}

sub update {
  my $self = shift;
  my $err = $self->get_args($self->{ARGS},
"SELECT logo AS logoold, full AS fullold
FROM product_gallery
WHERE galleryid=?", $self->{ARGS}->{galleryid});
  return $err if $err;

  return $self->SUPER::update(@_);
}

1;
