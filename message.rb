#!ruby -Ks

module SameRime

# SameRimeClient::Reporter����SameRimeServer::StatusManager�֑��M���郌�|�[�g�t�H�[�}�b�g���K�肷��B
# *  1byte��          �F�X�e�[�^�X(ACTIVE=="0",STOPPED=="1")
# *  2byte�ځ`16byte�ځF�N���C�A���gIP�A�h���X
# * 17byte�ځ`36byte�ځF�N���C�A���g�̖��O(20byte)
# * 37byte�ځ`41byte�ځF�N���C�A���g��Listener�҂�����Port�ԍ�
class Report
  attr_accessor :status,:ipaddress,:name,:port
  def initialize(str=nil)
    @status   = str[ 0, 1].strip if str
    @ipaddress= str[ 1,15].strip if str
    @name     = str[16,20].strip if str
    @port     = str[36, 5].strip if str
    if str
      raise "Invalid message string.#{str}" unless check
    end
  end

  def to_s
    if check
      @status   =@status[0,1]
      @ipaddress=@ipaddress[0,15]
      @name     =@name[0,20]
      @port     =@port[0,5]
      sprintf("%1s%15s%20s%5s",@status,@ipaddress,@name,@port)
    else
      nil
    end
  end

  def check
    return false unless (@status=="0" or @status=="1") 
    ipstr=@ipaddress.strip
    ipstr.split(".").each{|cls| return false unless cls=~/\d{1,3}/ }
    ipstr.split(".").each{|cls| return false if (cls.to_i<0 or cls.to_i >255) }
    return false if (@port.to_i<0 or @port.to_i>65535)
    return true
  end
  private :check
end

# SameRimeClient::Messenger��SameRimeServer::Forwarder��SameRimeClient::Listener
# �Ɨ���郁�b�Z�[�W�̃t�H�[�}�b�g���K�肷��B
# *   1byte�`15byte�F���b�Z�[�W���M���N���C�A���gIP�A�h���X
# *  16byte�`30byte�F���b�Z�[�W���M��N���C�A���gIP�A�h���X
# *  31byte�`50byte�F���b�Z�[�W���M���̖��O
# *  51byte�`      �F���b�Z�[�W������B
class Message
  attr_accessor :sender,:receiver,:message,:sender_name
  def initialize(str=nil)
    @sender     = str[ 0,15].strip if str
    @receiver   = str[15,15].strip if str
    @sender_name= str[30,20].strip if str
    @message    = str[50..-1].strip if str
    if str
      raise "Invalid message string.#{str}" unless check
    end
  end

  def to_s
    if check
      @sender   =@sender[0,14]
      @receiver =@receiver[0,14]
      sprintf("%15s%15s%20s%s",@sender,@receiver,@sender_name,@message)
    else
      nil
    end
  end

  def check
    [@sender,@receiver].each{|addr|
      laddr=addr.strip
      laddr.split(".").each{|cls| return false unless cls=~/\d{1,3}/ }
      laddr.split(".").each{|cls| return false if (cls.to_i<0 or cls.to_i >255) }
    }
    return true
  end
  private :check
end

end

