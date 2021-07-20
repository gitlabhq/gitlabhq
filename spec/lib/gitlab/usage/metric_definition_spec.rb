# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::MetricDefinition do
  let(:attributes) do
    {
      description: 'GitLab instance unique identifier',
      value_type: 'string',
      product_category: 'collection',
      product_stage: 'growth',
      status: 'data_available',
      default_generation: 'generation_1',
      key_path: 'uuid',
      product_group: 'group::product analytics',
      time_frame: 'none',
      data_source: 'database',
      distribution: %w(ee ce),
      tier: %w(free starter premium ultimate bronze silver gold),
      name: 'uuid',
      data_category: 'Standard'
    }
  end

  let(:path) { File.join('metrics', 'uuid.yml') }
  let(:definition) { described_class.new(path, attributes) }
  let(:yaml_content) { attributes.deep_stringify_keys.to_yaml }

  around do |example|
    described_class.instance_variable_set(:@definitions, nil)
    example.run
    described_class.instance_variable_set(:@definitions, nil)
  end

  def write_metric(metric, path, content)
    path = File.join(metric, path)
    dir = File.dirname(path)
    FileUtils.mkdir_p(dir)
    File.write(path, content)
  end

  after do
    # Reset memoized `definitions` result
    described_class.instance_variable_set(:@definitions, nil)
  end

  it 'has all definitons valid' do
    expect { described_class.definitions }.not_to raise_error
  end

  describe '#key' do
    subject { definition.key }

    it 'returns a symbol from name' do
      is_expected.to eq('uuid')
    end
  end

  describe '#validate' do
    using RSpec::Parameterized::TableSyntax

    where(:attribute, :value) do
      :description        | nil
      :value_type         | nil
      :value_type         | 'test'
      :status             | nil
      :data_category      | nil
      :key_path           | nil
      :product_group      | nil
      :time_frame         | nil
      :time_frame         | '29d'
      :data_source        | 'other'
      :data_source        | nil
      :distribution       | nil
      :distribution       | 'test'
      :tier               | %w(test ee)
      :name               | 'count_<adjective_describing>_boards'
      :repair_issue_url   | nil

      :instrumentation_class | 'Metric_Class'
      :instrumentation_class | 'metricClass'
    end

    with_them do
      before do
        attributes[attribute] = value
      end

      it 'raise exception' do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).at_least(:once).with(instance_of(Gitlab::Usage::Metric::InvalidMetricError))

        described_class.new(path, attributes).validate!
      end

      context 'with skip_validation' do
        it 'raise exception if skip_validation: false' do
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).at_least(:once).with(instance_of(Gitlab::Usage::Metric::InvalidMetricError))

          described_class.new(path, attributes.merge( { skip_validation: false } )).validate!
        end

        it 'does not raise exception if has skip_validation: true' do
          expect(Gitlab::ErrorTracking).not_to receive(:track_and_raise_for_dev_exception)

          described_class.new(path, attributes.merge( { skip_validation: true } )).validate!
        end
      end
    end

    context 'conditional validations' do
      context 'when metric has broken status' do
        it 'has to have repair issue url provided' do
          attributes[:status] = 'broken'
          attributes.delete(:repair_issue_url)

          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).at_least(:once).with(instance_of(Gitlab::Usage::Metric::InvalidMetricError))

          described_class.new(path, attributes).validate!
        end
      end
    end
  end

  describe 'statuses' do
    using RSpec::Parameterized::TableSyntax

    where(:status, :skip_validation?) do
      'deprecated'     | true
      'removed'        | true
      'data_available' | false
      'implemented'    | false
      'not_used'       | false
    end

    with_them do
      subject(:validation) do
        described_class.new(path, attributes.merge( { status: status } )).send(:skip_validation?)
      end

      it 'returns true/false for skip_validation' do
        expect(validation).to eq(skip_validation?)
      end
    end
  end

  describe '.load_all!' do
    let(:metric1) { Dir.mktmpdir('metric1') }
    let(:metric2) { Dir.mktmpdir('metric2') }
    let(:definitions) { {} }

    before do
      allow(described_class).to receive(:paths).and_return(
        [
          File.join(metric1, '**', '*.yml'),
          File.join(metric2, '**', '*.yml')
        ]
      )
    end

    subject { described_class.send(:load_all!) }

    it 'has empty list when there are no definition files' do
      is_expected.to be_empty
    end

    it 'has one metric when there is one file' do
      write_metric(metric1, path, yaml_content)

      is_expected.to be_one
    end

    it 'when the same metric is defined multiple times raises exception' do
      write_metric(metric1, path, yaml_content)
      write_metric(metric2, path, yaml_content)

      expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(instance_of(Gitlab::Usage::Metric::InvalidMetricError))

      subject
    end

    after do
      FileUtils.rm_rf(metric1)
      FileUtils.rm_rf(metric2)
    end
  end

  describe 'dump_metrics_yaml' do
    let(:other_attributes) do
      {
        description: 'Test metric definition',
        value_type: 'string',
        product_category: 'collection',
        product_stage: 'growth',
        status: 'data_available',
        default_generation: 'generation_1',
        key_path: 'counter.category.event',
        product_group: 'group::product analytics',
        time_frame: 'none',
        data_source: 'database',
        distribution: %w(ee ce),
        tier: %w(free starter premium ultimate bronze silver gold),
        data_category: 'Optional'
      }
    end

    let(:other_yaml_content) { other_attributes.deep_stringify_keys.to_yaml }
    let(:other_path) { File.join('metrics', 'test_metric.yml') }
    let(:metric1) { Dir.mktmpdir('metric1') }
    let(:metric2) { Dir.mktmpdir('metric2') }

    before do
      allow(described_class).to receive(:paths).and_return(
        [
          File.join(metric1, '**', '*.yml'),
          File.join(metric2, '**', '*.yml')
        ]
      )
    end

    after do
      FileUtils.rm_rf(metric1)
      FileUtils.rm_rf(metric2)
    end

    subject { described_class.dump_metrics_yaml }

    it 'returns a YAML with both metrics in a sequence' do
      write_metric(metric1, path, yaml_content)
      write_metric(metric2, other_path, other_yaml_content)

      is_expected.to eq([attributes, other_attributes].map(&:deep_stringify_keys).to_yaml)
    end
  end
end
