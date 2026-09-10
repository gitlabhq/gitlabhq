# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::PruneDeletionsWorker, :saas, feature_category: :seat_cost_management do
  let(:worker) { described_class.new }

  describe '#perform_work' do
    subject(:perform_work) { worker.perform_work }

    context 'with Members::DeletionSchedule records' do
      let_it_be(:group) { create(:group) }
      let_it_be(:owner) { create(:user) }
      let_it_be(:user) { create(:user) }

      before_all do
        group.add_owner(owner)
        group.add_developer(user)

        create(:members_deletion_schedules, user: user, namespace: group, scheduled_by: owner)
      end

      it_behaves_like 'an idempotent worker' do
        it 'destroys member records' do
          expect do
            perform_work
          end.to change { group.members.count }.from(2).to(1)
        end

        context 'with many deletion schedules' do
          it 'prunes schedules in batches' do
            stub_const "Members::PruneDeletionsWorker::SCHEDULE_BATCH_SIZE", 5
            create_list(:members_deletion_schedules, 5)

            expect { perform_work }.to change { Members::DeletionSchedule.count }.from(6).to(1)
          end
        end

        context 'with batches of memberships to destroy' do
          before do
            stub_const "Members::PruneDeletionsWorker::MEMBER_BATCH_SIZE", 1
            create(:group, parent: group, owners: user)
          end

          it 'limits how many members are deleted per worker' do
            expect(::Members::DestroyService).to receive(:new).exactly(1).time.and_call_original

            perform_work
          end

          it 'logs monitoring data' do
            allow(Gitlab::AppLogger).to receive(:info)

            expect(Gitlab::AppLogger).to receive(:info).with(
              message: 'Processed scheduled member deletion',
              user_id: user.id,
              namespace_id: group.id,
              destroyed_count: 1,
              destroy_duration_s: an_instance_of(Float),
              single_authorized_projects_refresh: true
            )

            perform_work
          end
        end

        context 'when all matching member records are removed' do
          let_it_be(:project) { create(:project, group: group) }

          before_all do
            project.add_developer(user)
          end

          it 'removes the Members::DeletionSchedule record' do
            expect do
              perform_work
            end.to change { group.members.count }.from(2).to(1)
              .and change { project.members.count }.from(1).to(0)
              .and change { Members::DeletionSchedule.count }.from(1).to(0)
          end
        end

        context 'when deletion takes too long' do
          before do
            allow_next_instance_of(Gitlab::Utils::ExecutionTracker) do |instance|
              allow(instance).to receive(:over_limit?).and_return(true)
            end
          end

          it 'returns early' do
            expect(::Members::DestroyService).not_to receive(:new)
            expect(UserProjectAccessChangedService).not_to receive(:new)

            perform_work
          end
        end
      end

      describe 'authorized projects refresh' do
        let_it_be(:subgroup) { create(:group, parent: group) }
        let_it_be(:project) { create(:project, group: subgroup) }

        before_all do
          subgroup.add_maintainer(user)
          # a project role below the inherited maintainer role would fail validation
          project.add_owner(user)
        end

        # The user has two group memberships and one project membership.
        # Flag enabled: the worker asks for one batch refresh, UserProjectAccessChangedService.new(user.id).execute at
        # MEDIUM_PRIORITY, which schedules UserRefreshWithLowUrgencyWorker a minute out.
        # Flag disabled: every destroyed membership refreshes on its own. StubbedMember runs those inline, so they
        # appear as AuthorizedProjectsWorker.new per group membership, ProjectRecalculatePerUserWorker.new per project
        # membership, plus one low priority safety-net request through UserProjectAccessChangedService.
        it 'refreshes once for the whole batch instead of once per destroyed membership' do
          expect_next_instances_of(UserProjectAccessChangedService, 1, false, user.id) do |service|
            expect(service).to receive(:execute)
              .with(priority: UserProjectAccessChangedService::MEDIUM_PRIORITY).and_call_original
          end

          expect(AuthorizedProjectsWorker).not_to receive(:new)
          expect(AuthorizedProjectUpdate::ProjectRecalculatePerUserWorker).not_to receive(:new)

          expect { perform_work }.to change { Member.with_user(user).count }.from(3).to(0)
        end

        it 'reads the feature flag once per schedule so a flip mid-batch cannot skip the refresh' do
          allow(Feature).to receive(:enabled?).and_call_original
          expect(Feature).to receive(:enabled?)
            .with(:member_prune_deletion_per_batch_authorized_projects_refresh, group).once.and_call_original

          perform_work
        end

        it 'removes the authorizations of the pruned memberships', :sidekiq_inline do
          expect(user.authorized_projects).to include(project)

          perform_work

          expect(user.authorized_projects).not_to include(project)
        end

        context 'when the memberships span several batches' do
          before do
            stub_const "Members::PruneDeletionsWorker::MEMBER_BATCH_SIZE", 2
          end

          it 'refreshes once per batch' do
            allow(UserProjectAccessChangedService).to receive(:new).and_call_original

            # each job in the chain is a new worker instance, like the re-enqueued jobs in production
            expect { described_class.new.perform_work }
              .to change { Member.with_user(user).count }.from(3).to(1)
              .and not_change { Members::DeletionSchedule.count }
            expect(UserProjectAccessChangedService).to have_received(:new).with(user.id).once

            expect { described_class.new.perform_work }
              .to change { Member.with_user(user).count }.from(1).to(0)
              .and change { Members::DeletionSchedule.count }.by(-1)
            expect(UserProjectAccessChangedService).to have_received(:new).with(user.id).twice
          end
        end

        context 'when the time limit stops the batch early' do
          before do
            allow_next_instance_of(Gitlab::Utils::ExecutionTracker) do |instance|
              allow(instance).to receive(:over_limit?).and_return(false, true)
            end
          end

          it 'still refreshes once for the memberships it destroyed' do
            expect(UserProjectAccessChangedService).to receive(:new).with(user.id).once.and_call_original

            expect { perform_work }.to change { Member.with_user(user).count }.by(-1)
              .and not_change { Members::DeletionSchedule.count }
          end
        end

        context 'when the user has no memberships left' do
          let_it_be(:other_user) { create(:user) }

          before do
            create(:members_deletion_schedules, user: other_user, namespace: group, scheduled_by: owner)
          end

          it 'removes the schedule and still refreshes, recovering a job killed after its last destroy' do
            allow(UserProjectAccessChangedService).to receive(:new).and_call_original
            expect(UserProjectAccessChangedService).to receive(:new).with(other_user.id).once.and_call_original

            expect { perform_work }.to change { Members::DeletionSchedule.exists_for?(group, other_user) }.to(false)
          end
        end

        context 'when the member_prune_deletion_per_batch_authorized_projects_refresh flag is disabled' do
          before do
            stub_feature_flags(member_prune_deletion_per_batch_authorized_projects_refresh: false)
          end

          it 'refreshes after each destroyed membership instead' do
            expect(AuthorizedProjectsWorker).to receive(:new).twice.and_call_original
            expect(AuthorizedProjectUpdate::ProjectRecalculatePerUserWorker).to receive(:new).once.and_call_original
            # the project membership's safety net is the only refresh request; there is no batch refresh
            expect_next_instance_of(UserProjectAccessChangedService, user.id) do |service|
              expect(service).to receive(:execute)
                .with(priority: UserProjectAccessChangedService::LOW_PRIORITY).and_call_original
            end

            perform_work
          end

          it 'logs that the batch refresh was not used' do
            allow(Gitlab::AppLogger).to receive(:info)
            expect(Gitlab::AppLogger).to receive(:info).with(hash_including(single_authorized_projects_refresh: false))

            perform_work
          end
        end
      end
    end

    context 'with no Members::DeletionSchedule records' do
      it 'returns early' do
        expect(::Members::DestroyService).not_to receive(:new)

        perform_work
      end
    end

    context 'when the scheduler does not have permission to remove the user' do
      before do
        group = create(:group)
        user = create(:user)
        other_user = create(:user)
        group.add_owner(user)

        create(:members_deletion_schedules, user: user, namespace: group, scheduled_by: other_user)
      end

      it 'deletes the schedule and does not remove the user' do
        expect do
          perform_work
        end.to change { Members::DeletionSchedule.count }.from(1).to(0)
          .and not_change { GroupMember.count }
      end
    end
  end

  describe '#max_running_jobs' do
    subject { worker.max_running_jobs }

    it { is_expected.to eq(described_class::MAX_RUNNING_JOBS) }
  end

  describe '#remaining_work_count' do
    let_it_be(:deletion_schedules) do
      create_list(:members_deletion_schedules, 2)
    end

    subject(:remaining_work_count) { worker.remaining_work_count }

    context 'when there is remaining work' do
      it { is_expected.to eq(described_class::MAX_RUNNING_JOBS + 1) }
    end

    context 'when there is no remaining work' do
      before do
        Members::DeletionSchedule.delete_all
      end

      it { is_expected.to eq(0) }
    end
  end
end
