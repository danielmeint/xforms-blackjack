module namespace dealer='xforms-blackjack/dealer';

import module namespace api="xforms-blackjack/api" at 'api.xq';
import module namespace deck="xforms-blackjack/deck" at 'deck.xq';

import module namespace hand="xforms-blackjack/hand" at 'hand.xq';

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
function dealer:draw($self) {
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
  
  (: give self ALL cards necessary (previously drawn after players have played) :)
  let $result := deck:drawTo17($self/hand, $self/deck)
  let $offset := count($result/hand/card)
  
  return (
    replace node $self/hand with $result/hand,
    for $card at $index in $result/hand/card
    return (
      delete node $self/deck/card[$index]
    ),
    for $player at $index in $game/player
    let $newHand := hand:addCard(hand:addCard($player/hand, $self/deck/card[$offset + ($index * 2) - 1]), $self/deck/card[$offset + ($index * 2)])
    return (
      replace node $player/hand with $newHand,
      delete node $self/deck/card[$offset + ($index * 2) - 1],
      delete node $self/deck/card[$offset + ($index * 2)]
    )
  )
};