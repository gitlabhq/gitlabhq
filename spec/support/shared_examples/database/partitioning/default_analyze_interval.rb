# frozen_string_literal: true

# Requires `model`, `partitioning_key` and `strategy_args` (the strategy's other required arguments)
RSpec.shared_examples 'a partitioning strategy with a default analyze_interval' do
  it 'falls back to DEFAULT_ANALYZE_INTERVAL when no analyze_interval is given', :aggregate_failures do
    strategy = described_class.new(model, partitioning_key, **strategy_args)

    expect(strategy.analyze_interval).to eq(Gitlab::Database::Partitioning::BaseStrategy::DEFAULT_ANALYZE_INTERVAL)
    expect(strategy).to be_default_analyze_interval
  end

  it 'prefers an explicit analyze_interval over the default', :aggregate_failures do
    strategy = described_class.new(model, partitioning_key, **strategy_args, analyze_interval: 3.days)

    expect(strategy.analyze_interval).to eq(3.days)
    expect(strategy).not_to be_default_analyze_interval
  end
end
