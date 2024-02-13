# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserStatusCleanup::BatchWorker, feature_category: :user_profile do
  it_behaves_like 'an idempotent worker' do
    subject do
      perform_multiple([], worker: described_class.new)
    end
  end

  describe '#perform' do
    subject(:run_worker) { described_class.new.perform }

    context 'when no records are scheduled for cleanup' do
      let(:user_status) { create(:user_status) }

      it 'does nothing' do
        expect { run_worker }.not_to change { user_status.reload }
      end
    end

    it 'cleans up the records' do
      user_status_1 = create(:user_status, clear_status_at: 1.year.ago)
      user_status_2 = create(:user_status, clear_status_at: 2.years.ago)

      run_worker

      deleted_statuses = UserStatus.where(user_id: [user_status_1.user_id, user_status_2.user_id])
      expect(deleted_statuses).to be_empty
    end
  end
end
