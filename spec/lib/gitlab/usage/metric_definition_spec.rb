# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::MetricDefinition, feature_category: :service_ping do
  let(:attributes) do
    {
      description: 'GitLab instance unique identifier',
      value_type: 'string',
      status: 'active',
      milestone: '14.1',
      introduced_by_url: 'http://gdk.test',
      key_path: 'uuid',
      product_group: 'platform_insights',
      time_frame: 'none',
      data_source: 'database',
      tiers: %w[free premium ultimate],
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

  def expect_validation_errors
    expect(described_class.new(path, attributes).validation_errors).not_to be_empty
  end

  def expect_no_validation_errors
    expect(described_class.new(path, attributes).validation_errors).to be_empty
  end

  def write_metric(metric, path, content)
    path = File.join(metric, path)
    dir = File.dirname(path)
    FileUtils.mkdir_p(dir)
    File.write(path, content)
  end

  describe '#instrumentation_class' do
    context 'for non internal events' do
      let(:attributes) { { key_path: 'metric1', instrumentation_class: 'RedisHLLMetric', data_source: 'redis_hll' } }

      it 'returns class from the definition' do
        expect(definition.instrumentation_class).to eq('RedisHLLMetric')
      end
    end

    context 'for internal events' do
      context 'for total counter' do
        let(:attributes) { { key_path: 'metric1', data_source: 'internal_events', events: [{ name: 'a' }] } }

        it 'returns TotalCounterMetric' do
          expect(definition.instrumentation_class).to eq('TotalCountMetric')
        end
      end

      context 'for uniq counter' do
        let(:attributes) { { key_path: 'metric1', data_source: 'internal_events', events: [{ name: 'a', unique: 'user.id' }] } }

        it 'returns UniqueCountMetric' do
          expect(definition.instrumentation_class).to eq('UniqueCountMetric')
        end
      end

      context 'for sum' do
        let(:attributes) { { key_path: 'metric1', data_source: 'internal_events', events: [{ name: 'a', operator: 'sum(value)' }] } }

        it 'returns TotalSumMetric' do
          expect(definition.instrumentation_class).to eq('TotalSumMetric')
        end
      end
    end
  end

  describe '.not_removed' do
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

      expect(described_class.not_removed.keys).to match_array(%w[metric1 metric2 metric3])
    end
  end

  describe 'invalid product_group' do
    before do
      attributes[:product_group] = 'a_product_group'
    end

    it 'has validation errors' do
      expect_validation_errors
    end
  end

  describe '.with_instrumentation_class' do
    let(:all_definitions) do
      metrics_definitions = [
        { key_path: 'metric1', status: 'active', data_source: 'redis_hll', instrumentation_class: 'RedisHLLMetric' },
        { key_path: 'metric2', status: 'active', data_source: 'internal_events' }, # class is defined by data_source

        { key_path: 'metric3', status: 'active', data_source: 'redis_hll' },
        { key_path: 'metric4', status: 'removed', instrumentation_class: 'RedisHLLMetric', data_source: 'redis_hll' },
        { key_path: 'metric5', status: 'removed', data_source: 'internal_events' },
        { key_path: 'metric_missing_status', data_source: 'internal_events' }
      ]
      metrics_definitions.map { |definition| described_class.new(definition[:key_path], definition.symbolize_keys) }
    end

    before do
      allow(described_class).to receive(:all).and_return(all_definitions)
    end

    it 'includes definitions with instrumentation_class' do
      expect(described_class.with_instrumentation_class.map(&:key_path)).to match_array(%w[metric1 metric2])
    end
  end

  describe '#key' do
    subject { definition.key }

    it 'returns a symbol from name' do
      is_expected.to eq('uuid')
    end
  end

  describe '#to_context' do
    subject { definition.to_context }

    context 'with data_source redis_hll metric' do
      before do
        attributes[:data_source] = 'redis_hll'
        attributes[:options] = { events: %w[some_event_1 some_event_2] }
      end

      it 'returns a ServicePingContext with first event as event_name' do
        expect(subject.to_h[:data][:event_name]).to eq('some_event_1')
      end
    end

    context 'with data_source redis metric' do
      before do
        attributes[:data_source] = 'redis'
        attributes[:events] = [
          { name: 'web_ide_viewed' }
        ]
      end

      it 'returns a ServicePingContext with first event as event_name' do
        expect(subject.to_h[:data][:event_name]).to eq('web_ide_viewed')
      end
    end

    context 'with data_source database metric' do
      before do
        attributes[:data_source] = 'database'
      end

      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end

  describe '#validate' do
    using RSpec::Parameterized::TableSyntax

    where(:attribute, :value) do
      :description        | nil
      :value_type         | nil
      :value_type         | 'test'
      :status             | nil
      :milestone          | 10.0
      :data_category      | nil
      :key_path           | nil
      :product_group      | nil
      :time_frame         | nil
      :time_frame         | '29d'
      :data_source        | 'other'
      :data_source        | nil
      :tiers              | %w[test ee]
      :repair_issue_url   | nil
      :removed_by_url     | 1
      :another_attribute  | nil
      :product_categories   | 'bad_category'
      :product_categories   | ['bad_category']

      :performance_indicator_type | nil
      :instrumentation_class      | 'Metric_Class'
      :instrumentation_class      | 'metricClass'
    end

    with_them do
      before do
        attributes[attribute] = value
      end

      it 'has validation errors' do
        expect_validation_errors
      end
    end

    context "validation errors" do
      it "has descriptive error messages" do
        attributes.delete(:milestone)

        expect(described_class.new(path, attributes).validation_errors.first).to match(/"missing_keys"=>\["milestone"\]/)
      end
    end

    context 'conditional validations' do
      context 'when metric has broken status' do
        it 'has to have repair issue url provided' do
          attributes[:status] = 'broken'
          attributes.delete(:repair_issue_url)

          expect_validation_errors
        end
      end

      context 'when metric has removed status' do
        before do
          attributes[:status] = 'removed'
        end

        it 'has validation errors when removed_by_url is not provided' do
          attributes.delete(:removed_by_url)

          expect_validation_errors
        end

        it 'has validation errors when milestone_removed is not provided' do
          attributes.delete(:milestone_removed)

          expect_validation_errors
        end
      end

      context 'internal metric' do
        let(:default_values) do
          {
            data_source: 'internal_events',
            time_frame: '7d',
            events: [{ name: 'a', unique: 'user.id' }]
          }
        end

        before do
          attributes.merge!(default_values)
        end

        context 'with instrumentation_class' do
          where(:instrumentation_class, :options, :events, :is_valid) do
            'AnotherClass'     | { events: ['a'] } | [{ name: 'a', unique: 'user.id' }] | false
            'RedisHLLMetric'   | { events: ['a'] } | [{ name: 'a', unique: 'user.id' }] | false
            'RedisHLLMetric'   | { events: ['a'] } | nil | false
            nil                | { events: ['a'] } | [{ name: 'a', unique: 'user.id' }] | true
          end

          with_them do
            it 'has validation errors when invalid' do
              attributes[:instrumentation_class] = instrumentation_class if instrumentation_class
              attributes[:options] = options if options
              attributes[:events] = events if events

              if is_valid
                expect_no_validation_errors
              else
                expect_validation_errors
              end
            end
          end
        end

        context 'with time_frame' do
          where(:time_frame, :is_valid) do
            ['7d']     | true
            %w[7d 28d] | true
            '7d'       | true
            'none'     | false
            nil        | false
          end

          with_them do
            it 'has validation errors when invalid' do
              attributes[:time_frame] = time_frame

              if is_valid
                expect_no_validation_errors
              else
                expect_validation_errors
              end
            end
          end
        end
      end

      context 'Redis metric' do
        before do
          attributes[:data_source] = 'redis'
        end

        where(:instrumentation_class, :options, :is_valid) do
          'AnotherClass'                      | { event: 'a', widget: 'b' } | false
          'RedisMetric'                       | { event: 'a', prefix: 'b', include_usage_prefix: true } | true
          'RedisMetric'                       | { event: 'a', prefix: nil, include_usage_prefix: true } | true
          'RedisMetric'                       | { event: 'a', prefix: 'b', include_usage_prefix: 2 } | false
          'RedisMetric'                       | { event: 'a', prefix: 'b', include_usage_prefix: true, c: 'd' } | false
          'RedisMetric'                       | { prefix: 'b', include_usage_prefix: true } | false
          'RedisMetric'                       | { event: 'a', include_usage_prefix: true } | false
          'RedisMetric'                       | { event: 'a', prefix: 'b' } | true
        end

        with_them do
          it 'validates properly' do
            attributes[:instrumentation_class] = instrumentation_class
            attributes[:options] = options

            if is_valid
              expect_no_validation_errors
            else
              expect_validation_errors
            end
          end
        end
      end

      context 'RedisHLL metric' do
        before do
          attributes[:data_source] = 'redis_hll'
        end

        where(:instrumentation_class, :options, :is_valid) do
          'AnotherClass'     | { events: ['a'] } | false
          'RedisHLLMetric'   | { events: ['a'] } | true
          'RedisHLLMetric'   | nil | false
          'RedisHLLMetric'   | {} | false
          'RedisHLLMetric'   | { events: ['a'], b: 'c' } | false
          'RedisHLLMetric'   | { events: [2] } | false
          'RedisHLLMetric'   | { events: 'a' } | false
          'RedisHLLMetric'   | { event: ['a'] } | false
        end

        with_them do
          it 'validates properly' do
            attributes[:instrumentation_class] = instrumentation_class
            attributes[:options] = options

            if is_valid
              expect_no_validation_errors
            else
              expect_validation_errors
            end
          end
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
      let(:attributes) { { events: [{ name: 'my_event', unique: 'user.id' }] } }

      it 'returns a correct hash' do
        expect(definition.events).to eq({ 'my_event' => :'user.id' })
      end
    end

    context 'when metric is using both formats' do
      let(:attributes) do
        {
          options: {
            events: ['a_event']
          },
          events: [{ name: 'my_event', unique: 'project.id' }]
        }
      end

      it 'uses the new format' do
        expect(definition.events).to eq({ 'my_event' => :'project.id' })
      end
    end
  end

  describe '#event_selection_rules' do
    def make_rule(name:, time_framed: true, filter: nil, unique_identifier_name: nil)
      Gitlab::Usage::EventSelectionRule.new(
        name: name,
        time_framed: time_framed,
        filter: filter,
        unique_identifier_name: unique_identifier_name
      )
    end

    subject { definition.event_selection_rules }

    context 'when metric is not event based' do
      it 'returns an empty array' do
        expect(subject).to eq([])
      end
    end

    context 'when the metric has unique keys' do
      let(:attributes) do
        {
          time_frame: '7d',
          events: [
            { name: 'an_event', unique: 'user.id' },
            { name: 'another_event', unique: 'project.id' }
          ]
        }
      end

      it 'returns unique counter event selection rules' do
        rule1 = make_rule(name: 'an_event', unique_identifier_name: :user)
        rule2 = make_rule(name: 'another_event', unique_identifier_name: :project)
        expect(subject).to match_array([rule1, rule2])

        subject.each do |rule|
          expect(rule.total_counter?).to be(false)
        end
      end
    end

    context 'when the metric has no unique keys' do
      let(:attributes) do
        {
          time_frame: '7d',
          events: [
            { name: 'an_event' },
            { name: 'another_event' }
          ]
        }
      end

      it 'returns total counter event selection rules' do
        rule1 = make_rule(name: 'an_event')
        rule2 = make_rule(name: 'another_event')
        expect(subject).to match_array([rule1, rule2])

        subject.each do |rule|
          expect(rule.total_counter?).to be(true)
        end
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

    context "with array time_frame definitions" do
      let(:yaml_content) { attributes.merge(time_frame: %w[7d 28d all]).deep_stringify_keys.to_yaml }

      it "creates a metric for each of the time frames" do
        write_metric(metric1, path, yaml_content)

        expected_key_paths = %w[uuid_monthly uuid_weekly uuid]

        expect(subject.length).to eq(3)
        expect(subject.keys).to match_array(expected_key_paths)
        expect(subject.values.map(&:key_path)).to match_array(expected_key_paths)
      end

      context "when array time_frame generates an already used key_path" do
        let(:yaml_content2) { attributes.merge(key_path: 'uuid_monthly').deep_stringify_keys.to_yaml }

        it "raises an exception" do
          write_metric(metric1, path, yaml_content)
          write_metric(metric2, path, yaml_content2)

          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(instance_of(Gitlab::Usage::MetricDefinition::InvalidError))

          subject
        end
      end
    end
  end

  describe 'dump_metrics_yaml' do
    let(:include_paths) { false }
    let(:other_attributes) do
      {
        description: 'Test metric definition',
        value_type: 'string',
        status: 'active',
        milestone: '14.1',
        key_path: 'counter.category.event',
        product_group: 'platform_insights',
        time_frame: 'none',
        data_source: 'database',
        tiers: %w[free starter premium ultimate bronze silver gold],
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

      write_metric(metric1, path, yaml_content)
      write_metric(metric2, other_path, other_yaml_content)
    end

    after do
      FileUtils.rm_rf(metric1)
      FileUtils.rm_rf(metric2)
    end

    subject { described_class.dump_metrics_yaml(include_paths: include_paths) }

    it 'returns a YAML with both metrics in a sequence' do
      is_expected.to eq([attributes, other_attributes].map(&:deep_stringify_keys).to_yaml)
    end

    context "with true include_paths" do
      let(:include_paths) { true }

      it 'returns a YAML including filepaths' do
        metrics = YAML.safe_load(subject)
        added_attribute = ['file_path']

        # First metric
        serialized_metric = metrics[0]
        expect(serialized_metric).to include(attributes.deep_stringify_keys)
        expect(serialized_metric.keys - attributes.keys.map(&:to_s)).to eq(added_attribute)
        expect(serialized_metric['file_path']).to end_with(path)

        # Second metric
        serialized_metric = metrics[1]
        expect(serialized_metric).to include(other_attributes.deep_stringify_keys)
        expect(serialized_metric.keys - other_attributes.keys.map(&:to_s)).to eq(added_attribute)
        expect(serialized_metric['file_path']).to end_with(other_path)
      end
    end
  end
end
