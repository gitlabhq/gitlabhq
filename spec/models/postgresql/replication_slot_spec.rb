# frozen_string_literal: true

require 'spec_helper'

describe Postgresql::ReplicationSlot, :postgresql do
  describe '.lag_too_great?' do
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
  end
end
