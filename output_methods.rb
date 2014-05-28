class SICServer
  def send_ping c, append
    send_raw_to_client 'void', c, 'PING :' + append
  end
  
  def send_pong c, append
    send_raw_to_client 'void', c, 'PONG :' + append
  end
  
  def send_init_connection c
    # Check if already initialized or not
    if @clients[c][:init] == 0 then
      send_raw_to_client @s, c, NR::RPL_WELCOME + ' ' + @clients[c][:nick] + ' :Welcome to the Internet Relay Chat Network ' + @clients[c][:nick]
      send_raw_to_client @s, c, NR::RPL_YOURHOST + ' ' + @clients[c][:nick] + ' :Your host is ' + CFG_SERVER_NAME + ', running version ' + GLOBAL_VERSION
      send_raw_to_client @s, c, NR::RPL_CREATED + ' ' + @clients[c][:nick] + ' :This server was created ' + GLOBAL_DATE
      send_raw_to_client @s, c, NR::RPL_MYINFO + ' ' + @clients[c][:nick] + ' :' + CFG_SERVER_NAME + ' ' + GLOBAL_VERSION + '   ' # TODO: <umodes> <cmodes>
      
      send_motd c
      @clients[c][:init] = 1
    end
  end
  
  def send_motd c
    send_raw_to_client @s, c, NR::RPL_MOTDSTART + ' ' + @clients[c][:nick] + ' :- ' + CFG_SERVER_FULLNAME + ' Message of the day - '
    
    File.open CFG_MOTD_PATH, 'r' do |motd|
      motd.each do |line|
	send_raw_to_client @s, c, NR::RPL_MOTD + ' ' + @clients[c][:nick] + ' :- ' + line
      end
    end
    
    
    send_raw_to_client @s, c, NR::RPL_ENDOFMOTD + ' ' + @clients[c][:nick] + ' :End of /MOTD command '
  end
  
  def send_rpl_topic c, chan
    send_raw_to_client @s, c, NR::RPL_TOPIC + ' ' + @clients[c][:nick] + ' ' + chan + ' :' + @channels[chan][:topic]
  end
  
  # Note the lack of 'e', RFC 1459 & 2812 compliant
  def send_rpl_namreply c, chan
    nicklist = ''
    @channels[chan][:clients].each do |client_c|
      nicklist += @clients[client_c][:nick] + ' '
    end
    
    send_raw_to_client @s, c, NR::RPL_NAMREPLY + ' ' + @clients[c][:nick] + ' = ' + chan + ' :' + nicklist
    send_raw_to_client @s, c, NR::RPL_ENDOFNAMES + ' ' + @clients[c][:nick] + ' ' + chan + ' :End of NAMES list'
  end
  
  def send_join c, raw
    channel = raw.split(' ')[1]
    send_raw_to_channel c, channel, raw
  end
  
  def send_raw_all_clients c, raw
    args = raw.split ' '
    
    case
    when channel_format?(args[1])# Used for commands which specify a channel (ie: PRIVMSG, PART ...)
      send_raw_to_channel c, args[1], raw, false
    when nick_format?(args[1]) # Used to send PRIVMSG to nicks
      send_raw_to_client c, @nicks[args[1]], raw, false
    else # Used for commands which does not specify a channel (ie: QUIT)
      @clients[c][:channels].each do |c_channels|
	send_raw_to_channel c, c_channels, raw
      end
    end
  end
  
  # Send to all clients on a specific channel
  def send_raw_to_channel c, channel, raw, double = true
    if channel_format?(channel) then
      if @channels.include? channel then
	if @clients[c][:channels].include? channel then
	  @channels[channel][:clients].each do |channel_clients|
	    if double then # If double = true, send the raw to the sender (c)
	      send_raw_to_client c, channel_clients, raw
	    else
	      unless channel_clients == c then
		send_raw_to_client c, channel_clients, raw
	      end
	    end
	  end
	else
	  send_errnr_to_client c, NR::ERR_CANNOTSENDTOCHAN, channel
	end
      else
	send_errnr_to_client c, NR::ERR_NOSUCHCHANNEL, channel
      end
    else
      send_errnr_to_client c, NR::ERR_BADCHANMASK, channel
    end
  end
  
   # Send an ERR numeric reply (nr) to a client
  def send_errnr_to_client c, err, between = ''
    # If between is set, append a space, as specified in the RFC 1459
    # between is used to fill error messages whose need an arg (ie: ERR_NOLOGIN <user> :User not logged in)
    unless between.empty?
      between += ' '
    end
    send_raw_to_client @s, c, err[:errno] + ' ' + @clients[c][:nick] + ' ' + between + ':' + err[:errmsg]
  end

  # Send to a specific client
  def send_raw_to_client sender, to, append
    unless sender == 'void'
      verbose_raw ':' + @clients[sender][:nick] + '!' + @clients[sender][:username] + '@' + @clients[sender][:hostname] + ' ' + append
      to.puts ':' + @clients[sender][:nick] + '!' + @clients[sender][:username] + '@' + @clients[sender][:hostname] + ' ' + append
    else
      # Used for PING messages
      verbose_raw append.to_s
      to.puts append.to_s
    end
  end
  
  def verbose msg
    if defined? ARG_VERBOSE then
      puts output_colorize msg
    end
  end
  
  def verbose_raw msg
    if defined? ARG_RAW then
      puts output_colorize msg
    end
  end
  
  def output_colorize msg
    if defined? ARG_COLOR then
      return msg
    else
      # TODO
      return msg
    end
  end
end