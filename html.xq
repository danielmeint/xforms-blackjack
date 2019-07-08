module namespace html = "xforms/bjx/html";

import module namespace api="xforms/bjx/api" at 'api.xq';

import module namespace session = 'http://basex.org/modules/session';

declare function html:wrap($content) {
  <html>
    <head>
      <link rel="stylesheet" type="text/css" href="/static/bjx/css/style.css"/>
    </head>
    <body>
    
    <div class="flex-container flex-center">
      <div class="content">
        {$content}
      </div>
    </div>
    </body>
  </html>
};

declare function html:menu() {
  let $name := session:get('name')
  let $user := $api:users/user[@name=$name]
  return (
    html:wrap(
      <div>
        <div id="login" class="right top">
          <span><b>{$name}</b> (${$user/balance/text()})</span>
          <a class="btn btn-secondary" href="/bjx/logout">
            <svg>
              <use href="/static/bjx/svg/solid.svg#sign-out-alt"/>
            </svg>
          </a>
        </div>
        <h1>XForms Multi-Client Blackjack</h1>
        <form class="form-menu" action="/bjx/games" method="post">
            <input class="btn btn-menu" type="submit" value="New Game" />
        </form>
        <form class="form-menu">
            <a class="btn btn-menu" href="/bjx/games">Join Game</a>
        </form>
        <form class="form-menu">
            <a class="btn btn-menu btn-secondary" href="/bjx/highscores">Highscores</a>
        </form>
      </div>
    )
  )

};

declare function html:login() {
  html:wrap(
  <form action='/bjx/login' method='post'>
    <p>Please enter your credentials</p>
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
        <td><a class="btn btn-secondary" href='/bjx/signup'>Sign Up</a></td>
        <td><button class="btn" type='submit'>Login</button></td>
      </tr>
    </table>
  </form>
  )
};

declare function html:signup($error) {
  html:wrap(
  <form action='/bjx/signup' method='post'>
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
        <td><a class="btn btn-secondary" href='/bjx'>Log In</a></td>
        <td><button class="btn" type='submit'>Create Account</button></td>
      </tr>
    </table>
  </form>

  )
};

declare function html:games() {
  let $stylesheet := doc("../static/bjx/xslt/lobby.xsl")
  let $data := $api:games
  let $map := map{ "screen": "games", "name": session:get('name') }
  let $content := xslt:transform($data, $stylesheet, $map)
  return html:wrap($content)
};

declare function html:highscores() {
  let $stylesheet := doc("../static/bjx/xslt/lobby.xsl")
  let $data := $api:users
  let $map := map{ "screen": "highscores", "name": session:get('name') }
  let $content := xslt:transform($data, $stylesheet, $map)
  return html:wrap($content)
};

declare function html:gameNotFound() {
  html:wrap(
    <form action="/bjx/games" method="post">
      <a class="btn btn-secondary left top" href="/bjx">◀ Menu</a>
      <p>Game not found.</p>
      <input class="btn" type="submit" value="Create new Game" />
    </form>
  )
};