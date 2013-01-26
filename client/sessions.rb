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
  
  # IPアドレス（Sessionの相手を示す文字列）から、画面のオブジェクトIDを取得する。
  # もし、IPアドレスに関係付けられた画面が存在しない場合には、nilを返すので新しい
  # 画面オブジェクトを生成する必要がある。
  def find(ipaddress)
    @@sessions[ipaddress]
  end
  
  # 相手のIPアドレス文字列と画面オブジェクトのIDを関係付ける。
  def add(ipaddress,ui_id)
    @@sessions[ipaddress]=ui_id
  end

  # 相手のIPアドレス文字列と画面オブジェクトのIDの関係付けを削除する。
  def remove_session(arg)
    @@sessions.delete_if{|ip,ui_id| arg==ip or arg==ui_id }
  end
end

end
end

