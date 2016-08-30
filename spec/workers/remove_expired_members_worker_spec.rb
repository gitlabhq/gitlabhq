require 'spec_helper'

describe RemoveExpiredMembersWorker do
  let(:worker) { RemoveExpiredMembersWorker.new }

  describe '#perform' do
    context 'project members' do
      let!(:expired_project_member) { create(:project_member, expires_at: 1.hour.ago, access_level: GroupMember::DEVELOPER) }
      let!(:project_member_expiring_in_future) { create(:project_member, expires_at: 10.days.from_now, access_level: GroupMember::DEVELOPER) }
      let!(:non_expiring_project_member) { create(:project_member, expires_at: nil, access_level: GroupMember::DEVELOPER) }

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
    end

    context 'group members' do
      let!(:expired_group_member) { create(:group_member, expires_at: 1.hour.ago, access_level: GroupMember::DEVELOPER) }
      let!(:group_member_expiring_in_future) { create(:group_member, expires_at: 10.days.from_now, access_level: GroupMember::DEVELOPER) }
      let!(:non_expiring_group_member) { create(:group_member, expires_at: nil, access_level: GroupMember::DEVELOPER) }

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
    end

    context 'when the last group owner expires' do
      let!(:expired_group_owner) { create(:group_member, expires_at: 1.hour.ago, access_level: GroupMember::OWNER) }

      it 'does not delete the owner' do
        worker.perform
        expect(expired_group_owner.reload).to be_present
      end
    end
  end
end
