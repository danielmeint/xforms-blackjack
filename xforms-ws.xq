xquery version "3.0";

module namespace xforms-ws = "xforms-blackjack/xforms-ws";

import module namespace ws = "http://basex.org/modules/ws";

import module namespace api="xforms-blackjack/api" at "api.xq";
import module namespace player="xforms-blackjack/player" at 'player.xq';
import module namespace game="xforms-blackjack/game" at 'game.xq';


declare
%ws-stomp:connect("/xforms-blackjack")
function xforms-ws:stompconnect(){
    trace(concat("xforms-blackjack: WS client connected with id ", ws:id()))
};

declare
%ws:close("/xforms-blackjack")
%updating
function xforms-ws:stompdisconnect(){
  let $wsId   := ws:id()
  let $gameId := ws:get($wsId, "gameId")
  let $game   := $api:games/game[@id=$gameId]
  let $name   := ws:get($wsId, "name")
  let $player := $game/player[@name=$name]
  let $trace  := trace(concat("xforms-blackjack: WS client disconnected - wsId: ", $wsId, ", gameId: ", $gameId, ", name: ", $name, ", was playing? ", exists($player)))
  let $allConnected := (
    for $wsId in ws:ids()
    where ws:get($wsId, "app") = "xforms-blackjack" and ws:get($wsId, "gameId") = $gameId
    return $wsId
  )
  return (
    if (exists($player))
    then (
      player:leave($player)
    ),
    if (count($allConnected) <= 1)
    then (
      (: no more spectators (should imply no more players) --> delete the game :)
      game:delete($game)
    )
  )
};

(: WS STOMP subscribe, gets the header parameter from the WebSocket request and
saves them for each client for later usage within the draw method :)
declare
%ws-stomp:subscribe("/xforms-blackjack")
%ws:header-param("param0", "{$app}")
%ws:header-param("param1", "{$path}")
%ws:header-param("param2", "{$gameId}")
%ws:header-param("param3", "{$name}")

%updating
function xforms-ws:subscribe($app, $path, $gameId, $name){
  ws:set(ws:id(), "app", "xforms-blackjack"),
  ws:set(ws:id(), "path", $path),
  ws:set(ws:id(), "gameId", $gameId),
  ws:set(ws:id(), "name", $name),
  update:output(trace(concat("xforms-blackjack: WS client with wsId ", ws:id(), " subscribed to ", $app, "/", $path, "/", $gameId, "/", $name)))
};