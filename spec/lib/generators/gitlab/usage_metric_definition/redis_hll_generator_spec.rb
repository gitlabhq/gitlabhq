# frozen_string_literal: true

require 'generator_helper'

RSpec.describe Gitlab::UsageMetricDefinition::RedisHllGenerator do
  let(:category) { 'test_category' }
  let(:event) { 'i_test_event' }
  let(:args) { [category, event] }
  let(:temp_dir) { Dir.mktmpdir }

  # Interpolating to preload the class
  # See https://github.com/rspec/rspec-mocks/issues/1079
  before do
    stub_const("#{Gitlab::UsageMetricDefinitionGenerator}::TOP_LEVEL_DIR", temp_dir)
    # Stub Prometheus requests from Gitlab::Utils::UsageData
    stub_request(:get, %r{^https?://::1:9090/-/ready})
      .to_return(
        status: 200,
        body: [{}].to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    stub_request(:get, %r{^https?://::1:9090/api/v1/query\?query=.*})
      .to_return(
        status: 200,
        body: [{}].to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  it 'creates metric definition files' do
    described_class.new(args).invoke_all

    weekly_metric_definition_path = Dir.glob(File.join(temp_dir, 'metrics/counts_7d/*i_test_event_weekly.yml')).first
    monthly_metric_definition_path = Dir.glob(File.join(temp_dir, 'metrics/counts_28d/*i_test_event_monthly.yml')).first

    expect(YAML.safe_load(File.read(weekly_metric_definition_path))).to include("key_path" => "redis_hll_counters.test_category.i_test_event_weekly")
    expect(YAML.safe_load(File.read(monthly_metric_definition_path))).to include("key_path" => "redis_hll_counters.test_category.i_test_event_monthly")
  end
end
