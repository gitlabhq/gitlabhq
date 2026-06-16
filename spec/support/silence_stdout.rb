# frozen_string_literal: true

RSpec.configure do |config|
  # Allows stdout to be redirected to reduce noise
  config.around(:each, :silence_stdout) do |example|
    next example.run if ENV['SKIP_SILENCE_STDOUT'].present?

    original_stdout = $stdout
    $stdout = StringIO.new
    example.run
  ensure
    $stdout = original_stdout
  end

  # Allows both stdout and stderr to be redirected to reduce noise
  config.around(:each, :silence_output) do |example|
    next example.run if ENV['SKIP_SILENCE_OUTPUT'].present?

    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    example.run
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end
end
