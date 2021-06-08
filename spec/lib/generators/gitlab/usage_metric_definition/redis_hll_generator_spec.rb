# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageMetricDefinition::RedisHllGenerator, :silence_stdout do
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
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  it 'creates metric definition files' do
    described_class.new(args).invoke_all

    weekly_metric_definition_path = Dir.glob(File.join(temp_dir, 'metrics/counts_7d/*i_test_event_weekly.yml')).first
    monthly_metric_definition_path = Dir.glob(File.join(temp_dir, 'metrics/counts_28d/*i_test_event_monthly.yml')).first

    expect(YAML.safe_load(File.read(weekly_metric_definition_path))).to include("key_path" => "redis_hll_counters.test_category.i_test_event_weekly")
    expect(YAML.safe_load(File.read(monthly_metric_definition_path))).to include("key_path" => "redis_hll_counters.test_category.i_test_event_monthly")
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
      described_class.new(args, { 'ee': true }).invoke_all

      expect(weekly_metric_definition).to include("key_path" => "redis_hll_counters.test_category.i_test_event_weekly")
      expect(weekly_metric_definition["distribution"]).to include('ee')

      expect(monthly_metric_definition).to include("key_path" => "redis_hll_counters.test_category.i_test_event_monthly")
      expect(monthly_metric_definition["distribution"]).to include('ee')
    end
  end
end
