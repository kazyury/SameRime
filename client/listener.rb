#!ruby -Ks


module SameRime
module SameRimeClient

# Serverよりメッセージを受け取り、送信元IPアドレスとメッセージをUIに通知する。
class Listener
  def initialize(controller)
    @controller=controller
    @status=SameRime::SameRimeClient::ACTIVE
    @sock=TCPServer.open(@controller.config[:ListeningPort])
  end

  # 
  def run
    while sock=@sock.accept
      Thread.new(sock){|client|
        msg=SameRime::Message.new(client.gets)
        @controller.message_received(msg)
      }
    end
  end
  
  def stop
    @status=SameRime::SameRimeClient::STOPPED
  end
end


end
end

