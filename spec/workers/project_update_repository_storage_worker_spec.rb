require 'spec_helper'

describe ProjectUpdateRepositoryStorageWorker do
  let(:project) { create(:project) }

  subject { ProjectUpdateRepositoryStorageWorker.new }

  describe "#perform" do
    it "should call the update repository storage service" do
      expect_any_instance_of(Projects::UpdateRepositoryStorageService).
        to receive(:execute).with('new_storage')

      subject.perform(project.id, 'new_storage')
    end
  end
end
