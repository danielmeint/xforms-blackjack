module namespace html = "xforms-blackjack/html";

import module namespace api="xforms-blackjack/api" at 'api.xq';

import module namespace session = 'http://basex.org/modules/session';

declare function html:wrap($content) {
  <html>
    <head>
      <link rel="stylesheet" type="text/css" href="/static/xforms-static/css/style.css"/>
    </head>
    <body>
    
    <div class="flex-container flex-center">
      {$content}
    </div>
    </body>
  </html>
};

declare function html:menu() {
  let $name := session:get('name')
  let $user := $api:users/user[@name=$name]
  return (
    html:wrap(
      <div class="content">
        <div id="login" class="right top">
          <span><b><a href="/xforms-blackjack/profile">{$name}</a></b> (${$user/balance/text()})</span>
          <a class="btn btn-secondary" href="/xforms-blackjack/logout">
            <svg>
              <use href="/static/xforms-static/svg/solid.svg#sign-out-alt"/>
            </svg>
          </a>
        </div>
        <h1>XForms Multi-Client Blackjack</h1>
        <form class="form-menu" action="/xforms-blackjack/games" method="post">
            <input class="btn btn-menu" type="submit" value="New Game" />
        </form>
        <form class="form-menu">
            <a class="btn btn-menu" href="/xforms-blackjack/games">Join Game</a>
        </form>
        <form class="form-menu">
            <a class="btn btn-menu btn-secondary" href="/xforms-blackjack/highscores">Highscores</a>
        </form>
      </div>
    )
  )

};

declare function html:login($error) {
  html:wrap(
  <div class="content">
    <form action='/xforms-blackjack/login' method='post'>
      <p class="error">{$error}</p>
      <table>
        <tr>
          <td><b>Name:</b></td>
          <td>
            <input size='30' type="text" name='name' id='user' autofocus=''/>
          </td>
        </tr>
        <tr>
          <td><b>Password:</b></td>
          <td>
            <input size='30' type='password' name='pass'/>
          </td>
        </tr>
        <tr>
          <td><a class="btn btn-secondary" href='/xforms-blackjack/signup'>Sign Up</a></td>
          <td><button class="btn" type='submit'>Login</button></td>
        </tr>
      </table>
    </form>
  </div>
  )
};

declare function html:signup($error) {
  html:wrap(
  <div class="content">
    <form action='/xforms-blackjack/signup' method='post'>
      <p class="error">{$error}</p>
      <table>
        <tr>
          <td><b>Name:</b></td>
          <td>
            <input size='30' type="text" name='name' id='user' autofocus=''/>
          </td>
        </tr>
        <tr>
          <td><b>Password:</b></td>
          <td>
            <input size='30' type='password' name='pass'/>
          </td>
        </tr>
        <tr>
          <td><a class="btn btn-secondary" href='/xforms-blackjack'>Log In</a></td>
          <td><button class="btn" type='submit'>Create Account</button></td>
        </tr>
      </table>
    </form>
  </div>
  )
};

declare function html:games() {
  let $name := session:get('name')
  let $user := $api:users/user[@name=$name]
  
  let $stylesheet := doc("../static/xforms-static/xslt/lobby.xsl")
  let $data := $api:games
  let $map := map{ "screen": "games", "name": $name, "balance": $user/balance }
  let $content := xslt:transform($data, $stylesheet, $map)
  return html:wrap($content)
};

declare function html:highscores() {
  let $name := session:get('name')
  let $user := $api:users/user[@name=$name]
  
  let $stylesheet := doc("../static/xforms-static/xslt/lobby.xsl")
  let $data := $api:users
  let $map := map{ "screen": "highscores", "name": $name, "balance": $user/balance }
  let $content := xslt:transform($data, $stylesheet, $map)
  return html:wrap($content)
};

declare function html:profile() {
  let $name := session:get('name')
  let $user := $api:users/user[@name=$name]
  
  let $stylesheet := doc("../static/xforms-static/xslt/lobby.xsl")
  let $data := $user
  let $map := map{ "screen": "profile", "name": $name, "balance": $user/balance }
  let $content := xslt:transform($data, $stylesheet, $map)
  return html:wrap($content)
};

declare function html:gameNotFound() {
  html:wrap(
    <div class="content">
      <form action="/xforms-blackjack/games" method="post">
        <a class="btn btn-secondary left top" href="/xforms-blackjack">◀ Menu</a>
        <p>Game not found.</p>
        <input class="btn" type="submit" value="Create new Game" />
      </form>
    </div>

  )
};