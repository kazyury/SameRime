#!ruby -Ks

module SameRime

# SameRimeClient::ReporterからSameRimeServer::StatusManagerへ送信するレポートフォーマットを規定する。
# *  1byte目          ：ステータス(ACTIVE=="0",STOPPED=="1")
# *  2byte目～16byte目：クライアントIPアドレス
# * 17byte目～36byte目：クライアントの名前(20byte)
# * 37byte目～41byte目：クライアントのListener待ちうけPort番号
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

# SameRimeClient::Messenger→SameRimeServer::Forwarder→SameRimeClient::Listener
# と流れるメッセージのフォーマットを規定する。
# *   1byte～15byte：メッセージ送信元クライアントIPアドレス
# *  16byte～30byte：メッセージ送信先クライアントIPアドレス
# *  31byte～50byte：メッセージ送信元の名前
# *  51byte～      ：メッセージ文字列。
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

