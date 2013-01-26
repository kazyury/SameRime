#!ruby -Ks

# :include: readme.txt
# :include: todo.txt
# :include: bugs.txt

require "socket.so"
require "rexml/document.rb"

require "./message.rb"
require "client/reporter.rb"
require "client/listener.rb"
require "client/ui.rb"
require "client/sessions.rb"
require "client/gui.rb"
require "client/messenger.rb"
require "client/controller.rb"


begin
  Thread.abort_on_exception=true
  controller=SameRime::SameRimeClient::Controller.new
  trap("INT"){controller.stop;exit}
  controller.run
rescue Exception=>e
  f=open("./client.error.log","a")
  f.puts e.message
  e.backtrace.each{|stackline| f.puts stackline }
  f.puts e.class
  f.puts "y#{Time.now}z"
  f.close
  raise e
end
