# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::EventDefinition, feature_category: :service_ping do
  let(:attributes) do
    {
      description: 'Created issues',
      category: 'issues',
      action: 'create',
      label_description: 'API',
      property_description: 'The string "issue_id"',
      value_description: 'ID of the issue',
      extra_properties: { confidential: false },
      product_group: 'group::product analytics',
      distributions: %w[ee ce],
      tiers: %w[free premium ultimate],
      introduced_by_url: "https://gitlab.com/example/-/merge_requests/123",
      milestone: '1.6'
    }
  end

  let(:path) { File.join('events', 'issues_create.yml') }
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

  it 'has no duplicated actions in InternalEventTracking events', :aggregate_failures do
    definitions_by_action = described_class
                              .definitions
                              .select(&:internal_events?)
                              .group_by(&:action)

    definitions_by_action.each do |action, definitions|
      expect(definitions.size).to eq(1),
        "Multiple definitions use the action '#{action}': #{definitions.map(&:path).join(', ')}"
    end
  end

  it 'only has internal events without category', :aggregate_failures do
    internal_events = described_class
      .definitions
      .select(&:internal_events?)

    internal_events.each do |event|
      expect(event.category).to be_nil,
        "Event definition with internal_events: true should not have a category: #{event.path}"
    end
  end

  it 'has event definitions for all events used in Internal Events metric definitions', :aggregate_failures do
    from_metric_definitions = Gitlab::Usage::MetricDefinition.not_removed
      .values
      .select(&:internal_events?)
      .flat_map { |m| m.events&.keys }
      .compact
      .uniq

    event_names = described_class.definitions.map(&:action)

    from_metric_definitions.each do |event|
      expect(event_names).to include(event),
        "Event '#{event}' is used in Internal Events but does not have an event definition yet. Please define it."
    end
  end

  describe '.definitions' do
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

    subject { described_class.definitions }

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

    context 'when definitions are already loaded' do
      before do
        allow(Dir).to receive(:glob).and_call_original
        described_class.definitions
      end

      it 'does not read any files' do
        expect(Dir).not_to receive(:glob)
        described_class.definitions
      end
    end
  end

  describe '.find' do
    let(:event_definition1) { described_class.new(nil, { action: 'event1' }) }
    let(:event_definition2) { described_class.new(nil, { action: 'event2' }) }

    before do
      described_class.clear_memoization(:find)
      allow(described_class).to receive(:definitions).and_return([event_definition1, event_definition2])
    end

    it 'finds the event definition by action' do
      expect(described_class.find('event1')).to eq(event_definition1)
    end

    it 'memorizes results' do
      expect(described_class).to receive(:definitions).exactly(3).times.and_call_original

      10.times do
        described_class.find('event1')
        described_class.find('event2')
        described_class.find('non-existing-event')
      end
    end
  end

  describe '.extra_tracking_classes' do
    it 'returns an empty array when no extra tracking classes are set' do
      expect(described_class.new(nil, {}).extra_tracking_classes).to eq([])
    end

    it 'returns the extra tracking classes when they are set' do
      config = attributes.merge({ extra_tracking_classes: ['Gitlab::Tracking::AiTracking'] })

      expect(described_class.new(nil, config).extra_tracking_classes).to eq([Gitlab::Tracking::AiTracking])
    end
  end
end
