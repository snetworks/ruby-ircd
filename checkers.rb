class IRCServer
  def check_pong c
    if (Time.now.to_i - @pongs[c]) >= CFG_PING_TIMEOUT
      verbose 'Ping timeout'
      @clients.delete c
      c.close
      Thread.exit
    end
  end
  
  def channel_format? chan
    if chan =~ /^#(\w*)$/ then
      return true
    else
      return false
    end
  end
  
  def nick_format? nick
    if nick =~ /^([\w`\"\'\^]*)$/ then
      return true
    else
      return false
    end
  end
  
  # Return either 'nick' or 'channel'
  def check_type var
    if channel_format? var then
      return 'channel'
    elsif nick_format? var then
      return 'nick'
    else
      return 'nil'
    end
  end
  
  # Check if c is registered (passed valid NICK and USER commands)
  # if verbose is set, send a warning to c through the socket
  def registered? c, verbose = false
    if @clients[c][:nick].empty?
      if verbose then
	send_errnr_to_client c, NR::ERR_NOTREGISTERED
      end
      
      return false
    elsif @clients[c][:user] != 1
      if verbose then
	send_errnr_to_client c, NR::ERR_NOTREGISTERED
      end
      
      return false
    else
      return true
    end
  end
  
end