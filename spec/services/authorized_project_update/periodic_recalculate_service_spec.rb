# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::PeriodicRecalculateService, feature_category: :groups_and_projects do
  subject(:service) { described_class.new }

  describe '#execute' do
    let(:batch_size) { 2 }

    let_it_be(:users) { create_list(:user, 6) }

    before do
      stub_const('AuthorizedProjectUpdate::PeriodicRecalculateService::BATCH_SIZE', batch_size)

      User.delete([users[1], users[2]])
    end

    it 'enqueues a job per batch with correct delay and ID range' do
      remaining_users = User.order(:id).pluck(:id)
      expected_batches = remaining_users.each_slice(batch_size).map(&:minmax)

      expected_batches.each_with_index do |batch, i|
        index = i + 1
        delay = described_class::DELAY_INTERVAL * index

        expect(AuthorizedProjectUpdate::UserRefreshOverUserRangeWorker).to(
          receive(:perform_in).with(delay, batch.first, batch.last))
      end

      service.execute
    end

    it 'enqueues jobs proportional to user count, not ID range' do
      remaining_user_count = User.count
      expected_batch_count = (remaining_user_count.to_f / batch_size).ceil

      expect(AuthorizedProjectUpdate::UserRefreshOverUserRangeWorker).to(
        receive(:perform_in).exactly(expected_batch_count).times)

      service.execute
    end

    context 'with large gaps in user IDs' do
      let!(:user_with_large_id) { create(:user, id: 1_000_000_000) }

      it 'does not create excessive jobs' do
        user_count = User.count
        expected_batch_count = (user_count.to_f / batch_size).ceil

        expect(AuthorizedProjectUpdate::UserRefreshOverUserRangeWorker).to(
          receive(:perform_in).exactly(expected_batch_count).times)

        service.execute
      end
    end
  end
end
