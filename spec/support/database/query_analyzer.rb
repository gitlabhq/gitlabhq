# frozen_string_literal: true

# With the usage of `describe '...', query_analyzers: false`
# can be disabled selectively

RSpec.configure do |config|
  config.before do |example|
    if example.metadata.fetch(:query_analyzers, true)
      ::Gitlab::Database::QueryAnalyzer.instance.begin!(
        ::Gitlab::Database::QueryAnalyzer.instance.all_analyzers
      )
    end
  end

  config.after do |example|
    if example.metadata.fetch(:query_analyzers, true)
      ::Gitlab::Database::QueryAnalyzer.instance.end!(
        ::Gitlab::Database::QueryAnalyzer.instance.all_analyzers
      )
    end
  end
end
