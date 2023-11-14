# frozen_string_literal: true

RSpec.configure do |config|
  config.around(:each, :suppress_partitioning_routing_analyzer) do |example|
    Gitlab::Database::QueryAnalyzers::Ci::PartitioningRoutingAnalyzer.with_suppressed(&example)
  end
end
