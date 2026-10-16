# frozen_string_literal: true

# Covers the behavior of Database::SyncEventTable. The including spec passes
# the factory whose creation produces one sync event per record.
RSpec.shared_examples 'a database sync event table' do |factory|
  describe '.unprocessed_events_for' do
    it 'returns only events not yet synced to the given consumer' do
      create_list(factory, 2)
      synced = described_class.first
      synced.update_column(:ci_synced, true)

      expect(described_class.unprocessed_events_for(:ci)).not_to include(synced)
      expect(described_class.unprocessed_events_for(:ci).count).to eq(1)
      expect(described_class.unprocessed_events_for(:sec).count).to eq(2)
    end
  end

  describe '.mark_records_processed' do
    let!(:records) { create_list(factory, 3) }

    let!(:events) { described_class.order_by_id_asc.to_a }

    it 'marks only the given records for the given consumer' do
      described_class.mark_records_processed(events.first(2), :ci)

      expect(described_class.where(ci_synced: true)).to match_array(events.first(2))
      expect(described_class.where(sec_synced: true)).to be_empty
    end

    it 'does not delete any events' do
      expect { described_class.mark_records_processed(events, :ci) }.not_to change { described_class.count }
    end
  end

  describe '.synced_conditions' do
    it 'requires every consumer column' do
      expect(described_class.synced_conditions).to eq(ci_synced: true, sec_synced: true)
    end

    context 'when the sync_sec_mirror_tables feature flag is disabled' do
      before do
        stub_feature_flags(sync_sec_mirror_tables: false)
      end

      it 'requires only the ci column' do
        expect(described_class.synced_conditions).to eq(ci_synced: true)
      end
    end
  end

  describe '.upper_bound_count' do
    it 'returns 0 when there are no records in the table' do
      expect(described_class.upper_bound_count(:ci)).to eq(0)
    end

    it 'returns an estimated number of unprocessed records for the given consumer' do
      create_list(factory, 3)
      described_class.order_by_id_asc.first.update_column(:ci_synced, true)

      expect(described_class.upper_bound_count(:ci)).to eq(2)
      expect(described_class.upper_bound_count(:sec)).to eq(3)
    end
  end
end
