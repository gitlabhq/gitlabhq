# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::BaseCounter do
  describe '.fetch_supported_event' do
    subject { described_class.fetch_supported_event(event_name) }

    let(:event_name) { 'generic_event' }
    let(:prefix) { 'generic' }
    let(:known_events) { %w[event another_event] }

    before do
      allow(described_class).to receive(:prefix) { prefix }
      allow(described_class).to receive(:known_events) { known_events }
    end

    it 'returns the matching event' do
      is_expected.to eq 'event'
    end

    context 'when event is unknown' do
      let(:event_name) { 'generic_unknown_event' }

      it { is_expected.to be_nil }
    end

    context 'when prefix does not match the event name' do
      let(:prefix) { 'special' }

      it { is_expected.to be_nil }
    end
  end
end
