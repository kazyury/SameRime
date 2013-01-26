#!ruby -Ks


module SameRime
module SameRimeClient

# �N���C�A���g����̃A�N�V�����ɂ��ASameRimeServer::Forwarder�Ƀ��b�Z�[�W�𑗐M����B
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

  # SameRimeServer::Forwarder�ɑ΂��ă��b�Z�[�W�𑗐M���AACK������B
  # ACK������I����\���ꍇ�ɂ́Atrue��Ԃ��B
  # ACK���ُ�I����\���ꍇ�ɂ́Afalse��Ԃ��B
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
