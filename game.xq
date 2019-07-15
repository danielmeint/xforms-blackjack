module namespace game='xforms-blackjack/game';

import module namespace api="xforms-blackjack/api" at 'api.xq';
import module namespace dealer="xforms-blackjack/dealer" at 'dealer.xq';
import module namespace player="xforms-blackjack/player" at 'player.xq';
import module namespace deck="xforms-blackjack/deck" at 'deck.xq';
import module namespace chat="xforms-blackjack/chat" at 'chat.xq';



declare
%updating
function game:updateCreate() {
  insert node game:newGame() into $api:games
};

declare
%updating
function game:delete($self) {
  delete node $self
};

declare
%updating
function game:play($self) {
  replace value of node $self/@state with 'playing',
  for $player at $index in $self/player
  return (
    if ($index = 1)
    then (replace value of node $player/@state with 'active')
    else (replace value of node $player/@state with 'inactive')
  ),
  dealer:deal($self/dealer)
};

declare function game:latestId() as xs:double {
  if (exists($api:games/game)) 
  then (max($api:games/game/@id)) 
  else (0)
};

declare 
%updating
function game:evaluate($self, $afterHit as xs:boolean, $afterDouble as xs:boolean) {
  let $regularPlayers := $self/player[count(hand/card) >= 2][position() != last()]
  let $lastPlayer := $self/player[count(hand/card) >= 2][position() = last()]
    return (
    for $p in $regularPlayers
    return (
      player:evaluate($p, false(), false())
    ),
    player:evaluate($lastPlayer, $afterHit, $afterDouble),
    replace value of node $self/@state with 'evaluated'
  )
};

declare
%updating
function game:newRound($self) {
  replace node $self with game:reset($self)
};


declare variable $game:defaultId := game:latestId() + 1;
declare variable $game:defaultState := "betting";
declare variable $game:defaultDealer := dealer:newDealer();
declare variable $game:defaultPlayers := ();
declare variable $game:defaultChat := chat:newChat();

declare function game:newGame($id, $state, $dealer, $players, $chat) {
  <game id="{$id}" state="{$state}">
    {$chat}
    {$dealer}
    {$players}
  </game>
};

declare function game:newGame() {
  game:newGame($game:defaultId, $game:defaultState, $game:defaultDealer, $game:defaultPlayers, $game:defaultChat)
};

declare function game:draw($self, $name) {
  let $xsl := doc('../static/xforms-static/xslt/game.xsl')
  let $user := $api:users/user[@name=$name]
  let $map := map{ "name" : $name, "balance" : $user/balance/text() }
  return xslt:transform($self, $xsl, $map)
};

declare function game:reset($self) {
  let $id := $self/@id
  let $state := $game:defaultState
  let $dealer := $game:defaultDealer
  let $players := $self/player ! player:reset(.)
  let $players := (
    for $player in $players
    let $user := $api:users/user[@name=$player/@name]
    where $user/balance > 0
    return $player
  )
  let $players := if (count($players) > 0) then (player:setState($players[1], 'active'), subsequence($players, 2, count($players) - 1)) else ($players)
  let $chat := $self/chat
  return game:newGame($id, $state, $dealer, $players, $chat)
};

declare function game:setId($self, $id) {
  let $state := $self/@state
  let $dealer := $self/dealer
  let $players := $self/player
  let $chat := $self/chat
  return game:newGame($id, $state, $dealer, $players, $chat)
};

declare function game:setState($self, $state) {
  let $id := $self/@id
  let $dealer := $self/dealer
  let $players := $self/player
  let $chat := $self/chat
  return game:newGame($id, $state, $dealer, $players, $chat)
};

declare function game:setDealer($self, $dealer) {
  let $id := $self/@id
  let $state := $self/@state
  let $players := $self/player
  let $chat := $self/chat
  return game:newGame($id, $state, $dealer, $players, $chat)
};

declare function game:setPlayers($self, $players) {
  let $id := $self/@id
  let $state := $self/@state
  let $dealer := $self/dealer
  let $chat := $self/chat
  return game:newGame($id, $state, $dealer, $players, $chat)
};

declare function game:setChat($self, $chat) {
  let $id := $self/@id
  let $state := $self/@state
  let $dealer := $self/dealer
  let $players := $self/player
  return game:newGame($id, $state, $dealer, $players, $chat)
};