module TimeoutHelper
  def command_exists?(command)
    _, status = Gitlab::Popen.popen(%W{ #{command} 1 echo })
    status == 0
  rescue Errno::ENOENT
    false
  end

  def timeout_command
    @timeout_command ||=
      if command_exists?('timeout')
        'timeout'
      elsif command_exists?('gtimeout')
        'gtimeout'
      else
        ''
      end
  end
end
