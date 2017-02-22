require 'spec_helper'

describe RepositoryForkWorker do
  let(:project) { create(:project) }
  let(:fork_project) { create(:project, forked_from_project: project) }
  let(:shell) { Gitlab::Shell.new }

  subject { RepositoryForkWorker.new }

  before do
    allow(subject).to receive(:gitlab_shell).and_return(shell)
  end

  describe "#perform" do
    it "creates a new repository from a fork" do
      expect(shell).to receive(:fork_repository).with(
        '/test/path',
        project.path_with_namespace,
        project.repository_storage_path,
        fork_project.namespace.path
      ).and_return(true)

      subject.perform(
        project.id,
        '/test/path',
        project.path_with_namespace,
        fork_project.namespace.path)
    end

    it 'flushes various caches' do
      expect(shell).to receive(:fork_repository).with(
        '/test/path',
        project.path_with_namespace,
        project.repository_storage_path,
        fork_project.namespace.path
      ).and_return(true)

      expect_any_instance_of(Repository).to receive(:expire_emptiness_caches).
        and_call_original

      expect_any_instance_of(Repository).to receive(:expire_exists_cache).
        and_call_original

      subject.perform(project.id, '/test/path', project.path_with_namespace,
                      fork_project.namespace.path)
    end

    it "handles bad fork" do
      expect(shell).to receive(:fork_repository).and_return(false)

      expect(subject.logger).to receive(:error)

      subject.perform(
        project.id,
        '/test/path',
        project.path_with_namespace,
        fork_project.namespace.path)
    end
  end
end
