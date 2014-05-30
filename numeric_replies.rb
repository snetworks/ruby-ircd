# Strings are used instead of Intergers to fix bug of output numbers starting with a zero (ie: 001 would output 1)

module NR
  RPL_WELCOME = '001'
  RPL_YOURHOST = '002'
  RPL_CREATED = '003'
  RPL_MYINFO = '004'
  
  RPL_WHOREPLY = '352'
  RPL_NAMREPLY = '353'
  RPL_ENDOFNAMES = '366'
  
  RPL_TOPIC = '332'
  
  RPL_MOTDSTART = '375'
  RPL_MOTD = '372'
  RPL_ENDOFMOTD = '376'
  
  ERR_NOSUCHNICK = {:errno => '401', :errmsg => 'No such nick/channel'}
  ERR_ERRONEUSNICKNAME = {:errno => '432', :errmsg => 'Erroneus nickname'}
  
  ERR_NOSUCHCHANNEL = {:errno => '403', :errmsg => 'No such channel'}
  ERR_CANNOTSENDTOCHAN = {:errono => '404', :errmsg => 'Cannot send to channel'}
  ERR_BADCHANMASK = {:errno => '476', :errmsg => 'Bad Channel Mask'}
  
  ERR_NOTREGISTERED = {:errno => '451', :errmsg => 'You have not registered'}
  ERR_NEEDMOREPARAMS = {:errno => '461', :errmsg => 'Not enough parameters'}
  ERR_ALREADYREGISTRED = {:errno => '462', :errmsg => 'You may not reregister'}
  ERR_NICKNAMEINUSE = {:errno => '433', :errmsg => 'Nickname is already in use'}
end