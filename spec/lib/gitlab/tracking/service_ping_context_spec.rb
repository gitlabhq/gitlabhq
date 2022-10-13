# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::ServicePingContext do
  describe '#init' do
    it 'does not accept unsupported data sources' do
      expect { described_class.new(data_source: :random, event: 'event a') }.to raise_error(ArgumentError)
    end
  end

  describe '#to_context' do
    let(:subject) { described_class.new(data_source: :redis_hll, event: 'sample_event') }

    it 'contains event_name' do
      expect(subject.to_context.to_json.dig(:data, :event_name)).to eq('sample_event')
    end
  end
end
