# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageMetricDefinitionGenerator, :silence_stdout, feature_category: :service_ping do
  include UsageDataHelpers

  let(:key_path) { 'counts_weekly.test_metric' }
  let(:dir) { '7d' }
  let(:class_name) { 'Count' }
  let(:temp_dir) { Dir.mktmpdir }

  before do
    stub_const("#{described_class}::TOP_LEVEL_DIR", temp_dir)
    # Stub Prometheus requests from Gitlab::Utils::UsageData
    stub_prometheus_queries

    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive(:ask).and_return('y') # confirm deprecation warning
    end
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe 'Creating metric definition file' do
    let(:sample_metric) { load_sample_metric_definition(filename: sample_filename) }

    # Stub version so that `milestone` key remains constant between releases to prevent flakiness.
    before do
      stub_const('Gitlab::VERSION', '13.9.0')
    end

    context 'without ee option' do
      let(:sample_filename) { 'sample_metric.yml' }
      let(:metric_definition_path) { Dir.glob(File.join(temp_dir, 'metrics/counts_7d/*_test_metric.yml')).first }

      it 'creates a metric definition file using the template' do
        described_class.new([key_path], { 'dir' => dir, 'class_name' => class_name }).invoke_all
        expect(YAML.safe_load(File.read(metric_definition_path))).to eq(sample_metric)
      end
    end

    context 'with ee option' do
      let(:sample_filename) { 'sample_metric_with_ee.yml' }
      let(:metric_definition_path) { Dir.glob(File.join(temp_dir, 'ee/config/metrics/counts_7d/*_test_metric.yml')).first }

      before do
        stub_const("#{described_class}::TOP_LEVEL_DIR", 'config')
        stub_const("#{described_class}::TOP_LEVEL_DIR_EE", File.join(temp_dir, 'ee'))
      end

      it 'creates a metric definition file using the template' do
        described_class.new([key_path], { 'dir' => dir, 'class_name' => class_name, ee: true }).invoke_all
        expect(YAML.safe_load(File.read(metric_definition_path))).to eq(sample_metric)
      end
    end
  end

  describe 'Validation' do
    let(:options) { [key_path, '--dir', dir, '--class_name', class_name] }

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

  context 'with multiple file names' do
    let(:key_paths) { ['counts_weekly.test_metric', 'counts_weekly.test1_metric'] }

    it 'creates multiple files' do
      described_class.new(key_paths, { 'dir' => dir, 'class_name' => class_name }).invoke_all
      files = Dir.glob(File.join(temp_dir, 'metrics/counts_7d/*_metric.yml'))

      expect(files.count).to eq(2)
    end
  end

  ['n', 'N', 'random word', nil].each do |answer|
    context "when user agreed with deprecation warning by typing: #{answer}" do
      it 'does not create definition file' do
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:ask).and_return(answer)
        end

        described_class.new([key_path], { 'dir' => dir, 'class_name' => class_name }).invoke_all
        files = Dir.glob(File.join(temp_dir, 'metrics/counts_7d/*_metric.yml'))

        expect(files.count).to eq(0)
      end
    end
  end
end
