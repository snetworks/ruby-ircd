class SICServer
  def check_pong c
    puts Time.now.to_i.to_s + ' - ' + @pongs[c].to_s
    if (Time.now.to_i - @pongs[c]) >= CFG_PING_TIMEOUT
      verbose 'Ping timeout'
      @clients.delete c
      c.close
    end
  end
  
  # Check if c is registered (passed valid NICK and USER commands)
  # if verbose is set, send a warning to c through the socket
  def registered? c, verbose = false
    if @clients[c][:nick] == nil
      if verbose then
	c.puts 'NICK is NOT set, you cannot operate'
      end
      
      return false
    elsif @clients[c][:user] == nil
      if verbose then
	c.puts 'You are not registered, please use the USER command, you cannot operate'
      end
      
      return false
    else
      return true
    end
  end
  
end