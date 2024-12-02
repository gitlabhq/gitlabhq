# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../../scripts/internal_events/cli'

RSpec.describe InternalEventsCli::Helpers::MetricOptions::Option, feature_category: :service_ping do
  let(:identifier) { 'user' }
  let(:events_name) { 'a list of events' }
  let(:filter_name) { nil }
  let(:defined) { false }
  let(:supported) { true }
  let(:styling_stub) { Pastel.new }

  let(:metrics) do
    [instance_double(InternalEventsCli::NewMetric,
      time_frame: instance_double(InternalEventsCli::Metric::TimeFrame, description: "time frame"))]
  end

  subject(:option) do
    described_class.new(
      identifier: identifier,
      events_name: events_name,
      filter_name: filter_name,
      metrics: metrics,
      defined: defined,
      supported: supported
    )
  end

  before do
    [:cyan, :yellow, :green, :bright_black, :magenta, :red, :bold].each do |color|
      allow(styling_stub).to receive(color).and_wrap_original do |method, arg|
        "<#{method.name}>#{arg}</#{method.name}>"
      end
    end

    allow(Pastel).to receive(:new).and_return(styling_stub)
  end

  context 'when option is for a supported and not yet defined metric' do
    it 'highlights key words in the name' do
      expect(option.formatted).to eq({
        name: "<cyan>Time frame</cyan> count of <cyan>unique users</cyan> who triggered a list of events",
        value: metrics
      })
    end

    context 'with a filter' do
      let(:filter_name) { 'label/prop/anything' }

      it 'highlights key words in the name' do
        expect(option.formatted).to eq({
          name: "<cyan>Time frame</cyan> count of <cyan>unique users</cyan> who triggered a list of events " \
            "<cyan>where label/prop/anything</cyan> is...",
          value: metrics
        })
      end
    end
  end

  context 'when option is already defined' do
    let(:defined) { true }

    it 'formats the option as disabled' do
      expect(option.formatted).to eq({
        name: "<bright_black>Time frame count of unique users who triggered a list of events</bright_black>",
        value: metrics,
        disabled: "<bold><bright_black>(already defined)</bright_black></bold>"
      })
    end

    context 'with a filter' do
      let(:filter_name) { 'label/prop/anything' }

      it 'highlights key words in the name' do
        expect(option.formatted).to eq({
          name: "<bright_black>Time frame count of unique users who triggered " \
            "a list of events where filtered</bright_black>",
          value: metrics,
          disabled: "<bold><bright_black>(already defined)</bright_black></bold>"
        })
      end
    end
  end

  context 'when option is not supported' do
    let(:supported) { false }

    it 'formats the option as disabled' do
      expect(option.formatted).to eq({
        name: "<bright_black>Time frame count of unique users who triggered a list of events</bright_black>",
        value: metrics,
        disabled: "<bold><bright_black>(user unavailable)</bright_black></bold>"
      })
    end

    context 'with a filter' do
      let(:filter_name) { 'label/prop/anything' }

      it 'highlights key words in the name' do
        expect(option.formatted).to eq({
          name: "<bright_black>Time frame count of unique users who triggered " \
            "a list of events where filtered</bright_black>",
          value: metrics,
          disabled: "<bold><bright_black>(user unavailable)</bright_black></bold>"
        })
      end
    end
  end

  context 'when identifier is an additional_property' do
    let(:identifier) { 'label' }

    it 'highlights key words in the name' do
      expect(option.formatted).to eq({
        name: "<cyan>Time frame</cyan> count of <cyan>unique values for 'label'</cyan> " \
          "from a list of events occurrences",
        value: metrics
      })
    end
  end

  context 'with no identifier' do
    let(:identifier) { nil }

    it 'highlights key words in the name' do
      expect(option.formatted).to eq({
        name: "<cyan>Time frame</cyan> count of a list of events occurrences",
        value: metrics
      })
    end
  end

  context 'with multiple metrics' do
    let(:metrics) do
      [
        instance_double(InternalEventsCli::NewMetric,
          time_frame: instance_double(InternalEventsCli::Metric::TimeFrame, description: "time frame 1")),
        instance_double(InternalEventsCli::NewMetric,
          time_frame: instance_double(InternalEventsCli::Metric::TimeFrame, description: "time frame 2"))
      ]
    end

    it 'highlights key words in the name' do
      expect(option.formatted).to eq({
        name: "<cyan>Time frame 1/Time frame 2</cyan> count of <cyan>unique users</cyan> " \
          "who triggered a list of events",
        value: metrics
      })
    end
  end
end

