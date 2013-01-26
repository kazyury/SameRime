#!ruby -Ke

# :include: readme.txt
# :include: todo.txt
# :include: bugs.txt

require "socket"
require "rexml/document.rb"
require "log4r"

require "./message.rb"
require "server/statusmanager.rb"
require "server/forwarder.rb"
require "server/controller.rb"

Thread.abort_on_exception=true
SameRime::SameRimeServer::Controller.new.run

