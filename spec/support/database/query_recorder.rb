# frozen_string_literal: true

RSpec.configure do |config|
  # Truncate the query_recorder log file before starting the suite
  config.before(:suite) do
    log_file = Rails.root.join(Gitlab::Database::QueryAnalyzers::QueryRecorder.log_file)
    File.write(log_file, '') if File.exist?(log_file)
  end
end
