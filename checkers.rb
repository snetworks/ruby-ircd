class SICServer
  def check_pong c
    if (Time.now.to_i - @pongs[c]) >= CFG_PING_TIMEOUT
      verbose 'Ping timeout'
      @clients.delete c
      c.close
      Thread.exit
    end
  end
  
  def channel? chan
    if chan =~ /^#(\w*)$/ then
      return true
    else
      return false
    end
  end
  
  def nick? nick
    if nick =~ /^([\w`\"\'\^]*)$/ then
      return true
    else
      return false
    end
  end
  
  # Return either 'nick' or 'channel'
  def check_type var
    if channel? var then
      return 'channel'
    elsif nick? var then
      return 'nick'
    else
      return 'nil'
    end
  end
  
  # Check if c is registered (passed valid NICK and USER commands)
  # if verbose is set, send a warning to c through the socket
  def registered? c, verbose = false
    if @clients[c][:nick] == nil
      if verbose then
	# TODO: ERR_NOTREGISTERED
	c.puts 'NICK is NOT set, you cannot operate'
      end
      
      return false
    elsif @clients[c][:user] == nil
      if verbose then
	# TODO: ERR_NOTREGISTERED
	c.puts 'You are not registered, please use the USER command, you cannot operate'
      end
      
      return false
    else
      return true
    end
  end
  
end