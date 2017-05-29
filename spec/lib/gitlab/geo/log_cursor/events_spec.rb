require 'spec_helper'

describe Gitlab::Geo::LogCursor::Events, lib: true do
  describe '.fetch_in_batches' do
    let!(:event_log) { create(:geo_event_log) }

    before do
      allow(described_class).to receive(:last_processed) { -1 }
    end

    it 'yields a group of events' do
      expect { |b| described_class.fetch_in_batches(&b) }.to yield_with_args([event_log])
    end

    it 'saves processed files after yielding' do
      expect(described_class).to receive(:save_processed)

      described_class.fetch_in_batches { |batch| batch }
    end
  end

  describe '.save_processed' do
    it 'saves a new entry in geo_event_log_state' do
      expect { described_class.save_processed(1) }.to change(Geo::EventLogState, :count).by(1)
      expect(Geo::EventLogState.last.event_id).to eq(1)
    end

    it 'removes older entries from geo_event_log_state' do
      create(:geo_event_log_state)

      expect { described_class.save_processed(2) }.to change(Geo::EventLogState, :count).by(0)
      expect(Geo::EventLogState.last.event_id).to eq(2)
    end
  end

  describe '.last_processed' do
    context 'when system has not generated any event yet' do
      it 'returns -1' do
        expect(described_class.last_processed).to eq(-1)
      end
    end

    context 'when there are existing events already but no event_log_state' do
      let!(:event_log) { create(:geo_event_log) }

      it 'returns last event id' do
        expect(described_class.last_processed).to eq(event_log.id)
      end
    end

    context 'when there is already an event_log_state' do
      let!(:event_log_state) { create(:geo_event_log_state) }

      it 'returns last event from event_log_state' do
        expect(described_class.last_processed).to eq(event_log_state.id)
      end
    end
  end
end
