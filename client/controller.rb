#!ruby -Ks

module SameRime
module SameRimeClient
  ACTIVE =true  # �eThread�̏I�������p
  STOPPED=false # 

class Controller
  # ��`���̓ǂݍ��݂ƁA���s����e�@�\�̏������A�y�ъe�@�\Thread�̃R���e�i��ݒ�B
  # �e�@�\��Controller����đ��݂̂������s�����߁A�e�@�\�̃R���X�g���N�^��self��n���B
  def initialize
    @config=configure # �e���`���̓ǂݎ��
    @runnable =[]
    @runnable << @reporter=SameRime::SameRimeClient::Reporter.new(self)
    @runnable << @listener=SameRime::SameRimeClient::Listener.new(self)
    @runnable << @ui      =SameRime::SameRimeClient::UI.new(self)
    @threads=[]       # �eAgent�𓮂����X���b�h�̃R���e�i
    @sessions=Sessions.instance
  end
  attr_reader :config
  
  # �e�@�\�𓮂����B
  # Reporter,Listener��Thread�Ƃ��Ď��s���AUI��messageloop�ɓ���B
  def run
    @threads << Thread.new(){@reporter.run}
    @threads << Thread.new(){@listener.run}
    @ui.run
  end

  # �e�@�\��stop���\�b�h���Ă񂾂̂��A�eThread��kill����B
  def stop
    @runnable.each{|ag| ag.stop }
    @threads.each{|th| th.kill }
  end

  # Reporter����̏���UI�ɓ]������B
  def update_gui(list)
    @ui.update_gui(list)
  end
  
  # �w�肳�ꂽIP�A�h���X�Ɋ֌W�t����ꂽ��ʂ����݂���ꍇ�ɂ͂��̉��ID���A
  # ���݂��Ȃ��ꍇ�ɂ�nil��Ԃ��B
  def find_form(address)
    @sessions.find(address)
  end
  
  def add_session(ipaddress,ui_id)
    @sessions.add(ipaddress,ui_id)
  end
  
  def remove_session(arg)
    @sessions.remove_session(arg)
  end
  
  # Message�I�u�W�F�N�g������AMessenger�ɓ]������B
  def messaging(msgobj)
    if Messenger.new(self).messaging(msgobj)
      return true
    else
      return false
    end
  end
  
  # Listener��胁�b�Z�[�W������AUI�ɓn���B
  def message_received(msg)
    @ui.message_received(msg)
  end
  
  # �|�[�g���I�[�v���ł��Ȃ������ꍇ�̃n���h��
  def error_on_openport(e)
    @ui.raise_alert(e)
  end

  # �\���t�@�C���i./sr_client.xml�j��ǂݍ��݁A�\������ԋp����B
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
