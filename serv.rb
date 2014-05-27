#!/usr/bin/ruby

GLOBAL_VERSION = '0.0.1 alpha'
t = Time.new
GLOBAL_DATE = t.day.to_s + '/' + t.month.to_s + '/' + t.year.to_s + ' ' + t.hour.to_s + ':' + t.min.to_s + ':' + t.sec.to_s

require 'socket'
require './argv_handling.rb' # handle argv and assign constants
require './cfg_file_parsing.rb' # parse config file (default is cfg.xml) & define CFG_MOTD
require './numeric_replies.rb' # define NR::name => numeric replies
require './output_methods.rb' # define output methods to send to clients

class SICServer
  def initialize host, port
    @srv_host = host
    @s = TCPServer.open host, port
    @clients = Hash.new # {conn => {cfg_vars => ...}
    @channels = Hash.new # {channel => {cfg_vars => ..., clients => [c, ...] ...}
    @nicks = Array.new # Used to check nick collisions
    
    # Set default USER & NICK values for the host (this server)
    # This is used to send messages to clients (ie: for numeric replies)
    server_info = {:server => {:nick => CFG_SERVER_NAME,
                               :username => GLOBAL_VERSION,
                               :hostname => CFG_SERVER_NAME,
                               :servername => 'localhost',
                               :realname => 'Your host'
                              }
                  }
    @clients.merge! server_info
    
    listen
  end

  def listen
    loop do
      Thread.start(@s.accept) do |c|
	verbose 'new client'
	puts 'newnwnn'
	
	new_client = {c => {}}
	@clients.merge! new_client
	@clients[c][:channels] = Array.new
	listen_clients c
      end
    end
  end
  
  def listen_clients c
    loop do
      msg = c.gets.chomp
      
      verbose msg
      
      evaluate c, msg
    end
  end
  
  # Evaluate SIC commands (REGISTER, NICK, ....)
  def evaluate c, msg
    verbose 'Starting evaluation'
    
    case
    when msg =~ /^NICK /
      evaluate_nick c, msg
    when msg =~ /^USER /
      evaluate_user c, msg
    when msg =~ /^PRIVMSG /
      evaluate_privmsg c, msg
    when msg =~ /^JOIN /
      evaluate_join c, msg
    when msg =~ /^QUIT[[:space:]]?/
      evaluate_quit c, msg
    when msg =~ /^DEBUG/
      send_raw_to_client c, @clients
      send_raw_to_client c, @channels
      send_raw_to_client c, @nicks
    end
  end
  
  # Command: NICK
  # Parameters: <nickname>
  def evaluate_nick c, raw
    verbose 'Evaluating NICK'
    
    args = raw.split ' '
    
    # Check if nickname is already in use
    unless @nicks.include? args[1] then
      @clients[c][:nick] = args[1]
      @nicks.push args[1]
    else
      send_errnr_to_client c, c, NR::ERR_NICKNAMEINUSE, args[1]
    end
    
    # If USER is already set, send RPL_WELCOME, RPL_YOURHOST, RPL_CREATED, and RPL_MYINFO
    if @client[c][:user] == 1 then
      send_init_connection c
    end
  end
  
  # Command: USER
  # Parameters: <username> <hostname> <servername> <realname>
  def evaluate_user c, raw
    verbose 'Evaluating USER'
    
    # c can USER only one time
    if @clients[c][:user] == 1 then
      send_errnr_to_client c, NR::ERR_ALREADYREGISTRED
    else
      args = raw.split ' '
      
      @clients[c][:username] = args[1]
      @clients[c][:hostname] = args[2]
      @clients[c][:servername] = args[3]
      @clients[c][:realname] = args[4]
      
      if @clients[c][:username] == nil ||
	  @clients[c][:hostname] == nil ||
	  @clients[c][:servername] == nil ||
	  @clients[c][:realname] == nil
	then
	  
	@clients[c][:user] = nil
	send_errnr_to_client c, NR::ERR_NEEDMOREPARAMS, 'USER'
      else
	@clients[c][:user] = 1
	send_motd
      end
    end
    
    # If NICK is already set, send RPL_WELCOME, RPL_YOURHOST, RPL_CREATED, and RPL_MYINFO
    if @client[c][:nick] != nil then
      send_init_connection c
    end
  end
  
  # Command: JOIN
  # Parameters: <channel>
  def evaluate_join c, raw
    verbose 'Evaluating JOIN'
    
    if registered? c, 1 then
      args = raw.split ' '
      
      # Push channel name in client's joined chans list
      @clients[c][:channels].push args[1]
	
      # If new channel, put it in channels list
      if @channels[args[1]] == nil then
	new_channel = {args[1] => {:clients => [c]}}
	@channels.merge! new_channel
      else
	# Put c in channel user list
	@channels[args[1]][:clients].push c
	send_raw_all_clients c, raw
      end
    end
  end
  
  # Command: PRIVMSG
  # Parameters: <channel> <message>
  def evaluate_privmsg c, raw
    verbose 'Evaluating PRIVMSG'
    send_raw_all_clients c, raw
  end
  
  # Command: QUIT
  # Parameters: <message>
  def evaluate_quit c, raw
    verbose 'Evaluating QUIT'
    
    send_raw_all_clients c, raw
    @clients.delete c
    c.close
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

s = SICServer.new 'localhost', 6666