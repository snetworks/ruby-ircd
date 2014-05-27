module NR
  RPL_WELCOME = 001
  RPL_YOURHOST = 002
  RPL_CREATED = 003
  RPL_MYINFO = 004
  
  RPL_WHOREPLY = 352
  RPL_NAMREPLY = 353
  
  RPL_MOTDSTART = 375
  RPL_MOTD = 372
  RPL_ENDOFMOTD = 376
  
  ERR_NEEDMOREPARAMS = {:errno => 461, :errmsg => 'Not enough parameters'}
  ERR_ALREADYREGISTRED = {:errno => 462, :errmsg => 'You may not reregister'}
  ERR_NICKNAMEINUSE = {:errno => 433, :errmsg => 'Nickname is already in use'}
end