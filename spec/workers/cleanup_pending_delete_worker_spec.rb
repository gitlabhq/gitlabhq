require 'spec_helper'

describe CleanupPendingDeleteWorker do
  let(:project) { create(:empty_project, pending_delete: true) }
  let(:admin)   { create(:admin) }

  subject { CleanupPendingDeleteWorker.new }

  describe "#perform" do
    it "queues projects for deletion" do
      expect(ProjectDestroyWorker).to receive(:perform_async).with(project.id, admin.id)
      subject.perform
    end
  end
end
