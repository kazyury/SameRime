#!ruby -Ks

require "vr/vruby.rb"
require "vr/vrcontrol.rb"
require "vr/vrcomctl.rb"
require "vr/vrrichedit.rb"
require "vr/vrhandler.rb"

# vruby.rb内のVRScreen#messageloopが、複数Thread環境下でCPUを使い切ってしまう問題
# への暫定パッチ
# vruby.rb は nyasuサン作
class VRScreen
  def messageloop(waitflag=false)
    @idleprocs=[] unless defined?(@idleprocs)
    threadlist = Thread.respond_to?(:list)   # when does this method appears?

    @application.messageloop do
      n=@idleprocs.shift
      if n then
        Thread.new do
          n.call
        end
      else
        if waitflag then
          @application.waitmessage
        elsif threadlist and Thread.list.size==1 then
          @application.waitmessage
        else
# patch for CPU-full under multi-thread env.
          sleep 0.001
# patch for CPU-full under multi-thread env.
          Thread.pass
        end
      end
    end
  end
end


module SameRime
module SameRimeClient

# SameRimeのメイン画面
class MainForm < VRForm
  include VRClosingSensitive

  def construct
    self.caption = 'SameRime-Client'
    self.move(136,123,266,400)
    self.sizebox=false
    self.maximizebox=false
    addControl(VRButton   ,'talkPB' ,'talk to'  , 80,336, 80, 25,1342177280)
    addControl(VRButton   ,'exitPB' ,'exit'     ,168,336, 80, 25,1342177280)
    addControl(VRListview ,'usersLV','listView1',  8,  8,240,320,1342177281)
    @usersLV.addColumn("Name",180)
    @usersLV.addColumn("Status",70)
    @usersLV.addColumn("IP",5)
    @usersLV.addColumn("Port",5)
    @children=[]
    update_gui(@list) if @list
  end
  attr_accessor :controller

  # talk toボタンを押したときの動作。
  # (1) リストから通信相手のIPアドレスを得る
  # (2) controllerにIPアドレスに合致するFormが存在するか否かを問い合わせる。
  # (3) もしいれば、IPアドレスと関係付けられた子画面を最前面に表示する。
  # (4) もしいなければ、SessionForm（子画面）を作成する。
  # (5)   作成した子画面のIDを取得する。
  # (6)   controllerに子画面のIDとIPアドレスを通知する。
  def talkPB_clicked
    target_address=@usersLV.getItemTextOf(@usersLV.focusedItem,2)
    target_name=@usersLV.getItemTextOf(@usersLV.focusedItem,0)
    if form_id=@controller.find_form(target_address)
      begin
        session_form=ObjectSpace._id2ref(form_id)
        session_form.top(true)  # 最前面に表示
      rescue RangeError
        # GCされていたら、Sessionsから子画面のIDを削除して
        # 新たなSessionFormを作成する。
        @controller.remove_session(form_id)
        create_child(target_name,target_address)
      end
    else
      create_child(target_name,target_address)
    end
  end
  
  # SessionFormの全画面を閉じ、Controller#stopを呼び、自らの画面を閉じる。
  def exitPB_clicked
    ObjectSpace.each_object(SameRime::SameRimeClient::SessionForm){|obj|
      begin
       obj.close
      rescue SWin::WindowNotExistError
        next
      end
    }
    @controller.stop
    self.close
  end

  # reporterが受信したサーバ上のユーザ情報を受取り、
  # MainForm画面を更新する。
  def update_gui(list)
    @list=list
    @usersLV.clearItems
    list.each{|user_info|
      data=SameRime::Report.new(user_info)
      case data.status
        when "0" ; status="ACTIVE"
        when "1" ; status="STOPPED"
        else     ; status="UNKNOWN"
      end
      @usersLV.addItem([data.name,status,data.ipaddress,data.port])
    }
  end
  
  # Listenerが受信したメッセージを受取り、適切な子画面に渡す。
  def message_received(msg)
    if form_id=@controller.find_form(msg.sender)
      begin
        session_form=ObjectSpace._id2ref(form_id)
        session_form.top(true)  # 最前面に表示
      rescue RangeError
        # GCされていたら、Sessionsから子画面のIDを削除して
        # 新たなSessionFormを作成する。
        @controller.remove_session(form_id)
        session_form=create_child(msg.sender_name,msg.sender)
      end
    else
      session_form=create_child(msg.sender_name,msg.sender)
    end
    session_form.add_message(msg)
  end

  # SessionFormオブジェクトを新たに生成する。
  def create_child(target_name,target_address)
    child=VRLocalScreen.newform(nil,nil,SessionForm)
    child.caption="#{target_name}さんとのセッション"
    child.controller=@controller
    child.parent_form=self
    child.target_addr=target_address
    @controller.add_session(target_address,child.id)
    child.create.show
    @children.push child
    return child
  end

  #
  def raise_alert(e)
    messageBox(e)
  end

  # windowの×ボタンで閉じたとき。
  def self_close;exitPB_clicked;end
  
  def remove_child(child)
    @children.delete(child)
  end
