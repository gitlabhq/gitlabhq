# frozen_string_literal: true

# With the usage of `describe '...', query_analyzers: false`
# can be disabled selectively

RSpec.configure do |config|
  config.around do |example|
    if example.metadata.fetch(:query_analyzers, true)
      ::Gitlab::Database::QueryAnalyzer.instance.within { example.run }
    else
      example.run
    end
  end
end
