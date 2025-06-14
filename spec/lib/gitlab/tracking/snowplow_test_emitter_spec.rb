# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::SnowplowTestEmitter, feature_category: :service_ping do
  describe '#send_requests' do
    it 'returns the number of events' do
      emitter = described_class.new(endpoint: 'test')
      events = [{}, {}]

      expect(emitter.send_requests(events)).to eq(2)
    end
  end
end
