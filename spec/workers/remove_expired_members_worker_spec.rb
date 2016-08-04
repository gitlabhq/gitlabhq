require 'spec_helper'

describe RemoveExpiredMembersWorker do
  let!(:worker) { RemoveExpiredMembersWorker.new }
  let!(:expired_member) { create(:project_member, expires_at: 1.hour.ago) }
  let!(:member_expiring_in_future) { create(:project_member, expires_at: 10.days.from_now) }
  let!(:non_expiring_member) { create(:project_member, expires_at: nil) }

  describe "#perform" do
    it "removes expired members" do
      expect { worker.perform }.to change { Member.count }.by(-1)
      expect(Member.find_by(id: expired_member.id)).to be_nil
    end

    it "leaves members who expire in the future" do
      worker.perform
      expect(member_expiring_in_future.reload).to be_present
    end

    it "leaves members who do not expire at all" do
      worker.perform
      expect(non_expiring_member.reload).to be_present
    end
  end
end
