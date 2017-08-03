require 'spec_helper'

describe GeoRepositoryDestroyWorker do
  let!(:project) { create :project_empty_repo }
  let!(:path) { project.repository.full_path }
  let!(:remove_path) { path.sub(/\.git\Z/, "+#{project.id}+deleted.git") }
  let(:perform!) { subject.perform(project.id, project.name, path) }

  it 'delegates project removal to Projects::DestroyService' do
    expect_any_instance_of(EE::Projects::DestroyService).to receive(:geo_replicate)

    perform!
  end

  context 'sidekiq execution' do
    before do
      project.delete
    end

    it 'removes the repository from disk' do
      expect(project.gitlab_shell.exists?(project.repository_storage_path, path + '.git')).to be_truthy

      Sidekiq::Testing.inline! { perform! }

      expect(project.gitlab_shell.exists?(project.repository_storage_path, path + '.git')).to be_falsey
      expect(project.gitlab_shell.exists?(project.repository_storage_path, remove_path + '.git')).to be_falsey
    end
  end

  describe '#probe_repository_storage' do
    it 'returns a repository_storage when repository can be found' do
      expect(subject.send(:probe_repository_storage, project.full_path)).to eq('default')
    end

    it 'returns nil when repository cannot be found in any existing repository_storage' do
      expect(subject.send(:probe_repository_storage, 'nonexistent/project')).to eq(nil)
    end
  end
end
