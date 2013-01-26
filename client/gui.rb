#!ruby -Ks

require "vr/vruby.rb"
require "vr/vrcontrol.rb"
require "vr/vrcomctl.rb"
require "vr/vrrichedit.rb"
require "vr/vrhandler.rb"

# vruby.rb����VRScreen#messageloop���A����Thread������CPU���g���؂��Ă��܂����
# �ւ̎b��p�b�`
# vruby.rb �� nyasu�T����
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

# SameRime�̃��C�����
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

  # talk to�{�^�����������Ƃ��̓���B
  # (1) ���X�g����ʐM�����IP�A�h���X�𓾂�
  # (2) controller��IP�A�h���X�ɍ��v����Form�����݂��邩�ۂ���₢���킹��B
  # (3) ��������΁AIP�A�h���X�Ɗ֌W�t����ꂽ�q��ʂ��őO�ʂɕ\������B
  # (4) �������Ȃ���΁ASessionForm�i�q��ʁj���쐬����B
  # (5)   �쐬�����q��ʂ�ID���擾����B
  # (6)   controller�Ɏq��ʂ�ID��IP�A�h���X��ʒm����B
  def talkPB_clicked
    target_address=@usersLV.getItemTextOf(@usersLV.focusedItem,2)
    target_name=@usersLV.getItemTextOf(@usersLV.focusedItem,0)
    if form_id=@controller.find_form(target_address)
      begin
        session_form=ObjectSpace._id2ref(form_id)
        session_form.top(true)  # �őO�ʂɕ\��
      rescue RangeError
        # GC����Ă�����ASessions����q��ʂ�ID���폜����
        # �V����SessionForm���쐬����B
        @controller.remove_session(form_id)
        create_child(target_name,target_address)
      end
    else
      create_child(target_name,target_address)
    end
  end
  
  # SessionForm�̑S��ʂ���AController#stop���ĂсA����̉�ʂ����B
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

  # reporter����M�����T�[�o��̃��[�U��������A
  # MainForm��ʂ��X�V����B
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
  
  # Listener����M�������b�Z�[�W������A�K�؂Ȏq��ʂɓn���B
  def message_received(msg)
    if form_id=@controller.find_form(msg.sender)
      begin
        session_form=ObjectSpace._id2ref(form_id)
        session_form.top(true)  # �őO�ʂɕ\��
      rescue RangeError
        # GC����Ă�����ASessions����q��ʂ�ID���폜����
        # �V����SessionForm���쐬����B
        @controller.remove_session(form_id)
        session_form=create_child(msg.sender_name,msg.sender)
      end
    else
      session_form=create_child(msg.sender_name,msg.sender)
    end
    session_form.add_message(msg)
  end

  # SessionForm�I�u�W�F�N�g��V���ɐ�������B
  def create_child(target_name,target_address)
    child=VRLocalScreen.newform(nil,nil,SessionForm)
    child.caption="#{target_name}����Ƃ̃Z�b�V����"
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

  # window�́~�{�^���ŕ����Ƃ��B
  def self_close;exitPB_clicked;end
  
  def remove_child(child)
    @children.delete(child)
  end
end 


# �e���胆�[�U�Ƃ�Session��\��������
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
    @messageTXT.setFont(factory.newfont('�l�r ����',11))
    self.sizebox=false
    self.maximizebox=false
  end

  # ���b�Z�[�W���͗��ɓ��͂����邩�ۂ����`�F�b�N���A
  # ���݂���ꍇ�ɂ�@controller�ɑ΂���Message�𑗂�B
  def sendPB_clicked
    if @messageTXT.text==""
      messageBox("���b�Z�[�W�����͂���Ă܂���B")
    else
      msg=SameRime::Message.new()
      msg.receiver=@target_addr
      msg.message=@messageTXT.text.gsub(/\n/," ")
      if @controller.messaging(msg)
        # ���b�Z�[�W���M����I��
        attr = @historyRE.selformat
        attr.color=0    # ���������������b�Z�[�W�͍�
        attr.fontface="�l�r ����"
        attr.height=160
        attr.pitch_family=11
        addtextwithattr("#{@controller.config[:MyName]}:#{@messageTXT.text}\n",attr)
        @messageTXT.text=""
      else
        # ���b�Z�[�W���M�ُ�I��
        messageBox("���炩�̗��R�Ń��b�Z�[�W���M�Ɏ��s���܂����B")
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
    attr.fontface="�l�r ����"
    attr.height=160
    attr.pitch_family=11
    addtextwithattr("#{msg.sender_name}:#{msg.message}\n",attr)
    loop do
      break if @historyRE.scrolldownPage==65536
    end
  end
  
  # window�́~�{�^���ŕ����Ƃ��B
  def self_close;closePB_clicked;end

  # �ȉ��Anyasu����̃T���v�����q�؁B

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
