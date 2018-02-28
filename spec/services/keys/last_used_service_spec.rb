require 'spec_helper'

describe Keys::LastUsedService do
  describe '#execute', :clean_gitlab_redis_shared_state do
    it 'updates the key when it has not been used recently' do
      key = create(:key, last_used_at: 1.year.ago)
      time = Time.zone.now

      Timecop.freeze(time) { described_class.new(key).execute }

      expect(key.last_used_at).to eq(time)
    end

    it 'does not update the key when it has been used recently' do
      time = 1.minute.ago
      key = create(:key, last_used_at: time)

      described_class.new(key).execute

      expect(key.last_used_at).to eq(time)
    end

    it 'does not update the updated_at field' do
      # Since a lot of these updates could happen in parallel for different keys
      # we want these updates to be as lightweight as possible, hence we want to
      # make sure we _only_ update last_used_at and not always updated_at.
      key = create(:key, last_used_at: 1.year.ago)

      expect { described_class.new(key).execute }.not_to change { key.updated_at }
    end
  end

  describe '#update?', :clean_gitlab_redis_shared_state do
    it 'returns true when no last used timestamp is present' do
      key = build(:key, last_used_at: nil)
      service = described_class.new(key)

      expect(service.update?).to eq(true)
    end

    it 'returns true when the key needs to be updated' do
      key = build(:key, last_used_at: 1.year.ago)
      service = described_class.new(key)

      expect(service.update?).to eq(true)
    end

    it 'returns false when a lease has already been obtained' do
      key = build(:key, last_used_at: 1.year.ago)
      service = described_class.new(key)

      expect(service.update?).to eq(true)
      expect(service.update?).to eq(false)
    end

    it 'returns false when the key does not yet need to be updated' do
      key = build(:key, last_used_at: 1.minute.ago)
      service = described_class.new(key)

      expect(service.update?).to eq(false)
    end
  end
end
