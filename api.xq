module namespace api = "xforms-blackjack/api";

import module namespace card="xforms-blackjack/card" at 'card.xq';
import module namespace dealer="xforms-blackjack/dealer" at 'dealer.xq';
import module namespace deck="xforms-blackjack/deck" at 'deck.xq';
import module namespace game="xforms-blackjack/game" at 'game.xq';
import module namespace hand="xforms-blackjack/hand" at 'hand.xq';
import module namespace html="xforms-blackjack/html" at 'html.xq';
import module namespace player="xforms-blackjack/player" at 'player.xq';
import module namespace usr="xforms-blackjack/usr" at 'usr.xq';

import module namespace ws = "http://basex.org/modules/ws";
import module namespace request = "http://exquery.org/ns/request";

import module namespace session = 'http://basex.org/modules/session';

declare variable $api:games := db:open('xforms-games')/games;
declare variable $api:users := db:open('xforms-users')/users;

declare
%rest:path("/xforms-blackjack")
%rest:GET
%output:method("html")
function api:entry() {
  if (session:get('name'))
  then (
    html:menu() 
  ) else (
    html:login()
  )
};

declare
%rest:GET
%rest:path('xforms-blackjack/signup')
%output:method("html")
%rest:query-param("error", "{$error}")
function api:sign-up($error) {
    html:signup($error)
};

declare
%rest:POST
%rest:path("/xforms-blackjack/signup")
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
      user:create($name, $pass, 'none'),
      usr:create($name)
    ),
    update:output(web:redirect("/xforms-blackjack"))
  } catch * {
    update:output(web:redirect("/xforms-blackjack/signup", map { 'error': $err:description }))
  }
};

declare
%rest:POST
%rest:path('/xforms-blackjack/signup-check')
%rest:query-param('name', '{$name}')
%rest:query-param('pass', '{$pass}')
function api:signup-check(
  $name as xs:string,
  $pass as xs:string
) as element(rest:response) {
  
};

declare
%rest:POST
%rest:path('/xforms-blackjack/login')
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
  web:redirect('/xforms-blackjack')
};

declare
%rest:path('/xforms-blackjack/logout')
function api:logout() as element(rest:response) {
  session:get('name') ! api:close(.),
  session:delete('name'),
  web:redirect('/xforms-blackjack')
};

declare function api:close($name  as  xs:string) as empty-sequence() {
  for $wsId in ws:ids()
  where ws:get($wsId, 'name') = $name
  return ws:close($wsId)
};

declare
%rest:path("/xforms-blackjack/setup")
%rest:GET
%output:method("html")
%updating
function api:setup() {
  db:create('xforms-games', doc('../static/xforms-static/xml/games.xml')),
  db:create('xforms-users', doc('../static/xforms-static/xml/users.xml')),
  update:output(web:redirect('/xforms-blackjack'))
};

declare
%rest:path("/xforms-blackjack/profile")
%rest:GET
%output:method("html")
function api:profile() {
  html:profile()
};

declare
%rest:path("/xforms-blackjack/deposit")
%rest:POST
%rest:form-param("amount", "{$amount}", 0) 
%output:method("html")
%updating
function api:deposit($amount) {
  let $name := session:get('name')
  let $user := $api:users/user[@name=$name]
  return (
    usr:deposit($user, $amount),
    update:output(web:redirect("/xforms-blackjack/profile"))
  )
};

declare
%rest:path("/xforms-blackjack/games")
%rest:GET
%output:method("html")
function api:accessGames() {
  if (session:get('name'))
  then (
    html:games()
  ) else (
    html:login()
  )
};

declare
%rest:path("/xforms-blackjack/highscores")
%rest:GET
%output:method("html")
function api:accessHighscores() {
  if (session:get('name'))
  then (
    html:highscores() 
  ) else (
    html:login()
  )
};

declare
%rest:path("/xforms-blackjack/games")
%rest:POST
%updating
function api:createGame() {
  game:updateCreate(),
  update:output(web:redirect(concat("/xforms-blackjack/games/", game:latestId() + 1)))
};

declare
%rest:path("/xforms-blackjack/games/{$gameId}/delete")
%rest:POST
%updating
function api:deleteGame($gameId as xs:integer) {
    let $game := $api:games/game[@id = $gameId]
    return (
      game:delete($game),
      update:output(web:redirect("/xforms-blackjack/games"))
    )
};

declare
%rest:path("/xforms-blackjack/games/{$gameId}/join")
%rest:POST
%updating
function api:joinGame($gameId as xs:integer) {
  let $name := session:get('name')
  return (
    player:joinGame($gameId, $name),
    update:output(web:redirect(concat("/xforms-blackjack/games/", $gameId, "/draw")))
  )
};

