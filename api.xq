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

import module namespace session = 'http://basex.org/modules/session';

declare variable $api:db := db:open("bjx");

declare
%rest:path("/bjx")
%rest:GET
%output:method("html")
function api:entry() {
  if (session:get('name'))
  then (
    api:main() 
  ) else (
    api:login()
  )
};

declare function api:main() {
  <div>
    Logged in as { session:get('name') }
    <form action='/bjx/games' method='post'>
      <input type='submit' value='Create new game'/>
    </form>
    <a href="/bjx/games">Load game</a>
    <a href="/bjx/logout">Logout</a>
  </div>
};

declare function api:login() {
    <div class='warning'>Please enter your credentials:</div>,
    <form action='/bjx/login' method='post'>
      <table>
        <tr>
          <td><b>Name:</b></td>
          <td>
            <input size='30' name='name' id='user' autofocus=''/>
          </td>
        </tr>
        <tr>
          <td><b>Password:</b></td>
          <td>{
            <input size='30' type='password' name='pass'/>,
            <button type='submit'>Login</button>
          }</td>
        </tr>
        <tr>
          <td>Or</td>
          <td><a href='/bjx/signup'>Sign Up Here!</a></td>
        </tr>
      </table>
    </form>
};

declare
%rest:GET
%rest:path('bjx/signup')
%output:method("html")
%rest:query-param("error", "{$error}")
function api:sign-up($error) {
  <form action='/bjx/signup' method='post'>
    <p>{$error}</p>
    <table>
      <tr>
        <td><b>Name:</b></td>
        <td>
          <input size='30' name='name' id='user' autofocus=''/>
        </td>
      </tr>
      <tr>
        <td><b>Password:</b></td>
        <td>{
          <input size='30' type='password' name='pass'/>,
          <button type='submit'>Create Account</button>
        }</td>
      </tr>
      <tr>
        <td>Or</td>
        <td><a href='/bjx'>Log In Here!</a></td>
      </tr>
    </table>
  </form>
};

declare
%rest:POST
%rest:path("/bjx/signup")
%rest:query-param("name", "{$name}")
%rest:query-param("pass", "{$pass}")
%updating
function api:user-create(
  $name as xs:string,
  $pass as xs:string
) as empty-sequence() {
  try {
    if(user:exists($name)) then (
      error((), 'User already exists.')
    ) else (
      user:create($name, $pass, 'none')
    ),
    update:output(web:redirect("/bjx"))
  } catch * {
    update:output(web:redirect("/bjx/signup", map { 'error': $err:description }))
  }
};

declare
%rest:POST
%rest:path('/bjx/signup-check')
%rest:query-param('name', '{$name}')
%rest:query-param('pass', '{$pass}')
function api:signup-check(
  $name as xs:string,
  $pass as xs:string
) as element(rest:response) {
  
};

declare
%rest:POST
%rest:path('/bjx/login')
%rest:query-param('name', '{$name}')
%rest:query-param('pass', '{$pass}')
function api:login-check(
  $name  as xs:string,
  $pass  as xs:string
) as element(rest:response) {
  try {
    user:check($name, $pass),
    session:set('name', $name)
  } catch user:* {
    (: login fails: no session info is set :)
  },
  web:redirect('/bjx')
};

declare
%rest:path('/bjx/logout')
function api:logout() as element(rest:response) {
  session:get('name') ! api:close(.),
  session:delete('name'),
  web:redirect('/bjx')
};

declare function api:close($name  as  xs:string) as empty-sequence() {
  for $wsId in ws:ids()
  where ws:get($wsId, 'name') = $name
  return ws:close($wsId)
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
%output:method("html")
function api:returnGames() {
  let $stylesheet := doc("../static/bjx/xslt/lobby.xsl")
  let $games := $api:db/games
  let $map := map{ "screen": "games" }
  return xslt:transform($games, $stylesheet, $map)
};

declare
%rest:path("/bjx/highscores")
%rest:GET
%output:method("html")
function api:returnHighscores() {
  let $stylesheet := doc("../static/bjx/xslt/lobby.xsl")
  let $games := $api:db/games
  let $map := map{ "screen": "highscores" }
  return xslt:transform($games, $stylesheet, $map)
};

declare
%rest:path("/bjx/games")
%rest:POST
%updating
function api:createGame() {
  game:updateCreate(),
  (: TODO: skip this step; but: game needs to be created in DB before we can join (?) :)
  update:output(web:redirect(concat("/bjx/games/", game:latestId() + 1, "/join")))
};

declare
%rest:path("/bjx/games/{$gameId}")
%rest:DELETE
%updating
function api:deleteGame($gameId as xs:integer) {
    let $game := $api:db/games/game[@id = $gameId]
    return (
      game:delete($game),
      update:output(web:redirect("/bjx"))
    )
};

declare
%rest:path("/bjx/games/{$gameId}/delete")
%rest:POST
%updating
function api:deleteGamePOST($gameId as xs:integer) {
    let $game := $api:db/games/game[@id = $gameId]
    return (
      game:delete($game),
      update:output(web:redirect("/bjx"))
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
        <input type='submit' />
      </form>
    </body>
  </html>
};

declare
%rest:path("/bjx/games/{$gameId}/join")
%rest:POST
%updating
function api:joinGame($gameId as xs:integer) {
  let $name := session:get('name')
  return (
    player:joinGame($gameId, $name),
    update:output(web:redirect(concat("/bjx/games/", $gameId)))
  )
};

declare
%rest:path("/bjx/games/{$gameId}")
%rest:GET
%output:method("html")
function api:returnGame($gameId) {
  let $name := session:get('name')
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
              <link rel="stylesheet" type="text/css" href="/static/bjx/css/style.css"/>
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
    let $data := game:drawFull($game, $name)
    return (
      trace(concat("BJX: drawing game to destination path: ", $destinationPath)),
      ws:sendchannel(fn:serialize($data), $destinationPath)
    )
  )
};

declare
%rest:path("/bjx/games/{$gameId}/{$name}/bet")
%rest:POST
%rest:form-param("bet", "{$bet}", 0) 
%updating
function api:betPlayer($gameId, $name, $bet) {
  let $game := $api:db/games/game[@id = $gameId]
  let $player := $game/player[@name=$name]
  return (
    player:bet($player, $bet),
    update:output(web:redirect(concat("/bjx/games/", $gameId, "/draw")))
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