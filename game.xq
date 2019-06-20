module namespace game='xforms/bjx/game';

import module namespace api="xforms/bjx/api" at 'api.xq';
import module namespace dealer="xforms/bjx/dealer" at 'dealer.xq';
import module namespace player="xforms/bjx/player" at 'player.xq';
import module namespace deck="xforms/bjx/deck" at 'deck.xq';


declare
%updating
function game:updateCreate() {
  insert node game:newGame() into $api:db/games
};

declare
%updating
function game:evaluate($self) {
  let $dealer := $self/dealer
  let $resTuple := deck:drawTo17($dealer/hand, $dealer/deck)
  let $newDealerHand := $resTuple/hand
  let $newDeck := $resTuple/deck
  return (
    for $player in $self/player
    return (
      player:evaluateAgainst($player, $newDealerHand/@value)
    ),
    replace node $dealer/hand with $newDealerHand,
    replace node $dealer/deck with $newDeck,
    replace value of node $self/@state with 'evaluated'
  )
};

declare function game:latestId() {
  if (exists($api:db/games/game)) 
  then (max($api:db/games/game/@id)) 
  else (0)
};

declare
%updating
function game:newRound($self) {
  replace node $self with game:reset($self)
};


declare variable $game:defaultId := game:latestId() + 1;
declare variable $game:defaultState := "betting";
declare variable $game:defaultDealer := dealer:new();
declare variable $game:defaultPlayers := ();

declare function game:newGame($id, $state, $dealer, $players) {
  <game id="{$id}" state="{$state}">
    {$dealer}
    {$players}
  </game>
};

declare function game:newGame() {
  game:newGame($game:defaultId, $game:defaultState, $game:defaultDealer, $game:defaultPlayers)
};

declare function game:draw($self, $name) {
  <div>
    <p>Playing as: {$name}</p>
    <textarea style="width: 100%; height: 80%;">
      {$self}
    </textarea>
    <form action="/bjx/games/{$self/@id}/newRound" method="POST" target="hiddenFrame">
      <input type="submit" value="newRound"/>
    </form>
    <form action="/bjx/games/{$self/@id}/{$name}/hit" method="POST" target="hiddenFrame">
      <input type="submit" value="Hit"/>
    </form>
    <form action="/bjx/games/{$self/@id}/{$name}/stand" method="POST" target="hiddenFrame">
      <input type="submit" value="Stand"/>
    </form>
    <form action="/bjx/games/{$self/@id}/{$name}/leave" method="POST">
      <input type="submit" value="Leave via POST (obsolete)"/>
    </form>
    <a href="/bjx/games/{$self/@id}/{$name}/leave">Leave via GET</a>
    <iframe class="hidden hiddenFrame" name="hiddenFrame"/>
  </div>
};

declare function game:reset($self) {
  let $id := $self/@id
  let $state := $game:defaultState
  let $dealer := $game:defaultDealer
  let $players := $self/player ! player:reset(.)
  let $players := (player:setState($players[1], 'active'), subsequence($players, 2, count($players) - 1))
  return game:newGame($id, $state, $dealer, $players)
};

declare function game:setId($self, $id) {
  let $state := $self/@state
  let $dealer := $self/dealer
  let $players := $self/player
  return game:newGame($id, $state, $dealer, $players)
};

declare function game:setState($self, $state) {
  let $id := $self/@id
  let $dealer := $self/dealer
  let $players := $self/player
  return game:newGame($id, $state, $dealer, $players)
};

declare function game:setDealer($self, $dealer) {
  let $id := $self/@id
  let $state := $self/@state
  let $players := $self/player
  return game:newGame($id, $state, $dealer, $players)
};

declare function game:setPlayers($self, $players) {
  let $id := $self/@id
  let $state := $self/@state
  let $dealer := $self/dealer
  return game:newGame($id, $state, $dealer, $players)
};