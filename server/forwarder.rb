#!/usr/local/bin/ruby -Ke


module SameRime
module SameRimeServer

# SameRimeClient::Messengerより各メッセージを受け取り、
# 転送可否をControllerに問い合わせた後に、SameRimeClient::Listenerにメッセージを通知する。
#
#                           Forwarder
#    Messenger            +-----------+
#   +----------+          |           |       Controller
#   |          |--------->|accept     |----->+-------------+
#   | close    |<---------|           |      |forwardable? |
#   +----------+   ack    |           |<-----+-------------+      Listener
#                         |           |                          +---------+
#                         |           |------------------------->|accept   |
#                         +-----------+                          |         |
#                                                                +---------+
#
class Forwarder
  def initialize(controller)
    @controller=controller
    @server=TCPServer.open(@controller.config[:ForwardingPort])
    @status={}
    @logger=Log4r::Logger['default_logger']
  end

  # クライアント（Messenger）からの接続を待ち受ける。
  # 宛先IPアドレスの送信可否をControllerに確認した後、宛先にForwardする。
  #
  # 受信するメッセージのフォーマットは
  # *   1byte目〜 15byte目：宛先IPアドレスを示す文字列
  # *  16byte目〜不定     ：メッセージ文字列
  # 宛先IPアドレスが不正な場合には、ACKとして1を返す。
  # 正しいIPアドレスが指定された場合には、ACKとして0を返す。
  def run
    begin
    @logger.info {"SameRimeServer::Forwarder running..."}
    while messenger=@server.accept
      msg=SameRime::Message.new(messenger.gets)
      @logger.debug {"SameRimeServer::Forwarder accepted message #{msg}"}
      to_addr=msg.receiver
      if port=@controller.forwardable?(to_addr)
        @logger.debug {"SameRimeServer::Forwarder forwards to #{to_addr} : #{port}"}
        begin
          listener=TCPSocket.open(to_addr,port)
          listener.puts msg.to_s
          listener.close
        rescue Exception=>e
          @logger.error {"SameRimeServer::Forwarder forwarding failed :#{e.backtrace}"}
          @controller.remove_client(to_addr)
          messenger.puts "1"
          messenger.close
        else
          messenger.puts "0"
          messenger.close
        end
      else
        @logger.error {"SameRimeServer::Forwarder forwardable? was #{port}."}
        @logger.error {"SameRimeServer::Forwarder sender's message was #{msg}"}
        messenger.puts "1"
        messenger.close
      end
    end
    rescue Exception=>e
      @logger.fatal {"SameRimeServer::Forwarder#run raises #{e.class}."}
      @logger.fatal {e.backtrace}
    end
  end
end


end
end
