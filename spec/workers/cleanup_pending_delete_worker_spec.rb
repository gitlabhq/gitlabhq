require 'spec_helper'

describe CleanupPendingDeleteWorker do
  let!(:admin)  { create(:admin) }
  let(:project) { create(:empty_project, pending_delete: true) }
  let(:group)   { create(:group) }

  subject { described_class.new }

  describe "#perform" do
    it "queues groups for deletion" do
      # We can't set deleted_at on 1.week.ago because of acts_as_paranoid
      group.destroy

      expect(GroupDestroyWorker).to receive(:perform_async).with(group.id, admin.id)

      subject.perform
    end

    it "queues projects for deletion" do
      expect(ProjectDestroyWorker).to receive(:perform_async).with(project.id, admin.id)

      subject.perform
    end
  end
end
