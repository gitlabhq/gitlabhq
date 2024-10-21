# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::InternalEvents::EventDefinitions, feature_category: :product_analytics do
  around do |example|
    described_class.instance_variable_set(:@events, nil)
    example.run
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
      allow(Gitlab::Usage::MetricDefinition).to receive(:all).and_return([definition1, definition2])
      allow(definition1).to receive(:available?).and_return(true)
      allow(definition2).to receive(:available?).and_return(true)
      allow(definition1).to receive(:events).and_return(events1)
      allow(definition2).to receive(:events).and_return(events2)
    end

    describe ".unique_properties" do
      context 'when event has valid unique value with a period', :aggregate_failures do
        let(:events1) { { 'event1' => :'user.id' } }
        let(:events2) { { 'event2' => :'project.id' } }

        it 'is returned' do
          expect(described_class.unique_properties('event1')).to eq([:user])
          expect(described_class.unique_properties('event2')).to eq([:project])
        end
      end

      context 'when event has no periods in unique property' do
        let(:events1) { { 'event1' => :user_id } }

        it 'fails' do
          expect { described_class.unique_properties('event1') }
            .to raise_error(described_class::InvalidMetricConfiguration, /Invalid unique value/)
        end
      end

      context 'when event has more than one period in unique property' do
        let(:events1) { { 'event1' => :'project.namespace.id' } }

        it 'fails' do
          expect { described_class.unique_properties('event1') }
            .to raise_error(described_class::InvalidMetricConfiguration, /Invalid unique value/)
        end
      end

      context 'when event does not have unique property' do
        it 'returns an empty array' do
          expect(described_class.unique_properties('event1')).to eq([])
        end
      end

      context 'when an event has multiple unique properties' do
        let(:events1) { { 'event1' => :'user.id' } }
        let(:events2) { { 'event1' => :'project.id' } }

        it "returns all the properties" do
          expect(described_class.unique_properties('event1')).to match_array([:user, :project])
        end
      end

      context 'when an event has nil property' do
        let(:events1) { { 'event1' => :'user.id' } }
        let(:events2) { { 'event1' => nil } }

        it "ignores the nil property" do
          expect(described_class.unique_properties('event1')).to eq([:user])
        end
      end
    end

    describe ".load_configurations" do
      it 'raises no errors' do
        described_class.load_configurations
      end
    end
  end
end
