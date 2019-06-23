module namespace player="xforms/bjx/player";

import module namespace api="xforms/bjx/api" at 'api.xq';
import module namespace card="xforms/bjx/card" at 'card.xq';
import module namespace dealer="xforms/bjx/dealer" at 'dealer.xq';
import module namespace deck="xforms/bjx/deck" at 'deck.xq';
import module namespace game="xforms/bjx/game" at 'game.xq';
import module namespace hand="xforms/bjx/hand" at 'hand.xq';


declare
%updating
function player:joinGame($gameId as xs:integer, $name as xs:string) {
  let $game := $api:db/games/game[@id=$gameId]
  let $newPlayer := player:setName(player:newPlayer(), $name)
  return (
    if (exists($game/player))
    then (
      insert node $newPlayer into $game
    ) else (
      (: first player to join :)
      let $newGame := game:reset(game:setPlayers($game, ($newPlayer)))
      return (
        replace node $game with $newGame
      )
    )
  )
};

declare
%updating
function player:leave($self) {
  delete node $self
};

declare
%updating
function player:bet($self, $bet) {
  let $game := $self/..
  let $isLast := not(exists($self/following-sibling::player))
  return (
    replace value of node $self/bet with $bet,
    if ($isLast)
    then (
      game:play($game)
    ) else (
      player:nextPlayer($self)
    )
  )
};

declare
%updating
function player:hit($self) {
  let $game := $self/..
  let $oldHand := $self/hand
  let $oldDeck := $game/dealer/deck
  let $resultTuple := deck:drawCard($oldDeck)
  let $newCard := $resultTuple/card
  let $newDeck := $resultTuple/deck
  let $newHand := hand:addCard($oldHand, $newCard)
  return (
    replace node $oldHand with $newHand,
    replace node $oldDeck with $newDeck
  )
};

declare
%updating
function player:stand($self) {
  let $game := $self/..
  let $isLast := not(exists($self/following-sibling::player))
  return (
    if ($isLast)
    then (
      game:evaluate($game)
    ) else (
      player:nextPlayer($self)
    )
  )
};

declare
%updating
function player:nextPlayer($self) {
  let $game := $self/..
  let $currPlayer := $self
  let $nextPlayer := $self/following-sibling::player[position() = 1]
  
  return (
    replace value of node $currPlayer/@state with 'inactive',
    if (exists($nextPlayer))
    then (
      replace value of node $nextPlayer/@state with 'active'
    )
  )
};

declare
%updating
function player:doubleDown($self) {
  let $bet := $self/bet
  return (
    replace value of node $bet with $bet/text() * 2,
    player:hit($self),
    player:stand($self)
  )
};

declare
%updating
function player:evaluate($self) {
  player:evaluateAgainst($self, $self/../dealer/hand/@value)
};

declare
%updating
function player:evaluateAgainst($self, $toBeat) {
  if ($self/hand/@value <= 21 and ($self/hand/@value > $toBeat or $toBeat > 21))
  then (
    replace value of node $self/@state with "won",
    replace value of node $self/balance with $self/balance/text() + $self/bet/text()
  )
  else if ($self/hand/@value <= 21 and $self/hand/@value = $toBeat)
  then (
    replace value of node $self/@state with "tied"
  )
  else (
    replace value of node $self/@state with "lost",
    replace value of node $self/balance with $self/balance/text() - $self/bet/text()
  )
};


declare variable $player:defaultName := "undefined";
declare variable $player:defaultState := "inactive";
declare variable $player:defaultBalance := 100;
declare variable $player:defaultBet := 0;
declare variable $player:defaultHand := hand:newHand();

declare function player:newPlayer($name, $state, $balance, $bet, $hand) {
  <player name="{$name}" state="{$state}">
    <balance>{$balance}</balance>
    <bet>{$bet}</bet>
    {$hand}
  </player>
};

declare function player:newPlayer() {
  player:newPlayer($player:defaultName, $player:defaultState, $player:defaultBalance, $player:defaultBet, $player:defaultHand)
};

declare function player:reset($self) {
  let $name := $self/@name
  let $state := $player:defaultState
  let $balance := $self/balance/text()
  let $bet := $player:defaultBet
  let $hand := $player:defaultHand
  return player:newPlayer($name, $state, $balance, $bet, $hand)
};

declare function player:setName($self, $name) {
  let $state := $self/@state
  let $balance := $self/balance/text()
  let $bet := $self/bet/text()
  let $hand := $self/hand
  return player:newPlayer($name, $state, $balance, $bet, $hand)
};

declare function player:setState($self, $state) {
  let $name := $self/@name
  let $balance := $self/balance/text()
  let $bet := $self/bet/text()
  let $hand := $self/hand
  return player:newPlayer($name, $state, $balance, $bet, $hand)
};


declare function player:setBalance($self, $balance) {
  let $name := $self/@name
  let $state := $self/@state
  let $bet := $self/bet/text()
  let $hand := $self/hand
  return player:newPlayer($name, $state, $balance, $bet, $hand)
};

declare function player:setBet($self, $bet) {
  let $name := $self/@name
  let $state := $self/@state
  let $balance := $self/balance/text()
  let $hand := $self/hand
  return player:newPlayer($name, $state, $balance, $bet, $hand)
};

declare function player:setHand($self, $hand) {
  let $name := $self/@name
  let $state := $self/@state
  let $balance := $self/balance/text()
  let $bet := $self/bet/text()
  return player:newPlayer($name, $state, $balance, $bet, $hand)
};