package MLM::Sale::Model;

use strict;
use MLM::Model;
use Net::Stripe;
use vars qw($AUTOLOAD @ISA);

@ISA=('MLM::Model');

sub myInvoice {
  my $self = shift;
  my $ARGS = $self->{ARGS};

  $self->{LISTS} = [];
  return $self->select_sql($self->{LISTS},
"SELECT s.saleid, s.amount, s.credit, s.paytype, s.paystatus,p.title, b.qty
FROM sale s JOIN def_type t ON s.typeid = t.typeid
JOIN sale_lineitem i ON s.saleid = i.saleid
JOIN sale_basket b ON i.basketid = b.basketid
join product_package p on b.id = p.packageid
where b.classify = 'package' AND s.saleid=?
union all
SELECT s.saleid, s.amount, s.credit, s.paytype, s.paystatus,g.title, b.qty
FROM sale s JOIN def_type t ON s.typeid = t.typeid
JOIN sale_lineitem i ON s.saleid = i.saleid
JOIN sale_basket b ON i.basketid = b.basketid
join product_gallery g on b.id = g.galleryid
where b.classify = 'gallery' AND s.saleid=?", $ARGS->{saleid}, $ARGS->{saleid});
}

sub buy {
  my $self = shift;
  my $ARGS = $self->{ARGS};
  my $extra = shift;

  my $err = $self->call_once({model=>"basket", action=>"topics"});
  return $err if $err;

  my $total_costs = $ARGS->{amount} + $ARGS->{shipping};
  my $ledger = $self->{OTHER}->{ledger_currentBalance}->[0];
  my $have = $ledger->{balance} + $ledger->{shop_balance};
  my $d1 = 0;
  my $d2 = 0;
  my $transaction;

  if($ARGS->{stripeToken}) {
    my $stripe = Net::Stripe->new(api_key => $ARGS->{StripeAPISecret});
    my $card_token = $ARGS->{stripeToken};
    if($ARGS->{method} == "debt") {
      my $charge = $stripe->post_charge(  # Net::Stripe::Charge
        amount      => $total_costs*100, #You must pass two 00 as the previous zero's are for cents and not dollars
        currency    => 'mxn',
        source      => $card_token,
        description => 'T3Dist-' . $ARGS->{memberid},
      );
      return 3203 unless $charge->paid;
      $transaction = $stripe->get_charge(charge_id => $charge->id);
      #Make purchase of $need on debt card.
    }
  }
  return 3204 unless $transaction;
  $err = $self->do_sql(
"INSERT INTO sale (memberid, amount, credit, shipping, paytype, paystatus, typeid, active, created, billingid)
VALUES (?, ?, ?, ?, 'CC', 'Processing', ".$ARGS->{shop_typeid}.", 'Yes', NOW(), '".$transaction->id."')", map {$ARGS->{$_}} (qw(memberid amount credit shipping)));
  return $err if $err;

  my $saleid = $self->last_insertid();
  my $str1 = "INSERT INTO sale_lineitem (saleid, basketid, amount, credit) VALUES ";
  my $str2 = "UPDATE sale_basket SET inbasket='No' WHERE basketid IN (";
  for my $item (@{$self->{OTHER}->{basket_topics}}) {
    $str1 .= "($saleid, " . $item->{basketid} . ", " . ($item->{amount}+$item->{shipping}) . ", " . $item->{credit} . "),";
    $str2 .= $item->{basketid} . ",";
  }
  substr($str1,-1,1)="";
  substr($str2,-1,1)=") AND memberid=".$ARGS->{memberid};
  $err = $self->do_sql($str1) || $self->do_sql($str2) || $self->do_sql(
"INSERT INTO income_ledger (memberid, amount, balance, shop_balance, old_ledgerid, weekid, created, status)
VALUES (?,?,?,?,?,?,NOW(),'Shopping')",
$ARGS->{memberid}, -1*$total_costs, 0, 0, $ledger->{ledgerid}, $ledger->{weekid});
}

1;
