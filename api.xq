module namespace api = "xforms/bjx/api";

(: import module namespace api="xforms/bjx/api" at 'api.xq';
import module namespace card="xforms/bjx/card" at 'card.xq';
import module namespace dealer="xforms/bjx/dealer" at 'dealer.xq';
import module namespace deck="xforms/bjx/deck" at 'deck.xq';
import module namespace game="xforms/bjx/game" at 'game.xq';
import module namespace hand="xforms/bjx/hand" at 'hand.xq';
import module namespace helper="xforms/bjx/helper" at 'helper.xq';
import module namespace player="xforms/bjx/player" at 'player.xq'; :)

import module namespace card="xforms/bjx/card" at 'card.xq';
import module namespace dealer="xforms/bjx/dealer" at 'dealer.xq';
import module namespace deck="xforms/bjx/deck" at 'deck.xq';
import module namespace game="xforms/bjx/game" at 'game.xq';
import module namespace hand="xforms/bjx/hand" at 'hand.xq';
import module namespace player="xforms/bjx/player" at 'player.xq';

import module namespace ws = "http://basex.org/modules/ws";
import module namespace request = "http://exquery.org/ns/request";

declare variable $api:db := db:open("bjx");

declare
%rest:path("/bjx")
%rest:GET
%output:method("html")
function api:entry() {
  <html>
  <body>
    <h1>Menu</h1>
    <form action='/bjx/games' method='post'>
      <input type='submit' value='Create new game'/>
    </form>
  </body>
  </html>
};

declare
%rest:path("/bjx/setup")
%rest:GET
%output:method("html")
%updating
function api:setup() {
    db:create("bjx", doc('model.xml')),
    update:output(web:redirect('/bjx'))
};

declare
%rest:path("/bjx/games")
%rest:GET
function api:returnGames() {
  $api:db/games
};

declare
%rest:path("/bjx/games/{$gameId}/{$name}")
%rest:GET
%output:method("html")
function api:returnGame($gameId, $name) {
  let $hostname := request:hostname()
  let $port := request:port()
  let $address := concat($hostname,":",$port)
  let $websocketURL := concat("ws://", $address, "/ws/bjx") (: or /ws/bjx/games/{$gameId} ?? :)
  let $getURL := concat("http://", $address, "/bjx/games/", $gameId, "/draw")
  let $subscription := concat("/bjx/games/", $gameId, "/", $name)
  let $html :=
      <html>
          <head>
              <title>BJX</title>
              <script src="/static/tictactoe/JS/jquery-3.2.1.min.js"></script>
              <script src="/static/tictactoe/JS/stomp.js"></script>
              <script src="/static/tictactoe/JS/ws-element.js"></script>
              <link rel="stylesheet" type="text/css" href="/static/blackjack/style.css"/>
          </head>
          <body>
              <ws-stream id="bjx" url="{$websocketURL}" subscription="{$subscription}" geturl="{$getURL}"/>
          </body>
      </html>
  return $html
};

declare
%rest:path("/bjx/games/{$gameId}/draw")
%rest:GET
function api:drawGame($gameId) {
  let $game := $api:db/games/game[@id = $gameId]
  let $wsIds := ws:ids()
  return (
    for $wsId in $wsIds
    where ws:get($wsId, "app") = "bjx" and ws:get($wsId, "gameId") = $gameId
    (: might need another check for gameId:)
    let $path := ws:get($wsId, "path")
    let $name := ws:get($wsId, "name")
    let $destinationPath := concat("/bjx/", $path, "/", $gameId, "/", $name)
    let $data := game:draw($game, $name)
    return (
      trace(concat("$destinationPath=", $destinationPath)),
      ws:sendchannel(fn:serialize($data), $destinationPath)
    )
  )
};

declare
%rest:path("/bjx/games/{$gameId}/join")
%rest:GET
%output:method("html")
function api:joinGameForm($gameId) {
  <html>
    <body>
      <form action='/bjx/games/{$gameId}/join' method='POST'>
        <input type='text' name='name' />
        <input type='submit' />
      </form>
    </body>
  </html>
};

declare
%rest:path("/bjx/games/{$gameId}/join")
%rest:POST
%rest:form-param("name", "{$name}", "anonymous")
%updating
function api:joinGame($gameId, $name) {
  let $name := api:uniqueName($gameId, $name)
  return (
    player:joinGame($gameId, $name),
    update:output(web:redirect(concat("/bjx/games/", $gameId, "/", $name)))
  )
};

(: obsolete, simply leave via GET and let bjxws:stompdisconnect() handle everything :)
declare
%rest:path("bjx/games/{$gameId}/{$name}/leave")
%rest:POST
%updating
function api:leaveGame($gameId, $name) {
  let $game := $api:db/games/game[@id = $gameId]
  let $player := $game/player[@name=$name]
  return (
    player:leave($player),
    update:output(web:redirect("/bjx"))
  )
};

declare
%rest:path("/bjx/games/{$gameId}/{$name}/hit")
%rest:POST
%updating
function api:hitPlayer($gameId, $name as xs:string) {
  let $game := $api:db/games/game[@id = $gameId]
  let $player := $game/player[@name=$name]
  return (
    player:hit($player),
    update:output(web:redirect(concat("/bjx/games/", $gameId, "/draw")))
  )
};

(: declare
%rest:path("/bjx/games/{$gameId}/{$name}/stand") 
%rest:POST
%updating
function api:standPlayer($gameId, $name as xs:string) {
  let $game := $api:db/games/game[@id = $gameId]
  let $player := $game/player[@name=$name]
  let $isLast := $player/position() = count($game/player)
  return (
    if (not($isLast))
    then (
      player:nextPlayer($player)
    )
    else (
      dealer:play($game/dealer),
      game:evaluate($game)
    ),
    update:output(web:redirect(concat("/bjx/games/", $gameId, "/draw")))
  )
}; :)

declare
%rest:path("bjx/games/{$gameId}/evaluate")
%rest:POST
%updating
function api:evaluateGame($gameId) {
  let $game := $api:db/games/game[@id = $gameId]
  return (
    game:evaluate($game),
    update:output(web:redirect(concat("/bjx/games/", $gameId, "/draw")))
  )
};


declare
%rest:path("/bjx/games/{$gameId}/{$name}/stand") 
%rest:POST
%updating
function api:standPlayer($gameId, $name as xs:string) {
  let $game := $api:db/games/game[@id = $gameId]
  let $player := $game/player[@name=$name]
  return (
    player:stand($player),
    update:output(web:redirect(concat("/bjx/games/", $gameId, "/draw")))
  )
};

declare
%rest:path("/bjx/games/{$gameId}/newRound")
%rest:POST
%updating
function api:newRound($gameId) {
  let $game := $api:db/games/game[@id = $gameId]
  return (
    game:newRound($game),
    update:output(web:redirect(concat("/bjx/games/", $gameId, "/draw")))
  )

};

declare
%rest:path("/bjx/games")
%rest:POST
%updating
function api:createGame() {
  game:updateCreate(),
  update:output(web:redirect(concat("/bjx/games/", game:latestId() + 1, "/join")))
};


(:
Helper function 
appends '_' to otherwise non-unique names
:)
declare
function api:uniqueName($gameId, $name) {
  let $game := $api:db/games/game[@id=$gameId]
  return (
    if (not(exists($game/player[@name=$name])))
    then (
      $name
    )
    else (
      api:uniqueName($gameId, concat($name, "_"))
    )
  )
};