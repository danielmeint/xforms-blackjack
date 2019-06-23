xquery version "3.0";

module namespace bjxws = "TicTacToe/WS";

import module namespace ws = "http://basex.org/modules/ws";

import module namespace api="xforms/bjx/api" at "api.xq";
import module namespace player="xforms/bjx/player" at 'player.xq';

(: WS STOMP connect, increase client count by 1 :)
declare
%ws-stomp:connect("/bjx")
function bjxws:stompconnect(){
    trace(concat("BJX: WS client connected with id ", ws:id()))
};

(: WS STOMP disconnect, decrease client count by 1 :)
declare
%ws:close("/bjx")
%updating
function bjxws:stompdisconnect(){
  let $wsId   := ws:id()
  let $gameId := ws:get($wsId, "gameId")
  let $name   := ws:get($wsId, "name")
  let $player := $api:db/games/game[@id=$gameId]/player[@name=$name]
  return (
    player:leave($player),
    update:output(trace(concat("BJX: WS client disconnected - wsId: ", $wsId, ", gameId: ", $gameId, ", name: ", $name)))
  )
};

(: WS STOMP subscribe, gets the header parameter from the WebSocket request and
saves them for each client for later usage within the draw method :)
declare
%ws-stomp:subscribe("/bjx")
%ws:header-param("param0", "{$app}")
%ws:header-param("param1", "{$path}")
%ws:header-param("param2", "{$gameId}")
%ws:header-param("param3", "{$name}")

%updating
function bjxws:subscribe($app, $path, $gameId, $name){
  ws:set(ws:id(), "app", "bjx"),
  ws:set(ws:id(), "path", $path),
  ws:set(ws:id(), "gameId", $gameId),
  ws:set(ws:id(), "name", $name),
  update:output(trace(concat("BJX: WS client with wsId ", ws:id(), " subscribed to ", $app, "/", $path, "/", $gameId, "/", $name)))
};