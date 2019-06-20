module namespace deck='xforms/bjx/deck';

import module namespace api="xforms/bjx/api" at 'api.xq';
import module namespace card="xforms/bjx/card" at 'card.xq';
import module namespace dealer="xforms/bjx/dealer" at 'dealer.xq';
import module namespace game="xforms/bjx/game" at 'game.xq';
import module namespace hand="xforms/bjx/hand" at 'hand.xq';

declare function deck:newDeck() {
  let $cards := (
    for $suit in ("clubs", "hearts", "spades", "diamonds")
    return (
      for $value in ("A", 2 to 10, "J", "Q", "K")
      return <card value="{$value}" suit="{$suit}"/>
    )
  )
  return <deck>{$cards}</deck>
};

declare function deck:newDeck($cards) {
  <deck>
  {$cards}
  </deck>
};

declare function deck:setCards($self, $cards) {
  deck:newDeck($cards)
};

declare function deck:getSize($self) {
  count($self/card)
};

declare function deck:getCard($self, $index as xs:integer) {
  $self/card[$index]
};

declare function deck:removeCard($self, $card as element(card)) {
   let $newCards := (
    for $card2 in $self/card
    where not(card:equals($card, $card2))
    return $card2
  )
  return deck:setCards($self, $newCards)
};

(: Assumes cards are unique within a deck! :)
declare function deck:removeCardAtIndex($self, $index as xs:integer) {
  let $cardToRemove := $self/card[$index]
  return deck:removeCard($self, $cardToRemove)
};

(: returns a tuple of the drawn card and the remaining deck :)
declare function deck:drawCard($self) {
  <result>
    {deck:getCard($self, 1)}
    {deck:removeCardAtIndex($self, 1)}
  </result>
};

declare function deck:drawXCards($self, $x) {
  let $result := deck:drawCard($self)
  return deck:drawXCards($result, $x, $x - 1)
};

declare function deck:drawXCards($result, $x, $toGo) {
  if ($toGo = 0)
  then (
    $result
  ) else (
    let $cardsDrawn := $result/card
    let $deck := $result/deck
    return <todo></todo>
  )
};

declare function deck:shuffle($self) {
  let $rng := fn:random-number-generator()
  let $indexes := (1 to deck:getSize($self))
  let $permutedIndexes := $rng('permute')($indexes)
  let $cards := (
    for $i in $permutedIndexes
    return $self/card[$i]
  )
  return deck:setCards($self, $cards)
};

declare function deck:drawTo17($hand, $deck) {
  if ($hand/@value >= 17)
  then (
    <result>
      {$hand}
      {$deck}
    </result>
  ) else (
    let $result := deck:drawCard($deck)
    let $newCard := $result/card
    let $newDeck := $result/deck
    let $newHand := hand:addCard($hand, $newCard)
    return deck:drawTo17($newHand, $newDeck)
  )
};