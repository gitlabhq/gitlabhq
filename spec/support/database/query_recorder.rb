# frozen_string_literal: true

RSpec.configure do |config|
  # Truncate the query_recorder log file before starting the suite
  config.before(:suite) do
    log_file = Rails.root.join(Gitlab::Database::QueryAnalyzers::QueryRecorder.log_file)
    File.write(log_file, '') if File.exist?(log_file)
    File.delete("#{log_file}.gz") if File.exist?("#{log_file}.gz")
  end

  config.after(:suite) do
    if ENV['CI']
      log_file = Rails.root.join(Gitlab::Database::QueryAnalyzers::QueryRecorder.log_file)
      system("gzip #{log_file}") if File.exist?(log_file)
    end
  end
end
