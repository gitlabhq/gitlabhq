# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::InternalEvents::EventDefinitions, feature_category: :product_analytics_data_management do
  after(:all) do
    described_class.instance_variable_set(:@events, nil)
  end

  context 'when using actual metric definitions' do
    it 'they can load' do
      expect { described_class.load_configurations }.not_to raise_error
    end
  end

  context 'when using mock data' do
    let(:definition1) { instance_double(Gitlab::Usage::MetricDefinition) }
    let(:definition2) { instance_double(Gitlab::Usage::MetricDefinition) }
    let(:events1) { { 'event1' => nil } }
    let(:events2) { { 'event2' => nil } }

    before do
      allow(Gitlab::Usage::MetricDefinition).to receive(:metric_definitions_changed?).and_return(true)
      allow(Gitlab::Usage::MetricDefinition).to receive(:all).and_return([definition1, definition2])
      allow(definition1).to receive(:available?).and_return(true)
      allow(definition2).to receive(:available?).and_return(true)
      allow(definition1).to receive(:events).and_return(events1)
      allow(definition2).to receive(:events).and_return(events2)
    end

    describe ".unique_property" do
      context 'when event has valid unique value with a period', :aggregate_failures do
        let(:events1) { { 'event1' => :'user.id' } }
        let(:events2) { { 'event2' => :'project.id' } }

        it 'is returned' do
          expect(described_class.unique_property('event1')).to eq(:user)
          expect(described_class.unique_property('event2')).to eq(:project)
        end
      end

      context 'when event has no periods in unique property', :aggregate_failures do
        let(:events1) { { 'event1' => :plan_id } }

        it 'fails' do
          expect { described_class.unique_property('event1') }
            .to raise_error(described_class::InvalidMetricConfiguration, /Invalid unique value/)
        end
      end

      context 'when event has more than one period in unique property' do
        let(:events1) { { 'event1' => :'project.namespace.id' } }

        it 'fails' do
          expect { described_class.unique_property('event1') }
            .to raise_error(described_class::InvalidMetricConfiguration, /Invalid unique value/)
        end
      end

      context 'when event does not have unique property' do
        it 'unique fails' do
          expect { described_class.unique_property('event1') }
            .to raise_error(described_class::InvalidMetricConfiguration, /Unique property not defined for/)
        end
      end
    end

    describe ".load_configurations" do
      context 'when unique property for event is ambiguous' do
        let(:events1) { { 'event1' => :user_id } }
        let(:events2) { { 'event1' => :project_id } }

        it 'logs error when loading' do
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
            .with(described_class::InvalidMetricConfiguration)

          described_class.load_configurations
        end
      end
    end

    describe ".known_events" do
      it 'has known events', :aggregate_failures do
        expect(described_class.known_event?('event1')).to be_truthy
        expect(described_class.known_event?('event2')).to be_truthy
        expect(described_class.known_event?('event3')).to be_falsy
      end

      context 'when a metric fails to load' do
        before do
          allow(definition1).to receive(:available?).and_raise(ArgumentError)
        end

        it 'loads the healthy metrics', :aggregate_failures do
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).at_least(:once)
          expect(described_class.known_event?('event1')).to be_falsy
          expect(described_class.known_event?('event2')).to be_truthy
        end
      end
    end
  end
end