declare
%rest:path("/xforms-blackjack/games/{$gameId}/leave")
%rest:POST
%updating
function api:leaveGame($gameId as xs:integer) {
  let $game := $api:games/game[@id = $gameId]
  let $name := session:get('name')
  let $player := $game/player[@name = $name]
  return (
    player:leave($player),
    update:output(web:redirect(concat("/xforms-blackjack/games/", $gameId, "/draw")))
  ) 
};

declare
%rest:path("/xforms-blackjack/games/{$gameId}")
%rest:GET
%output:method("html")
function api:accessGame($gameId) {
  if (session:get('name'))
  then (
    api:getGame($gameId)
  ) else (
    html:login()
  )
};

declare function api:getGame($gameId) {
  if (exists($api:games/game[@id = $gameId]))
  then (
    api:returnGame($gameId)
  ) else (
    api:gameNotFound()
  )
};

declare function api:returnGame($gameId) {
  let $name := session:get('name')
  let $hostname := request:hostname()
  let $port := request:port()
  let $address := concat($hostname,":",$port)
  let $websocketURL := concat("ws://", $address, "/ws/xforms-blackjack")
  let $getURL := concat("http://", $address, "/xforms-blackjack/games/", $gameId, "/draw")
  let $subscription := concat("/xforms-blackjack/games/", $gameId, "/", $name)
  let $html :=
      <html>
          <head>
              <title>xforms-blackjack</title>
              <script src="/static/xforms-static/js/jquery-3.2.1.min.js"></script>
              <script src="/static/xforms-static/js/stomp.js"></script>
              <script src="/static/xforms-static/js/ws-element.js"></script>
              <link rel="stylesheet" type="text/css" href="/static/xforms-static/css/style.css"/>
          </head>
          <body>
              <ws-stream id="xforms-blackjack" url="{$websocketURL}" subscription="{$subscription}" geturl="{$getURL}"/>
          </body>
      </html>
  return $html
};

declare function api:gameNotFound() {
  html:gameNotFound()
};

declare
%rest:path("/xforms-blackjack/games/{$gameId}/draw")
%rest:GET
function api:drawGame($gameId) {
  let $game := $api:games/game[@id = $gameId]
  let $wsIds := ws:ids()
  return (
    for $wsId in $wsIds
    where ws:get($wsId, "app") = "xforms-blackjack" and ws:get($wsId, "gameId") = $gameId
    let $path := ws:get($wsId, "path")
    let $name := ws:get($wsId, "name")
    let $destinationPath := concat("/xforms-blackjack/", $path, "/", $gameId, "/", $name)
    let $data := game:draw($game, $name)
    let $trace := trace(concat("xforms-blackjack: drawing game to destination path: ", $destinationPath))
    return (
      ws:sendchannel(fn:serialize($data), $destinationPath)
    )
  )
};

declare
%rest:path("/xforms-blackjack/games/{$gameId}/draw")
%rest:POST
function api:redraw($gameId) {
  api:drawGame($gameId)
};

declare
%rest:path("/xforms-blackjack/games/{$gameId}/bet")
%rest:POST
%rest:form-param("bet", "{$bet}", 0) 
%updating
function api:betPlayer($gameId, $bet) {
  let $game := $api:games/game[@id = $gameId]
  let $player := $game/player[@state='active']
  return (
    player:bet($player, $bet),
    update:output(web:redirect(concat("/xforms-blackjack/games/", $gameId, "/draw")))
  )
};

declare
%rest:path("/xforms-blackjack/games/{$gameId}/hit")
%rest:POST
%updating
function api:hitPlayer($gameId) {
  let $game := $api:games/game[@id = $gameId]
  let $player := $game/player[@state='active']
  return (
    player:hit($player),
    update:output(web:redirect(concat("/xforms-blackjack/games/", $gameId, "/draw")))
  )
};

declare
%rest:path("/xforms-blackjack/games/{$gameId}/stand") 
%rest:POST
%updating
function api:standPlayer($gameId) {
  let $game := $api:games/game[@id = $gameId]
  let $player := $game/player[@state='active']
  return (
    player:stand($player),
    update:output(web:redirect(concat("/xforms-blackjack/games/", $gameId, "/draw")))
  )
};

declare
%rest:path("/xforms-blackjack/games/{$gameId}/double")
%rest:POST
%updating
function api:doublePlayer($gameId) {
  let $game := $api:games/game[@id = $gameId]
  let $player := $game/player[@state='active']
  return (
    player:double($player),
    update:output(web:redirect(concat("/xforms-blackjack/games/", $gameId, "/draw")))
  )
};

declare
%rest:path("/xforms-blackjack/games/{$gameId}/newRound")
%rest:POST
%updating
function api:newRound($gameId) {
  let $game := $api:games/game[@id = $gameId]
  return (
    game:newRound($game),
    update:output(web:redirect(concat("/xforms-blackjack/games/", $gameId, "/draw")))
  )
};

