module namespace card='xforms/bjx/card';

declare function card:newCard($value, $suit) {
  <card value="{$value}" suit="{$suit}"/>
};

declare function card:setValue($self, $value) {
  let $suit := $self/@suit
  return card:newCard($value, $suit)
};

declare function card:setSuit($self, $suit) {
  let $value := $self/@value
  return card:newCard($value, $suit)
};

declare function card:equals($card1, $card2) {
  $card1/@value eq $card2/@value and $card1/@suit eq $card2/@suit
};

declare function card:getNumericalValue($self) {
  if (some $x in ('J', 'Q', 'K') satisfies $x eq $self/@value)
  then (
    10
  ) else if ($self/@value eq 'A')
  then (
    11
  ) else (
    data($self/@value)
  )
};