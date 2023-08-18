# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::MetricDefinition do
  let(:attributes) do
    {
      description: 'GitLab instance unique identifier',
      value_type: 'string',
      product_stage: 'growth',
      product_section: 'devops',
      status: 'active',
      milestone: '14.1',
      default_generation: 'generation_1',
      key_path: 'uuid',
      product_group: 'product_analytics',
      time_frame: 'none',
      data_source: 'database',
      distribution: %w(ee ce),
      tier: %w(free starter premium ultimate bronze silver gold),
      data_category: 'standard',
      removed_by_url: 'http://gdk.test'
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

  describe 'not_removed' do
    let(:all_definitions) do
      metrics_definitions = [
        { key_path: 'metric1', instrumentation_class: 'RedisHLLMetric', status: 'active' },
        { key_path: 'metric2', instrumentation_class: 'RedisHLLMetric', status: 'broken' },
        { key_path: 'metric3', instrumentation_class: 'RedisHLLMetric', status: 'active' },
        { key_path: 'metric4', instrumentation_class: 'RedisHLLMetric', status: 'removed' }
      ]
      metrics_definitions.map { |definition| described_class.new(definition[:key_path], definition.symbolize_keys) }
    end

    before do
      allow(described_class).to receive(:all).and_return(all_definitions)
    end

    it 'includes metrics that are not removed' do
      expect(described_class.not_removed.count).to eq(3)

      expect(described_class.not_removed.keys).to match_array(%w(metric1 metric2 metric3))
    end
  end

  describe '#with_instrumentation_class' do
    let(:all_definitions) do
      metrics_definitions = [
        { key_path: 'metric1', instrumentation_class: 'RedisHLLMetric', status: 'active' },
        { key_path: 'metric2', instrumentation_class: 'RedisHLLMetric', status: 'broken' },
        { key_path: 'metric3', instrumentation_class: 'RedisHLLMetric', status: 'active' },
        { key_path: 'metric4', instrumentation_class: 'RedisHLLMetric', status: 'removed' },
        { key_path: 'metric5', status: 'active' },
        { key_path: 'metric_missing_status' }
      ]
      metrics_definitions.map { |definition| described_class.new(definition[:key_path], definition.symbolize_keys) }
    end

    before do
      allow(described_class).to receive(:all).and_return(all_definitions)
    end

    it 'includes definitions with instrumentation_class' do
      expect(described_class.with_instrumentation_class.count).to eq(3)
    end

    context 'with removed metric' do
      let(:metric_status) { 'removed' }

      it 'excludes removed definitions' do
        expect(described_class.with_instrumentation_class.count).to eq(3)
      end
    end
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
      :milestone          | nil
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
      :repair_issue_url   | nil
      :removed_by_url     | 1

      :performance_indicator_type | nil
      :instrumentation_class      | 'Metric_Class'
      :instrumentation_class      | 'metricClass'
    end

    with_them do
      before do
        attributes[attribute] = value
      end

      it 'raise exception' do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).at_least(:once).with(instance_of(Gitlab::Usage::MetricDefinition::InvalidError))

        described_class.new(path, attributes).validate!
      end

      context 'with skip_validation' do
        it 'raise exception if skip_validation: false' do
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).at_least(:once).with(instance_of(Gitlab::Usage::MetricDefinition::InvalidError))

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

          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).at_least(:once).with(instance_of(Gitlab::Usage::MetricDefinition::InvalidError))

          described_class.new(path, attributes).validate!
        end
      end
    end
  end

  describe '#events' do
    context 'when metric is not event based' do
      it 'returns empty hash' do
        expect(definition.events).to eq({})
      end
    end

    context 'when metric is using old format' do
      let(:attributes) { { options: { events: ['my_event'] } } }

      it 'returns a correct hash' do
        expect(definition.events).to eq({ 'my_event' => nil })
      end
    end

    context 'when metric is using new format' do
      let(:attributes) { { events: [{ name: 'my_event', unique: 'user_id' }] } }

      it 'returns a correct hash' do
        expect(definition.events).to eq({ 'my_event' => :user_id })
      end
    end

    context 'when metric is using both formats' do
      let(:attributes) do
        {
          options: {
            events: ['a_event']
          },
          events: [{ name: 'my_event', unique: 'project_id' }]
        }
      end

      it 'uses the new format' do
        expect(definition.events).to eq({ 'my_event' => :project_id })
      end
    end
  end

  describe '#valid_service_ping_status?' do
    context 'when metric has active status' do
      it 'has to return true' do
        attributes[:status] = 'active'

        expect(described_class.new(path, attributes).valid_service_ping_status?).to be_truthy
      end
    end

    context 'when metric has removed status' do
      it 'has to return false' do
        attributes[:status] = 'removed'

        expect(described_class.new(path, attributes).valid_service_ping_status?).to be_falsey
      end
    end
  end

  describe 'statuses' do
    using RSpec::Parameterized::TableSyntax

    where(:status, :skip_validation?) do
      'active'         | false
      'broken'         | false
      'removed'        | true
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

    after do
      FileUtils.rm_rf(metric1)
      FileUtils.rm_rf(metric2)
    end

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

      expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(instance_of(Gitlab::Usage::MetricDefinition::InvalidError))

      subject
    end
  end

  describe 'dump_metrics_yaml' do
    let(:other_attributes) do
      {
        description: 'Test metric definition',
        value_type: 'string',
        product_stage: 'growth',
        product_section: 'devops',
        status: 'active',
        milestone: '14.1',
        default_generation: 'generation_1',
        key_path: 'counter.category.event',
        product_group: 'product_analytics',
        time_frame: 'none',
        data_source: 'database',
        distribution: %w(ee ce),
        tier: %w(free starter premium ultimate bronze silver gold),
        data_category: 'optional'
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

  describe '.metric_definitions_changed?', :freeze_time do
    let(:metric1) { Dir.mktmpdir('metric1') }
    let(:metric2) { Dir.mktmpdir('metric2') }

    before do
      allow(Rails).to receive_message_chain(:env, :development?).and_return(is_dev)
      allow(described_class).to receive(:paths).and_return(
        [
          File.join(metric1, '**', '*.yml'),
          File.join(metric2, '**', '*.yml')
        ]
      )

      write_metric(metric1, path, yaml_content)
      write_metric(metric2, path, yaml_content)
    end

    after do
      FileUtils.rm_rf(metric1)
      FileUtils.rm_rf(metric2)
    end

    context 'in development', :freeze_time do
      let(:is_dev) { true }

      it 'has changes on the first invocation' do
        expect(described_class.metric_definitions_changed?).to be_truthy
      end

      context 'when no files are changed' do
        it 'does not have changes on the second invocation' do
          described_class.metric_definitions_changed?

          expect(described_class.metric_definitions_changed?).to be_falsy
        end
      end

      context 'when file is changed' do
        it 'has changes on the next invocation when more than 3 seconds have passed' do
          described_class.metric_definitions_changed?

          write_metric(metric1, path, yaml_content)
          travel_to 10.seconds.from_now

          expect(described_class.metric_definitions_changed?).to be_truthy
        end

        it 'does not have changes on the next invocation when less than 3 seconds have passed' do
          described_class.metric_definitions_changed?

          write_metric(metric1, path, yaml_content)
          travel_to 1.second.from_now

          expect(described_class.metric_definitions_changed?).to be_falsy
        end
      end

      context 'in production' do
        let(:is_dev) { false }

        it 'does not detect changes' do
          expect(described_class.metric_definitions_changed?).to be_falsy
        end
      end
    end
  end
end
