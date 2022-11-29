# frozen_string_literal: true

RSpec.configure do |config|
  # Truncate the query_recorder log file before starting the suite
  config.before(:suite) do
    log_path = Rails.root.join(Gitlab::Database::QueryAnalyzers::QueryRecorder::LOG_FILE)
    File.write(log_path, '') if File.exist?(log_path)
  end
end
