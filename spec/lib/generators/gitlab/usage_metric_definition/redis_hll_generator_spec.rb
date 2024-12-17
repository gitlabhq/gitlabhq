# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageMetricDefinition::RedisHllGenerator, :silence_stdout, feature_category: :service_ping do
  include UsageDataHelpers

  let(:category) { 'test_category' }
  let(:event) { 'i_test_event' }
  let(:args) { [category, event] }
  let(:temp_dir) { Dir.mktmpdir }

  # Interpolating to preload the class
  # See https://github.com/rspec/rspec-mocks/issues/1079
  before do
    stub_const("#{Gitlab::UsageMetricDefinitionGenerator}::TOP_LEVEL_DIR", temp_dir)
    # Stub Prometheus requests from Gitlab::Utils::UsageData
    stub_prometheus_queries

    allow_next_instance_of(Gitlab::UsageMetricDefinitionGenerator) do |instance|
      allow(instance).to receive(:ask).and_return('y') # confirm deprecation warning
    end
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  it 'creates metric definition files' do
    described_class.new(args).invoke_all

    weekly_metric_definition_path = Dir.glob(File.join(temp_dir, 'metrics/counts_7d/*i_test_event_weekly.yml')).first
    monthly_metric_definition_path = Dir.glob(File.join(temp_dir, 'metrics/counts_28d/*i_test_event_monthly.yml')).first

    weekly_metric_definition = YAML.safe_load(File.read(weekly_metric_definition_path))
    monthly_metric_definition = YAML.safe_load(File.read(monthly_metric_definition_path))

    expect(weekly_metric_definition).to include("key_path" => "redis_hll_counters.test_category.i_test_event_weekly")
    expect(monthly_metric_definition).to include("key_path" => "redis_hll_counters.test_category.i_test_event_monthly")

    expect(weekly_metric_definition["instrumentation_class"]).to eq('RedisHLLMetric')
    expect(monthly_metric_definition["instrumentation_class"]).to eq('RedisHLLMetric')
  end

  context 'with multiple events', :aggregate_failures do
    let(:event_2) { 'i_test_event_2' }
    let(:args) { [category, event, event_2] }

    it 'creates metric definition files' do
      described_class.new(args).invoke_all

      [event, event_2].each do |event|
        weekly_metric_definition_path = Dir.glob(File.join(temp_dir, "metrics/counts_7d/*#{event}_weekly.yml")).first
        monthly_metric_definition_path = Dir.glob(File.join(temp_dir, "metrics/counts_28d/*#{event}_monthly.yml")).first

        weekly_metric_definition = YAML.safe_load(File.read(weekly_metric_definition_path))
        monthly_metric_definition = YAML.safe_load(File.read(monthly_metric_definition_path))

        expect(weekly_metric_definition).to include("key_path" => "redis_hll_counters.test_category.#{event}_weekly")
        expect(monthly_metric_definition).to include("key_path" => "redis_hll_counters.test_category.#{event}_monthly")

        expect(weekly_metric_definition["instrumentation_class"]).to eq('RedisHLLMetric')
        expect(monthly_metric_definition["instrumentation_class"]).to eq('RedisHLLMetric')
      end
    end
  end

  context 'with ee option' do
    let(:weekly_metric_definition_path) { Dir.glob(File.join(temp_dir, 'ee/config/metrics/counts_7d/*i_test_event_weekly.yml')).first }
    let(:monthly_metric_definition_path) { Dir.glob(File.join(temp_dir, 'ee/config/metrics/counts_28d/*i_test_event_monthly.yml')).first }

    let(:weekly_metric_definition) { YAML.safe_load(File.read(weekly_metric_definition_path)) }
    let(:monthly_metric_definition) { YAML.safe_load(File.read(monthly_metric_definition_path)) }

    before do
      stub_const("#{Gitlab::UsageMetricDefinitionGenerator}::TOP_LEVEL_DIR", 'config')
      stub_const("#{Gitlab::UsageMetricDefinitionGenerator}::TOP_LEVEL_DIR_EE", File.join(temp_dir, 'ee'))
    end

    it 'creates metric definition files' do
      described_class.new(args, { ee: true }).invoke_all

      expect(weekly_metric_definition).to include("key_path" => "redis_hll_counters.test_category.i_test_event_weekly")
      expect(weekly_metric_definition["instrumentation_class"]).to eq('RedisHLLMetric')

      expect(monthly_metric_definition).to include("key_path" => "redis_hll_counters.test_category.i_test_event_monthly")
      expect(monthly_metric_definition["instrumentation_class"]).to eq('RedisHLLMetric')
    end
  end
end
