# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoveExpiredMembersWorker do
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

        expect(new_job).to include('meta.project' => expired_project_member.project.full_path,
                                   'meta.user' => expired_project_member.user.username)
      end
    end

    context 'project bots' do
      let(:project) { create(:project) }

      context 'expired project bot', :sidekiq_inline do
        let_it_be(:expired_project_bot) { create(:user, :project_bot) }

        before do
          project.add_user(expired_project_bot, :maintainer, expires_at: 1.day.from_now)
          travel_to(3.days.from_now)
        end

        it 'removes expired project bot membership' do
          expect { worker.perform }.to change { Member.count }.by(-1)
          expect(Member.find_by(user_id: expired_project_bot.id)).to be_nil
        end

        it 'deletes expired project bot' do
          worker.perform

          expect(User.exists?(expired_project_bot.id)).to be(false)
        end
      end

      context 'non-expired project bot' do
        let_it_be(:other_project_bot) { create(:user, :project_bot) }

        before do
          project.add_user(other_project_bot, :maintainer, expires_at: 10.days.from_now)
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

        expect(new_job).to include('meta.root_namespace' => expired_group_member.group.full_path,
                                   'meta.user' => expired_group_member.user.username)
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
  end
end
