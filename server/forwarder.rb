#!/usr/local/bin/ruby -Ke


module SameRime
module SameRimeServer

# SameRimeClient::Messenger���ƥ�å������������ꡢ
# ž�����ݤ�Controller���䤤��碌����ˡ�SameRimeClient::Listener�˥�å����������Τ��롣
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

  # ���饤����ȡ�Messenger�ˤ������³���Ԥ������롣
  # ����IP���ɥ쥹���������ݤ�Controller�˳�ǧ�����塢�����Forward���롣
  #
  # ���������å������Υե����ޥåȤ�
  # *   1byte�ܡ� 15byte�ܡ�����IP���ɥ쥹�򼨤�ʸ����
  # *  16byte�ܡ�����     ����å�����ʸ����
  # ����IP���ɥ쥹�������ʾ��ˤϡ�ACK�Ȥ���1���֤���
  # ������IP���ɥ쥹�����ꤵ�줿���ˤϡ�ACK�Ȥ���0���֤���
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
