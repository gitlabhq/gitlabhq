# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoveExpiredMembersWorker, feature_category: :system_access do
  let(:worker) { described_class.new }

  describe '#perform' do
    context 'project members' do
      let_it_be(:expired_project_member) { create(:project_member, expires_at: 1.day.from_now, access_level: GroupMember::DEVELOPER) }
      let_it_be(:project_member_expiring_in_future) { create(:project_member, expires_at: 10.days.from_now, access_level: GroupMember::DEVELOPER) }
      let_it_be(:non_expiring_project_member) { create(:project_member, expires_at: nil, access_level: GroupMember::DEVELOPER) }

      before do
        travel_to(3.days.from_now)
      end

      it 'removes expired members' do
        expect { worker.perform }.to change { Member.count }.by(-1)
        expect(Member.find_by(id: expired_project_member.id)).to be_nil
      end

      it 'leaves members that expire in the future' do
        worker.perform
        expect(project_member_expiring_in_future.reload).to be_present
      end

      it 'leaves members that do not expire at all' do
        worker.perform
        expect(non_expiring_project_member.reload).to be_present
      end

      it 'adds context to resulting jobs' do
        worker.perform

        new_job = Sidekiq::Worker.jobs.last

        expect(new_job).to include(
          'meta.project' => expired_project_member.project.full_path,
          'meta.user' => expired_project_member.user.username
        )
      end
    end

    context 'project bots' do
      let(:project) { create(:project) }

      context 'expired project bot', :sidekiq_inline do
        let_it_be(:expired_project_bot) { create(:user, :project_bot) }

        before do
          project.add_member(expired_project_bot, :maintainer, expires_at: 1.day.from_now)
          travel_to(3.days.from_now)
        end

        it 'removes expired project bot membership' do
          expect { worker.perform }.to change { Member.count }.by(-1)
          expect(Member.find_by(user_id: expired_project_bot.id)).to be_nil
        end

        it 'initiates project bot removal' do
          worker.perform

          expect(
            Users::GhostUserMigration.where(user: expired_project_bot, initiator_user: nil)
          ).to be_exists
        end
      end

      context 'non-expired project bot' do
        let_it_be(:other_project_bot) { create(:user, :project_bot) }

        before do
          project.add_member(other_project_bot, :maintainer, expires_at: 10.days.from_now)
          travel_to(3.days.from_now)
        end

        it 'does not remove expired project bot that expires in the future' do
          expect { worker.perform }.to change { Member.count }.by(0)
          expect(other_project_bot.reload).to be_present
        end

        it 'does not delete project bot expiring in the future' do
          worker.perform

          expect(User.exists?(other_project_bot.id)).to be(true)
        end
      end
    end

    context 'group members' do
      let_it_be(:expired_group_member) { create(:group_member, expires_at: 1.day.from_now, access_level: GroupMember::DEVELOPER) }
      let_it_be(:group_member_expiring_in_future) { create(:group_member, expires_at: 10.days.from_now, access_level: GroupMember::DEVELOPER) }
      let_it_be(:non_expiring_group_member) { create(:group_member, expires_at: nil, access_level: GroupMember::DEVELOPER) }

      before do
        travel_to(3.days.from_now)
      end

      it 'removes expired members' do
        expect { worker.perform }.to change { Member.count }.by(-1)
        expect(Member.find_by(id: expired_group_member.id)).to be_nil
      end

      it 'leaves members that expire in the future' do
        worker.perform
        expect(group_member_expiring_in_future.reload).to be_present
      end

      it 'leaves members that do not expire at all' do
        worker.perform
        expect(non_expiring_group_member.reload).to be_present
      end

      it 'adds context to resulting jobs' do
        worker.perform

        new_job = Sidekiq::Worker.jobs.last

        expect(new_job).to include(
          'meta.root_namespace' => expired_group_member.group.full_path,
          'meta.user' => expired_group_member.user.username
        )
      end

      context 'when the user has a direct membership in a subproject' do
        let_it_be(:subproject) { create(:project, group: expired_group_member.group) }
        let_it_be(:non_expired_project_membership) { create(:project_member, user: expired_group_member.user, access_level: ProjectMember::MAINTAINER, project: subproject) }

        it 'does not expire the membership in the subgroup' do
          worker.perform
          expect(non_expired_project_membership.reload).to be_present
        end
      end

      context 'when the user has a direct membership in a subgroup' do
        let_it_be(:subgroup) { create(:group, parent: expired_group_member.group) }
        let_it_be(:non_expired_group_membership) { create(:group_member, user: expired_group_member.user, access_level: GroupMember::MAINTAINER, group: subgroup) }

        it 'does not expire the membership in the subgroup' do
          worker.perform
          expect(non_expired_group_membership.reload).to be_present
        end
      end
    end

    context 'when the last group owner expires' do
      let_it_be(:expired_group_owner) { create(:group_member, expires_at: 1.day.from_now, access_level: GroupMember::OWNER) }

      before do
        travel_to(3.days.from_now)
      end

      it 'does not delete the owner' do
        worker.perform
        expect(expired_group_owner.reload).to be_present
      end
    end

    context 'when service raises an error' do
      let_it_be(:expired_project_member) { create(:project_member, expires_at: 1.day.from_now, access_level: GroupMember::DEVELOPER) }

      let(:logger_double) { instance_double('Gitlab::Logger') }
      let(:test_err) { StandardError.new('test error') }

      before do
        allow_next_instance_of(Members::DestroyService) do |service|
          allow(service).to receive(:execute).and_raise(test_err)
        end
        allow(worker).to receive(:logger).and_return(logger_double)
        travel_to(3.days.from_now)
      end

      it 'logs errors to logger and error tracking' do
        expect(logger_double).to receive(:error).with(a_string_matching(/cannot be removed/))
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(test_err)

        worker.perform
      end
    end

    context 'pagination' do
      let_it_be(:expired_group_member) { create(:group_member, expires_at: 1.day.from_now, access_level: GroupMember::DEVELOPER) }
      let(:instance) { described_class.new }
      let(:cursor) { nil }
      let(:has_next_page) { true }
      let(:cursor_for_next_page) { 'next-page-cursor' }

      let(:paginator) do
        instance_double(
          Gitlab::Pagination::Keyset::Paginator,
          has_next_page?: has_next_page,
          cursor_for_next_page: cursor_for_next_page
        )
      end

      subject(:perform) { instance.perform(cursor) }

      before do
        allow(paginator).to receive(:each).and_yield(expired_group_member)
        travel_to(3.days.from_now)
      end

      it 'logs completed row count and enqueues next batch' do
        allow(instance).to receive(:paginate).and_return(paginator)
        expect(instance).to receive(:log_extra_metadata_on_done).with(:result, status: :limit_reached, updated_rows: 1)
        expect(described_class).to receive(:perform_in).with(described_class::BATCH_DELAY, 'next-page-cursor')

        perform
      end

      context 'when initialized with cursor' do
        let(:cursor) { 'fake-base64-encoded-data' }

        it 'passes cursor to paginate method' do
          expect(instance).to receive(:paginate).with(cursor).and_return(paginator)

          perform
        end
      end

      context 'when last page is reached' do
        let(:has_next_page) { false }
        let(:cursor_for_next_page) { nil }

        it 'logs completed row count and does not enqueue next batch' do
          allow(instance).to receive(:paginate).and_return(paginator)
          expect(instance).to receive(:log_extra_metadata_on_done).with(:result, status: :completed, updated_rows: 1)
          expect(described_class).not_to receive(:perform_async)

          perform
        end
      end
    end
  end
end
