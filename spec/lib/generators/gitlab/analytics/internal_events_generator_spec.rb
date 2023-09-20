# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::InternalEventsGenerator, :silence_stdout, feature_category: :service_ping do
  include UsageDataHelpers

  let(:temp_dir) { Dir.mktmpdir }
  let(:ee_temp_dir) { Dir.mktmpdir }
  let(:tmpfile) { Tempfile.new('test-metadata') }
  let(:existing_key_paths) { {} }
  let(:description) { "This metric counts unique users viewing analytics metrics dashboard section" }
  let(:group) { "group::analytics instrumentation" }
  let(:stage) { "analytics" }
  let(:section) { "analytics" }
  let(:mr) { "https://gitlab.com/some-group/some-project/-/merge_requests/123" }
  let(:event) { "view_analytics_dashboard" }
  let(:unique) { "user.id" }
  let(:time_frames) { %w[7d] }
  let(:include_default_identifiers) { 'yes' }
  let(:options) do
    {
      time_frames: time_frames,
      free: true,
      mr: mr,
      group: group,
      stage: stage,
      section: section,
      event: event,
      unique: unique
    }.stringify_keys
  end

  let(:key_path_without_time_frame) { "count_distinct_#{unique.sub('.', '_')}_from_#{event}" }
  let(:key_path_7d) { "#{key_path_without_time_frame}_7d" }
  let(:metric_definition_path_7d) { Dir.glob(File.join(temp_dir, "metrics/counts_7d/#{key_path_7d}.yml")).first }
  let(:metric_definition_7d) do
    {
      "key_path" => key_path_7d,
      "description" => description,
      "product_section" => section,
      "product_stage" => stage,
      "product_group" => group,
      "performance_indicator_type" => [],
      "value_type" => "number",
      "status" => "active",
      "milestone" => "13.9",
      "introduced_by_url" => mr,
      "time_frame" => "7d",
      "data_source" => "internal_events",
      "data_category" => "optional",
      "instrumentation_class" => "RedisHLLMetric",
      "distribution" => %w[ce ee],
      "tier" => %w[free premium ultimate],
      "options" => {
        "events" => [event]
      },
      "events" => [{ "name" => event, "unique" => unique }]
    }
  end

  before do
    stub_const("#{described_class}::TOP_LEVEL_DIR_EE", ee_temp_dir)
    stub_const("#{described_class}::TOP_LEVEL_DIR", temp_dir)
    # Stub version so that `milestone` key remains constant between releases to prevent flakiness.
    stub_const('Gitlab::VERSION', '13.9.0')

    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive(:ask)
                           .with(/Please describe in at least 50 characters/)
                           .and_return(description)
    end

    allow(Gitlab::TaskHelpers).to receive(:prompt).and_return(include_default_identifiers)
    allow(Gitlab::Usage::MetricDefinition).to receive(:definitions).and_return(existing_key_paths)
  end

  after do
    FileUtils.rm_rf(temp_dir)
    FileUtils.rm_rf(ee_temp_dir)
    FileUtils.rm_rf(tmpfile.path)
  end

  describe 'Creating event definition file' do
    let(:event_definition_path) { Dir.glob(File.join(temp_dir, "events/#{event}.yml")).first }
    let(:identifiers) { %w[project user namespace] }
    let(:event_definition) do
      {
        "category" => "InternalEventTracking",
        "action" => event,
        "description" => description,
        "product_section" => section,
        "product_stage" => stage,
        "product_group" => group,
        "label_description" => nil,
        "property_description" => nil,
        "value_description" => nil,
        "extra_properties" => nil,
        "identifiers" => identifiers,
        "milestone" => "13.9",
        "introduced_by_url" => mr,
        "distributions" => %w[ce ee],
        "tiers" => %w[free premium ultimate]
      }
    end

    it 'creates an event definition file using the template' do
      described_class.new([], options).invoke_all

      expect(YAML.safe_load(File.read(event_definition_path))).to eq(event_definition)
    end

    context 'for ultimate only feature' do
      let(:event_definition_path) do
        Dir.glob(File.join(ee_temp_dir, temp_dir, "events/#{event}.yml")).first
      end

      it 'creates an event definition file using the template' do
        described_class.new([], options.merge(tiers: %w[ultimate])).invoke_all

        expect(YAML.safe_load(File.read(event_definition_path)))
          .to eq(event_definition.merge("tiers" => ["ultimate"], "distributions" => ["ee"]))
      end
    end

    context 'without default identifiers' do
      let(:include_default_identifiers) { 'no' }

      it 'creates an event definition file using the template' do
        described_class.new([], options).invoke_all

        expect(YAML.safe_load(File.read(event_definition_path)))
          .to eq(event_definition.merge("identifiers" => nil))
      end
    end

    context 'with duplicated event' do
      context 'in known_events' do
        before do
          allow(::Gitlab::UsageDataCounters::HLLRedisCounter)
            .to receive(:known_event?).with(event).and_return(true)
        end

        it 'does not create event definition' do
          described_class.new([], options).invoke_all

          expect(event_definition_path).to eq(nil)
        end
      end

      context 'in event definition files' do
        before do
          Dir.mkdir(File.join(temp_dir, "events"))
          File.write(File.join(temp_dir, "events", "#{event}.yml"), { action: event }.to_yaml)
        end

        it 'raises error' do
          expect { described_class.new([], options).invoke_all }.to raise_error(RuntimeError)
        end
      end
    end
  end

  describe 'Creating metric definition file' do
    context 'for single time frame' do
      let(:time_frames) { %w[7d] }

      it 'creates a metric definition file using the template' do
        described_class.new([], options).invoke_all

        expect(YAML.safe_load(File.read(metric_definition_path_7d))).to eq(metric_definition_7d)
      end

      context 'for ultimate only feature' do
        let(:metric_definition_path_7d) do
          Dir.glob(File.join(ee_temp_dir, temp_dir, "metrics/counts_7d/#{key_path_7d}.yml")).first
        end

        it 'creates a metric definition file using the template' do
          described_class.new([], options.merge(tiers: %w[ultimate])).invoke_all

          expect(YAML.safe_load(File.read(metric_definition_path_7d)))
            .to eq(metric_definition_7d.merge("tier" => ["ultimate"], "distribution" => ["ee"]))
        end
      end

      context 'with invalid time frame' do
        let(:time_frames) { %w[14d] }

        it 'raises error' do
          expect { described_class.new([], options).invoke_all }.to raise_error(RuntimeError)
        end
      end

      context 'with duplicated key path' do
        let(:existing_key_paths) { { key_path_7d => true } }

        it 'raises error' do
          expect { described_class.new([], options).invoke_all }.to raise_error(RuntimeError)
        end
      end

      context 'with unique value passed with a dot' do
        it 'creates a metric definition file using the template' do
          described_class.new([], options.merge(unique: 'user.id')).invoke_all

          expect(YAML.safe_load(File.read(metric_definition_path_7d))).to eq(metric_definition_7d)
        end
      end

      context 'without at least one tier available' do
        it 'raises error' do
          expect { described_class.new([], options.merge(tiers: [])).invoke_all }
            .to raise_error(RuntimeError)
        end
      end

      context 'with unknown tier' do
        it 'raises error' do
          expect { described_class.new([], options.merge(tiers: %w[superb])).invoke_all }
            .to raise_error(RuntimeError)
        end
      end

      context 'without obligatory parameter' do
        it 'raises error', :aggregate_failures do
          %w[unique event mr section stage group].each do |option|
            expect { described_class.new([], options.without(option)).invoke_all }
              .to raise_error(RuntimeError)
          end
        end
      end

      context 'with to short description' do
        it 'asks again for description' do
          allow_next_instance_of(described_class) do |instance|
            allow(instance).to receive(:ask)
                                 .with(/By convention all events automatically include the following properties/)
                                 .and_return(include_default_identifiers)

            allow(instance).to receive(:ask).twice
                                 .with(/Please describe in at least 50 characters/)
                                 .and_return("I am to short")

            expect(instance).to receive(:ask).twice
                                 .with(/Please provide description that is 50 characters long/)
                                 .and_return(description)
          end

          described_class.new([], options).invoke_all
        end
      end
    end

    context 'for multiple time frames' do
      let(:time_frames) { %w[7d 28d] }
      let(:key_path_28d) { "#{key_path_without_time_frame}_28d" }
      let(:metric_definition_path_28d) { Dir.glob(File.join(temp_dir, "metrics/counts_28d/#{key_path_28d}.yml")).first }
      let(:metric_definition_28d) do
        metric_definition_7d.merge(
          "key_path" => key_path_28d,
          "time_frame" => "28d"
        )
      end

      it 'creates a metric definition file using the template' do
        described_class.new([], options).invoke_all

        expect(YAML.safe_load(File.read(metric_definition_path_7d))).to eq(metric_definition_7d)
        expect(YAML.safe_load(File.read(metric_definition_path_28d))).to eq(metric_definition_28d)
      end
    end

    context 'with default time frames' do
      let(:time_frames) { nil }
      let(:key_path_28d) { "#{key_path_without_time_frame}_28d" }
      let(:metric_definition_path_28d) { Dir.glob(File.join(temp_dir, "metrics/counts_28d/#{key_path_28d}.yml")).first }
      let(:metric_definition_28d) do
        metric_definition_7d.merge(
          "key_path" => key_path_28d,
          "time_frame" => "28d"
        )
      end

      it 'creates a metric definition file using the template' do
        described_class.new([], options.without('time_frames')).invoke_all

        expect(YAML.safe_load(File.read(metric_definition_path_7d))).to eq(metric_definition_7d)
        expect(YAML.safe_load(File.read(metric_definition_path_28d))).to eq(metric_definition_28d)
      end
    end
  end
end
