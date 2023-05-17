# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Keys::LastUsedService, feature_category: :source_code_management do
  describe '#execute', :clean_gitlab_redis_shared_state do
    context 'when it has not been used recently' do
      let(:key) { create(:key, last_used_at: 1.year.ago) }
      let(:time) { Time.zone.now }

      it 'updates the key' do
        travel_to(time) { described_class.new(key).execute }

        expect(key.reload.last_used_at).to be_like_time(time)
      end
    end

    context 'when it has been used recently' do
      let(:time) { 1.minute.ago }
      let(:key) { create(:key, last_used_at: time) }

      it 'does not update the key' do
        described_class.new(key).execute

        expect(key.reload.last_used_at).to be_like_time(time)
      end
    end
  end

  describe '#execute_async', :clean_gitlab_redis_shared_state do
    context 'when it has not been used recently' do
      let(:key) { create(:key, last_used_at: 1.year.ago) }
      let(:time) { Time.zone.now }

      it 'schedules a job to update last_used_at' do
        expect(::SshKeys::UpdateLastUsedAtWorker).to receive(:perform_async)

        travel_to(time) { described_class.new(key).execute_async }
      end
    end

    context 'when it has been used recently' do
      let(:key) { create(:key, last_used_at: 1.minute.ago) }

      it 'does not schedule a job to update last_used_at' do
        expect(::SshKeys::UpdateLastUsedAtWorker).not_to receive(:perform_async)

        described_class.new(key).execute_async
      end
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

    it 'returns false when the key does not yet need to be updated' do
      key = build(:key, last_used_at: 1.minute.ago)
      service = described_class.new(key)

      expect(service.update?).to eq(false)
    end
  end
end
