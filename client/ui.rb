#!ruby -Ks


module SameRime
module SameRimeClient

class UI
  def initialize(controller)
    @main_form=VRLocalScreen.newform(nil,nil,MainForm)
    @main_form.controller=controller
  end
  
  def run
    @main_form.create.show
    VRLocalScreen.messageloop
  end
  
  def stop
  end
  
  def update_gui(list)
    @main_form.update_gui(list)
  end
  
  # Controller��胁�b�Z�[�W������AGUI�֓]������B
  def message_received(msg)
    @main_form.message_received(msg)
  end
  
  # �A���[�g��������
  def raise_alert(e)
    @main_form.raise_alert(e)
  end
end

end
end
