# frozen_string_literal: true

RSpec.configure do |config|
  # Allows stdout to be redirected to reduce noise
  config.before(:each, :silence_stdout) do
    next if ENV['SKIP_SILENCE_STDOUT'].present?

    $stdout = StringIO.new
  end

  config.after(:each, :silence_stdout) do
    $stdout = STDOUT
  end
end
