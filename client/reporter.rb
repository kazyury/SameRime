#!ruby -Ks


module SameRime
module SameRimeClient

# クライアントの状況を定期的にサーバに報告する。
# 報告の際にサーバ側より他のユーザ情報を受取り、その内容をGUIに通知する。
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
class Reporter

  def initialize(controller)
    @controller=controller
    @status=SameRime::SameRimeClient::ACTIVE
    @interval  =@controller.config[:Interval]
    @sr_server =@controller.config[:SameRimeServer]
    @stmgr_port=@controller.config[:StatusManagerPort]
    @report=SameRime::Report.new
    @report.name=@controller.config[:MyName]
    @report.port=@controller.config[:ListeningPort].to_s
    @report.ipaddress=IPSocket.getaddress(Socket.gethostname)
  end

  # 自らの状況がACTIVEの間、Interval間隔でサーバに状況を伝える。
  def run
    report("0")
    while @status==SameRime::SameRimeClient::ACTIVE
      sleep @interval
      report("0") if @status==SameRime::SameRimeClient::ACTIVE
    end
  end

  # STOPした旨をサーバに伝え、self#runのループをストップさせる。
  def stop
    @status=SameRime::SameRimeClient::STOPPED
    report("1")
  end

  # StatusManagerとレポートを送受信する。
  # StatusManagerからレポートを受取った際には、GUIを更新するよう@controller#update_guiを呼ぶ
  def report(status)
    begin
      sock=TCPSocket.open(@sr_server,@stmgr_port)
      @report.status=status
      sock.puts @report.to_s
      if status=="0"
        update_value=[]
        while other=sock.gets
          update_value.push other
        end
        @controller.update_gui(update_value)
      else status=="1"
        sock.flush
      end
      sock.close
    rescue Exception=>e
      msg ="Reporter:サーバポートのオープンに失敗しました。\n"
      msg+="sr_client.xmlファイルの設定及びサーバ側の設定を確認して下さい。\n\n"
      msg+="不明な点はサーバ管理者又はSameRimeの製造元にお尋ねください。"
      @controller.error_on_openport(msg)
    end
  end
  private :report
end


end
end
