require 'spec_helper'

describe Gitlab::Geo::LogCursor::Events, lib: true do
  describe '.fetch_in_batches' do
    let!(:event_log_1) { create(:geo_event_log) }
    let!(:event_log_2) { create(:geo_event_log) }

    context 'when no event_log_state exist' do
      it 'does not yield a group of events' do
        expect { |b| described_class.fetch_in_batches(&b) }.not_to yield_with_args([event_log_1, event_log_2])
      end
    end

    context 'when there is already an event_log_state' do
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log_1.id - 1) }

      it 'yields a group of events' do
        expect { |b| described_class.fetch_in_batches(&b) }.to yield_with_args([event_log_1, event_log_2])
      end

      it 'saves last event as last processed after yielding' do
        described_class.fetch_in_batches { |batch| batch }

        expect(Geo::EventLogState.last.event_id).to eq(event_log_2.id)
      end
    end

    it 'skips execution if cannot achieve a lease' do
      expect_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain) { }

      expect { |b| described_class.fetch_in_batches(&b) }.not_to yield_control
    end
  end

  describe '.save_processed' do
    it 'creates a new event_log_state when no event_log_state exist' do
      expect { described_class.save_processed(1) }.to change(Geo::EventLogState, :count).by(1)
      expect(Geo::EventLogState.last.event_id).to eq(1)
    end

    it 'updates the event_id when there is already an event_log_state' do
      create(:geo_event_log_state)

      expect { described_class.save_processed(2) }.not_to change(Geo::EventLogState, :count)
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

      it 'saves last event as the last processed' do
        expect { described_class.last_processed }.to change(Geo::EventLogState, :count).by(1)
        expect(Geo::EventLogState.last.event_id).to eq(event_log.id)
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
