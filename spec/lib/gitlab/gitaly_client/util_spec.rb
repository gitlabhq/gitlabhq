require 'spec_helper'

describe Gitlab::GitalyClient::Util do
  describe '.repository' do
    let(:repository_storage) { 'default' }
    let(:relative_path) { 'my/repo.git' }
    let(:gl_repository) { 'project-1' }
    let(:git_object_directory) { '.git/objects' }
    let(:git_alternate_object_directory) { ['/dir/one', '/dir/two'] }

    subject do
      described_class.repository(repository_storage, relative_path, gl_repository)
    end

    it 'creates a Gitaly::Repository with the given data' do
      allow(Gitlab::Git::Env).to receive(:[]).with('GIT_OBJECT_DIRECTORY_RELATIVE')
        .and_return(git_object_directory)
      allow(Gitlab::Git::Env).to receive(:[]).with('GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE')
        .and_return(git_alternate_object_directory)

      expect(subject).to be_a(Gitaly::Repository)
      expect(subject.storage_name).to eq(repository_storage)
      expect(subject.relative_path).to eq(relative_path)
      expect(subject.gl_repository).to eq(gl_repository)
      expect(subject.git_object_directory).to eq(git_object_directory)
      expect(subject.git_alternate_object_directories).to eq(git_alternate_object_directory)
    end
  end

  describe '.gitaly_user' do
    let(:user) { create(:user) }
    let(:gl_id) { Gitlab::GlId.gl_id(user) }

    subject { described_class.gitaly_user(user) }

    it 'creates a Gitaly::User from a GitLab user' do
      expect(subject).to be_a(Gitaly::User)
      expect(subject.name).to eq(user.name)
      expect(subject.email).to eq(user.email)
      expect(subject.gl_id).to eq(gl_id)
    end
  end
end
