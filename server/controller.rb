#!/usr/local/bin/ruby -Ke


module SameRime
module SameRimeServer

class Controller
  # ���������ɤ߹��ߤȡ��¹Ԥ���Ƶ�ǽ�ν�������ڤӳƵ�ǽThread�Υ���ƥʤ����ꡣ
  # �Ƶ�ǽ��Controller��𤷤���ߤΤ�����Ԥ����ᡢ�Ƶ�ǽ�Υ��󥹥ȥ饯����self���Ϥ���
  def initialize
    @logger=create_logger
    @config=configure # �Ƽ����������ɤ߼��
    @logger.level=eval("Log4r::"+@config[:LogLevel])
    @runnable =[]
    @runnable << @status_manager=SameRime::SameRimeServer::StatusManager.new(self)
    @runnable << @forwarder     =SameRime::SameRimeServer::Forwarder.new(self)
    @threads=[]       # ��Agent��ư��������åɤΥ���ƥ�
    @logger.info {"SameRimeServer::Controller initialized"}
  end
  attr_reader :config

  def run
    begin
    @logger.info {"SameRimeServer::Controller running..."}
    Thread.new{ @status_manager.run }
    Thread.new{ @forwarder.run }
    loop do
      sleep 0.001
      # do nothing
    end
    rescue Exception=>e
      @logger.fatal {"SameRimeServer::Controller#run raises #{e.class}."}
      @logger.fatal {e.backtrace}
    end
  end

  
  def forwardable?(str)
    begin
    @logger.debug {"SameRimeServer::Controller#forwardable? accepted #{str}"}
    ipstr=str.strip
    ipstr.split(".").each{|cls| return false unless cls=~/\d{1,3}/ }
    ipstr.split(".").each{|cls| return false if (cls.to_i<0 or cls.to_i >255) }
    @status_manager.forwardable?(ipstr)
    rescue Exception=>e
      @logger.fatal {"SameRimeServer::Controller#forwardable? raises #{e.class}."}
      @logger.fatal {e.backtrace}
    end
  end

  def remove_client(client)
    begin
    @logger.debug {"SameRimeServer::Controller#remove_client accepted #{client}"}
    @status_manager.remove_client(client)
    rescue Exception=>e
      @logger.fatal {"SameRimeServer::Controller#remove_client raises #{e.class}."}
      @logger.fatal {e.backtrace}
    end
  end
  
  # SameRimeServer�ǻ��Ѥ��������������롣
  # SameRimeServer�۲��γƥ��饹��logger����Ѥ��������ˤ�Log4r::Logger['default_logger']����Ѥ��ƥ�����������롣
  # default_logger�Υ��������./samerime_srv.log�˻��ꤵ���
  def create_logger
    logger=Log4r::Logger.new("default_logger")
    _outputter=Log4r::FileOutputter.new('default_outputter',{:filename=>"./samerime_srv.log"})
    _formatter=Log4r::PatternFormatter.new({:pattern=>'%d::[%l] %m'})
    _outputter.formatter=_formatter
    logger.outputters=_outputter
    logger
  end

  # �����ե������./sr_server.xml�ˤ��ɤ߹��ߡ�����������ֵѤ��롣
  def configure
    ret={}
    this_dir=File.dirname(__FILE__)
    root=REXML::Document.new(File.new("#{this_dir}/sr_server.xml")).root # => returns REXML::Element
    root.each_element("/configuration/*"){|config|
      type=config.attributes["type"]
      type ? value=config.text.send("to_"+type) : value=config.text
      ret[config.name.intern]=value
    }
    ret
  end
  private :configure,:create_logger
end


end
end
