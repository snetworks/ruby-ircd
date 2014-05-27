require 'rexml/document'

begin
  doc = REXML::Document.new File.read ARG_CFG_FILE
rescue NameError
  doc = REXML::Document.new File.read 'cfg.xml'
end

CFG_SERVER_NAME = doc.root.elements['name'].text
CFG_MOTD_PATH = doc.root.elements['motd'].text
CFG_MOTD = File.read CFG_MOTD_PATH