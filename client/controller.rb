#!ruby -Ks

module SameRime
module SameRimeClient
  ACTIVE =true  # 各Threadの終了処理用
  STOPPED=false # 

class Controller
  # 定義情報の読み込みと、実行する各機能の初期化、及び各機能Threadのコンテナを設定。
  # 各機能はControllerを介して相互のやり取りを行うため、各機能のコンストラクタにselfを渡す。
  def initialize
    @config=configure # 各種定義情報の読み取り
    @runnable =[]
    @runnable << @reporter=SameRime::SameRimeClient::Reporter.new(self)
    @runnable << @listener=SameRime::SameRimeClient::Listener.new(self)
    @runnable << @ui      =SameRime::SameRimeClient::UI.new(self)
    @threads=[]       # 各Agentを動かすスレッドのコンテナ
    @sessions=Sessions.instance
  end
  attr_reader :config
  
  # 各機能を動かす。
  # Reporter,ListenerはThreadとして実行し、UIはmessageloopに入る。
  def run
    @threads << Thread.new(){@reporter.run}
    @threads << Thread.new(){@listener.run}
    @ui.run
  end

  # 各機能のstopメソッドを呼んだのち、各Threadをkillする。
  def stop
    @runnable.each{|ag| ag.stop }
    @threads.each{|th| th.kill }
  end

  # Reporterからの情報をUIに転送する。
  def update_gui(list)
    @ui.update_gui(list)
  end
  
  # 指定されたIPアドレスに関係付けられた画面が存在する場合にはその画面IDを、
  # 存在しない場合にはnilを返す。
  def find_form(address)
    @sessions.find(address)
  end
  
  def add_session(ipaddress,ui_id)
    @sessions.add(ipaddress,ui_id)
  end
  
  def remove_session(arg)
    @sessions.remove_session(arg)
  end
  
  # Messageオブジェクトを受取り、Messengerに転送する。
  def messaging(msgobj)
    if Messenger.new(self).messaging(msgobj)
      return true
    else
      return false
    end
  end
  
  # Listenerよりメッセージを受取り、UIに渡す。
  def message_received(msg)
    @ui.message_received(msg)
  end
  
  # ポートをオープンできなかった場合のハンドラ
  def error_on_openport(e)
    @ui.raise_alert(e)
  end

  # 構成ファイル（./sr_client.xml）を読み込み、構成情報を返却する。
  def configure
    ret={}
    this_dir=File.dirname(__FILE__)
    root=REXML::Document.new(File.new("#{this_dir}/sr_client.xml")).root # => returns REXML::Element
    root.each_element("/configuration/*"){|config|
      type=config.attributes["type"]
      type ? value=config.text.send("to_"+type) : value=config.text
      ret[config.name.intern]=value
    }
    ret
  end
  private :configure
end

end
end
