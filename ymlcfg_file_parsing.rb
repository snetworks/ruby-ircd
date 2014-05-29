require 'yaml'

y = YAML.load_file ARG_CFG_FILE

CFG_SERVER_FULLNAME = y['fullname']
CFG_SERVER_NAME = y['name']
CFG_MOTD_PATH = y['motd']

CFG_SSL_CERT_PATH = y['ssl_cert_path']
CFG_SSL_KEY_PATH = y['ssl_key_path']

CFG_PING_INTERVAL = y['ping_interval']
CFG_PING_TIMEOUT = y['ping_timeout']

CFG_MOTD = File.read CFG_MOTD_PATH