#!ruby -Ks
require "singleton"

module SameRime
module SameRimeClient

# 
class Sessions
  include Singleton
  def initialize
    @@sessions={}
  end
  
  # IP�A�h���X�iSession�̑��������������j����A��ʂ̃I�u�W�F�N�gID���擾����B
  # �����AIP�A�h���X�Ɋ֌W�t����ꂽ��ʂ����݂��Ȃ��ꍇ�ɂ́Anil��Ԃ��̂ŐV����
  # ��ʃI�u�W�F�N�g�𐶐�����K�v������B
  def find(ipaddress)
    @@sessions[ipaddress]
  end
  
  # �����IP�A�h���X������Ɖ�ʃI�u�W�F�N�g��ID���֌W�t����B
  def add(ipaddress,ui_id)
    @@sessions[ipaddress]=ui_id
  end

  # �����IP�A�h���X������Ɖ�ʃI�u�W�F�N�g��ID�̊֌W�t�����폜����B
  def remove_session(arg)
    @@sessions.delete_if{|ip,ui_id| arg==ip or arg==ui_id }
  end
end

end
end

