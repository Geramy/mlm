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
"SELECT pg.price, _discount AS 'pd'
FROM product_gallery pg
INNER JOIN member m ON m.memberid = ?
LEFT JOIN def_type t ON t.typeid = m.typeid
WHERE pg.galleryid=?", $self->{ARGS}->{memberid}, $self->{ARGS}->{galleryid});
  return $err if $err;
  $self->{ARGS}->{discount_price} = $self->{ARGS}->{price} - (($self->{ARGS}->{price} / 100) * $self->{ARGS}->{pd});

  return $self->SUPER::edit(@_);
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
