# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GitalyClient::Util do
  describe '.repository' do
    let(:repository_storage) { 'default' }
    let(:relative_path) { 'my/repo.git' }
    let(:gl_repository) { 'project-1' }
    let(:git_object_directory) { '.git/objects' }
    let(:git_alternate_object_directory) { ['/dir/one', '/dir/two'] }
    let(:gl_project_path) { 'namespace/myproject' }
    let(:git_env) do
      {
        'GIT_OBJECT_DIRECTORY_RELATIVE' => git_object_directory,
        'GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE' => git_alternate_object_directory
      }
    end

    subject do
      described_class.repository(repository_storage, relative_path, gl_repository, gl_project_path)
    end

    it 'creates a Gitaly::Repository with the given data' do
      allow(Gitlab::Git::HookEnv).to receive(:all).with(gl_repository).and_return(git_env)

      expect(subject).to be_a(Gitaly::Repository)
      expect(subject.storage_name).to eq(repository_storage)
      expect(subject.relative_path).to eq(relative_path)
      expect(subject.gl_repository).to eq(gl_repository)
      expect(subject.git_object_directory).to eq(git_object_directory)
      expect(subject.git_alternate_object_directories).to eq(git_alternate_object_directory)
      expect(subject.gl_project_path).to eq(gl_project_path)
    end
  end
end
