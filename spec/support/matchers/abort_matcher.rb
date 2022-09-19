# frozen_string_literal: true

RSpec::Matchers.define :abort_execution do
  match do |code_block|
    @captured_stderr = StringIO.new
    original_stderr = $stderr
    $stderr = @captured_stderr

    code_block.call

    false
  rescue SystemExit => e
    captured = @captured_stderr.string.chomp
    @actual_exit_code = e.status
    break false unless e.status == 1
    break true unless @message

    case @message
    when String
      @message == captured
    when Regexp
      @message.match?(captured)
    else
      raise ArgumentError, 'with_message must be either a String or a Regular Expression'
    end
  ensure
    $stderr = original_stderr
  end

  chain :with_message do |message|
    @message = message
  end

  failure_message do |block|
    unless @actual_exit_code
      break "expected #{block} to abort with '#{@message}' but didnt call abort."
    end

    if @actual_exit_code != 1
      break "expected #{block} to abort with: '#{@message}' but exited with success instead."
    end

    "expected #{block} to abort with: '#{@message}' \n but received: '#{@captured_stderr.string.chomp}' instead."
  end

  supports_block_expectations
end
