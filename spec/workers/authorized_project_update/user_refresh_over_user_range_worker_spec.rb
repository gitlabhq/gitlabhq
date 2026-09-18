# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::UserRefreshOverUserRangeWorker, feature_category: :permissions do
  subject(:execute_worker) { described_class.new.perform(start_user_id, end_user_id) }

  let_it_be(:project) { create(:project) }

  let(:user) { project.namespace.owner }
  let(:start_user_id) { user.id }
  let(:end_user_id) { start_user_id }

  before do
    stub_feature_flags(do_not_run_safety_net_auth_refresh_jobs: false)
  end

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :delayed

  describe '#perform' do
    context 'when the feature flag `do_not_run_safety_net_auth_refresh_jobs` is disabled' do
      it 'runs the safety net refresh' do
        User.where(id: start_user_id..end_user_id).find_each do |user|
          expect(AuthorizedProjectUpdate::FindRecordsDueForRefreshService).to(
            receive(:new).with(user).and_call_original)
        end

        execute_worker
      end
    end

    context 'when the feature flag `do_not_run_safety_net_auth_refresh_jobs` is enabled' do
      before do
        stub_feature_flags(do_not_run_safety_net_auth_refresh_jobs: true)
      end

      it 'skips the safety net refresh' do
        expect(AuthorizedProjectUpdate::FindRecordsDueForRefreshService).not_to receive(:new)

        execute_worker
      end
    end

    context 'when there are project authorization records due for either removal or addition for a specific user' do
      before do
        user.project_authorizations.delete_all
      end

      it 'enqueues a new project authorization update job for the user' do
        expect(AuthorizedProjectUpdate::UserRefreshWithLowUrgencyWorker).to receive(:perform_async).with(user.id)

        execute_worker
      end

      it 'sets its own class as related_class so the refresh is attributed to the periodic sweep' do
        execute_worker

        expect(AuthorizedProjectUpdate::UserRefreshWithLowUrgencyWorker.jobs).to all(
          include(Labkit::Context.log_key(:related_class) => described_class.name)
        )
      end

      it 'tags the job with the safety-net refresh purpose' do
        execute_worker

        expect(AuthorizedProjectUpdate::UserRefreshWithLowUrgencyWorker.jobs).to all(
          include(
            Labkit::Context.log_key(:authorized_projects_refresh_purpose) =>
              UserProjectAccessChangedService::SAFETY_NET_REFRESH_PURPOSE
          )
        )
      end
    end

    context 'when there are no additions or removals to be made to project authorizations for a specific user' do
      it 'does not enqueue a new project authorization update job for the user' do
        expect(AuthorizedProjectUpdate::UserRefreshWithLowUrgencyWorker).not_to receive(:perform_async)

        execute_worker
      end
    end
  end
end
