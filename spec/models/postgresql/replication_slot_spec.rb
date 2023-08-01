# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Postgresql::ReplicationSlot do
  it { is_expected.to be_a Gitlab::Database::SharedModel }

  describe '.in_use?' do
    it 'returns true when replication slots are present' do
      expect(described_class).to receive(:exists?).and_return(true)
      expect(described_class.in_use?).to be_truthy
    end

    it 'returns false when replication slots are not present' do
      expect(described_class.in_use?).to be_falsey
    end

    it 'returns false if the existence check is invalid' do
      expect(described_class).to receive(:exists?).and_raise(ActiveRecord::StatementInvalid.new('PG::FeatureNotSupported'))
      expect(described_class.in_use?).to be_falsey
    end
  end

  describe '.lag_too_great?' do
    before do
      expect(described_class).to receive(:in_use?).and_return(true)
    end

    it 'does not raise an exception' do
      expect { described_class.lag_too_great? }.not_to raise_error
    end

    it 'returns true when replication lag is too great' do
      expect(described_class)
        .to receive(:pluck)
        .and_return([125.megabytes])

      expect(described_class.lag_too_great?).to eq(true)
    end

    it 'returns false when more than one replicas is up to date enough' do
      expect(described_class)
        .to receive(:pluck)
        .and_return([125.megabytes, 0.megabytes, 0.megabytes])

      expect(described_class.lag_too_great?).to eq(false)
    end

    it 'returns false when replication lag is not too great' do
      expect(described_class)
        .to receive(:pluck)
        .and_return([0.megabytes])

      expect(described_class.lag_too_great?).to eq(false)
    end

    it 'returns false when there is a nil replication lag' do
      expect(described_class)
        .to receive(:pluck)
        .and_return([0.megabytes, nil])

      expect(described_class.lag_too_great?).to eq(false)
    end
  end

  describe '#max_replication_slots' do
    it 'returns the maximum number of replication slots' do
      expect(described_class.max_replication_slots).to be >= 0
    end
  end

  context 'with enough slots available' do
    skip_examples = described_class.max_replication_slots <= described_class.count

    before_all do
      skip('max_replication_slots too small') if skip_examples

      @current_slot_count = described_class
        .connection
        .select_value("SELECT COUNT(*) FROM pg_replication_slots")

      @current_unused_count = described_class
        .connection
        .select_value("SELECT COUNT(*) FROM pg_replication_slots WHERE active = 'f';")

      described_class
        .connection
        .execute("SELECT * FROM pg_create_physical_replication_slot('test_slot');")
    end

    after(:all) do
      unless skip_examples
        described_class
          .connection
          .execute("SELECT pg_drop_replication_slot('test_slot');")
      end
    end

    describe '#slots_count' do
      it 'returns the number of replication slots' do
        expect(described_class.count).to eq(@current_slot_count + 1)
      end
    end

    describe '#unused_slots_count' do
      it 'returns the number of unused replication slots' do
        expect(described_class.unused_slots_count).to eq(@current_unused_count + 1)
      end
    end

    describe '#max_retained_wal' do
      it 'returns the retained WAL size' do
        expect(described_class.max_retained_wal).not_to be_nil
      end
    end

    describe '#slots_retained_bytes' do
      it 'returns the number of retained bytes' do
        slot = described_class.slots_retained_bytes.find { |x| x['slot_name'] == 'test_slot' }

        expect(slot).not_to be_nil
        expect(slot['retained_bytes']).to be_nil
      end
    end
  end
end
