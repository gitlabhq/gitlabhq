# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::EnqueueGroupMembersRefreshAuthorizedProjectsWorker, feature_category: :permissions do
  subject(:execute_worker) { described_class.new.perform(group_id, params) }

  let_it_be(:group) { create(:group) }

  let(:group_id) { group.id }
  let(:params) { {} }

  it 'has the `until_executed` deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
  end

  it 'has an option to reschedule once if deduplicated' do
    expect(described_class.get_deduplication_options).to include(
      { if_deduplicated: :reschedule_once, including_scheduled: true })
  end

  describe '#perform' do
    context 'when group exists' do
      before do
        allow(Group).to receive(:find_by_id).with(group.id).and_return(group)
      end

      context 'when the feature flag `do_not_run_safety_net_auth_refresh_jobs` is disabled' do
        before do
          stub_feature_flags(do_not_run_safety_net_auth_refresh_jobs: false)
        end

        it 'calls Group#refresh_members_authorized_projects' do
          expect(group).to receive(:refresh_members_authorized_projects).with(
            priority: UserProjectAccessChangedService::LOW_PRIORITY,
            direct_members_only: false
          )

          execute_worker
        end

        context 'with priority in params' do
          let(:params) { { 'priority' => UserProjectAccessChangedService::MEDIUM_PRIORITY.to_s } }

          it 'takes priority from params' do
            expect(group).to receive(:refresh_members_authorized_projects).with(
              priority: UserProjectAccessChangedService::MEDIUM_PRIORITY,
              direct_members_only: false
            )

            execute_worker
          end
        end

        context 'with direct_members_only in params' do
          let(:params) { { 'direct_members_only' => true } }

          it 'takes direct_members_only from params' do
            expect(group).to receive(:refresh_members_authorized_projects).with(
              priority: UserProjectAccessChangedService::LOW_PRIORITY,
              direct_members_only: true
            )

            execute_worker
          end
        end
      end

      context 'when the feature flag `do_not_run_safety_net_auth_refresh_jobs` is enabled' do
        before do
          stub_feature_flags(do_not_run_safety_net_auth_refresh_jobs: true)
        end

        it 'skips the safety net refresh when the priority is low' do
          expect(group).not_to receive(:refresh_members_authorized_projects)

          execute_worker
        end

        context 'with medium priority in params' do
          let(:params) do
            {
              'priority' => UserProjectAccessChangedService::MEDIUM_PRIORITY.to_s,
              'direct_members_only' => true
            }
          end

          it 'does not skip the refresh' do
            expect(group).to receive(:refresh_members_authorized_projects).with(
              priority: UserProjectAccessChangedService::MEDIUM_PRIORITY,
              direct_members_only: true
            )

            execute_worker
          end
        end
      end
    end

    context 'when group is not found' do
      let(:group_id) { non_existing_record_id }

      before do
        stub_feature_flags(do_not_run_safety_net_auth_refresh_jobs: false)
      end

      it 'does not raise errors' do
        expect { execute_worker }.not_to raise_error
      end
    end
  end
end
