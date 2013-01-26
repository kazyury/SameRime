#!/usr/local/bin/ruby -Ke


module SameRime
module SameRimeServer

# SameRimeClient::Reporter����ü���Υ��ơ������������ꡢ�����Х����ɤǴ������롣
#
#                               StatusManager
#    Reporter                   +-----------+
#   +----------+                |           |
#   |          |--------------->|accept     |
#   |          |  rep OK        | check rep |
#   |          |  and status="0"|           |
#   |          |<---------------| close     |
#   |          |                +-----------+
#   +----------+
#
class StatusManager
  def initialize(controller)
    @controller=controller
    @server=TCPServer.open(@controller.config[:StatusManagerPort])
    @interval=@controller.config[:Interval]
    @status={}
    @logger=Log4r::Logger['default_logger']
    Thread.new{
      while true
        sleep @interval
        clean_up
      end
    }
  end

  # ���饤����ȡ�Reporter�ˤ������³���Ԥ�������
  # ���饤����Ȥ�ꥹ�ơ������������ꡢ@status���ݴɤ��롣
  #
  # ���������å������Υե����ޥåȤ�
  # *  1byte��          ��"0" or "1" ����¾���㳰�ʥ����Ф�Ȥ�Ƥ��ޤ��Τ�ɤ����Ȥ����Ȥ�������ɡ�
  # *  2byte�ܡ�22byte�ܡ����饤����ȤΥ˥å��͡���
  # * 23byte�ܡ�27byte�ܡ�Listener���Ԥ�����Port�ֹ�
  # ���饤����Ȥ�status="0"�ξ����ֵѤ����å������Υե����ޥåȤ�
  # * "IP���ɥ쥹:::���ơ�����:::�˥å��͡���"�η����֤�
  def run
    @logger.info {"SameRimeServer::StatusManager running..."}
    @logger.info {"SameRimeServer::StatusManager waits on #{@server.addr}"}
    begin
    while reporter=@server.accept
      report=SameRime::Report.new(reporter.gets)
      @logger.debug {"SameRimeServer::StatusManager received : #{report}"}
      status=report.status.strip
      name  =report.name.strip
      port  =report.port.strip
      @status[report.ipaddress.strip]=[status,name,port]
      @logger.debug {"SameRimeServer::StatusManager current status is  #{@status}."}
      if status=="0"
        # ���饤����Ȥ�����ʾ��֤ξ��ˤϡ���³���Ƥ������饤����Ȥ��Ф���¾�Υ桼���ξ�����֤���
        @status.each{|key,val|
          user_info=SameRime::Report.new
          user_info.ipaddress=key
          user_info.status=val[0]
          user_info.name=val[1]
          user_info.port=val[2]
          reporter.puts user_info.to_s
        }
        reporter.close
      elsif status=="1"
        # ���饤����Ȥ���λ���֤ξ��ˤϡ����⤷�ʤ��ǽ�λ��
      else
        # ���ΤȤ���ǧ��Ƥ��ʤ���
        @logger.error {"SameRimeServer::StatusManager#run raises Invalid Protocol::Reporter sent me #{status}"}
        raise "Invalid Protocol::Reporter sent me #{status}"
      end
    end
    rescue Exception=>e
      @logger.fatal {"SameRimeServer::StatusManager#run raises #{e.class}."}
      @logger.fatal {e.backtrace}
    end
  end

  def forwardable?(ipstr)
    begin
    @logger.debug {"SameRimeServer::StatusManager#forwardable? called with #{ipstr}"}
    return false unless @status[ipstr][0]=="0"
    @status[ipstr][2]
    rescue Exception=>e
      @logger.fatal {"SameRimeServer::StatusManager#forwardable? raises #{e.class}."}
      @logger.fatal {e.backtrace}
    end
  end
  
  # ���饤�����IP���ɥ쥹��@status�������ä��롣
  def remove_client(client_ip)
    begin
    @logger.debug {"SameRimeServer::StatusManager#remove_client called with #{client_ip}"}
    @status.delete(client_ip.strip)
    rescue Exception=>e
      @logger.fatal {"SameRimeServer::StatusManager#remove_client raises #{e.class}."}
      @logger.fatal {e.backtrace}
    end
  end

  # ���ơ�������"0"�ʳ��ˤʤäƤ��륯�饤����ȥ���ȥ�����
  def clean_up
    begin
    @status.reject!{|client_ip,value| value[0]!="0"}
    @logger.debug {"SameRimeServer::StatusManager#clean_up results #{@status}"}
    rescue Exception=>e
      @logger.fatal {"SameRimeServer::StatusManager#clean_up raises #{e.class}."}
      @logger.fatal {e.backtrace}
    end
  end

end

end
end

