require 'spec_helper'

describe GitGarbageCollectWorker do
  let(:project) { create(:project) }
  let(:shell) { Gitlab::Shell.new }

  subject { GitGarbageCollectWorker.new }

  before do
    allow(subject).to receive(:gitlab_shell).and_return(shell)
  end

  describe "#perform" do
    it "runs `git gc`" do
      expect(shell).to receive(:gc).with(
        project.repository_storage_path,
        project.path_with_namespace).
      and_return(true)
      expect_any_instance_of(Repository).to receive(:after_create_branch)

      subject.perform(project.id)
    end
  end
end
