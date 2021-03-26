# frozen_string_literal: true

require 'generator_helper'

RSpec.describe Gitlab::UsageMetricDefinitionGenerator do
  include UsageDataHelpers

  let(:key_path) { 'counts_weekly.test_metric' }
  let(:dir) { '7d' }
  let(:temp_dir) { Dir.mktmpdir }

  before do
    stub_const("#{described_class}::TOP_LEVEL_DIR", temp_dir)
    # Stub Prometheus requests from Gitlab::Utils::UsageData
    stub_request(:get, 'https://::1:9090/-/ready')
      .to_return(
        status: 200,
        body: [{}].to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    stub_request(:get, %r{^https://::1:9090/api/v1/query\?query=.*})
      .to_return(
        status: 200,
        body: [{}].to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe 'Creating metric definition file' do
    let(:sample_metric) { load_sample_metric_definition }

    # Stub version so that `milestone` key remains constant between releases to prevent flakiness.
    before do
      stub_const('Gitlab::VERSION', '13.9.0')
      allow(::Gitlab::Usage::Metrics::NamesSuggestions::Generator).to receive(:generate).and_return('test metric name')
    end

    context 'with product_intelligence_metrics_names_suggestions feature ON' do
      let(:sample_metric) { load_sample_metric_definition(filename: 'sample_metric_with_name_suggestions.yml') }

      it 'creates a metric definition file using the template' do
        stub_feature_flags(product_intelligence_metrics_names_suggestions: true)

        described_class.new([key_path], { 'dir' => dir }).invoke_all

        metric_definition_path = Dir.glob(File.join(temp_dir, 'metrics/counts_7d/*_test_metric.yml')).first

        expect(YAML.safe_load(File.read(metric_definition_path))).to eq(sample_metric)
      end
    end

    context 'with product_intelligence_metrics_names_suggestions feature OFF' do
      it 'creates a metric definition file using the template' do
        stub_feature_flags(product_intelligence_metrics_names_suggestions: false)

        described_class.new([key_path], { 'dir' => dir }).invoke_all

        metric_definition_path = Dir.glob(File.join(temp_dir, 'metrics/counts_7d/*_test_metric.yml')).first

        expect(YAML.safe_load(File.read(metric_definition_path))).to eq(sample_metric)
      end
    end
  end

  describe 'Validation' do
    let(:options) { [key_path, '--dir', dir] }

    subject { described_class.start(options) }

    it 'does not raise an error' do
      expect { subject }.not_to raise_error
    end

    context 'with a missing directory' do
      let(:options) { [key_path, '--pretend'] }

      it 'raises an error' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end

    context 'with an invalid directory' do
      let(:dir) { '8d' }

      it 'raises an error' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end

    context 'with an already existing metric with the same key_path' do
      before do
        allow(Gitlab::Usage::MetricDefinition).to receive(:definitions).and_return(Hash[key_path, 'definition'])
      end

      it 'raises an error' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end
  end

  describe 'Name suggestions' do
    context 'with product_intelligence_metrics_names_suggestions feature ON' do
      it 'adds name key to metric definition' do
        stub_feature_flags(product_intelligence_metrics_names_suggestions: true)

        expect(::Gitlab::Usage::Metrics::NamesSuggestions::Generator).to receive(:generate).and_return('some name')
        described_class.new([key_path], { 'dir' => dir }).invoke_all
        metric_definition_path = Dir.glob(File.join(temp_dir, 'metrics/counts_7d/*_test_metric.yml')).first

        expect(YAML.safe_load(File.read(metric_definition_path))).to include("name" => "some name")
      end
    end

    context 'with product_intelligence_metrics_names_suggestions feature OFF' do
      it 'adds name key to metric definition' do
        stub_feature_flags(product_intelligence_metrics_names_suggestions: false)

        expect(::Gitlab::Usage::Metrics::NamesSuggestions::Generator).not_to receive(:generate)
        described_class.new([key_path], { 'dir' => dir }).invoke_all
        metric_definition_path = Dir.glob(File.join(temp_dir, 'metrics/counts_7d/*_test_metric.yml')).first

        expect(YAML.safe_load(File.read(metric_definition_path)).keys).not_to include(:name)
      end
    end
  end
end
