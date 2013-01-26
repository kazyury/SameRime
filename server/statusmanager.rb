#!/usr/local/bin/ruby -Ke


module SameRime
module SameRimeServer

# SameRimeClient::Reporterより各端末のステータスを受け取り、サーバサイドで管理する。
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

  # クライアント（Reporter）からの接続を待ち受け、
  # クライアントよりステータスを受け取り、@statusに保管する。
  #
  # 受信するメッセージのフォーマットは
  # *  1byte目          ："0" or "1" その他は例外（サーバをとめてしまうのもどうかというところだけど）
  # *  2byte目〜22byte目：クライアントのニックネーム
  # * 23byte目〜27byte目：Listenerの待ちうけPort番号
  # クライアントのstatus="0"の場合に返却するメッセージのフォーマットは
  # * "IPアドレス:::ステータス:::ニックネーム"の繰り返し
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
        # クライアントが正常な状態の場合には、接続してきたクライアントに対して他のユーザの情報を返す。
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
        # クライアントが終了状態の場合には。何もしないで終了。
      else
        # 今のところ認めていない。
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
  
  # クライアントIPアドレスを@statusから抹消する。
  def remove_client(client_ip)
    begin
    @logger.debug {"SameRimeServer::StatusManager#remove_client called with #{client_ip}"}
    @status.delete(client_ip.strip)
    rescue Exception=>e
      @logger.fatal {"SameRimeServer::StatusManager#remove_client raises #{e.class}."}
      @logger.fatal {e.backtrace}
    end
  end

  # ステータスが"0"以外になっているクライアントエントリを除去
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

