# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Postgresql::ReplicationSlot do
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
end
