# frozen_string_literal: true

# This context replaces the logger and exposes the `log_data` variable for
# inspection
RSpec.shared_context 'parsed logs' do
  let(:logger) do
    Logger.new(log_output).tap { |logger| logger.formatter = ->(_, _, _, msg) { msg } }
  end

  let(:log_output) { StringIO.new }
  let(:log_data) { Gitlab::Json.parse(log_output.string) }

  around do |example|
    initial_logger = Lograge.logger
    Lograge.logger = logger

    example.run

    Lograge.logger = initial_logger
  end
end
