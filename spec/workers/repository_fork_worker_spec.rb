require 'spec_helper'

describe RepositoryForkWorker do
  let(:project) { create(:project) }
  let(:fork_project) { create(:project, forked_from_project: project) }

  subject { RepositoryForkWorker.new }

  describe "#perform" do
    it "creates a new repository from a fork" do
      expect_any_instance_of(Gitlab::Shell).to receive(:fork_repository).with(
                                                   project.path_with_namespace,
                                                   fork_project.namespace.path).
                                                   and_return(true)
      expect(ProjectCacheWorker).to receive(:perform_async)

      subject.perform(project.id,
                      project.path_with_namespace,
                      fork_project.namespace.path)
    end

    it "handles bad fork" do
      expect_any_instance_of(Gitlab::Shell).to receive(:fork_repository).and_return(false)
      subject.perform(project.id,
                      project.path_with_namespace,
                      fork_project.namespace.path)
    end
  end
end
