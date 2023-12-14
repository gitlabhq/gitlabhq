# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::EventDefinition do
  let(:attributes) do
    {
      description: 'Created issues',
      category: 'issues',
      action: 'create',
      label_description: 'API',
      property_description: 'The string "issue_id"',
      value_description: 'ID of the issue',
      extra_properties: { confidential: false },
      product_stage: 'growth',
      product_section: 'dev',
      product_group: 'group::product analytics',
      distribution: %w[ee ce],
      tier: %w[free premium ultimate]
    }
  end

  let(:path) { File.join('events', 'issues_create.yml') }
  let(:definition) { described_class.new(path, attributes) }
  let(:yaml_content) { attributes.deep_stringify_keys.to_yaml }

  def write_metric(metric, path, content)
    path = File.join(metric, path)
    dir = File.dirname(path)
    FileUtils.mkdir_p(dir)
    File.write(path, content)
  end

  it 'has all definitions valid' do
    expect { described_class.definitions }.not_to raise_error
  end

  it 'has no duplicated actions in InternalEventTracking events', :aggregate_failures do
    definitions_by_action = described_class.definitions
                                           .each_value.select { |d| d.category == 'InternalEventTracking' }
                                           .group_by(&:action)

    definitions_by_action.each do |action, definitions|
      expect(definitions.size).to eq(1),
        "Multiple definitions use the action '#{action}': #{definitions.map(&:path).join(', ')}"
    end
  end

  it 'has event definitions for all events used in Internal Events metric definitions', :aggregate_failures do
    from_metric_definitions = Gitlab::Usage::MetricDefinition.definitions
      .values
      .select { |m| m.attributes[:data_source] == 'internal_events' }
      .flat_map { |m| m.events&.keys }
      .compact
      .uniq

    event_names = Gitlab::Tracking::EventDefinition.definitions.values.map { |e| e.attributes[:action] }

    from_metric_definitions.each do |event|
      expect(event_names).to include(event),
        "Event '#{event}' is used in Internal Events but does not have an event definition yet. Please define it."
    end
  end

  describe '#validate' do
    using RSpec::Parameterized::TableSyntax

    where(:attribute, :value) do
      :description          | 1
      :category             | nil
      :action               | nil
      :label_description    | 1
      :property_description | 1
      :value_description    | 1
      :extra_properties     | 'smth'
      :product_stage        | 1
      :product_section      | nil
      :product_group        | nil
      :distributions        | %(be eb)
      :tiers                | %(pro)
    end

    with_them do
      before do
        attributes[attribute] = value
      end

      it 'raise exception' do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).at_least(:once).with(instance_of(Gitlab::Tracking::InvalidEventError))

        described_class.new(path, attributes).validate!
      end
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
  end
end
