require 'rexml/document'

if defined? ARG_CFG_FILE
  doc = REXML::Document.new File.read ARG_CFG_FILE
else
  doc = REXML::Document.new File.read 'cfg.xml'
end

CFG_SERVER_FULLNAME = doc.root.elements['fullname'].text
CFG_SERVER_NAME = doc.root.elements['name'].text
CFG_MOTD_PATH = doc.root.elements['motd'].text
CFG_PING_INTERVAL = doc.root.elements['ping_interval'].text.to_i
CFG_PING_TIMEOUT = doc.root.elements['ping_timeout'].text.to_i

CFG_MOTD = File.read CFG_MOTD_PATH