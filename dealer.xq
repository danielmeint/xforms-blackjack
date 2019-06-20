module namespace dealer='xforms/bjx/dealer';

import module namespace api="xforms/bjx/api" at 'api.xq';
import module namespace deck="xforms/bjx/deck" at 'deck.xq';

import module namespace hand="xforms/bjx/hand" at 'hand.xq';

declare variable $dealer:defaultHand := hand:newHand();
declare variable $dealer:defaultDeck := deck:shuffle(deck:newDeck());

declare function dealer:new($hand, $deck) {
  <dealer>
  {$hand}
  {$deck}
  </dealer>
};

declare function dealer:new() {
  dealer:new($dealer:defaultHand, $dealer:defaultDeck)
};

declare
%updating
function dealer:play($self) {
  let $game := $self/..
  let $oldHand := $self/hand
  let $oldDeck := $self/deck
  let $result  := deck:drawTo17($oldHand, $oldDeck)
  let $newHand := $result/hand
  let $newDeck := $result/deck
  return (
    replace node $oldHand with $newHand,
    replace node $oldDeck with $newDeck
  )
};