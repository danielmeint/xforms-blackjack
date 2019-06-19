module namespace api = "xforms/bjx/api";

(: import module namespace api="xforms/bjx/game" at 'api.xq';
import module namespace card="xforms/bjx/card" at 'card.xq';
import module namespace dealer="xforms/bjx/dealer" at 'dealer.xq';
import module namespace deck="xforms/bjx/deck" at 'deck.xq';
import module namespace game="xforms/bjx/game" at 'game.xq';
import module namespace hand="xforms/bjx/hand" at 'hand.xq';
import module namespace helper="xforms/bjx/helper" at 'helper.xq';
import module namespace player="xforms/bjx/player" at 'player.xq'; :)

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
  let $game := $api:db/games/game[position() = $gameId]
  let $wsIds := ws:ids()
  return (
    for $wsId in $wsIds
    where ws:get($wsId, "app") = "bjx" and ws:get($wsId, "gameId") = $gameId
    (: might need another check for gameId:)
    let $path := ws:get($wsId, "path")
    let $name := ws:get($wsId, "name")
    let $destinationPath := concat("/bjx/", $path, "/", $gameId, "/", $name)
    let $data := 
    <div>
      <p>Hello, {$name}</p>
      {
        for $p in $game/player
        return <p>{data($p/@name)}: {count($p/card)} cards</p>
      }
      <form action="/bjx/games/{$gameId}/{$name}/hit" method="POST" target="hiddenFrame">
        <input type="submit"/>
       </form>
       <iframe class="hiddenFrame" name="hiddenFrame"/>
    </div>
    return (
      trace(concat("$destinationPath=", $destinationPath)),
      ws:sendchannel(fn:serialize($data), $destinationPath)
    )
  )
};

declare
%rest:path("/bjx/games/{$gameId}/{$name}/hit")
%rest:POST
%updating
function api:hitPlayer($gameId, $name as xs:string) {
  let $game := $api:db/games/game[position() = $gameId]
  let $player := $game/player[@name=$name]
  return (
    insert node <card/> into $player,
    update:output(web:redirect(concat("/bjx/games/", $gameId, "/draw")))
  )
};

declare
%rest:path("/bjx/games")
%rest:POST
%updating
function api:createGame() {
  insert node <game></game> into $api:db/games,
  update:output(web:redirect("/bjx/games"))
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
  let $name := (
    if ($name = '')
    then (
      "anonymous"
    ) else (
      $name
    )
  )
  return (
    insert node <player name="{$name}"/> into $api:db/games/game[position() = $gameId],
    update:output(web:redirect(concat("/bjx/games/", $gameId, "/", $name)))
  )
};