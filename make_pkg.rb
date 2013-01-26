#!ruby -Ks
require "ftools.rb"

begin
  File.copy("./readme.txt"  ,"./binary/SameRime/")
  File.copy("./bugs.txt"  ,"./binary/SameRime/")
  File.copy("./todo.txt"  ,"./binary/SameRime/")
  File.copy("./client.exe","./binary/SameRime/")
rescue Errno::ENOENT
end
exec("C:/SASAKI/Util/Archway/Cool/ARCHCOOL.EXE","#{File.expand_path('./binary/SameRime/').gsub('/','\\')}")