end 


# 各相手ユーザとのSessionを表現する画面
class SessionForm < VRForm
  include VRClosingSensitive

  attr_writer :controller,:parent_form,:target_addr
  def construct
    self.move(503,120,255,326)
    addControl(VRRichedit,'historyRE','',8,8,224,176,1342177284)
    addControl(VRText,'messageTXT','',8,192,224,64,1342177348)
    addControl(VRButton,'sendPB','send',64,264,80,25,1342177280)
    addControl(VRButton,'closePB','close',152,264,80,25,1342177280)
    @historyRE.readonly=true
    factory=SWin::LWFactory.new(SWin::Application.hInstance)
    @messageTXT.setFont(factory.newfont('ＭＳ 明朝',11))
    self.sizebox=false
    self.maximizebox=false
  end

  # メッセージ入力欄に入力があるか否かをチェックし、
  # 存在する場合には@controllerに対してMessageを送る。
  def sendPB_clicked
    if @messageTXT.text==""
      messageBox("メッセージが入力されてません。")
    else
      msg=SameRime::Message.new()
      msg.receiver=@target_addr
      msg.message=@messageTXT.text.gsub(/\n/," ")
      if @controller.messaging(msg)
        # メッセージ送信正常終了
        attr = @historyRE.selformat
        attr.color=0    # 自分が送ったメッセージは黒
        attr.fontface="ＭＳ 明朝"
        attr.height=160
        attr.pitch_family=11
        addtextwithattr("#{@controller.config[:MyName]}:#{@messageTXT.text}\n",attr)
        @messageTXT.text=""
      else
        # メッセージ送信異常終了
        messageBox("何らかの理由でメッセージ送信に失敗しました。")
      end
    end
  end
  
  def closePB_clicked
    @parent_form.remove_child(self)
    @controller.remove_session(self.id)
    self.close
  end
  
  def add_message(msg)
    attr = @historyRE.selformat
    attr.color=0xff
    attr.fontface="ＭＳ 明朝"
    attr.height=160
    attr.pitch_family=11
    addtextwithattr("#{msg.sender_name}:#{msg.message}\n",attr)
    loop do
      break if @historyRE.scrolldownPage==65536
    end
  end
  
  # windowの×ボタンで閉じたとき。
  def self_close;closePB_clicked;end

  # 以下、nyasuさんのサンプルより拝借。

  private
  def jlengthOf(text)
    text.gsub(/[^\Wa-zA-Z_\d]/, ' ').length  # from jcode.rb
  end

  def realizecol
    @attrs.each do |attr|
      @historyRE.setSel *attr[0]
      @historyRE.selformat = attr[1]
    end
  end

  def addtextwithattr(txt,attr)
    @attrs = [] unless @attrs
    st = jlengthOf(@historyRE.text)
    len= jlengthOf(txt)
    @historyRE.text += txt
    @attrs.push [ [st,st+len],attr.dup ]
    realizecol
  end

end

end
end
