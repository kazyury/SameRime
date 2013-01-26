#!ruby -Ks


module SameRime
module SameRimeClient

# クライアントからのアクションにより、SameRimeServer::Forwarderにメッセージを送信する。
#
#
class Messenger
  def initialize(controller)
    @controller=controller
    @my_address=IPSocket.getaddress(Socket.gethostname)
    @sr_server =@controller.config[:SameRimeServer]
    @forwarder_port=@controller.config[:ForwarderPort]
    @name=@controller.config[:MyName]
  end

  # SameRimeServer::Forwarderに対してメッセージを送信し、ACKを受取る。
  # ACKが正常終了を表す場合には、trueを返す。
  # ACKが異常終了を表す場合には、falseを返す。
  def messaging(msg)
    msg.sender=@my_address
    msg.sender_name=@name
    sock=TCPSocket.open(@sr_server,@forwarder_port)
    sock.puts msg.to_s
    ack=sock.gets.chomp
    if ack=="0"
      return true
    else
      return false
    end
  end
end


end
end
