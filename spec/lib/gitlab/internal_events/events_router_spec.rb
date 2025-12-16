# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::InternalEvents::EventsRouter, feature_category: :product_analytics do
  let(:event_name) { 'test_event' }
  let(:additional_properties) { { foo: 'bar', baz: 'qux', public1: 1, public2: 2 } }
  let(:kwargs) { { extra: 'value' } }
  let(:event_definition) { instance_double(Gitlab::Tracking::EventDefinition) }

  subject(:router) { described_class.new(event_name, additional_properties, kwargs) }

  before do
    allow(Gitlab::Tracking::EventDefinition).to receive(:find).with(event_name).and_return(event_definition)
  end

  describe '#public_additional_properties' do
    before do
      allow(event_definition).to receive(:additional_properties).and_return({ public1: {}, public2: {} })
    end

    it 'returns only public additional properties' do
      expect(router.public_additional_properties).to eq({ public1: 1, public2: 2 })
    end
  end

  describe '#event_definition' do
    it 'returns the event definition for the event name' do
      expect(router.event_definition).to eq(event_definition)
    end
  end

  describe '#extra_tracking_data' do
    let(:properties) { { protected_properties: [:foo, :baz] } }

    before do
      allow(event_definition).to receive(:additional_properties).and_return({ public1: {}, public2: {} })
      allow(router).to receive(:public_additional_properties).and_return({ public1: 1, public2: 2 })
    end

    it 'merges extra properties, public properties, and kwargs' do
      expect(router.extra_tracking_data(properties)).to eq({
        foo: 'bar',
        baz: 'qux',
        public1: 1,
        public2: 2,
        extra: 'value'
      })
    end
  end
end