RSpec.describe InternalEventsCli::Helpers::MetricOptions::EventSelection, feature_category: :service_ping do
  let(:event_1) do
    instance_double(
      InternalEventsCli::ExistingEvent,
      action: 'action_1',
      available_filters: ['property'],
      identifiers: %w[user namespace]
    )
  end

  let(:event_2) do
    instance_double(
      InternalEventsCli::ExistingEvent,
      action: 'action_2',
      available_filters: %w[property value],
      identifiers: %w[user project namespace]
    )
  end

  let(:event_3) do
    instance_double(
      InternalEventsCli::ExistingEvent,
      action: 'action_3',
      available_filters: [],
      identifiers: ['user']
    )
  end

  let(:events) { [event_1, event_2, event_3] }

  subject(:selection) { described_class.new(events) }

  context 'with one event selected' do
    let(:events) { [event_2] }

    it 'reflects the full capabilities of a metric', :aggregate_failures do
      expect(selection.actions).to contain_exactly('action_2')
      expect(selection.events_name).to eq('action_2')

      expect(selection.filter_name('user')).to eq('property/value')
      expect(selection.filter_name('value')).to eq('property')

      expect(selection.shared_filters).to contain_exactly('property', 'value')
      expect(selection.filter_options).to contain_exactly('property', 'value')
      expect(selection.shared_identifiers).to contain_exactly('user', 'project', 'namespace')
      expect(selection.uniqueness_options).to contain_exactly('user', 'project', 'namespace', 'property', 'value', nil)

      expect(selection.can_be_unique?('user')).to be(true)
      expect(selection.can_be_unique?('label')).to be(false)
      expect(selection.can_be_unique?(nil)).to be(true)

      expect(selection.can_filter_when_unique?('value')).to be(true)
      expect(selection.can_filter_when_unique?('label')).to be(false)
      expect(selection.can_filter_when_unique?('user')).to be(true)

      expect(selection.exclude_filter_identifier?('property')).to be(false)
      expect(selection.exclude_filter_identifier?('value')).to be(false)
      expect(selection.exclude_filter_identifier?('label')).to be(false)
      expect(selection.exclude_filter_identifier?('user')).to be(false)
    end
  end

  context 'with multiple events selected' do
    let(:events) { [event_1, event_2] }

    it 'restricts based on common attributes between the metrics', :aggregate_failures do
      expect(selection.actions).to contain_exactly('action_1', 'action_2')
      expect(selection.events_name).to eq('any of 2 events')

      expect(selection.filter_name('user')).to eq('property/value')
      expect(selection.filter_name('value')).to eq('property')

      expect(selection.shared_filters).to contain_exactly('property')
      expect(selection.filter_options).to contain_exactly('property', 'value')
      expect(selection.shared_identifiers).to contain_exactly('user', 'namespace')
      expect(selection.uniqueness_options).to contain_exactly('user', 'namespace', 'property', nil)

      expect(selection.can_be_unique?('user')).to be(true)
      expect(selection.can_be_unique?('property')).to be(true)
      expect(selection.can_be_unique?('project')).to be(false)

      expect(selection.can_filter_when_unique?('value')).to be(false)
      expect(selection.can_filter_when_unique?('label')).to be(false)
      expect(selection.can_filter_when_unique?('property')).to be(true)
      expect(selection.can_filter_when_unique?('user')).to be(true)

      expect(selection.exclude_filter_identifier?('property')).to be(false)
      expect(selection.exclude_filter_identifier?('value')).to be(false)
      expect(selection.exclude_filter_identifier?('label')).to be(false)
      expect(selection.exclude_filter_identifier?('user')).to be(false)
      expect(selection.exclude_filter_identifier?(nil)).to be(false)
    end
  end

  context 'with even more events selected' do
    let(:events) { [event_1, event_2, event_3] }

    it 'restricts based on common attributes between the metrics', :aggregate_failures do
      expect(selection.actions).to contain_exactly('action_1', 'action_2', 'action_3')
      expect(selection.events_name).to eq('any of 3 events')

      expect(selection.filter_name('user')).to eq('property/value')
      expect(selection.filter_name('value')).to eq('property')

      expect(selection.shared_filters).to be_empty
      expect(selection.filter_options).to contain_exactly('property', 'value')
      expect(selection.shared_identifiers).to contain_exactly('user')
      expect(selection.uniqueness_options).to contain_exactly('user', nil)

      expect(selection.can_be_unique?('user')).to be(true)
      expect(selection.can_be_unique?('property')).to be(false)
      expect(selection.can_be_unique?('project')).to be(false)

      expect(selection.can_filter_when_unique?('value')).to be(false)
      expect(selection.can_filter_when_unique?('label')).to be(false)
      expect(selection.can_filter_when_unique?('property')).to be(false)
      expect(selection.can_filter_when_unique?('user')).to be(true)

      expect(selection.exclude_filter_identifier?('property')).to be(false)
      expect(selection.exclude_filter_identifier?('value')).to be(false)
      expect(selection.exclude_filter_identifier?('label')).to be(false)
      expect(selection.exclude_filter_identifier?('user')).to be(false)
    end
  end
end