declare
%rest:path("/xforms-blackjack/games/{$gameId}/chat")
%rest:POST
%rest:form-param("msg", "{$msg}")
%updating
function api:chat($gameId, $msg) {
  let $game := $api:games/game[@id = $gameId]
  let $name := session:get('name')
  let $trace := trace("new message in chat")
  let $chat := $game/chat
  
  return (
    insert node <message author="{$name}">{$msg}</message> into $chat,
    update:output(web:redirect(concat("/xforms-blackjack/games/", $gameId, "/draw")))
  )
};

declare
%rest:path("/xforms-blackjack/test")
%rest:GET
%output:method("html")
function api:test() {
  let $myHand :=
        <hand value="21">
        <card value="4" suit="spades"/>
        <card value="7" suit="spades"/>
        <card value="K" suit="diamonds"/>
      </hand>
  let $dealerHand := 
  <hand value="19">
  <card value="J" suit="spades"/>
  <card value="9" suit="clubs"/>
  </hand>
  let $result := hand:evaluate($myHand, $dealerHand)
  let $trace := trace($result)
  return (
    <div></div>
  )
};

declare
%rest:path("/xforms-blackjack/test/game")
%rest:GET
%output:method("html")
function api:testGame() {
  let $self := 
  <game id="1" state="playing">
    <dealer>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
      <deck>
      </deck>
    </dealer>
    <player name="1" state="active">
      
      <bet>20</bet>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
    </player>
    <player name="2" state="active">
      
      <bet>50</bet>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
    </player>
    <player name="3" state="active">
      
      <bet>70</bet>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
    </player>
    <player name="4" state="active">
      
      <bet>200</bet>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
    </player>
    <player name="5" state="active">
      
      <bet>500</bet>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
    </player>
    <chat>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">long message long message long message long message long message long message long message long message long message </message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">Hello</message>
      <message author="test">last message</message>
    </chat>
  </game>
  return 
  <html>
    <head>
        <title>xforms-blackjack</title>
        <script src="/static/xforms-static/JS/jquery-3.2.1.min.js"></script>
        <script src="/static/xforms-static/JS/stomp.js"></script>
        <script src="/static/xforms-static/JS/ws-element.js"></script>
        <link rel="stylesheet" type="text/css" href="/static/xforms-static/css/style.css"/>
    </head>
    <body>
      {game:draw($self, "daniel3")}
    </body>
  </html>
};

declare
%rest:path("/xforms-blackjack/test/lobby")
%rest:GET
%output:method("html")
function api:testLobby() {
  let $stylesheet := doc("../static/xforms-static/xslt/lobby.xsl")
  let $games := <games>
  <game id="1" state="evaluated">
    <dealer>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
      <deck>
      </deck>
    </dealer>
    <player name="1" state="lost">
      
      <bet>20</bet>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
    </player>
    <player name="2" state="lost">
      
      <bet>50</bet>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
    </player>
    <player name="3" state="won">
      
      <bet>70</bet>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
    </player>
    <player name="4" state="lost">
      
      <bet>200</bet>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
    </player>
    <player name="5" state="won">
      
      <bet>500</bet>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
    </player>
  </game>
  <game id="1" state="evaluated">
    <dealer>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
      <deck>
      </deck>
    </dealer>
    <player name="1" state="lost">
      
      <bet>20</bet>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
    </player>
    <player name="2" state="lost">
      
      <bet>50</bet>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
    </player>
    <player name="3" state="won">
      
      <bet>70</bet>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
    </player>
    <player name="4" state="lost">
      
      <bet>200</bet>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
    </player>
    <player name="5" state="won">
      
      <bet>500</bet>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
    </player>
  </game>
  <game id="1" state="evaluated">
    <dealer>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
      <deck>
      </deck>
    </dealer>
    <player name="1" state="lost">
      
      <bet>20</bet>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
    </player>
    <player name="2" state="lost">
      
      <bet>50</bet>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
    </player>
    <player name="3" state="won">
      
      <bet>70</bet>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
    </player>
    <player name="4" state="lost">
      
      <bet>200</bet>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
    </player>
    <player name="5" state="won">
      
      <bet>500</bet>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
    </player>
  </game>
  <game id="1" state="evaluated">
    <dealer>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
      <deck>
      </deck>
    </dealer>
    <player name="1" state="lost">
      
      <bet>20</bet>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
    </player>
    <player name="2" state="lost">
      
      <bet>50</bet>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
    </player>
    <player name="3" state="won">
      
      <bet>70</bet>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
    </player>
    <player name="4" state="lost">
      
      <bet>200</bet>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
    </player>
    <player name="5" state="won">
      
      <bet>500</bet>
      <hand value="14">
        <card value="7" suit="hearts"/>
        <card value="7" suit="hearts"/>
      </hand>
    </player>
  </game>
</games>
  let $map := map{ "screen": "games", "name": "test" }
  return xslt:transform($games, $stylesheet, $map)
};