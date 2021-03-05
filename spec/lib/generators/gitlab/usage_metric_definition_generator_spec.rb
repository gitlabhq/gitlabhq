# frozen_string_literal: true

require 'spec_helper'
require 'rails/generators/testing/behaviour'

RSpec.describe Gitlab::UsageMetricDefinitionGenerator do
  let(:temp_dir) { Dir.mktmpdir }

  before do
    stub_const("#{described_class}::TOP_LEVEL_DIR", temp_dir)
  end

  context 'with product_intelligence_metrics_names_suggestions feature ON' do
    it 'adds name key to metric definition' do
      stub_feature_flags(product_intelligence_metrics_names_suggestions: true)

      expect(::Gitlab::Usage::Metrics::NamesSuggestions::Generator).to receive(:generate).and_return('some name')
      described_class.new(['counts_weekly.test_metric'], { 'dir' => '7d' }).invoke_all
      metric_definition_path = Dir.glob(File.join(temp_dir, 'metrics/counts_7d/*_test_metric.yml')).first

      expect(YAML.safe_load(File.read(metric_definition_path))).to include("name" => "some name")
    end
  end

  context 'with product_intelligence_metrics_names_suggestions feature OFF' do
    it 'adds name key to metric definition' do
      stub_feature_flags(product_intelligence_metrics_names_suggestions: false)

      expect(::Gitlab::Usage::Metrics::NamesSuggestions::Generator).not_to receive(:generate)
      described_class.new(['counts_weekly.test_metric'], { 'dir' => '7d' }).invoke_all
      metric_definition_path = Dir.glob(File.join(temp_dir, 'metrics/counts_7d/*_test_metric.yml')).first

      expect(YAML.safe_load(File.read(metric_definition_path)).keys).not_to include(:name)
    end
  end
end
