module namespace usr = "xforms-blackjack/usr";

import module namespace api="xforms-blackjack/api" at 'api.xq';

declare variable $usr:defaultPassword := "";
declare variable $usr:defaultBalance := 100;
declare variable $usr:defaultHighscore := $usr:defaultBalance;

declare 
%updating 
function usr:create($name) {
  insert node usr:newUser($name) into $api:users
};

declare
%updating
function usr:create($name, $password) {
  insert node usr:newUser($name, $password) into $api:users
};

declare function usr:newUser($name, $password, $balance, $highscore) {
  <user name="{$name}" password="{$password}">
    <balance>{$balance}</balance>
    <highscore>{$highscore}</highscore>
  </user>
};

declare function usr:newUser($name, $password) {
  usr:newUser($name, $password, $usr:defaultBalance, $usr:defaultHighscore)
};

declare function usr:newUser($name) {
  usr:newUser($name, $usr:defaultPassword, $usr:defaultBalance, $usr:defaultHighscore)
};

declare function usr:check($name, $password) as xs:boolean {
  if ($api:users/user[@name=$name and @password=$password])
  then (
    true()
  ) else (
    false()
  )
};

declare function usr:exists($name) {
  if ($api:users/user[@name=$name])
  then (
    true()
  ) else (
    false()
  )
};

declare
%updating
function usr:deposit($self, $amount) {
  let $newBalance := $self/balance/text() + $amount
  return (
    replace value of node $self/balance with $newBalance,
    if ($newBalance > $self/highscore)
    then (
      replace value of node $self/highscore with $newBalance
    )
  )
};