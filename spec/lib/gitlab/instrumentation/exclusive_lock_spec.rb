# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Instrumentation::ExclusiveLock, :request_store, feature_category: :scalability do
  describe '.requested_count' do
    it 'returns the value from Gitlab::SafeRequestStore' do
      allow(Gitlab::SafeRequestStore).to receive(:[]).with(:exclusive_lock_requested_count).and_return(5)

      expect(described_class.requested_count).to eq(5)
    end

    it 'returns 0 if value not set in Gitlab::SafeRequestStore' do
      allow(Gitlab::SafeRequestStore).to receive(:[]).with(:exclusive_lock_requested_count).and_return(nil)

      expect(described_class.requested_count).to eq(0)
    end
  end

  describe '.increment_requested_count' do
    it 'increments the lock count' do
      expect { described_class.increment_requested_count }
        .to change { described_class.requested_count }.from(0).to(1)
    end
  end

  describe '.wait_duration' do
    it 'returns the value from Gitlab::SafeRequestStore' do
      allow(Gitlab::SafeRequestStore).to receive(:[]).with(:exclusive_lock_wait_duration_s).and_return(5)

      expect(described_class.wait_duration).to eq(5)
    end

    it 'returns 0 if value not set in Gitlab::SafeRequestStore' do
      allow(Gitlab::SafeRequestStore).to receive(:[]).with(:exclusive_lock_wait_duration_s).and_return(nil)

      expect(described_class.wait_duration).to eq(0)
    end
  end

  describe '.add_wait_duration' do
    it 'increments the duration' do
      expect { described_class.add_wait_duration(5) }
        .to change { described_class.wait_duration }.from(0).to(5)
    end
  end

  describe '.hold_duration' do
    it 'returns the value from Gitlab::SafeRequestStore' do
      allow(Gitlab::SafeRequestStore).to receive(:[]).with(:exclusive_lock_hold_duration_s).and_return(5)

      expect(described_class.hold_duration).to eq(5)
    end

    it 'returns 0 if value not set in Gitlab::SafeRequestStore' do
      allow(Gitlab::SafeRequestStore).to receive(:[]).with(:exclusive_lock_hold_duration_s).and_return(nil)

      expect(described_class.hold_duration).to eq(0)
    end
  end

  describe '.add_hold_duration' do
    it 'increments the duration' do
      expect { described_class.add_hold_duration(5) }
          .to change { described_class.hold_duration }.from(0).to(5)
    end
  end

  describe '.payload' do
    it 'returns a hash with metrics' do
      described_class.increment_requested_count
      described_class.add_wait_duration(2)
      described_class.add_hold_duration(3)

      expect(described_class.payload).to eq({
        exclusive_lock_requested_count: 1,
        exclusive_lock_wait_duration_s: 2,
        exclusive_lock_hold_duration_s: 3
      })
    end
  end
end
