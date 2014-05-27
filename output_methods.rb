class SICServer
  def send_init_connection c
    send_raw_to_client :server, c, RPL_WELCOME + ' :Welcome to the Internet Chat Network ' +
	@clients[c][':nick'] + '!' + @clients[c][':hostname'] + '@' + @clients[c][':hostname']
    send_raw_to_client :server, c, RPL_YOURHOST + ':Your host is ' + CFG_SERVER_NAME + ', running version ' + GLOBAL_VERSION
    send_raw_to_client :server, c, RPL_CREATED + ':This server was created ' + GLOBAL_DATE
    send_raw_to_client :server, c, RPL_MYINFO + ':' + CFG_SERVER_NAME + ' ' + GLOBAL_VERSION + '   ' # TODO: <umodes> <cmodes>
  end
  
  def send_raw_all_clients c, raw
    # Send raw only to people on the channel
    channel = raw.split(' ')[1]
    
    # Check if sender is registered before fetching entire clients list (more efficient) & on the channel
    # If sender isn't registered, the PRIVMSG will not be send and will receive a warning
    if registered? c, true && @clients[c][:channels].include?(channel) then
      @channels[channel][:clients].each do |send_to|
	if send_to.class == TCPSocket then
	  send_raw_to_client c, send_to, raw
	end
      end
    end
  end
  
   # Send a ERR numeric reply (nr) to a client
  def send_errnr_to_client c, err, between = ''
    # If between is set, append a space, as specified in the RFC 1459
    # between is used to fill error messages whose need an arg (ie: ERR_NOLOGIN <user> :User not logged in)
    unless between.empty?
      between += ' '
    end
    send_raw_to_client c, c, err[:errno].to_s + ' ' + between + ':' + err[:errmsg]
  end

  # Send to a specific client (useful for debugging with --verbose)
  def send_raw_to_client sender, to, append
    begin
      verbose_raw ':' + @clients[sender][:nick] + '!' + @clients[sender][:username] + '@' + @clients[sender][:hostname] + ' :' + append
      to.puts ':' + @clients[sender][:nick] + '!' + @clients[sender][:username] + '@' + @clients[sender][:hostname] + ' :' + append
    rescue TypeError
      # If @clients[sender][:] are equal nil, send directly the message
      verbose 'Type error in send_raw_to_client :handled'
      verbose_raw ':' + @srv_host + '@' + @srv_host + ' ' + append
      to.puts ':' + @srv_host + '@' + @srv_host + ' ' + append
    rescue => e
      verbose e.class.to_s + ' in send_raw_to_client :NOT HANDLED'
    end
  end
  
  def verbose msg
    if ARG_VERBOSE == true then
      output_colorize msg
      puts 'bebebeb'
    end
    puts 'oh shit dude'
  end
  
  def verbose_raw msg
    if ARG_RAW == true then
      puts output_colorize msg
    end
  end
  
  def output_colorize msg
    if ARG_COLOR == true then
      return msg
    else
      # TODO
      return msg
    end
  end
end