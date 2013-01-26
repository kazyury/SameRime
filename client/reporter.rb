#!ruby -Ks


module SameRime
module SameRimeClient

# �N���C�A���g�̏󋵂����I�ɃT�[�o�ɕ񍐂���B
# �񍐂̍ۂɃT�[�o����葼�̃��[�U��������A���̓��e��GUI�ɒʒm����B
#
#                               StatusManager
#    Reporter                   +-----------+
#   +----------+                |           |
#   |          |--------------->|accept     |
#   |          |  rep OK        | check rep |
#   |          |  and status="0"|           |
#   |          |<---------------| close     |
#   |          |                +-----------+
#   +----------+
#
class Reporter

  def initialize(controller)
    @controller=controller
    @status=SameRime::SameRimeClient::ACTIVE
    @interval  =@controller.config[:Interval]
    @sr_server =@controller.config[:SameRimeServer]
    @stmgr_port=@controller.config[:StatusManagerPort]
    @report=SameRime::Report.new
    @report.name=@controller.config[:MyName]
    @report.port=@controller.config[:ListeningPort].to_s
    @report.ipaddress=IPSocket.getaddress(Socket.gethostname)
  end

  # ����̏󋵂�ACTIVE�̊ԁAInterval�Ԋu�ŃT�[�o�ɏ󋵂�`����B
  def run
    report("0")
    while @status==SameRime::SameRimeClient::ACTIVE
      sleep @interval
      report("0") if @status==SameRime::SameRimeClient::ACTIVE
    end
  end

  # STOP�����|���T�[�o�ɓ`���Aself#run�̃��[�v���X�g�b�v������B
  def stop
    @status=SameRime::SameRimeClient::STOPPED
    report("1")
  end

  # StatusManager�ƃ��|�[�g�𑗎�M����B
  # StatusManager���烌�|�[�g���������ۂɂ́AGUI���X�V����悤@controller#update_gui���Ă�
  def report(status)
    begin
      sock=TCPSocket.open(@sr_server,@stmgr_port)
      @report.status=status
      sock.puts @report.to_s
      if status=="0"
        update_value=[]
        while other=sock.gets
          update_value.push other
        end
        @controller.update_gui(update_value)
      else status=="1"
        sock.flush
      end
      sock.close
    rescue Exception=>e
      msg ="Reporter:�T�[�o�|�[�g�̃I�[�v���Ɏ��s���܂����B\n"
      msg+="sr_client.xml�t�@�C���̐ݒ�y�уT�[�o���̐ݒ���m�F���ĉ������B\n\n"
      msg+="�s���ȓ_�̓T�[�o�Ǘ��Җ���SameRime�̐������ɂ��q�˂��������B"
      @controller.error_on_openport(msg)
    end
  end
  private :report
end


end
end
