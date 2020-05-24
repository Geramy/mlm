package MLM::Basket::Model;

use strict;
use MLM::Model;
use vars qw($AUTOLOAD @ISA);

@ISA=('MLM::Model');

sub topics {
  my $self = shift;
  my $ARGS = $self->{ARGS};
  my $extra = shift;

	$self->{LISTS} = [];
	my $err = $self->select_sql($self->{LISTS},
"SELECT basketid, classify, id, title, logo, (g.price - ((g.price / 100) * t.product_discount)), sh, g.bv, qty,
	(qty*(g.price - ((g.price / 100) * t.product_discount))) AS amount, (qty*g.bv) AS credit, (qty*sh) AS shipping, t.product_discount as discount
FROM sale_basket b
INNER JOIN product_gallery g ON (b.id=g.galleryid AND b.classify='gallery')
INNER JOIN member m ON m.memberid = ?
INNER JOIN def_type t ON t.typeid = m.typeid
WHERE g.memberid=? AND inbasket='Yes'
UNION
SELECT basketid, classify, id, title, logo, (g.price - ((g.price / 100) * t.product_discount)), sh, g.bv, qty,
	(qty*(g.price - ((g.price / 100) * t.product_discount))) AS amount, (qty*g.bv) AS credit, (qty*sh) AS shipping, t.product_discount as discount
FROM sale_basket b
INNER JOIN member m ON m.memberid = ?
INNER JOIN def_type t ON t.typeid = m.typeid
INNER JOIN product_package g ON (b.id=g.packageid AND b.classify='package')
WHERE g.memberid=? AND inbasket='Yes'",  $ARGS->{memberid}, $ARGS->{memberid}, $ARGS->{memberid}, $ARGS->{memberid});
  if($self->{CUSTOM}->{StripeAPIPubKey}) {
    $ARGS->{StripeAPIPubKey} = $self->{CUSTOM}->{StripeAPIPubKey};
  }
  if($self->{CUSTOM}->{StripeAPISecret}) {
    $ARGS->{StripeAPISecret} = $self->{CUSTOM}->{StripeAPISecret};
  }
	$ARGS->{amount} = 0;
	$ARGS->{credit} = 0;
	$ARGS->{shipping} = 0;
	for (@{$self->{LISTS}}) {
		$ARGS->{amount}   += $_->{amount};
		$ARGS->{credit}   += $_->{credit};
		$ARGS->{shipping} += $_->{shipping};
	}

	return $self->process_after("topics", @_);
}

1;
