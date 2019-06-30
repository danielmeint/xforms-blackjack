module namespace dealer='xforms/bjx/dealer';

import module namespace api="xforms/bjx/api" at 'api.xq';
import module namespace deck="xforms/bjx/deck" at 'deck.xq';

import module namespace hand="xforms/bjx/hand" at 'hand.xq';

declare variable $dealer:defaultHand := hand:newHand();
declare variable $dealer:defaultDeck := deck:shuffle(deck:newDeck());

declare function dealer:newDealer($hand, $deck) {
  <dealer>
  {$hand}
  {$deck}
  </dealer>
};

declare function dealer:newDealer() {
  dealer:newDealer($dealer:defaultHand, $dealer:defaultDeck)
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

declare
%updating
function dealer:deal($self) {
  let $game := $self/..
  (: Everybody gets cards because we cannot tell who betted 0, do not show cards in xslt if bet = 0 :)
  for $player at $index in ($game/player, $self)
  let $oldHand := $player/hand
  let $deck := $self/deck
  let $newHand := hand:addCard(hand:addCard($oldHand, $deck/card[$index * 2 - 1]), $deck/card[$index * 2])
  return (
    replace node $oldHand with $newHand,
    delete node $deck/card[$index * 2 - 1],
    delete node $deck/card[$index * 2]
  )
};