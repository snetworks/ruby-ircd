#!/usr/bin/ruby

GLOBAL_VERSION = '0.0.1 alpha'
t = Time.new
GLOBAL_DATE = t.day.to_s + '/' + t.month.to_s + '/' + t.year.to_s + ' ' + t.hour.to_s + ':' + t.min.to_s + ':' + t.sec.to_s

require 'socket'
require './argv_handling.rb' # handle argv and assign constants
require './ymlcfg_file_parsing.rb' # parse config file (default is cfg.xml) & define CFG_MOTD
require './numeric_replies.rb' # define NR::name => numeric replies
require './checkers.rb' # checking methods to validates nicks, channels ... also include ping timeout checker
require './output_methods.rb' # define output methods to send to clients


class SICServer
  def initialize host, port
    @srv_host = host
    @s = TCPServer.open host, port
    # Set default USER & NICK values for server (this server)
    # This is used to send messages to clients (ie: for numeric replies)
    @clients = {@s => {:nick => CFG_SERVER_FULLNAME,
                                :username => CFG_SERVER_NAME,
                                :hostname => CFG_SERVER_NAME,
                                :servername => CFG_SERVER_FULLNAME,
                                :realname => 'Your host',
                                :user => 1,
				:init => 1,
				:channels => []
                               }
                  }
    @channels = {'' => {:topic => '', :clients => []}} # {channel => {cfg_vars => ..., clients => [c, ...] ...}
    @nicks = Hash.new # {nick => c ...} Used to check nick collisions, & get c from nick
    @pongs = Hash.new # {c => last_pong_timestamp ...}
    
    
    listen
  end

  def listen
    loop do
      Thread.start(@s.accept) do |c|
	verbose 'New client'
	
	# Fill default values, to escape NoMethod * for NilClass
	# Ie: to send RPL_NICKNAMEINUSE
	new_client = {c => {:nick => '',
			     :username => '',
			     :hostname => '',
			     :servername => '',
			     :realname => '',
			     :user => 0,
	                     :init => 0,
	                     :channels => []
			    }
	      }
	new_ping = {c => Time.now.to_i}
	@clients.merge! new_client
	@pongs.merge! new_ping
	
	@clients[c][:channels] = Array.new
	
	pong = Thread.new do
	  loop do
	    check_pong c
	    sleep CFG_PING_TIMEOUT
	  end
	end
	
	ping = Thread.new do
	  loop do
	    send_ping c, CFG_SERVER_FULLNAME
	    sleep CFG_PING_INTERVAL
	  end
	end
	
	listen_clients c
      end
    end
  end
  
  def listen_clients c
    loop do
      unless c.closed? then
	msg =  c.gets.chomp
	
	verbose '<<' + msg
	evaluate c, msg
      end
    end
  end
  
  # Evaluate SIC commands (REGISTER, NICK, ....)
  def evaluate c, msg
    verbose 'Starting evaluation'
    verbose_raw msg
    
    case
    when msg =~ /^NICK /
      evaluate_nick c, msg
    when msg =~ /^USER /
      evaluate_user c, msg
    when msg =~ /^PONG /
      evaluate_pong c, msg
    when msg =~ /^PING /
      evaluate_ping c, msg
    when msg =~ /^PRIVMSG /
      if registered? c, 1 then
	evaluate_privmsg c, msg
      end
    when msg =~ /^JOIN /
      if registered? c, 1 then
	evaluate_join c, msg
      end
    when msg =~ /^NOTICE /
      if registered? c, 1 then
	evaluate_notice c, msg
      end
    when msg =~ /^QUIT[[:space:]]?/
      evaluate_quit c, msg
    when msg =~ /^DEBUG/
      send_raw_to_client @s, c, @clients.to_s
      send_raw_to_client @s, c, @channels.to_s
      send_raw_to_client @s, c, @nicks.to_s
      send_raw_to_client @s, c, @pongs.to_s
    end
  end
  
  # Command: NICK
  # Parameters: <nickname>
  def evaluate_nick c, raw
    verbose 'Evaluating NICK'
    
    args = raw.split ' '
    
    # Check if nickname is already in use
    unless @nicks.include? args[1] then
      # If it is first NICK use
      if @clients[c][:nick].empty? then
	@clients[c][:nick] = args[1]
      else # If request a second NICK: change :nick value & delete previous nick from nicklist
	verbose 'Switching nick'
	
	@nicks.delete @clients[c][:nick]
	@clients[c][:nick] = args[1]
      end
      
      new_nick = {args[1] => c}
      @nicks.merge! new_nick
    else
      verbose 'Nick collision'
      send_errnr_to_client c, NR::ERR_NICKNAMEINUSE, args[1]
    end
    
    # If USER is already set, send RPL_WELCOME, RPL_YOURHOST, RPL_CREATED, and RPL_MYINFO
    if @clients[c][:user] == 1 then
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
      end
    end
    
    # If NICK is already set, send RPL_WELCOME, RPL_YOURHOST, RPL_CREATED, and RPL_MYINFO
    unless @clients[c][:nick].empty? then
      send_init_connection c
    end
  end
  
  def evaluate_ping c, raw
    verbose 'Evaluating PING'
    if matches = raw.match(/^PING :([\w\.]*)$/) then
      send_pong c, matches[1]
    end
  end
  
  def evaluate_pong c, raw
    verbose 'Evaluating PONG'
    if matches = raw.match(/^PONG :([\w\.]*)$/) then
      # @pongs is used to check ping timeouts in checkers.rb
      tmp_pong = {c => Time.now.to_i}
      @pongs.merge! tmp_pong
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
	
      # If new channel, put c in channels list
      if @channels[args[1]] == nil then
	new_channel = {args[1] => {:clients => [c], :topic => ''}}
	@channels.merge! new_channel
	
      else
	# Put c in channel user list
	@channels[args[1]][:clients].push c
      end
      
      send_join c, raw
      send_rpl_topic c, args[1]
      send_rpl_namreply c, args[1]
    end
  end
  
  # Command: PRIVMSG
  # Parameters: <channel> <message>
  def evaluate_privmsg c, raw
    verbose 'Evaluating PRIVMSG'
    send_raw_all_clients c, raw
  end
  
  # Command: NOTICE
  # Parameters: <nick> <message>
  def evaluate_notice c, raw
    verbose 'Evaluating NOTICE'
    
    args = raw.split ' '
    unless @nicks[args[1]].nil? then
      send_raw_to_client c, @nicks[args[1]], raw
    else
      send_errnr_to_client c, NR::ERR_NOSUCHNICK, args[1]
    end
  end
  
  # Command: QUIT
  # Parameters: <message>
  def evaluate_quit c, raw
    verbose 'Evaluating QUIT'
    
    send_raw_all_clients c, raw
    @clients.delete c
    c.close
    Thread.exit
  end
  
end

s = SICServer.new 'localhost', 6666