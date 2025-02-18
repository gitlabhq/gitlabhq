# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::PruneDeletionsWorker, :saas, feature_category: :seat_cost_management do
  let(:worker) { described_class.new }

  describe '#perform_work' do
    subject(:perform_work) { worker.perform_work }

    before do
      stub_feature_flags(limited_capacity_member_destruction: true)
    end

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
            create_list(:members_deletion_schedules, 10)

            expect { perform_work }.to change { Members::DeletionSchedule.count }.from(11).to(6)
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
              destroy_duration_s: an_instance_of(Float)
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

    context 'with limited_capacity_member_destruction disabled' do
      before do
        stub_feature_flags(limited_capacity_member_destruction: false)
      end

      it { is_expected.to eq 0 }
    end
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

    context 'with limited_capacity_member_destruction disabled' do
      before do
        create(:members_deletion_schedules)

        stub_feature_flags(limited_capacity_member_destruction: false)
      end

      it { is_expected.to eq 0 }
    end
  end
end
