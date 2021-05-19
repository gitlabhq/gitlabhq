# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::UserRefreshOverUserRangeWorker do
  let(:project) { create(:project) }
  let(:user) { project.namespace.owner }
  let(:start_user_id) { user.id }
  let(:end_user_id) { start_user_id }
  let(:execute_worker) { subject.perform(start_user_id, end_user_id) }

  it_behaves_like 'worker with data consistency',
                  described_class,
                  feature_flag: :delayed_consistency_for_user_refresh_over_range_worker,
                  data_consistency: :delayed

  describe '#perform' do
    context 'when the feature flag `periodic_project_authorization_update_via_replica` is enabled' do
      before do
        stub_feature_flags(periodic_project_authorization_update_via_replica: true)
      end

      context 'checks if project authorization update is required' do
        it 'checks if a project_authorization refresh is needed for each of the users' do
          User.where(id: start_user_id..end_user_id).each do |user|
            expect(AuthorizedProjectUpdate::FindRecordsDueForRefreshService).to(
              receive(:new).with(user).and_call_original)
          end

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
      end

      context 'when there are no additions or removals to be made to project authorizations for a specific user' do
        it 'does not enqueue a new project authorization update job for the user' do
          expect(AuthorizedProjectUpdate::UserRefreshWithLowUrgencyWorker).not_to receive(:perform_async)

          execute_worker
        end
      end
    end

    context 'when the feature flag `periodic_project_authorization_update_via_replica` is disabled' do
      before do
        stub_feature_flags(periodic_project_authorization_update_via_replica: false)
      end

      it 'calls AuthorizedProjectUpdate::RecalculateForUserRangeService' do
        expect_next_instance_of(AuthorizedProjectUpdate::RecalculateForUserRangeService, start_user_id, end_user_id) do |service|
          expect(service).to receive(:execute)
        end

        execute_worker
      end
    end
  end
end
