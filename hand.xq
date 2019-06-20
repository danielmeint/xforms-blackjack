module namespace hand='xforms/bjx/hand';

import module namespace card="xforms/bjx/card" at 'card.xq';


declare function hand:newHand() {
  hand:newHand(())
};

declare function hand:newHand($cards) {
  let $hand   := <hand>{$cards}</hand>
  let $value  := hand:getValue($hand)
  return hand:newHand($cards, $value)
};

declare function hand:newHand($cards, $value) {
  <hand value="{$value}">{$cards}</hand>
};

declare function hand:setCards($self, $cards) {
  hand:newHand($cards)
};

declare function hand:setValue($self, $value) {
  let $cards := $self/card
  return hand:newHand($cards, $value)
};

declare function hand:addCard($self, $card) {
  let $newCards := ($self/card, $card)
  return hand:setCards($self, $newCards)
};

declare function hand:removeCard($self, $card) {
  let $newCards := (
    for $card2 in $self/card
    where not(card:equals($card, $card2))
    return $card2
  )
  return hand:setCards($self, $newCards)
};

declare function hand:getValue($self) {
  let $numValues := $self/card ! card:getNumericalValue(.)
  return hand:getOptimalSum($numValues)
};

declare function hand:getOptimalSum($values as xs:integer*) {
  if (sum($values) le 21 or not(some $x in $values satisfies $x eq 11))
  then (
    sum($values)
  )
  else (
    (: remove the first 11, append a 1, and recursively recalculate :)
    let $firstIndex := index-of($values, 11)[1]
    let $newValues := ($values[not(position() eq $firstIndex)], 1)
    return hand:getOptimalSum($newValues)
  )
};