module namespace chat='xforms-blackjack/chat';

declare function chat:newChat() {
  <chat/>
};

declare function chat:newChat($messages) {
  <chat>
    {$messages}
  </chat>
};

declare function chat:setMessages($self, $messages) {
  chat:newChat($messages)
};

declare function chat:addMessage($self, $msg) {
  let $newMessages := ($self/message, $msg)
  return chat:setMessages($self, $newMessages)
};