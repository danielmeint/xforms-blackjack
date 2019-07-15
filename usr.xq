module namespace usr = "xforms-blackjack/usr";

import module namespace api="xforms-blackjack/api" at 'api.xq';

declare variable $usr:defaultBalance := 100;
declare variable $usr:defaultHighscore := $usr:defaultBalance;

declare 
%updating 
function usr:create($name) {
  insert node usr:newUser($name) into $api:users
};

declare function usr:newUser($name) {
  usr:newUser($name, $usr:defaultBalance, $usr:defaultHighscore)
};

declare function usr:newUser($name, $balance, $highscore) {
  <user name="{$name}">
    <balance>{$balance}</balance>
    <highscore>{$highscore}</highscore>
  </user>
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