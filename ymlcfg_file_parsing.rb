require 'yaml'

if defined? ARG_CFG_FILE
  y = YAML.load_file ARG_CFG_FILE
else
  y = YAML.load_file 'cfg.yml'
end

CFG_SERVER_FULLNAME = y['fullname']
CFG_SERVER_NAME = y['name']
CFG_MOTD_PATH = y['motd']
CFG_PING_INTERVAL = y['ping_interval']
CFG_PING_TIMEOUT = y['ping_timeout']

CFG_MOTD = File.read CFG_MOTD_PATH