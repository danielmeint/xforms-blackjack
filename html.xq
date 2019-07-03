module namespace html = "xforms/bjx/html";

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

declare function html:gameNotFound() {
  html:wrap(
    <form action="/bjx/games" method="post">
      <a class="btn btn-secondary left top" href="/bjx">◀ Menu</a>
      <p>Game not found.</p>
      <input class="btn" type="submit" value="Create new Game" />
    </form>
  )
};